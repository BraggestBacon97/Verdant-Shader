#version 330 compatibility

// Shader option defaults with slider ranges
#ifndef STYLE_STRENGTH
#define STYLE_STRENGTH 0.65 // [0.0 0.25 0.5 0.65 0.8 1.0]
#endif
#ifndef LIGHTING_STRENGTH
#define LIGHTING_STRENGTH 1.0 // [0.5 0.75 1.0 1.25 1.5]
#endif
#ifndef SPECULAR_STRENGTH
#define SPECULAR_STRENGTH 0.12 // [0.0 0.06 0.12 0.2 0.35]
#endif
#ifndef RIM_LIGHT_STRENGTH
#define RIM_LIGHT_STRENGTH 0.18 // [0.0 0.1 0.18 0.28 0.4]
#endif
#ifndef ATMOSPHERE_STRENGTH
#define ATMOSPHERE_STRENGTH 0.55 // [0.0 0.25 0.55 0.75 1.0]
#endif
#define SKY_CLOUDS
#ifndef SKY_CLOUD_AMOUNT
#define SKY_CLOUD_AMOUNT 0.72 // [0.0 0.35 0.55 0.72 0.9 1.0]
#endif
#ifndef CLOUD_OPACITY
#define CLOUD_OPACITY 0.92 // [0.0 0.3 0.55 0.82 1.0]
#endif
#ifndef CLOUD_DETAIL
#define CLOUD_DETAIL 0.82 // [0.0 0.25 0.45 0.72 0.9 1.0]
#endif
#ifndef BLOOM_STRENGTH
#define BLOOM_STRENGTH 0.18 // [0.0 0.08 0.18 0.3 0.45]
#endif
#ifndef FOG_DENSITY
#define FOG_DENSITY 5.0 // [1.0 2.5 5.0 8.0 12.0]
#endif

// Noise and utility functions
float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float valueNoise2D(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm2D(vec2 p) {
    float n = valueNoise2D(p) * 0.55;
    n += valueNoise2D(p * 2.07 + 13.7) * 0.28;
    n += valueNoise2D(p * 4.13 + 31.1) * 0.12;
    n += valueNoise2D(p * 8.19 + 79.4) * 0.05;
    return n;
}

float fbm2DHigh(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float maxAmplitude = 0.0;
    for (int i = 0; i < octaves; i++) {
        value += amplitude * valueNoise2D(p * frequency);
        maxAmplitude += amplitude;
        frequency *= 2.05;
        amplitude *= 0.52;
    }
    return value / maxAmplitude;
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
    vec4 homPos = projectionMatrix * vec4(position, 1.0);
    return homPos.xyz / homPos.w;
}

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 fogColor;
uniform float far;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 renderSkyCloudsSkydome(vec3 eyeVector, vec3 skyColor) {
    // Ensure we only render upper hemisphere
    if (eyeVector.y <= 0.0) return skyColor;
    
    // Normalize eye vector for proper cone calculation
    eyeVector = normalize(eyeVector);
    
    // Planar projection: xz divided by y gives infinite plane mapping
    // This is the mathematical trick for sky domes
    vec2 cloudUV = eyeVector.xz / eyeVector.y;
    
    // Scale and apply animation with CLOUD_DETAIL control
    float detailScale = mix(0.7, 2.8, CLOUD_DETAIL);
    float timeMod = frameTimeCounter * 0.0012;
    vec2 windSlow = vec2(timeMod, timeMod * 0.5);
    vec2 windFast = vec2(timeMod * 2.5, timeMod * 1.2);
    
    // Layer 1: Large cloud structure with slow movement
    vec2 largeCloudUv = cloudUV * 0.08 * detailScale + windSlow;
    float largeClouds = fbm2DHigh(largeCloudUv, 5);
    largeClouds = smoothstep(0.28, 0.72, largeClouds);
    
    // Layer 2: Medium detail with different phase
    vec2 mediumCloudUv = cloudUV * 0.22 * detailScale + windSlow * 0.6 + vec2(12.5, 8.3);
    float mediumClouds = fbm2DHigh(mediumCloudUv, 4);
    mediumClouds = smoothstep(0.32, 0.76, mediumClouds * 1.2);
    
    // Multiplicative blending for depth
    float cloudCover = mix(largeClouds * mediumClouds, 1.0, 0.15);
    
    // Layer 3: High-frequency wisps with detail control
    vec2 wispUv = cloudUV * 0.45 * detailScale + windFast + vec2(33.7, 19.2);
    float wisps = fbm2D(wispUv);
    wisps = smoothstep(0.45, 0.80, wisps);
    
    // Combine all layers with higher base coverage
    float totalCloud = mix(cloudCover, 1.0, wisps * 0.45);
    totalCloud = clamp(totalCloud, 0.0, 1.0);
    
    // Horizon fading with softer falloff for better visibility
    float horizonFade = smoothstep(0.02, 0.40, eyeVector.y);
    totalCloud *= horizonFade;
    
    // Sky gradient based on view angle
    float zenithGradient = mix(0.2, 1.0, eyeVector.y);
    
    // Color grading: dramatic shadow-to-light transitions
    vec3 darkShadow = vec3(0.04, 0.08, 0.14);
    vec3 midTone = vec3(0.34, 0.42, 0.54);
    vec3 brightTop = vec3(0.90, 0.90, 0.86);
    
    // Interpolate through cloud density
    vec3 cloudColor = mix(darkShadow, midTone, cloudCover);
    cloudColor = mix(cloudColor, brightTop, wisps * 0.65);
    
    // Apply amount, coverage and opacity control
    float cloudStrength = SKY_CLOUD_AMOUNT;
    float coverage = totalCloud * mix(0.3, 1.0, CLOUD_OPACITY) * cloudStrength;
    vec3 result = mix(skyColor, cloudColor, coverage);
    
    // Subtle brightening at high altitude
    result = mix(result, vec3(0.84, 0.88, 0.92), wisps * 0.12 * zenithGradient);
    
    return result;
}

void main() {
    color = texture(colortex0, texcoord);

    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        // Calculate view vector for sky dome mapping
        vec3 ndcPos = vec3(texcoord * 2.0 - 1.0, depth);
        vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
        vec3 eyeVector = (gbufferModelViewInverse * vec4(viewPos, 0.0)).xyz;
        
        float horizon = 1.0 - smoothstep(0.42, 0.86, texcoord.y);
        vec3 skyHaze = mix(pow(fogColor, vec3(2.2)), vec3(0.55, 0.70, 0.62), 0.22 * STYLE_STRENGTH);
        color.rgb = mix(color.rgb, skyHaze, horizon * 0.18 * ATMOSPHERE_STRENGTH);
#ifdef SKY_CLOUDS
        color.rgb = renderSkyCloudsSkydome(eyeVector, color.rgb);
#endif
        return;
    }

    vec3 NDCPos = vec3(texcoord, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);

    float dist = length(viewPos) / far;
    float fogFactor = exp(-FOG_DENSITY * (1.0 - dist));
    vec3 styledFog = mix(pow(fogColor, vec3(2.2)), vec3(0.42, 0.58, 0.54), 0.18 * STYLE_STRENGTH);
    float lowMist = smoothstep(0.55, 1.0, dist) * (1.0 - smoothstep(0.55, 0.95, texcoord.y));
    float atmosphere = clamp(fogFactor + lowMist * 0.16 * ATMOSPHERE_STRENGTH, 0.0, 1.0);
    color.rgb = mix(color.rgb, styledFog, atmosphere);
}
