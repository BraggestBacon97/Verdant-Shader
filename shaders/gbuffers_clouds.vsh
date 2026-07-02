#version 330 compatibility

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 worldPos;

void main() {
    gl_Position = ftransform();
    vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    worldPos = feetPlayerPos + cameraPosition;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);
    glcolor = gl_Color;

    normal = gl_NormalMatrix * gl_Normal;
    normal = normalize(mat3(gbufferModelViewInverse) * normal);
}
