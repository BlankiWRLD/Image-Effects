#include <metal_stdlib>
#include "structs.h"
using namespace metal;



fragment float4 fragment_main(VertexOut current [[stage_in]])
{
    return current.color;
}

fragment float4 fragment_main_black(VertexOut current [[stage_in]])
{
    return float4(30/255., 20./255., 45./255., 1.);
}


fragment float4 fragment_main_basic(VertexOut_temp vertexOut [[stage_in]], texture2d<float> Texture [[texture(0)]], sampler Sampler [[sampler(0)]]) {
    float4 color = Texture.sample(Sampler, vertexOut.textureCoord);
    return color;
}


fragment float4 fragment_main_chessboard(VertexOut_temp vertexOut [[stage_in]], texture2d<float> Texture [[texture(0)]], sampler Sampler [[sampler(0)]], constant float* value [[buffer(1)]])
{
    float2 pos = vertexOut.textureCoord;
    
    int a = value[0]*pos.x;
    int b = value[1]*pos.y;
    
    if((a%2==0 && b%2==0) || (a%2!=0 && b%2!=0)) return float4(0.,0.,0.,1);
    
    return float4(1.,1.,1.,1);
}
