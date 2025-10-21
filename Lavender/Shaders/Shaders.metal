#include <metal_stdlib>
using namespace metal;

#import "ShaderCommon.h"


struct VertexIn {
    float3 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float2 uv [[attribute(UV)]];
};

struct RasterizerData {
    float4 position [[position]];
    float2 uv;
};

vertex RasterizerData vertex_main(
    VertexIn in [[stage_in]],
    constant FrameConstants& frameConstants [[buffer(FrameConstantsBuffer)]],
    constant InstanceConstants& instanceConstants [[buffer(InstanceConstantsBuffer)]])
{
    return RasterizerData {
        .position = frameConstants.projectionMatrix *
            frameConstants.viewMatrix *
            instanceConstants.modelMatrix * float4(in.position, 1.0),
        .uv = in.uv
    };
}


struct Material {
    MaterialFactors factors;
    texture2d<float, access::sample> baseColorTexture;
    texture2d<float, access::sample> roughnessTexture;
    texture2d<float, access::sample> metalnessTexture;
    texture2d<float, access::sample> normalTexture;
    texture2d<float, access::sample> occlusionTexture;
    texture2d<float, access::sample> opacityTexture;
    texture2d<float, access::sample> emissionTexture;
};

fragment float4 fragment_main(
    RasterizerData in [[stage_in]],
    constant Material& material [[buffer(MaterialBuffer)]])
{
    constexpr sampler s(
        filter::linear,
        mip_filter::linear,
        max_anisotropy(8),
        address::repeat);
    
    float3 color = material.baseColorTexture.sample(s, in.uv).rgb;
    return float4(color, 1.0);
    //return float4(1.0, 0.0, 0.0, 1.0);
}

