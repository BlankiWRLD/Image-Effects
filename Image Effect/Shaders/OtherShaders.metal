#include <metal_stdlib>
#include "structs.h"
using namespace metal;

#pragma mark GRAYSCALE
kernel void kernel_grayscale(
    texture2d<float> sourceTexture [[texture(0)]],
    texture2d<float, access::read_write> targetTexture [[texture(1)]],
    uint2 gid [[thread_position_in_grid]])
{
    float4 temp = sourceTexture.read(gid);
    float3 xd = float3(temp.x*0.2126+temp.y*0.7152+temp.z*0.0722);
    float4 adjusted = float4(xd, 1.);
    targetTexture.write(adjusted, gid);
}

#pragma mark GAMMA CORRECTION
kernel void kernel_gamma(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    constant float& value [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    float4 temp = sourceTexture.read(gid);
    
    float gamma;
    if(value > 50.) gamma = 1./(2*(value+2.)/50.-1.);
    else gamma = 1./((value+2.)/50.);
    float4 adjusted = float4(pow(temp.x, gamma), pow(temp.y, gamma), pow(temp.z, gamma), 1.);
    targetTexture.write(adjusted, gid);
}

#pragma mark LUT
kernel void kernel_lut(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    constant float* value [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    float4 temp = sourceTexture.read(gid);
    temp.x*=(value[0]==0 ? 1. : value[0]); temp.y*=(value[1]==0 ? 1. : value[1]); temp.z*=(value[2]==0 ? 1. : value[2]);
    targetTexture.write(temp, gid);
}

#pragma mark NEGATIVE
kernel void kernel_negative(
    texture2d<float> sourceTexture [[texture(0)]],
    texture2d<float, access::read_write> targetTexture [[texture(1)]],
    uint2 gid [[thread_position_in_grid]])
{
    float4 temp = sourceTexture.read(gid);
    targetTexture.write(float4(1.-temp.x, 1.-temp.y, 1.-temp.z, 1.), gid);
}


#pragma mark EDGE DETECTION
fragment float4 fragment_main_edge_detection(VertexOut_temp vertexOut [[stage_in]], texture2d<float> Texture [[texture(0)]], sampler Sampler [[sampler(0)]], constant float& value [[buffer(1)]])
{
    float4 color = Texture.sample(Sampler, vertexOut.textureCoord);
    float grayscale = color.x*0.2126 + color.y*0.7152 + color.z*0.0722;
    color.x=grayscale; color.y=grayscale; color.z=grayscale;

    float2 offset = vertexOut.textureCoord;
    float width = Texture.get_width();
    float height = Texture.get_width();
    float xPixel = (1 / width) * 3;
    float yPixel = (1 / height) * 2;
    
    
    float3 sum = float3(0.0, 0.0, 0.0);

    if(offset.x - 4.0*xPixel >= 0 && offset.y - 4.0*yPixel >=0)
        sum += Texture.sample(Sampler, float2(offset.x - 4.0*xPixel, offset.y - 4.0*yPixel)).rgb * 0.0162162162;
    
    if(offset.x - 3.0*xPixel >= 0 && offset.y - 3.0*yPixel >=0)
        sum += Texture.sample(Sampler, float2(offset.x - 3.0*xPixel, offset.y - 3.0*yPixel)).rgb * 0.0540540541;
    
    if(offset.x - 2.0*xPixel >= 0 && offset.y - 2.0*yPixel >=0)
        sum += Texture.sample(Sampler, float2(offset.x - 2.0*xPixel, offset.y - 2.0*yPixel)).rgb * 0.1216216216;
    
    if(offset.x - 1.0*xPixel >= 0 && offset.y - 1.0*yPixel >=0)
        sum += Texture.sample(Sampler, float2(offset.x - 1.0*xPixel, offset.y - 1.0*yPixel)).rgb * 0.1945945946;

        sum += Texture.sample(Sampler, offset).rgb * 0.2270270270;
    
    if(offset.x + 1.0*xPixel <width && offset.y + 1.0*yPixel < height)
        sum += Texture.sample(Sampler, float2(offset.x + 1.0*xPixel, offset.y + 1.0*yPixel)).rgb * 0.1945945946;
    
    if(offset.x + 2.0*xPixel <width && offset.y + 2.0*yPixel < height)
        sum += Texture.sample(Sampler, float2(offset.x + 2.0*xPixel, offset.y + 2.0*yPixel)).rgb * 0.1216216216;
    
    if(offset.x + 3.0*xPixel <width && offset.y + 3.0*yPixel < height)
        sum += Texture.sample(Sampler, float2(offset.x + 3.0*xPixel, offset.y + 3.0*yPixel)).rgb * 0.0540540541;
    
    if(offset.x + 4.0*xPixel <width && offset.y + 4.0*yPixel < height)
        sum += Texture.sample(Sampler, float2(offset.x + 4.0*xPixel, offset.y + 4.0*yPixel)).rgb * 0.0162162162;
    
    
    float4 adjusted;
    adjusted.rgb = sum;
    adjusted.a = 1;
    
    grayscale = adjusted.x*0.2126 + adjusted.y*0.7152 + adjusted.z*0.0722;
    adjusted.x = adjusted.y = adjusted.z = grayscale;
    
    return abs((value+5.)/15.*(color-adjusted));
}

#pragma mark EFFECT DIFFERENCE
kernel void kernel_effect_difference(
    texture2d<float, access::read> sourceTexture1 [[texture(0)]],
    texture2d<float, access::read> sourceTexture2 [[texture(1)]],
    texture2d<float, access::write> targetTexture [[texture(2)]],
    uint2 gid [[thread_position_in_grid]])
{
    float4 temp1 = sourceTexture1.read(gid), temp2 = sourceTexture2.read(gid);
    
    targetTexture.write(abs(temp1-temp2), gid);
}

