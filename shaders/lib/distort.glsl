const int shadowMapResolution = 2048;
const float shadowDistanceRenderMul = 1.0;
const bool shadowtex0Nearest = true;

vec3 distortShadowClipPos(vec3 shadowClipPos) {
    float distortionFactor = length(shadowClipPos.xy) + 0.1;
    shadowClipPos.xy /= distortionFactor;
    shadowClipPos.z *= 0.5;
    return shadowClipPos;
}
