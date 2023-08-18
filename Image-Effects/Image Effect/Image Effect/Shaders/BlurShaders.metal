#include <metal_stdlib>
#include "structs.h"
using namespace metal;

kernel void kernel_blur(texture2d<float, access::sample> inputTexture [[texture(0)]],
                        texture2d<float, access::write> outputTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]])
{
    const int kernelSize = 9;
    float weights[kernelSize];
    float totalWeight = 0.0;

   
    for (int i = 0; i < kernelSize; ++i) {
        int x = i - (kernelSize - 1) / 2;
        weights[i] = exp(-float(x * x) / (2.0 * 2.0)) / (2.50663 * 2.0);  // Wzór na Gaussa
        totalWeight += weights[i];
    }

    for (int i = 0; i < kernelSize; ++i) {
        weights[i] /= totalWeight;
    }

    float2 texCoord = float2(float(gid.x) / outputTexture.get_width(),
                             float(gid.y) / outputTexture.get_height());
    float2 texSize = float2(inputTexture.get_width(), inputTexture.get_height());
    float3 sum = float3(0.0);

    for (int i = 0; i < kernelSize; ++i) {
        float2 offset = float2(float(i - (kernelSize - 1) / 2), 0.0);
        float2 sampleCoord = texCoord + offset / texSize;

        sum += inputTexture.sample(sampler(s_address::clamp_to_edge, t_address::clamp_to_edge), sampleCoord).rgb * weights[i];
    }

    float4 adjusted;
    adjusted.rgb = sum;
    adjusted.a = 1.0;

    outputTexture.write(adjusted, gid);
}




#pragma mark KAWASE BLUR
///podaje prawy gorny kwadrat i po kolei sprawdzam ktore sie mieszcza w scopie
float check_if_fits(uint2 curr_pos, uint2 size)
{
    float dziel = 0.;
    
    if(curr_pos.x < size.x && curr_pos.x >=0 && curr_pos.y < size.y && curr_pos.y >=0) dziel++;
    if(curr_pos.x-1 < size.x && curr_pos.x-1 >=0 && curr_pos.y < size.y && curr_pos.y >=0) dziel++;
    if(curr_pos.x < size.x && curr_pos.x >=0 && curr_pos.y-1 < size.y && curr_pos.y-1 >=0) dziel++;
    if(curr_pos.x-1 < size.x-1 && curr_pos.x-1 >=0 && curr_pos.y-1 < size.y && curr_pos.y-1 >=0) dziel++;
    return dziel;
}


kernel void kernel_kawase_blur(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    constant float& blurRadius [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    float4 colorSum = float4(0.0);
    
    uint2 pos = uint2(sourceTexture.get_width(), sourceTexture.get_height());
    
    int radius = int(blurRadius);
    
    float dziel = check_if_fits(gid + uint2(radius, radius), pos);
    
    if(dziel!=0.)
            colorSum += (sourceTexture.read(clamp(gid + uint2(radius, radius), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(radius, radius)-uint2(0,1), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(radius, radius) - uint2(1,0), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(radius, radius) - uint2(1,1), uint2(0), pos - 1)))/dziel;
        
        dziel = check_if_fits(gid+uint2(-radius+1, radius), pos);
        
        if(dziel!=0.)
            colorSum += (sourceTexture.read(clamp(gid + uint2(-radius, radius), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(-radius, radius)-uint2(0,1), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(-radius, radius) + uint2(1,0), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(-radius, radius) + uint2(1,-1), uint2(0), pos - 1)))/dziel;
        
        dziel = check_if_fits(gid+uint2(radius, -radius+1), pos);
        
        if(dziel!=0.)
            colorSum += (sourceTexture.read(clamp(gid + uint2(radius, -radius), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(radius, -radius)+uint2(0,1), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(radius, -radius) - uint2(1,0), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(radius, -radius) - uint2(1,-1), uint2(0), pos - 1)))/dziel;
        
        dziel = check_if_fits(gid+uint2(-radius+1, -radius+1), pos);
        
        if(dziel!=0.)
            colorSum += (sourceTexture.read(clamp(gid + uint2(-radius, -radius), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(-radius, -radius) + uint2(0,1), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(-radius, -radius) + uint2(1,0), uint2(0), pos - 1)) +
                         sourceTexture.read(clamp(gid + uint2(-radius, -radius) + uint2(1,1), uint2(0), pos - 1)))/4.;

        targetTexture.write(colorSum/4., gid);

}



