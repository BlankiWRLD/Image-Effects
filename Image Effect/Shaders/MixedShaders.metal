#include <metal_stdlib>
#include "structs.h"
using namespace metal;

kernel void kernel_grayscale_negative(
    texture2d<float> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gid [[thread_position_in_grid]])
{
    float4 temp = sourceTexture.read(gid);
    float grayscale = dot(temp.rgb, float3(0.2126, 0.7152, 0.0722));
    float4 adjusted = float4(1.0 - grayscale);
    targetTexture.write(adjusted, gid);
}

fragment float4 fragment_main_grayscale_gamma(VertexOut_temp vertexOut [[stage_in]],
    texture2d<float> Texture [[texture(0)]], sampler Sampler [[sampler(0)]], constant float& value [[buffer(1)]])
{
    float4 color = Texture.sample(Sampler, vertexOut.textureCoord);
    float grayscale = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    color.rgb = float3(grayscale);
    float gamma = value > 50.0 ? 1.0 / (2.0 * (value + 2.0) / 50.0 - 1.0) : 1.0 / ((value + 2.0) / 50.0);
    color.rgb = pow(color.rgb, float3(gamma));
    return color;
}

fragment float4 fragment_main_negative_lut(VertexOut_temp vertexOut [[stage_in]],
    texture2d<float> Texture [[texture(0)]], sampler Sampler [[sampler(0)]], constant float* value [[buffer(1)]])
{
    float4 color = Texture.sample(Sampler, vertexOut.textureCoord);
    color.rgb = 1.0 - color.rgb;
    color.rgb *= float3(value[0], value[1], value[2]);
    return color;
}

fragment float4 fragment_main_chessboard_image(VertexOut_temp vertexOut [[stage_in]],
    texture2d<float> Texture [[texture(0)]], sampler Sampler [[sampler(0)]], constant float* value [[buffer(1)]])
{
    float4 color = Texture.sample(Sampler, vertexOut.textureCoord);
    
    float2 pos = vertexOut.textureCoord;
    
    int a = int(value[0] * pos.x);
    int b = int(value[1] * pos.y);
    
    bool isEven = (a % 2 == 0 && b % 2 == 0) || (a % 2 != 0 && b % 2 != 0);
    color.rgb = mix(color.rgb, float3(isEven ? 0.0 : 1.0), 0.5);
    
    return color;
}
