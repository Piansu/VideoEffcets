//
//  GLRenderView.h
//  YUVPlayer
//
//  Created by suruochang on 2019/1/9.
//  Copyright © 2019年 Su Ruochang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLRenderView : NSOpenGLView

- (void)uploadYUVData:(u_char *)data
                width:(int)width
               height:(int)height;
- (void)draw;

@end
