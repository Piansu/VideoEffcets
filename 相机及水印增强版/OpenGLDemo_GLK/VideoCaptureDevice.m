//
//  VideoCaptureDevice.m
//  LearnOpenGLES
//
//  Created by suruochang on 2018/9/29.
//  Copyright © 2018年 Mac OS X. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoCaptureDevice.h"
#import <AssetsLibrary/ALAssetsLibrary.h>

@interface VideoCaptureDevice ()

@property (nonatomic, strong) AVCaptureSession *mCaptureSession; //负责输入和输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureDeviceInput *mCaptureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (nonatomic, strong) AVCaptureVideoDataOutput *mCaptureDeviceOutput; //output

@property (nonatomic, strong) dispatch_queue_t mProcessQueue;


@end

@implementation VideoCaptureDevice

- (void)setupDevice
{
    self.mProcessQueue = dispatch_queue_create("videoProcessQueue", DISPATCH_QUEUE_SERIAL);

    self.mCaptureSession = [[AVCaptureSession alloc] init];
    
//    [self.mCaptureSession beginConfiguration];
    self.mCaptureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
    
    AVCaptureDevice *inputCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == AVCaptureDevicePositionBack)
        {
            inputCamera = device;
        }
    }
    
    NSError *error = nil;
    self.mCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:&error];
    if (error) {
        NSLog(@"取得视频设备输入对象时出错");
        return;
    }

    if ([self.mCaptureSession canAddInput:self.mCaptureDeviceInput]) {
        [self.mCaptureSession addInput:self.mCaptureDeviceInput];
    }
    
    self.mCaptureDeviceOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.mCaptureDeviceOutput setAlwaysDiscardsLateVideoFrames:NO];
    
    [self.mCaptureDeviceOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.mCaptureDeviceOutput setSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)self queue:_mProcessQueue];
    if ([self.mCaptureSession canAddOutput:self.mCaptureDeviceOutput]) {
        [self.mCaptureSession addOutput:self.mCaptureDeviceOutput];
    }
    
    AVCaptureConnection *connection = [self.mCaptureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
//    [self.mCaptureSession commitConfiguration];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)deviceOrientationChange
{
//    AVCaptureConnection *connection = [self.mCaptureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
//    [connection setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
}

- (void)startRunning;
{
    __weak typeof(self) weakself = self;
    [self checkCameraAuthPermissed:^{
        __strong typeof(self) strongself = weakself;
        [strongself.mCaptureSession startRunning];
    }];
}

- (void)stopRunning;
{
    [self.mCaptureSession stopRunning];
}


#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
{
    CFRetain(sampleBuffer);
    dispatch_async(dispatch_get_main_queue(), ^{
//        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if (_delegate && [_delegate respondsToSelector:@selector(device:didOutputSampleBuffer:)])
        {
            [_delegate device:self didOutputSampleBuffer:sampleBuffer];
        }
        
        CFRelease(sampleBuffer);
    });
}

- (void)dealloc
{
    
}

// iOS在App运行中，修改Mic以及相机权限，App会退出
// 检查Camera权限，没有权限时，执行noauthBlock
- (void)checkCameraAuthPermissed:(void (^)(void))permissedBlock
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
    {
        // 没有权限，到设置中打开权限
        [[[UIAlertView alloc] initWithTitle:@"授权"
                                    message:@"相机没授权"
                                   delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil, nil] show];
    }
    else if (authStatus == AVAuthorizationStatusNotDetermined)
    {
        // Explicit user permission is required for media capture, but the user has not yet granted or denied such permission.
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (granted)
                {
                    if (permissedBlock)
                    {
                        permissedBlock();
                    }
                }
                else
                {
                    // 没有权限，到设置中打开权限
                    [[[UIAlertView alloc] initWithTitle:@"授权"
                                                message:@"相机没授权"
                                               delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil, nil] show];
                }
            });
        }];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (permissedBlock)
            {
                permissedBlock();
            }
        });
    }
}

@end
