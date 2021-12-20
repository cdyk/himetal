#include "renderer.h"

@implementation MyRenderer
{
    id<MTLDevice> _mDevice;
    id<MTLCommandQueue> _mQueue;
    id<MTLDepthStencilState> _mDepthState;
    id<MTLRenderPipelineState> _mPipeState;
    id<MTLBuffer> _mVBuf;
    
    CGSize _mViewSize;
}

- (instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if(self) {
        NSError* error = nil;
        
        _mViewSize = mtkView.drawableSize;
        
        _mDevice = mtkView.device;
        _mQueue = [_mDevice newCommandQueue];

        mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
  
        id<MTLLibrary> deflib = [_mDevice newDefaultLibrary];
        if(!deflib) {
            NSLog(@"newLibraryWithFile: %@", error);
            exit(0);
        }

        id<MTLFunction> vs = [deflib newFunctionWithName:@"myVertexShader"];
        assert(vs);

        id<MTLFunction> fs = [deflib newFunctionWithName:@"myFragmentShader"];
        assert(fs);

        MTLDepthStencilDescriptor* depthDesc = [MTLDepthStencilDescriptor new];
        depthDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthDesc.depthWriteEnabled = YES;
        _mDepthState = [_mDevice newDepthStencilStateWithDescriptor:depthDesc];
        
        struct Vertex {
            float x, y, z;
            uint8_t r, g, b, a;
        } vertices[] = {
            {-0.5, -0.5, 0, 255, 0, 0, 255},
            { 0.0,  0.5, 0, 0, 255, 0, 255},
            { 0.5, -0.5, 0, 0, 0, 255, 255}
        };
        _mVBuf = [_mDevice newBufferWithBytes:vertices length:sizeof(vertices) options:0];
        
        MTLVertexDescriptor* vertDesc = [MTLVertexDescriptor new];
        vertDesc.attributes[0].format = MTLVertexFormatFloat3;
        vertDesc.attributes[0].offset = 0;
        vertDesc.attributes[0].bufferIndex = 0;
        vertDesc.attributes[1].format = MTLVertexFormatUChar4;
        vertDesc.attributes[1].offset = offsetof(struct Vertex, r);
        vertDesc.attributes[1].bufferIndex = 0;
        vertDesc.layouts[0].stride = sizeof(struct Vertex);
        vertDesc.layouts[0].stepRate = 1;
        vertDesc.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
        
        MTLRenderPipelineDescriptor* pipeDesc = [MTLRenderPipelineDescriptor new];
        pipeDesc.sampleCount = mtkView.sampleCount;
        pipeDesc.vertexFunction = vs;
        pipeDesc.fragmentFunction = fs;
        pipeDesc.vertexDescriptor = vertDesc;
        pipeDesc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipeDesc.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat;
        pipeDesc.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat;
        _mPipeState = [_mDevice newRenderPipelineStateWithDescriptor:pipeDesc error:&error];
        if(!_mPipeState) {
            NSLog(@"Failed to create pipe state: %@", error);
            exit(0);
        }

        mtkView.enableSetNeedsDisplay = YES;
        mtkView.clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 0.0);
    }
    return self;
}
- (void)drawInMTKView:(MTKView *)view
{
    MTLRenderPassDescriptor* passDesc = view.currentRenderPassDescriptor;
    if(passDesc == nil) return;
    
    id<MTLCommandBuffer> cmdBuf = [_mQueue commandBuffer];
    id<MTLRenderCommandEncoder> enc = [cmdBuf renderCommandEncoderWithDescriptor:passDesc];

    simd_float4x4 MVP = matrix_identity_float4x4;
    
    
    [enc setRenderPipelineState:_mPipeState];
    [enc setViewport:(MTLViewport){0.0, 0.0, _mViewSize.width, _mViewSize.height}];
    [enc setVertexBuffer:_mVBuf offset:0 atIndex:0];
    [enc setVertexBytes: &MVP length:sizeof(MVP) atIndex:1];
    [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [enc endEncoding];
    
    id<MTLDrawable> drawable = view.currentDrawable;
    [cmdBuf presentDrawable:drawable];
    [cmdBuf commit];
    NSLog(@"draw");
}
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _mViewSize = size;
}
@end
