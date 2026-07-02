#version 330 compatibility

vec3 distortShadowClipPos(vec3 shadowClipPos) {
    return vec3(shadowClipPos.x, shadowClipPos.y, shadowClipPos.z * 0.2 + 0.8) * 0.96 + 0.02;
}

out vec2 texcoord;
out vec4 glcolor;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;

    gl_Position = ftransform();
    gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
}
