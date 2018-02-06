//
//  ViewController.m
//  MetalDemo
//
//  Created by suruochang on 2018/10/22.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#import "ViewController.h"
#import "SRCMetalView.h"

@import MetalKit;

@interface ViewController ()

@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    int width = 256;
    int height = 256;
    
    int stride = width * height * 1.5;
    u_char *buffer = malloc(stride * sizeof(u_char));
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"lena_256x256_yuv420p" ofType:@"yuv"];
    FILE *fd = fopen(path.UTF8String, "r");
    
//     Do any additional setup after loading the view.
    SRCMetalView *mtlView = [[SRCMetalView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:mtlView];
    NSTimer *timer =
    [NSTimer scheduledTimerWithTimeInterval:1.0/25.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        size_t readSize = fread(buffer, 1, stride, fd);
        if (readSize != stride) {
            //end
        } else {

            UInt8 *pixels[3] = { buffer,
                buffer + (width * height),
                buffer + (width * height * 5 / 4) };
            int widths[3]  = { width, width / 2, width / 2 };
            int heights[3] = { height, height / 2, height / 2 };
            int planarIndexs[3] = {SRCPlanarY, SRCPlanarU, SRCPlanarV};
            
            for (int i=0; i<3; i++) {
                [mtlView uploadTextureForYUVData:pixels[i] width:widths[i] height:heights[i] bytesPerPixel:1 pixelFormat:(MTLPixelFormatR8Unorm) planarIndex:planarIndexs[i]];
            }
            [mtlView render];
        }
    }];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
} 

@end
