#version 330 compatibility

#define SHADOWS

// Core shader functions and options (common)
#ifndef STYLE_STRENGTH
#define STYLE_STRENGTH 0.65
#endif
#ifndef LIGHTING_STRENGTH
#define LIGHTING_STRENGTH 1.0
#endif
#ifndef SPECULAR_STRENGTH
#define SPECULAR_STRENGTH 0.12
#endif
#ifndef RIM_LIGHT_STRENGTH
#define RIM_LIGHT_STRENGTH 0.18
#endif
#ifndef ATMOSPHERE_STRENGTH
#define ATMOSPHERE_STRENGTH 0.55
#endif
#ifndef BLOOM_STRENGTH
#define BLOOM_STRENGTH 0.18
#endif

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

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
    vec4 homPos = projectionMatrix * vec4(position, 1.0);
    return homPos.xyz / homPos.w;
}

vec3 decodeNormal(vec3 encodedNormal) {
    return normalize((encodedNormal - 0.5) * 2.0);
}

vec3 applyVerdantGrade(vec3 color) {
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    vec3 saturated = mix(vec3(luma), color, 1.0 + 0.12 * STYLE_STRENGTH);
    vec3 lifted = saturated + vec3(0.01, 0.018, 0.012) * STYLE_STRENGTH;
    return max(lifted, vec3(0.0));
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

const vec3 blocklightColor = vec3(1.0, 0.50, 0.16);
const vec3 skylightColor = vec3(0.09, 0.18, 0.32);
const vec3 sunlightColor = vec3(1.0, 0.93, 0.76);
const vec3 ambientColor = vec3(0.045, 0.052, 0.058);
const vec3 shadowTint = vec3(0.72, 0.82, 1.0);

// Shadow distortion from distort.glsl
vec3 distortShadowClipPos(vec3 shadowClipPos) {
    return vec3(shadowClipPos.x, shadowClipPos.y, shadowClipPos.z * 0.2 + 0.8) * 0.96 + 0.02;
}

/*
const int colortex0Format = RGB16;
*/

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

float getShadow(vec3 shadowScreenPos) {
    if (shadowScreenPos.x < 0.0 || shadowScreenPos.x > 1.0 ||
        shadowScreenPos.y < 0.0 || shadowScreenPos.y > 1.0 ||
        shadowScreenPos.z < 0.0 || shadowScreenPos.z > 1.0) {
        return 1.0;
    }

#ifdef SHADOWS
    return step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);
#else
    return 1.0;
#endif
}

void main() {
    color = texture(colortex0, texcoord);
    color.rgb = pow(color.rgb, vec3(2.2));

    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        return;
    }

    vec2 lightmap = texture(colortex1, texcoord).rg;
    vec3 normal = decodeNormal(texture(colortex2, texcoord).rgb);

    vec3 lightVector = normalize(shadowLightPosition);
    vec3 worldLightVector = normalize(mat3(gbufferModelViewInverse) * lightVector);

    vec3 NDCPos = vec3(texcoord, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 viewDir = normalize(-feetPlayerPos + vec3(0.0, 0.0001, 0.0));
    vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
    vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    shadowClipPos.z -= 0.001;
    shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
    vec3 shadowScreenPos = (shadowClipPos.xyz / shadowClipPos.w) * 0.5 + 0.5;

    float NdotL = clamp(dot(worldLightVector, normal), 0.0, 1.0);
    float wrappedSun = clamp(NdotL * 0.82 + 0.18, 0.0, 1.0);
    float shadow = getShadow(shadowScreenPos);
    float normalUp = clamp(normal.y * 0.5 + 0.5, 0.0, 1.0);
    float contactShade = mix(0.82, 1.0, normalUp);

    vec3 halfVector = normalize(worldLightVector + viewDir + vec3(0.0, 0.0001, 0.0));
    float specular = pow(clamp(dot(normal, halfVector), 0.0, 1.0), 48.0);
    specular *= SPECULAR_STRENGTH * shadow * lightmap.g * smoothstep(0.15, 0.75, NdotL);

    float rim = pow(1.0 - clamp(dot(normal, viewDir), 0.0, 1.0), 2.2);
    rim *= RIM_LIGHT_STRENGTH * lightmap.g * (0.45 + 0.55 * shadow);

    float blockAmount = pow(clamp(lightmap.r, 0.0, 1.0), 1.35);
    vec3 blocklight = blockAmount * blocklightColor * (1.0 + 0.25 * blockAmount);
    vec3 skylight = lightmap.g * skylightColor * (0.70 + 0.30 * normalUp);
    vec3 sunlight = sunlightColor * wrappedSun * mix(vec3(0.30) * shadowTint, vec3(1.0), shadow);
    vec3 ambient = ambientColor * (1.0 + 0.35 * lightmap.g);

    vec3 direct = blocklight + skylight + sunlight;
    vec3 lit = color.rgb * (ambient + direct * LIGHTING_STRENGTH) * contactShade;
    lit += sunlightColor * specular * (0.35 + 0.65 * (1.0 - luminance(color.rgb)));
    lit += skylightColor * rim * STYLE_STRENGTH;
    color.rgb = mix(lit, applyVerdantGrade(lit), STYLE_STRENGTH);
}
