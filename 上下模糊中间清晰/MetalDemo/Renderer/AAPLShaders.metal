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

float4 gaussian_blur_2d(texture2d<float> inTexture,
                        texture2d<float> weights,
                        uint2 gid)
{
    
//    uint2 textureIndex(gid.x, gid.y);
//    float4 color = inTexture.read(textureIndex).rgba;
//    return color;
    
    int size = weights.get_width();
    int radius = size / 2;

    float4 accumColor(0, 0, 0, 0);
    for (int j = 0; j < size; ++j)
    {
        for (int i = 0; i < size; ++i)
        {
            uint2 kernelIndex(i, j);
            uint2 textureIndex(gid.x + (i - radius), gid.y + (j - radius));
            float4 color = inTexture.read(textureIndex).rgba;
            float4 weight = weights.read(kernelIndex).rrrr;
            accumColor += weight * color;
        }
    }

    return float4(accumColor.rgb, 1);
}


fragment float4 fragment_main(ReturnVertex inVertex [[stage_in]],
                              texture2d<float> inTexture [[ texture(0) ]],
                              texture2d<float> weights [[ texture(1) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    // Sample the texture and return the color to colorSample

    float2 coord2 = float2(inVertex.textureCoordinate);
    if (coord2.y >= 0.33333)
    {
        if (coord2.y <= 0.6666667)
        {
            const float4 colorSample = inTexture.sample (textureSampler, inVertex.textureCoordinate);
            return float4(colorSample);
        }
    }
    // We return the color of the texture
    
    uint2 gid( coord2.x * inTexture.get_width(),
              coord2.y * inTexture.get_height() );
    
    return gaussian_blur_2d(inTexture, weights, gid);
    
}





