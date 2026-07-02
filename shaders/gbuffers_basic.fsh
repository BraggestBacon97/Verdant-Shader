#version 330 compatibility

in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

void main() {
    color = glcolor;
    lightmapData = vec4(clamp(lmcoord, 0.0, 1.0), 0.0, 1.0);
    encodedNormal = vec4(normalize(normal) * 0.5 + 0.5, 1.0);
}
