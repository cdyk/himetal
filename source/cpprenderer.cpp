#include <cassert>
#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>

#include "cpprenderer.h"

namespace {

    struct ScopedAutoReleasePool
    {
        NS::AutoreleasePool* pool = nullptr;
        ScopedAutoReleasePool() : pool(NS::AutoreleasePool::alloc()->init()) {}
        ~ScopedAutoReleasePool() { pool->drain(); }
    };

    struct Vertex {
        float x, y, z;
        uint8_t r, g, b, a;
    } vertices[] = {
        {-0.5, -0.5, 0, 255, 0, 0, 255},
        { 0.0,  0.5, 0, 0, 255, 0, 255},
        { 0.5, -0.5, 0, 0, 0, 255, 255}
    };

    float I_4x4[16] = {
        1.f, 0.f, 0.f, 0.f,
        0.f, 1.f, 0.f, 0.f,
        0.f, 0.f, 1.f, 0.f,
        0.f, 0.f, 0.f, 1.f
    };

}

struct CppRenderer {

    bool init(MTL::Device* device,
              MTL::PixelFormat pixelFormat,
              MTL::PixelFormat depthStencilPixelFormat)
    {
        ScopedAutoReleasePool pool;
        
        this->device = device;
        device->retain();

        queue = device->newCommandQueue();

        MTL::DepthStencilDescriptor* depthDesc = MTL::DepthStencilDescriptor::alloc()->init()->autorelease();
        depthDesc->setDepthCompareFunction(MTL::CompareFunctionLess);
        depthDesc->setDepthWriteEnabled(YES);
        depthState = device->newDepthStencilState(depthDesc);

        MTL::VertexDescriptor* vertDesc = MTL::VertexDescriptor::alloc()->init()->autorelease();
        vertDesc->attributes()->object(0)->setFormat(MTL::VertexFormatFloat3);
        vertDesc->attributes()->object(0)->setOffset(0);
        vertDesc->attributes()->object(0)->setBufferIndex(0);
        vertDesc->attributes()->object(1)->setFormat(MTL::VertexFormatUChar4);
        vertDesc->attributes()->object(1)->setOffset(offsetof(struct Vertex, r));
        vertDesc->attributes()->object(1)->setBufferIndex(0);
        vertDesc->layouts()->object(0)->setStride(sizeof(struct Vertex));
        vertDesc->layouts()->object(0)->setStepRate(1);
        vertDesc->layouts()->object(0)->setStepFunction(MTL::VertexStepFunctionPerVertex);

        MTL::Library* lib = device->newDefaultLibrary()->autorelease();
        if(!lib) {
            fprintf(stderr, "Failed to create library\n");
            return false;
        }

        MTL::Function* vs = lib->newFunction(NS::MakeConstantString("myVertexShader"))->autorelease();
        if(!vs) {
            fprintf(stderr, "Failed to create vertex shader func\n");
            return false;
        }

        MTL::Function* fs = lib->newFunction(NS::MakeConstantString("myFragmentShader"))->autorelease();
        if(!vs) {
            fprintf(stderr, "Failed to create fragment shader func\n");
            return false;
        }

        MTL::RenderPipelineDescriptor* pipeDesc = MTL::RenderPipelineDescriptor::alloc()->init()->autorelease();
        pipeDesc->setSampleCount(1);
        pipeDesc->setVertexFunction(vs);
        pipeDesc->setFragmentFunction(fs);
        pipeDesc->setVertexDescriptor(vertDesc);
        pipeDesc->colorAttachments()->object(0)->setPixelFormat(pixelFormat);
        pipeDesc->setDepthAttachmentPixelFormat(depthStencilPixelFormat);
        pipeDesc->setStencilAttachmentPixelFormat(depthStencilPixelFormat);

        NS::Error* error = nullptr;
        pipeState = device->newRenderPipelineState(pipeDesc, &error);

        if(!pipeState) {
            fprintf(stderr, "Failed to create pipe state: %s\n", error->description()->utf8String());
            return false;
        }

        vBuf = device->newBuffer(vertices, sizeof(vertices), 0);

        return true;
    }

    ~CppRenderer()
    {
        if(depthState) depthState->release();
        if(pipeState) pipeState->release();
        if(device) device->release();
    }
    
    void render(MTL::RenderPassDescriptor* passDesc, MTL::Drawable* drawable)
    {
        if(!passDesc) return;
        
        MTL::CommandBuffer* cmdBuf = queue->commandBuffer();
        MTL::RenderCommandEncoder* enc = cmdBuf->renderCommandEncoder(passDesc);

        enc->setRenderPipelineState(pipeState);
        enc->setDepthStencilState(depthState);
        enc->setViewport(MTL::Viewport{0.0, 0.0, w, h, 0.0, 1.0});
        enc->setVertexBuffer(vBuf, 0, 0);
        enc->setVertexBytes(I_4x4, sizeof(I_4x4), 1);
        enc->drawPrimitives(MTL::PrimitiveTypeTriangle, NS::UInteger(0), NS::UInteger(3));
        enc->endEncoding();
        
        cmdBuf->presentDrawable(drawable);
        cmdBuf->commit();
    }
    
    
    MTL::Device* device = nullptr;
    MTL::CommandQueue* queue = nullptr;
    MTL::DepthStencilState* depthState = nullptr;
    MTL::RenderPipelineState* pipeState = nullptr;
    MTL::Buffer* vBuf = nullptr;

    
    float w = 100.f;
    float h = 100.f;
};


CppRenderer* CppRenderer_create(void* device, uintptr_t pixelFormat, uintptr_t depthStencilFormat)
{
    fprintf(stderr, "create\n");
    CppRenderer* renderer = new CppRenderer;
    
    if(renderer->init(reinterpret_cast<MTL::Device*>(device),
                      static_cast<MTL::PixelFormat>(pixelFormat),
                      static_cast<MTL::PixelFormat>(depthStencilFormat)))
    {
        return renderer;
    }
    delete renderer;
    return nullptr;
}

void CppRenderer_resize(CppRenderer* renderer, float w, float h)
{
    if(!renderer) return;
    renderer->w = w;
    renderer->h = h;
}

void CppRenderer_render(CppRenderer* renderer, void* passDesc, void* drawable)
{
    if(!renderer) return;
    renderer->render(reinterpret_cast<MTL::RenderPassDescriptor*>(passDesc),
                     reinterpret_cast<MTL::Drawable*>(drawable));
}

void CppRenderer_destroy(CppRenderer* renderer)
{
    if(!renderer) return;
    fprintf(stderr, "destroy\n");
    delete renderer;
}
