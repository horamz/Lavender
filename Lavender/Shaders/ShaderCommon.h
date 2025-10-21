#ifndef ShaderCommon_h
#define ShaderCommon_h

#include <simd/simd.h>

#ifndef __METAL__
#import <Metal/MTLTypes.h>
#endif

typedef enum {
    Position = 0,
    Normal = 1,
    UV = 2
} AttributeIndices;

typedef enum {
    VertexBuffer,
    FrameConstantsBuffer,
    InstanceConstantsBuffer,
    VertexBindPointCount
} VertexBufferBindPoints;

typedef enum {
    MaterialBuffer,
    FragmentBindPointCount
} FragmentBufferBindPoints;

typedef struct {
    matrix_float4x4 modelMatrix;
} InstanceConstants;

typedef struct {
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} FrameConstants;


typedef struct {
    simd_float4 baseColorFactor;
    float roughnessFactor;
    float metallicFactor;
    float normalScale;
    float occlusionStrength;
    simd_float3 emissiveFactor;
} MaterialFactors;

typedef struct {
    MaterialFactors factors;
    MTLResourceID baseColorTexture;
    MTLResourceID roughnessTexture;
    MTLResourceID metalnessTexture;
    MTLResourceID normalTexture;
    MTLResourceID occlusionTexture;
    MTLResourceID opacityTexture;
    MTLResourceID emissiveTexture;
} MaterialArguments;

/*
typedef enum {
    Undefined = 0,
    Ambient = 1,
    Directional = 2,
    Point = 3,
    Spot = 4,
} LightType;

typedef struct {
    LightType type;
    simd_float3 position;
    simd_float3 direction;
    simd_float3 diffuseColor;
    simd_float3 specularColor;
    simd_float3 attenuation;
    float range;
    float innerConeCos;
    float outerConeCos;
} Light;
*/
#endif
