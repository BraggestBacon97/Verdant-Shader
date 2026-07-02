#define STYLE_STRENGTH 0.65 // [0.0 0.25 0.5 0.65 0.8 1.0]
#define LIGHTING_STRENGTH 1.0 // [0.5 0.75 1.0 1.25 1.5]
#define SPECULAR_STRENGTH 0.12 // [0.0 0.06 0.12 0.2 0.35]
#define RIM_LIGHT_STRENGTH 0.18 // [0.0 0.1 0.18 0.28 0.4]
#define ATMOSPHERE_STRENGTH 0.55 // [0.0 0.25 0.55 0.75 1.0]
#define SKY_CLOUDS
#define SKY_CLOUD_AMOUNT 0.72 // [0.0 0.35 0.55 0.72 0.9 1.0]
#define BLOOM_STRENGTH 0.18 // [0.0 0.08 0.18 0.3 0.45]

const vec3 blocklightColor = vec3(1.0, 0.50, 0.16);
const vec3 skylightColor = vec3(0.09, 0.18, 0.32);
const vec3 sunlightColor = vec3(1.0, 0.93, 0.76);
const vec3 ambientColor = vec3(0.045, 0.052, 0.058);
const vec3 shadowTint = vec3(0.72, 0.82, 1.0);

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
