/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of our platform independent renderer class, which performs Metal setup and per frame rendering
*/

@import simd;
@import MetalKit;

#import "Renderer.h"

// Header shared between C code here, which executes Metal API commands, and .metal files, which
//   uses these types as inputs to the shaders
#import "SRCRenderTypes.h"

// Main class performing the rendering

@interface Renderer ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLTexture> texture;

@end

@implementation Renderer
{
    // The device (aka GPU) we're using to render
//    id<MTLDevice> _device;
//
//    // Our render pipeline composed of our vertex and fragment shaders in the .metal shader file
//    id<MTLRenderPipelineState> _pipelineState;
//
//    // The command Queue from which we'll obtain command buffers
//    id<MTLCommandQueue> _commandQueue;

    // The current size of our view so we can use this in our render pipeline
    vector_uint2 _viewportSize;
}

/// Initialize with the MetalKit view from which we'll obtain our Metal device
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        
        _device = mtkView.device;
        
        [self makeBuffers];
        [self makeTexture];
        [self makePipeline];
    }

    return self;
}



/// Called whenever view changes orientation or is resized
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Save the size of the drawable as we'll pass these
    //   values to our vertex shader when we draw
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

/// Called whenever the view needs to render a frame
- (void)drawInMTKView:(nonnull MTKView *)view
{
    id<CAMetalDrawable> drawable = view.currentDrawable;
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

//- (CAMetalLayer *)metalLayer {
//    return (CAMetalLayer *)self.layer;
//}

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
    NSImage *image = [NSImage imageNamed:@"test"];
    
    if(!image)
    {
        return;
    }
    _texture = [self textureForImage:image device:self.device];
    
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
    textureDescriptor.width = image.size.width;
    textureDescriptor.height = image.size.height;
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



@end
