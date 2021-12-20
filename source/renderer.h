#import <MetalKit/MetalKit.h>

@interface MyRenderer : NSObject<MTKViewDelegate>
- (instancetype)initWithMetalKitView:(MTKView *)mtkView;
@end
