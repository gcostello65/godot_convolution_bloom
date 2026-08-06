BloomGlareEffect : CompositorEffect
├── PSFProvider (Resource, GDExtension-exposed, swappable at runtime)
├── FFTPass (RenderingDevice compute pipeline)
│     - radix-2 or radix-4 Stockham FFT, horizontal pass then vertical pass
│     - separate compute shaders: fft_forward.glsl, fft_inverse.glsl
├── ComplexMultiply.glsl   // scene_fft * kernel_fft (cached RID)
├── BrightPass.glsl
└── Composite.glsl
