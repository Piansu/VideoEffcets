//
//  ViewController.m
//  MetalDemo
//
//  Created by suruochang on 2018/10/22.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#import "ViewController.h"
#import "GLRenderView.h"

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
    
//    int width = 256;
//    int height = 256;
    
    int width = 1280;
    int height = 720;
    
    int stride = width * height * 1.5;
    u_char *buffer = malloc(stride * sizeof(u_char));

    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"yuv"];
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"lena_256x256_yuv420p" ofType:@"yuv"];
    FILE *fd = fopen(path.UTF8String, "r");

    GLRenderView *glview = [[GLRenderView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:glview];
    NSTimer *timer =
    [NSTimer scheduledTimerWithTimeInterval:1.0/25.0 repeats:YES block:^(NSTimer * _Nonnull timer) {

        size_t readSize = fread(buffer, 1, stride, fd);
        if (readSize != stride) {
            //end
        } else {

            [glview uploadYUVData:buffer width:width height:height];
            
            [glview draw];
        }
    }];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
} 

@end
