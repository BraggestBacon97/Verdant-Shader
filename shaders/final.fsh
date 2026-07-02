#version 330 compatibility

#include "/lib/common.glsl"

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
