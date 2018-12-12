#include <metal_stdlib>
#include <simd/simd.h>
#import "SRCRenderTypes.h"

#define M_PI        3.14159265358979323846264338327950288   /* pi             */

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
//    out.textureCoordinate = vertices[vid].textureCoordinate;
    out.textureCoordinate = out.position.xy;
    return out;
}


fragment float4 fragment_main(ReturnVertex inVertex [[stage_in]],
                              texture2d<half> colorTexture [[ texture(0) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    float2 samplePosion = inVertex.textureCoordinate;
    
    float radius = length(samplePosion);
    
    float theta = atan(samplePosion.y / samplePosion.x);  // (-PI/2 ~ PI/2)
        
    float piece = (theta + M_PI / 2.0 ) / (M_PI * 2);  // (0 ~ 0.5)
    
    piece = (samplePosion.x >= 0) ? piece + 0.5 : piece; //samplePosion.x > 0 时 (0.5 ~ 1.0)

    float2 newPosition = float2(piece, radius * 0.65);
    
    // Sample the texture and return the color to colorSample
    const half4 colorSample = colorTexture.sample (textureSampler,newPosition);
    
    // We return the color of the texture
    return float4(colorSample);
    
}
