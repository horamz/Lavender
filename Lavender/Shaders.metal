#include <metal_stdlib>
using namespace metal;

struct RasterizerData {
    float4 position [[position]];
    float3 color;
};

vertex RasterizerData vertex_main(
    constant float3* vBuffer [[buffer(0)]],
    constant float3* cBuffer [[buffer(1)]],
    uint vertexID [[vertex_id]])
{
    return RasterizerData {
        .position = float4(vBuffer[vertexID], 1.0),
        .color = cBuffer[vertexID]
    };
}

fragment float4 fragment_main(RasterizerData in [[stage_in]]) {
    return float4(in.color, 1.0);
}

