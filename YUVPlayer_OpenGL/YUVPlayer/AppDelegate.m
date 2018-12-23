//
//  AppDelegate.m
//  YUVPlayer
//
//  Created by suruochang on 2019/1/1.
//  Copyright © 2019年 Su Ruochang. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    ViewController *vc = [[ViewController alloc] init];
    self.window.contentViewController = vc;
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
