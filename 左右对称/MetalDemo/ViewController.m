//
//  ViewController.m
//  MetalDemo
//
//  Created by suruochang on 2018/10/22.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#import "ViewController.h"
#import "Renderer.h"

@import MetalKit;

@interface ViewController ()
{
    MTKView *_view;
    Renderer *_renderer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set the view to use the default device
    _view = (MTKView *)self.view;
    _view.device = MTLCreateSystemDefaultDevice();
    
    if(!_view.device)
    {
        NSLog(@"Metal is not supported on this device");
        return;
    }
    
    _renderer = [[Renderer alloc] initWithMetalKitView:_view];
    
    if(!_renderer)
    {
        NSLog(@"Renderer failed initialization");
        return;
    }
    
    // Initialize our renderer with the view size
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];
    
    _view.delegate = _renderer;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
