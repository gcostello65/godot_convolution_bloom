#ifndef BLOOM_GLARE_EFFECT_H
#define BLOOM_GLARE_EFFECT_H

#include <godot_cpp/classes/compositor_effect.hpp>
#include <godot_cpp/classes/render_data.hpp>

#include "PSFProvider/psf_provider.hpp"

namespace godot {

    class BloomGlareEffect : public CompositorEffect {
        GDCLASS(BloomGlareEffect, CompositorEffect)

    private:
        Ref<PSFProvider> psf;
        float intensity = 1.0f;
        uint64_t frame_counter = 0;

    protected:
        static void _bind_methods();

    public:
        BloomGlareEffect();
        ~BloomGlareEffect();

        void set_psf(const Ref<PSFProvider> &p_psf);
        Ref<PSFProvider> get_psf() const;

        void set_intensity(float p_intensity);
        float get_intensity() const;

        void _render_callback(int32_t p_effect_callback_type, RenderData *p_render_data) override;
    };

}

#endif // BLOOM_GLARE_EFFECT_H
