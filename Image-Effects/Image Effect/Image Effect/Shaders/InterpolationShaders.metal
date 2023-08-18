#include <metal_stdlib>
#include "structs.h"
using namespace metal;
#pragma mark INTERPOLATION - NEAREST
constexpr sampler sampler_nearest(coord::normalized,
                                 address::clamp_to_edge,
                                 filter::nearest);


fragment float4 fragment_main_nearest(VertexOut_temp vertexOut [[stage_in]], texture2d<float> Texture [[texture(0)]], sampler Sampler [[sampler(0)]], constant float* value [[buffer(1)]])
{
    
    
    if( 1. - value[2] < 0.)
        return Texture.sample(sampler_nearest, vertexOut.textureCoord);
    
    float2 uv = (vertexOut.textureCoord + float2(value[1],1.-value[0]))*(1.-value[2])*(value[2]/.5);
    float4 color = Texture.sample(sampler_nearest, uv);
  
    return color;
}


#pragma mark INTERPOLATION - BICUBIC
constexpr sampler sampler_bicubic(coord::normalized,
                                 address::clamp_to_edge,
                                  filter::bicubic);

kernel void kernel_bicubic_interpolation(
    texture2d<float> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    constant float& blurRadius [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    float4 colorSum = float4(0.0);
    
    float width = sourceTexture.get_width(), height = sourceTexture.get_height();

    float radius = static_cast<float>(blurRadius);
    colorSum += sourceTexture.sample(sampler_bicubic, float2(static_cast<float>(gid.x)/width,
                                                             static_cast<float>(gid.y)/height) + float2(radius/width, radius/width));

    
    colorSum += sourceTexture.sample(sampler_bicubic, float2(static_cast<float>(gid.x)/width,
                                                             static_cast<float>(gid.y)/height) + float2(-radius/width, radius/width));
    
    colorSum += sourceTexture.sample(sampler_bicubic, float2(static_cast<float>(gid.x)/width,
                                                             static_cast<float>(gid.y)/height) + float2(radius/width, -radius/width));
    
    colorSum += sourceTexture.sample(sampler_bicubic, float2(static_cast<float>(gid.x)/width,
                                                             static_cast<float>(gid.y)/height) + float2(-radius/width, -radius/width));


    targetTexture.write(colorSum/4., gid);
}



#pragma mark INTERPOLATION - LINEAR
constexpr sampler sampler_linear(coord::normalized,
                                 address::clamp_to_edge,
                                  filter::linear);

kernel void kernel_linear_interpolation(
    texture2d<float> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    constant float& blurRadius [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    float4 colorSum = float4(0.0);
    
    float width = sourceTexture.get_width(), height = sourceTexture.get_height();

    float radius = static_cast<float>(blurRadius);
    colorSum += sourceTexture.sample(sampler_linear, float2(static_cast<float>(gid.x)/width,
                                                             static_cast<float>(gid.y)/height) + float2(radius/width, radius/width));

    
    colorSum += sourceTexture.sample(sampler_linear, float2(static_cast<float>(gid.x)/width,
                                                             static_cast<float>(gid.y)/height) + float2(-radius/width, radius/width));
    
    colorSum += sourceTexture.sample(sampler_linear, float2(static_cast<float>(gid.x)/width,
                                                             static_cast<float>(gid.y)/height) + float2(radius/width, -radius/width));
    
    colorSum += sourceTexture.sample(sampler_linear, float2(static_cast<float>(gid.x)/width,
                                                             static_cast<float>(gid.y)/height) + float2(-radius/width, -radius/width));


    targetTexture.write(colorSum/4., gid);
}
