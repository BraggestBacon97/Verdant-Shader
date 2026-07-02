#version 330 compatibility

#ifndef STYLE_STRENGTH
#define STYLE_STRENGTH 0.65
#endif
#ifndef BLOOM_STRENGTH
#define BLOOM_STRENGTH 0.18
#endif

vec3 applyVerdantGrade(vec3 color) {
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    vec3 saturated = mix(vec3(luma), color, 1.0 + 0.12 * STYLE_STRENGTH);
    vec3 lifted = saturated + vec3(0.01, 0.018, 0.012) * STYLE_STRENGTH;
    return max(lifted, vec3(0.0));
}

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    color = texture(colortex0, texcoord);

    vec2 texel = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec3 bloom = vec3(0.0);
    bloom += max(texture(colortex0, texcoord + texel * vec2(-2.0, 0.0)).rgb - vec3(0.78), vec3(0.0));
    bloom += max(texture(colortex0, texcoord + texel * vec2(2.0, 0.0)).rgb - vec3(0.78), vec3(0.0));
    bloom += max(texture(colortex0, texcoord + texel * vec2(0.0, -2.0)).rgb - vec3(0.78), vec3(0.0));
    bloom += max(texture(colortex0, texcoord + texel * vec2(0.0, 2.0)).rgb - vec3(0.78), vec3(0.0));
    bloom += max(texture(colortex0, texcoord + texel * vec2(-1.5, -1.5)).rgb - vec3(0.78), vec3(0.0));
    bloom += max(texture(colortex0, texcoord + texel * vec2(1.5, -1.5)).rgb - vec3(0.78), vec3(0.0));
    bloom += max(texture(colortex0, texcoord + texel * vec2(-1.5, 1.5)).rgb - vec3(0.78), vec3(0.0));
    bloom += max(texture(colortex0, texcoord + texel * vec2(1.5, 1.5)).rgb - vec3(0.78), vec3(0.0));
    color.rgb += bloom * (BLOOM_STRENGTH / 8.0);

    color.rgb = color.rgb / (color.rgb + vec3(1.0));
    color.rgb = mix(color.rgb, smoothstep(vec3(0.0), vec3(1.0), color.rgb), 0.16 * STYLE_STRENGTH);
    color.rgb = applyVerdantGrade(color.rgb);

    vec2 vignetteCoord = texcoord * (1.0 - texcoord.yx);
    float vignette = clamp(vignetteCoord.x * vignetteCoord.y * 18.0, 0.0, 1.0);
    color.rgb *= mix(0.86, 1.0, mix(1.0, vignette, STYLE_STRENGTH));

    color.rgb = pow(max(color.rgb, vec3(0.0)), vec3(1.0 / 2.2));
}
