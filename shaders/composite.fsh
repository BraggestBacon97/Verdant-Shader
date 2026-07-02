#version 330 compatibility

#define SHADOWS

#include "/lib/common.glsl"
#include "/lib/distort.glsl"

/*
const int colortex0Format = RGB16;
*/

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

float getShadow(vec3 shadowScreenPos) {
    if (shadowScreenPos.x < 0.0 || shadowScreenPos.x > 1.0 ||
        shadowScreenPos.y < 0.0 || shadowScreenPos.y > 1.0 ||
        shadowScreenPos.z < 0.0 || shadowScreenPos.z > 1.0) {
        return 1.0;
    }

#ifdef SHADOWS
    return step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);
#else
    return 1.0;
#endif
}

void main() {
    color = texture(colortex0, texcoord);
    color.rgb = pow(color.rgb, vec3(2.2));

    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        return;
    }

    vec2 lightmap = texture(colortex1, texcoord).rg;
    vec3 normal = decodeNormal(texture(colortex2, texcoord).rgb);

    vec3 lightVector = normalize(shadowLightPosition);
    vec3 worldLightVector = normalize(mat3(gbufferModelViewInverse) * lightVector);

    vec3 NDCPos = vec3(texcoord, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
    vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    shadowClipPos.z -= 0.001;
    shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
    vec3 shadowScreenPos = (shadowClipPos.xyz / shadowClipPos.w) * 0.5 + 0.5;

    float NdotL = clamp(dot(worldLightVector, normal), 0.0, 1.0);
    float shadow = getShadow(shadowScreenPos);

    vec3 blocklight = lightmap.r * blocklightColor;
    vec3 skylight = lightmap.g * skylightColor;
    vec3 sunlight = sunlightColor * NdotL * shadow;
    vec3 ambient = ambientColor;

    color.rgb *= ambient + blocklight + skylight + sunlight;
}
