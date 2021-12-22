#include "renderer.h"
#include "cpprenderer.h"

@implementation MyRenderer
{
    CppRenderer* _mCppRenderer;
}

- (instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if(self) {
        mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
        mtkView.enableSetNeedsDisplay = YES;
        mtkView.clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 0.0);

        _mCppRenderer = CppRenderer_create(mtkView.device,
                                           mtkView.colorPixelFormat,
                                           mtkView.depthStencilPixelFormat);
        
        CppRenderer_resize(_mCppRenderer, mtkView.drawableSize.width, mtkView.drawableSize.height);
    }
    return self;
}
- (void)drawInMTKView:(MTKView *)view
{
    CppRenderer_render(_mCppRenderer, view.currentRenderPassDescriptor, view.currentDrawable);
}
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    CppRenderer_resize(_mCppRenderer, size.width, size.height);
}
@end
