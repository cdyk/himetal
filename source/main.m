#import <MetalKit/MetalKit.h>
#import <Cocoa/Cocoa.h>
#import "cpprenderer.h"

@interface MyRenderDelegate : NSObject<MTKViewDelegate>
- (instancetype)initWithMetalKitView:(MTKView *)mtkView;
@end

@implementation MyRenderDelegate {
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
        CppRenderer_resize(_mCppRenderer,
                           mtkView.drawableSize.width,
                           mtkView.drawableSize.height);
    }
    return self;
}
- (void)drawInMTKView:(MTKView *)view
{
    CppRenderer_render(_mCppRenderer,
                       view.currentRenderPassDescriptor,
                       view.currentDrawable);
}
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    CppRenderer_resize(_mCppRenderer,
                       size.width,
                       size.height);
}
@end

@interface MyMTKView : MTKView {
}
@end

@implementation MyMTKView

NSPoint _mClickStart;
MyRenderDelegate* _mRenderer;

- (instancetype)initWithFrame:(CGRect)frameRect device:(nullable id<MTLDevice>)device {
    self = [super initWithFrame:frameRect device:device];
    if(self) {
        _mRenderer = [[MyRenderDelegate alloc] initWithMetalKitView:self];
        [self setDelegate:_mRenderer];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
    [_mRenderer release];
}

-(BOOL)acceptsFirstResponder {
    return YES;
}

- (void)mouseDown:(NSEvent *)event {
    _mClickStart = [self convertPoint:[event locationInWindow] fromView:nil];
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    NSLog(@"Mousedrag delta %f %f", p.x - _mClickStart.x, p.y - _mClickStart.y);
}

- (void)keyDown:(NSEvent *)event {
    NSString* c = [event charactersIgnoringModifiers];
    if([c isEqual:@"q"]) {
        [NSApp terminate:self];
    }
    else {
        [super keyDown:event];
    }
}
@end


int main(int argc, char** argv)
{
    @autoreleasepool {
        [NSApplication sharedApplication];
        NSWindow* win = [[[NSWindow alloc] initWithContentRect:NSMakeRect(10, 10, 500, 300)
                                                     styleMask:NSWindowStyleMaskTitled |
                                                               NSWindowStyleMaskClosable |
                                                               NSWindowStyleMaskTitled |
                                                               NSWindowStyleMaskResizable |
                                                               NSWindowStyleMaskMiniaturizable
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO] autorelease];

        id view = [[[MyMTKView alloc] initWithFrame:win.contentLayoutRect
                                             device:MTLCreateSystemDefaultDevice()] autorelease];
        [win setTitle:@"Hi Metal"];
        [win setContentView:view];
        [win setIsVisible:YES];
        [win autorelease];
        [win makeMainWindow];
        [NSApp run];
    }
	return 0;
}
