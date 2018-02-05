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
    id<MTLTexture> _textureY;
    id<MTLTexture> _textureU;
    id<MTLTexture> _textureV;
}

@dynamic device;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self makeDevice];
        [self makeBuffers];
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

- (void)render
{
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
//      id<CAMetalDrawable> drawable = [self currentDrawable];
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
        
        if (_textureY) {
            [commandEncoder setFragmentTexture:_textureY
                                       atIndex:SRCPlanarY];
        }
        
        if (_textureU) {
            [commandEncoder setFragmentTexture:_textureU
                                       atIndex:SRCPlanarU];
        }
        
        if (_textureV) {
            [commandEncoder setFragmentTexture:_textureV
                                       atIndex:SRCPlanarV];
        }
        
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
        [commandEncoder endEncoding];
        
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

- (id <MTLTexture>)uploadTextureForYUVData:(u_char *)data
                                     width:(int)width
                                    height:(int)height
                             bytesPerPixel:(int)bytesPerPixel
                               pixelFormat:(MTLPixelFormat)pixelFormat
                               planarIndex:(SRCPlanarIndex)index;
{
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    
    // Indicate we're creating a 2D texture.
    textureDescriptor.textureType = MTLTextureType2D;
    
    // Indicate that each pixel has a Blue, Green, Red, and Alpha channel,
    //    each in an 8 bit unnormalized value (0 maps 0.0 while 255 maps to 1.0)
    textureDescriptor.pixelFormat = pixelFormat;
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    
    // Create an input and output texture with similar descriptors.  We'll only
    //   fill in the inputTexture however.  And we'll set the output texture's descriptor
    //   to MTLTextureUsageShaderWrite
    id <MTLTexture> texture = [self.device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = {{ 0, 0, 0 }, {textureDescriptor.width, textureDescriptor.height, 1}};
    
    NSUInteger bytesPerRow = bytesPerPixel * width;
    uint8_t *rawData = data;
    // Copy the bytes from our data object into the texture
    [texture replaceRegion:region
               mipmapLevel:0
                 withBytes:rawData
               bytesPerRow:bytesPerRow];
    
    if(!texture)
    {
        NSLog(@"Error creating texture");
        return nil;
    }
    
    if (index == SRCPlanarY) {
        _textureY = texture;
    }
    
    if (index == SRCPlanarU) {
        _textureU = texture;
    }
    
    if (index == SRCPlanarV) {
        _textureV = texture;
    }
    
    return texture;
}


@end
