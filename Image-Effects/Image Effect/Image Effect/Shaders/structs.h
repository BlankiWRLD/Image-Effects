struct VertexIn_temp {
    float2 position [[attribute(0)]];
    float2 textureCoord [[attribute(1)]];
};

struct VertexOut_temp {
    float4 position [[position]];
    float2 textureCoord;
};

struct VertexIn
{
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut
{
    float4 position [[position]];
    float4 color;
};

