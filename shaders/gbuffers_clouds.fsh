#version 330 compatibility

#define CUSTOM_CLOUDS
#define CLOUD_OPACITY 0.82 // [0.35 0.5 0.65 0.82 1.0]
#define CLOUD_DETAIL 0.65 // [0.0 0.35 0.65 0.85 1.0]

uniform sampler2D gtexture;
uniform float alphaTestRef;
uniform float frameTimeCounter;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 worldPos;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float cloudNoise(vec2 p) {
    float n = valueNoise(p);
    n += valueNoise(p * 2.03 + 17.4) * 0.5;
    n += valueNoise(p * 4.01 + 41.7) * 0.25 * CLOUD_DETAIL;
    return n / (1.5 + 0.25 * CLOUD_DETAIL);
}

void main() {
    vec4 base = texture(gtexture, texcoord) * glcolor;

#ifdef CUSTOM_CLOUDS
    vec2 cloudCoord = worldPos.xz * 0.009 + vec2(frameTimeCounter * 0.012, frameTimeCounter * 0.004);
    float shape = cloudNoise(cloudCoord);
    float softEdge = smoothstep(0.30, 0.78, shape);
    float underside = clamp(1.0 - normal.y * 0.35, 0.55, 1.0);
    vec3 warmTop = vec3(1.0, 0.96, 0.88);
    vec3 coolBase = vec3(0.62, 0.70, 0.76);

    base.rgb *= mix(coolBase * underside, warmTop, softEdge);
    base.a *= CLOUD_OPACITY * mix(0.45, 1.12, softEdge);
#endif

    color = base;

    if (color.a < alphaTestRef) {
        discard;
    }

    lightmapData = vec4(clamp(lmcoord, 0.0, 1.0), 0.0, 1.0);
    encodedNormal = vec4(normalize(normal) * 0.5 + 0.5, 1.0);
}
