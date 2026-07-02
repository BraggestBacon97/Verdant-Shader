#version 330 compatibility

uniform sampler2D colortex0;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    color = texture(colortex0, texcoord);
    color.rgb = pow(max(color.rgb, vec3(0.0)), vec3(1.0 / 2.2));
}
