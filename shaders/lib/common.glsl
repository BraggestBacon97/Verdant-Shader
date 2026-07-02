const vec3 blocklightColor = vec3(1.0, 0.48, 0.12);
const vec3 skylightColor = vec3(0.08, 0.18, 0.34);
const vec3 sunlightColor = vec3(1.0, 0.95, 0.82);
const vec3 ambientColor = vec3(0.035, 0.045, 0.055);

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
    vec4 homPos = projectionMatrix * vec4(position, 1.0);
    return homPos.xyz / homPos.w;
}

vec3 decodeNormal(vec3 encodedNormal) {
    return normalize((encodedNormal - 0.5) * 2.0);
}
