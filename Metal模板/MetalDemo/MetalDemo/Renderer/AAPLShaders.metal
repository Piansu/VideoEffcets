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
                              texture2d<half> colorTexture [[ texture(0) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    // Sample the texture and return the color to colorSample
    const half4 colorSample = colorTexture.sample (textureSampler, inVertex.textureCoordinate);
    
    // We return the color of the texture
    return float4(colorSample);
    
}
