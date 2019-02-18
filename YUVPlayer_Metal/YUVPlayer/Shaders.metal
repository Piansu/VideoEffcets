#include <metal_stdlib>
#include <simd/simd.h>
#import "SRCRenderTypes.h"

using namespace metal;

struct ReturnVertex
{
    float4 position [[position]];
    float2 textureCoordinate;
};


struct INSRCVertex
{
    // Positions in pixel space (i.e. a value of 100 indicates 100 pixels from the origin/center)
    float2 position [[attribute(0)]];
    
    // 2D texture coordinate
    float2 textureCoordinate [[attribute(1)]];
} ;

vertex ReturnVertex test_vertex_main(INSRCVertex vertices [[stage_in]],
                                     uint vid [[vertex_id]])
{
    ReturnVertex out;
    out.position = float4(vertices.position.xy, 0 ,1);
    out.textureCoordinate = vertices.textureCoordinate;
    return out;
}


vertex ReturnVertex vertex_main(device SRCVertex *vertices [[buffer(0)]],
                                uint vid [[vertex_id]])
{
    ReturnVertex out;
    out.position = float4(vertices[vid].position.xy, 0 ,1);
    out.textureCoordinate = vertices[vid].textureCoordinate;
    return out;
}

fragment float4 fragment_main(ReturnVertex inVertex [[stage_in]],
                              texture2d<half> colorTexture0 [[ texture(SRCPlanarY) ]],
                              texture2d<half> colorTexture1 [[ texture(SRCPlanarU) ]],
                              texture2d<half> colorTexture2 [[ texture(SRCPlanarV) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    float2 uv = float2(inVertex.textureCoordinate.x, 1.0-inVertex.textureCoordinate.y);
    // Sample the texture and return the color to colorSample
    float yPlanar = colorTexture0.sample(textureSampler, uv).r - (16.0 / 255.0);
    
    float uPlanar = colorTexture1.sample(textureSampler, uv).r - 0.5;
    
    float vPlanar = colorTexture2.sample(textureSampler, uv).r - 0.5;
    
    float3x3 colorConversionMatrix = float3x3{
        1.164,  1.164,  1.164,
        0.0,   -0.213,  2.112,
        1.793, -0.533,  0.0,
    };
    
    float3 yuv = float3(yPlanar, uPlanar, vPlanar);
    float3 rgb = colorConversionMatrix * yuv;
    // We return the color of the texture
    return float4(rgb, 1.0);
//    return float4(yPlanar, yPlanar, yPlanar, 1.0);
}
