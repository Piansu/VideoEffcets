//
//  SRCMetalView.h
//  MetalShaderDesigner
//
//  Created by suruochang on 2018/10/18.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import "SRCRenderTypes.h"

@interface SRCMetalView : MTKView

- (id <MTLTexture>)uploadTextureForYUVData:(u_char *)data
                                     width:(int)width
                                    height:(int)height
                             bytesPerPixel:(int)bytesPerPixel
                               pixelFormat:(MTLPixelFormat)pixelFormat
                               planarIndex:(SRCPlanarIndex)index;

- (void)render;

@end
