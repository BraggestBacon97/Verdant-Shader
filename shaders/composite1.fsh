#version 330 compatibility

#define FOG_DENSITY 5.0 // [1.0 2.5 5.0 8.0 12.0]

#include "/lib/common.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform float far;
uniform float frameTimeCounter;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 renderSkyClouds(vec2 uv, vec3 skyColor) {
    vec2 centered = uv * 2.0 - 1.0;
    float horizon = 1.0 - smoothstep(0.35, 0.92, uv.y);
    float upperSky = smoothstep(0.36, 0.90, uv.y);
    float perspective = 1.0 / max(0.18, uv.y + 0.08);
    vec2 wind = vec2(frameTimeCounter * 0.006, frameTimeCounter * 0.0015);

    vec2 deckUv = vec2(centered.x * perspective * 1.45, perspective * 0.42) + wind;
    float broad = fbm2D(deckUv * vec2(1.15, 0.62));
    float broken = fbm2D(deckUv * vec2(2.6, 1.25) + vec2(21.0, 3.5));
    float deck = smoothstep(0.47, 0.72, broad + broken * 0.34);
    deck *= smoothstep(0.04, 0.28, uv.y) * horizon;

    vec2 cirrusUv = vec2(centered.x * 1.9 + frameTimeCounter * 0.004, uv.y * 7.0);
    float cirrusBands = sin((cirrusUv.x + fbm2D(cirrusUv * 0.55) * 1.8) * 6.0);
    float cirrusNoise = fbm2D(cirrusUv * vec2(1.4, 0.22) + 9.0);
    float cirrus = smoothstep(0.42, 0.82, cirrusBands * 0.26 + cirrusNoise);
    cirrus *= upperSky * (1.0 - deck * 0.65);

    vec3 deckShadow = vec3(0.48, 0.56, 0.62);
    vec3 deckLight = vec3(1.0, 0.94, 0.82);
    vec3 cloudDeck = mix(deckShadow, deckLight, smoothstep(0.45, 0.9, broad));
    vec3 cirrusColor = vec3(0.92, 0.94, 0.92);

    vec3 withDeck = mix(skyColor, cloudDeck, deck * SKY_CLOUD_AMOUNT);
    return mix(withDeck, cirrusColor, cirrus * 0.32 * SKY_CLOUD_AMOUNT);
}

void main() {
    color = texture(colortex0, texcoord);

    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        float horizon = 1.0 - smoothstep(0.42, 0.86, texcoord.y);
        vec3 skyHaze = mix(pow(fogColor, vec3(2.2)), vec3(0.55, 0.70, 0.62), 0.22 * STYLE_STRENGTH);
        color.rgb = mix(color.rgb, skyHaze, horizon * 0.18 * ATMOSPHERE_STRENGTH);
#ifdef SKY_CLOUDS
        color.rgb = renderSkyClouds(texcoord, color.rgb);
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
