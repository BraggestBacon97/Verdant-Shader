#version 330 compatibility

// Shadow distortion
vec3 distortShadowClipPos(vec3 shadowClipPos) {
    return vec3(shadowClipPos.x, shadowClipPos.y, shadowClipPos.z * 0.2 + 0.8) * 0.96 + 0.02;
}

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
    color = texture(gtexture, texcoord) * glcolor;

    if (color.a < 0.1) {
        discard;
    }
}
