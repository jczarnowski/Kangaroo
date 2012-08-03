#include "all.h"
#include "launch_utils.h"

namespace Gpu
{

//////////////////////////////////////////////////////
// Plane Fitting
//////////////////////////////////////////////////////

void InitHeightMap(Image<float4> dHeightMap)
{
    // initialize the heightmap
    dHeightMap.Fill(make_float4(0,1E20,128,0.0));
}

//////////////////////////////////////////////////////

__global__ void KernUpdateHeightmap(Image<float4> dHeightMap, const Image<float4> d3d, const Image<unsigned char> dImage,  const Mat<float,3,4> T_hc, float max_height)
{
    const unsigned int u = blockIdx.x*blockDim.x + threadIdx.x;
    const unsigned int v = blockIdx.y*blockDim.y + threadIdx.y;

    // Calculate the position in heightmap coordinates
    const float4 p_c = d3d(u,v);
    const float3 p_h = T_hc * p_c;

    // Find bin on z=0 grid.
    int x = (int)(p_h.x+0.5);
    int y = (int)(p_h.y+0.5);

    if(dHeightMap.InBounds(x,y) && isfinite(p_c.z) && p_h.z < max_height ) {
        //calculate the variance of the measurement
        float v_z = p_c.z*1; //this is the perp. distance from the camera
        unsigned char colour = dImage.IsValid() ? dImage(u,v) : 0;

        float4 oldVal = dHeightMap(x,y);
        float4 newVal = make_float4((oldVal.y * p_h.z + v_z * oldVal.x)/(oldVal.y+v_z),
                                    oldVal.y*v_z / (oldVal.y+v_z),
                                    colour > 0 ? (oldVal.y * colour + v_z * oldVal.z)/(oldVal.y+v_z) : oldVal.z,
                                    0.0);

        // Take new val
//        float4 newVal = make_float4(p_h.z, 0, dImage(u,v), 0);

        dHeightMap(x,y) = newVal;
    }
}

void UpdateHeightMap(Image<float4> dHeightMap, const Image<float4> d3d, const Image<unsigned char> dImage, const Mat<float,3,4> T_hc, float max_height)
{
    dim3 blockDim, gridDim;
    InitDimFromOutputImage(blockDim,gridDim, d3d);
    KernUpdateHeightmap<<<gridDim,blockDim>>>(dHeightMap,d3d,dImage,T_hc, max_height);
}

//////////////////////////////////////////////////////

__global__ void KernVboFromHeightmap(Image<float4> dVbo, const Image<float4> dHeightMap)
{
    const unsigned int u = blockIdx.x*blockDim.x + threadIdx.x;
    const unsigned int v = blockIdx.y*blockDim.y + threadIdx.y;

    dVbo(u,v) = make_float4(u,v,dHeightMap(u,v).x,1.0);
}


void VboFromHeightMap(Image<float4> dVbo, const Image<float4> dHeightMap)
{
    dim3 blockDim, gridDim;
    InitDimFromOutputImage(blockDim,gridDim, dVbo);
    KernVboFromHeightmap<<<gridDim,blockDim>>>(dVbo,dHeightMap);
}

//////////////////////////////////////////////////////

__global__ void KernVboWorldFromHeightmap(Image<float4> dVbo, const Image<float4> dHeightMap, const Mat<float,3,4> T_wh)
{
    const unsigned int u = blockIdx.x*blockDim.x + threadIdx.x;
    const unsigned int v = blockIdx.y*blockDim.y + threadIdx.y;

    const float3 Ph = make_float3(u,v,dHeightMap(u,v).x);
    const float3 Pw = T_wh * Ph;

    dVbo(u,v) = make_float4(Pw.x, Pw.y, Pw.z, 1);
}


void VboWorldFromHeightMap(Image<float4> dVbo, const Image<float4> dHeightMap, const Mat<float,3,4> T_wh)
{
    dim3 blockDim, gridDim;
    InitDimFromOutputImage(blockDim,gridDim, dVbo);
    KernVboWorldFromHeightmap<<<gridDim,blockDim>>>(dVbo,dHeightMap,T_wh);
}

//////////////////////////////////////////////////////

__global__ void KernColourHeightmap(Image<uchar4> dCbo, const Image<float4> dHeightMap)
{
    const unsigned int u = blockIdx.x*blockDim.x + threadIdx.x;
    const unsigned int v = blockIdx.y*blockDim.y + threadIdx.y;

    float v_z = dHeightMap(u,v).z;
//    dCbo(u,v) = make_uchar4(255,0,0,255);
    dCbo(u,v) = make_uchar4(v_z,v_z,v_z,255);
}

void ColourHeightMap(Image<uchar4> dCbo, const Image<float4> dHeightMap)
{
    dim3 blockDim, gridDim;
    InitDimFromOutputImage(blockDim,gridDim, dCbo);
    KernColourHeightmap<<<gridDim,blockDim>>>(dCbo,dHeightMap);
}

//////////////////////////////////////////////////////

__global__ void KernGenerateWorldVboAndImageFromHeightmap(Image<float4> dVbo, Image<unsigned char> dImage, const Image<float4> dHeightMap, const Mat<float,3,4> T_wh)
{
    const unsigned int u = blockIdx.x*blockDim.x + threadIdx.x;
    const unsigned int v = blockIdx.y*blockDim.y + threadIdx.y;

    const float4 heightMap = dHeightMap(u,v);
    const float3 Ph = make_float3(u,v,heightMap.x);
    const float3 Pw = T_wh * Ph;

    dVbo(u,v) = make_float4(Pw.x, Pw.y, Pw.z, 1);
    dImage(u,v) = heightMap.z;
}

void GenerateWorldVboAndImageFromHeightmap(Image<float4> dVbo, Image<unsigned char> dImage, const Image<float4> dHeightMap, const Mat<float,3,4> T_wh)
{
    dim3 blockDim, gridDim;
    InitDimFromOutputImage(blockDim,gridDim, dHeightMap);
    KernGenerateWorldVboAndImageFromHeightmap<<<gridDim,blockDim>>>(dVbo,dImage,dHeightMap,T_wh);
}

}