//
//  ImageStitchingProcessor.metal
//  CamApp
//
//  Created by Xinzhe Wang on 1/9/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void mergeHalfAlpha(texture2d<float, access::read> inTexture1 [[texture(0)]],
                           texture2d<float, access::read> inTexture2 [[texture(1)]],
                           texture2d<float, access::write> outTexture [[texture(2)]],
                           uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    const float4 pixel1 = inTexture1.read(gid);
    const float4 pixel2 = inTexture2.read(gid);
    const float4 outputPixel = float4((pixel1.r + pixel2.r)/2, (pixel1.g + pixel2.g)/2, (pixel1.b + pixel2.b)/2, 1);
    outTexture.write(outputPixel, gid);
}
