//
//  VideoCaptureDevice.h
//  LearnOpenGLES
//
//  Created by suruochang on 2018/9/29.
//  Copyright © 2018年 Mac OS X. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class VideoCaptureDevice;

@protocol VideoCaptureDeviceDelegate <NSObject>

- (void)device:(VideoCaptureDevice *)device didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

@interface VideoCaptureDevice : NSObject

@property (nonatomic, weak) id<VideoCaptureDeviceDelegate> delegate;

- (void)setupDevice;

- (void)startRunning;

- (void)stopRunning;

@end
