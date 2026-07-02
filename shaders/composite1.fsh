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

// Uniforms
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

// 3D Hash function for volumetric noise
float hash31(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

// 3D Value Noise
float valueNoise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);
    
    float a = hash31(i);
    float b = hash31(i + vec3(1.0, 0.0, 0.0));
    float c = hash31(i + vec3(0.0, 1.0, 0.0));
    float d = hash31(i + vec3(1.0, 1.0, 0.0));
    float e = hash31(i + vec3(0.0, 0.0, 1.0));
    float f_val = hash31(i + vec3(1.0, 0.0, 1.0));
    float g = hash31(i + vec3(0.0, 1.0, 1.0));
    float h = hash31(i + vec3(1.0, 1.0, 1.0));
    
    float n0 = mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
    float n1 = mix(mix(e, f_val, u.x), mix(g, h, u.x), u.y);
    return mix(n0, n1, u.z);
}

// 3D fBm for cloud structure
float fbm3D(vec3 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float maxAmplitude = 0.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * valueNoise3D(p * frequency);
        maxAmplitude += amplitude;
        frequency *= 2.05;
        amplitude *= 0.52;
    }
    return value / maxAmplitude;
}

// Cloud density function with height-based falloff
float getCloudDensity(vec3 pos, float time) {
    // Apply wind animation
    vec3 windScroll = vec3(time * 0.02, 0.0, time * 0.008);
    vec3 p = pos * 0.008 + windScroll;
    
    // Multiple octaves for natural cloud structure
    float density = fbm3D(p, 4);
    density += fbm3D(p * 1.5 + 21.5, 3) * 0.5;
    
    // Shape the clouds with smoothstep
    density = smoothstep(0.35, 0.75, density);
    
    // Height-based density falloff (clouds dissipate at edges)
    float heightGradient = smoothstep(0.0, 1.0, pos.y);
    heightGradient *= smoothstep(2.0, 0.5, pos.y);
    
    return density * heightGradient * SKY_CLOUD_AMOUNT;
}

// Light transmission through clouds (shadow ray)
float getLightTransmission(vec3 pos, vec3 sunDir, float time) {
    vec3 shadowPos = pos;
    float transmission = 1.0;
    
    // Sample along sun direction (short march)
    for (int i = 0; i < 6; i++) {
        shadowPos += sunDir * 0.3;
        float d = getCloudDensity(shadowPos, time);
        transmission *= exp(-d * 0.5);
        if (transmission < 0.1) break;
    }
    
    return transmission;
}

// Main volumetric raymarching function
vec3 renderVolumetricClouds(vec3 rayDir, vec3 eyeVector, vec3 skyColor) {
    if (eyeVector.y <= 0.01) return skyColor;
    
    vec3 rayDir_norm = normalize(rayDir);
    
    // Cloud layer boundaries (world units)
    float cloudBase = 80.0;
    float cloudTop = 250.0;
    
    // Calculate intersection distances
    float tBase = cloudBase / eyeVector.y;
    float tTop = cloudTop / eyeVector.y;
    
    // Clamp march range
    float t_start = max(tBase * 0.1, 0.1);
    float t_end = min(tTop, 500.0);
    
    vec4 accum = vec4(0.0);
    
    // Adaptive step count based on detail slider
    int steps = int(mix(16.0, 48.0, CLOUD_DETAIL));
    float stepSize = (t_end - t_start) / float(steps);
    
    // Dithering for better quality with fewer steps
    float dither = fract(sin(dot(eyeVector.xy, vec2(12.9898, 78.233))) * 43758.5453);
    
    vec3 sunDir = normalize(vec3(1.0, 0.8, 0.3)); // Approximate sun direction
    
    for (int i = 0; i < steps; i++) {
        // Jittered sampling
        float t = t_start + (float(i) + dither * 0.5) * stepSize;
        vec3 pos = eyeVector * t;
        
        // Ensure position is within reasonable bounds
        if (pos.y < cloudBase * 0.5 || pos.y > cloudTop * 2.0) continue;
        
        // Sample cloud density at this position
        float density = getCloudDensity(pos, frameTimeCounter);
        
        if (density > 0.001) {
            // Calculate light transmission through cloud
            float lightTrans = getLightTransmission(pos, sunDir, frameTimeCounter);
            
            // Cloud coloring based on height and light
            vec3 cloudCol = mix(vec3(0.1, 0.15, 0.25), vec3(1.0, 0.95, 0.85), lightTrans * 0.8);
            cloudCol = mix(cloudCol, vec3(0.95), density * 0.3); // Brighten thick clouds
            
            // Front-to-back alpha blending
            float alpha = density * mix(0.5, 1.0, CLOUD_OPACITY) * stepSize;
            accum.rgb += (1.0 - accum.a) * cloudCol * alpha;
            accum.a += (1.0 - accum.a) * alpha;
        }
        
        // Early termination for performance
        if (accum.a >= 0.95) break;
    }
    
    // Blend volumetric clouds over sky
    return mix(skyColor, accum.rgb, accum.a);
}

vec3 renderSkyClouds(vec3 eyeVector, vec3 skyColor) {
    // Use volumetric raymarching for 3D clouds
    if (eyeVector.y <= 0.01) return skyColor;
    
    // Simple estimate of ray direction (could be more accurate)
    return renderVolumetricClouds(eyeVector, eyeVector, skyColor);
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
        color.rgb = renderSkyClouds(eyeVector, color.rgb);
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
