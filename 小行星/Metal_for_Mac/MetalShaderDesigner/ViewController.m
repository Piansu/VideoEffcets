//
//  ViewController.m
//  MetalShaderDesigner
//
//  Created by suruochang on 2018/10/18.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#import "ViewController.h"
#import "SRCMetalView.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    SRCMetalView *mtlView = [[SRCMetalView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:mtlView];
    
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
