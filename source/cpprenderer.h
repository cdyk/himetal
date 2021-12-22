#ifdef __cplusplus
extern "C" {
#endif
typedef struct CppRenderer CppRenderer;

CppRenderer* CppRenderer_create(void* device, uintptr_t pixelFormat, uintptr_t depthStencilFormat);

void CppRenderer_resize(CppRenderer* renderer, float w, float h);

void CppRenderer_render(CppRenderer* renderer, void* passDesc, void* drawable);

void CppRenderer_destroy(CppRenderer* renderer);

#ifdef __cplusplus
}
#endif
