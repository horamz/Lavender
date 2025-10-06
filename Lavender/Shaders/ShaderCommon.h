#ifndef ShaderCommon_h
#define ShaderCommon_h

#include <simd/simd.h>

typedef enum {
    Position = 0,
    Normal = 1,
    UV = 2
} AttributeIndices;

typedef enum {
    VertexBuffer,
    UniformsBuffer,
    VertexBindPointCount
} VertexBufferBindPoints;

typedef enum {
    BaseColor,
    TextureBindPointCount
} TextureBindPoints;


// separate per frame and per draw structures later
typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

#endif
