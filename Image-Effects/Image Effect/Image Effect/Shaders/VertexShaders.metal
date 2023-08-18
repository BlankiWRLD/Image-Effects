#include <metal_stdlib>
#include "structs.h"
using namespace metal;

vertex VertexOut_temp vertex_main_basic(const device VertexIn_temp* vertex_array [[buffer(0)]], uint vertex_id [[vertex_id]]) {
    VertexOut_temp vertexOut;
    vertexOut.position = float4(vertex_array[vertex_id].position.x,-1.*vertex_array[vertex_id].position.y , 0.0, 1.0);
    vertexOut.textureCoord = 0.5*vertex_array[vertex_id].textureCoord + float2(0.5,0.5);
    return vertexOut;
}

vertex VertexOut vertex_main(const device VertexIn* vertex_array [[buffer(0)]], unsigned int vid [[vertex_id]])
{
    VertexOut out;
    out.position = float4(vertex_array[vid].position, 1.0);
    out.color = vertex_array[vid].color;
    return out;
}
