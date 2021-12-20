#import <MetalKit/MetalKit.h>

#include <Cocoa/Cocoa.h>
#include "renderer.h"

@interface MyWindow : NSWindow {
}
@end

@implementation MyWindow
- (instancetype)init {
    
    self = [super initWithContentRect:NSMakeRect(10, 10, 500, 300)
                            styleMask:NSWindowStyleMaskTitled |
                                      NSWindowStyleMaskClosable |
                                      NSWindowStyleMaskTitled |
                                      NSWindowStyleMaskResizable |
                                      NSWindowStyleMaskMiniaturizable
                              backing:NSBackingStoreBuffered
                                defer:NO];
    if(self) {
        id view = [[MTKView alloc] initWithFrame:self.contentLayoutRect
                                          device:MTLCreateSystemDefaultDevice()];

        MyRenderer* _renderer = [[MyRenderer alloc] initWithMetalKitView:view];

        [view setDelegate:_renderer];
        [self setTitle:@"Hi Metal"];
        [self setContentView:view];
        [self setIsVisible:YES];
    }
    return self;
}
@end

int main(int argc, char** argv)
{
    [NSApplication sharedApplication];
    [[[[MyWindow alloc] init] autorelease] makeMainWindow];
    [NSApp run];
	return 0;
}
