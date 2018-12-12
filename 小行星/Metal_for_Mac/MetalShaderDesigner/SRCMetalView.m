//
//  SRCMetalView.m
//  MetalShaderDesigner
//
//  Created by suruochang on 2018/10/18.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#import "SRCMetalView.h"
#import "SRCRenderTypes.h"

@interface SRCMetalView ()

@property (nonatomic, strong) NSTimer *displayLink;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

@end

@implementation SRCMetalView
{
    id<MTLTexture> _texture;
}

@dynamic device;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self makeDevice];
        [self makeBuffers];
        [self makeTexture];
        [self makePipeline];
    }
    
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect]))
    {
        [self makeDevice];
        [self makeBuffers];
        [self makeTexture];
        [self makePipeline];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}


- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    // During the first layout pass, we will not be in a view hierarchy, so we guess our scale
    CGFloat scale = 1.0;
    
    // If we've moved to a window by the time our frame is being set, we can take its scale as our own
//    if (self.window)
//    {
//        scale = self.window.screen.scale;
//    }
    
    CGSize drawableSize = self.bounds.size;
    
    // Since drawable size is in pixels, we need to multiply by the scale to move from points to pixels
    drawableSize.width *= scale;
    drawableSize.height *= scale;
    
    self.metalLayer.drawableSize = drawableSize;
}

- (CAMetalLayer *)metalLayer {
    return (CAMetalLayer *)self.layer;
}

- (void)makeDevice
{
    self.device = MTLCreateSystemDefaultDevice();
    self.metalLayer.device = self.device;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
}

- (void)makePipeline
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_main"];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    
    NSError *error = nil;
    _pipeline = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                       error:&error];
    
    if (!_pipeline)
    {
        NSLog(@"Error occurred when creating render pipeline state: %@", error);
    }
    
    _commandQueue = [self.device newCommandQueue];
}

- (void)makeBuffers
{
    static const SRCVertex vertices[] =
    {
        { {  1.0,  -1.0 }, { 1.f, 0.f } },
        { { -1.0,  -1.0 }, { 0.f, 0.f } },
        { { -1.0,   1.0 }, { 0.f, 1.f } },
        
        { {  1.0,  -1.0 }, { 1.f, 0.f } },
        { { -1.0,   1.0 }, { 0.f, 1.f } },
        { {  1.0,   1.0 }, { 1.f, 1.f } },
    };
    
    _vertexBuffer = [self.device newBufferWithBytes:vertices
                                        length:sizeof(vertices)
                                       options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)makeTexture
{
    NSImage *image = [NSImage imageNamed:@"test.jpg"];
    
    if(!image)
    {
        return;
    }
    _texture = [self textureForImage:image device:self.device];
    
}

- (void)render
{
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    id<MTLTexture> framebufferTexture = drawable.texture;
    
    if (drawable)
    {
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].texture = framebufferTexture;
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1);
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        [commandEncoder setRenderPipelineState:self.pipeline];
        [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
        
        [commandEncoder setFragmentTexture:_texture
                                  atIndex:0];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
        [commandEncoder endEncoding];
        
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

- (id <MTLTexture>)textureForImage:(NSImage *)image device:(id <MTLDevice>)device
{
    CGImageRef imageRef = [image CGImageForProposedRect:NULL context:NULL hints:nil];
    // Create a suitable bitmap context for extracting the bits of the image
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8_t *rawData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef bitmapContext = CGBitmapContextCreate(rawData, width, height,
                                                       bitsPerComponent, bytesPerRow, colorSpace,
                                                       kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    // Flip the context so the positive Y axis points down
    CGContextTranslateCTM(bitmapContext, 0, height);
    CGContextScaleCTM(bitmapContext, 1, -1);
    
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(bitmapContext);
    
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    
    // Indicate we're creating a 2D texture.
    textureDescriptor.textureType = MTLTextureType2D;
    
    // Indicate that each pixel has a Blue, Green, Red, and Alpha channel,
    //    each in an 8 bit unnormalized value (0 maps 0.0 while 255 maps to 1.0)
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    
    // Create an input and output texture with similar descriptors.  We'll only
    //   fill in the inputTexture however.  And we'll set the output texture's descriptor
    //   to MTLTextureUsageShaderWrite
    id <MTLTexture> texture = [device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = {{ 0, 0, 0 }, {textureDescriptor.width, textureDescriptor.height, 1}};
    
    
    // Copy the bytes from our data object into the texture
    [texture replaceRegion:region
               mipmapLevel:0
                 withBytes:rawData
               bytesPerRow:bytesPerRow];
    
    free(rawData);
    
    if(!texture)
    {
        NSLog(@"Error creating texture");
        return nil;
    }
    
    return texture;
}

- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];
    if (self.superview)
    {
        self.displayLink = [NSTimer scheduledTimerWithTimeInterval:(1/60.0) target:self selector:@selector(displayLinkDidFire:) userInfo:nil repeats:YES];

    }
    else
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)displayLinkDidFire:(NSTimer *)displayLink
{
    [self render];
}

@end
