#include <simd/simd.h>
using namespace metal;

struct VertexIn
{
    float3 position [[attribute(0)]];
    half4 color [[attribute(1)]];
};

struct VertexOut
{
    float4 position [[position]];
    half4 color;
};

struct MyUniforms {
    float4x4 MVP;
};

vertex VertexOut myVertexShader(VertexIn in [[stage_in]],
                                constant MyUniforms& uni [[buffer(1)]])
{
    VertexOut out;
    out.position = uni.MVP * float4(in.position, 1.f);
    out.color = (1.f/255.f)*in.color;
    return out;
}

fragment half4 myFragmentShader(VertexOut in [[stage_in]])
{
    return in.color;
}
