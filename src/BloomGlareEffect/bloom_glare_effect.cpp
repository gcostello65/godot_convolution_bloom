#include "bloom_glare_effect.hpp"

#include <godot_cpp/classes/rendering_device.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/classes/render_scene_buffers.hpp>
#include <godot_cpp/classes/render_scene_buffers_rd.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

namespace {
    constexpr uint64_t LOG_EVERY_N_FRAMES = 60;
}

void BloomGlareEffect::_bind_methods() {
    ClassDB::bind_method(
            D_METHOD("set_psf", "psf"),
            &BloomGlareEffect::set_psf);
    ClassDB::bind_method(
            D_METHOD("get_psf"),
            &BloomGlareEffect::get_psf);

    ClassDB::bind_method(
            D_METHOD("set_intensity", "intensity"),
            &BloomGlareEffect::set_intensity);
    ClassDB::bind_method(
            D_METHOD("get_intensity"),
            &BloomGlareEffect::get_intensity);

    ADD_PROPERTY(
            PropertyInfo(
                    Variant::OBJECT,
                    "psf",
                    PROPERTY_HINT_RESOURCE_TYPE,
                    "PSFProvider"
            ),
            "set_psf",
            "get_psf");
    ADD_PROPERTY(
            PropertyInfo(
                    Variant::FLOAT,
                    "intensity"
            ),
            "set_intensity",
            "get_intensity");
}

BloomGlareEffect::BloomGlareEffect() {
    set_effect_callback_type(EFFECT_CALLBACK_TYPE_POST_TRANSPARENT);
    set_needs_motion_vectors(false);
}

BloomGlareEffect::~BloomGlareEffect() {
}

void BloomGlareEffect::set_psf(const Ref<PSFProvider> &p_psf) {
    psf = p_psf;
}

Ref<PSFProvider> BloomGlareEffect::get_psf() const {
    return psf;
}

void BloomGlareEffect::set_intensity(float p_intensity) {
    intensity = p_intensity;
}

float BloomGlareEffect::get_intensity() const {
    return intensity;
}

void BloomGlareEffect::_render_callback(int32_t p_effect_callback_type, RenderData *p_render_data) {
    if (p_render_data == nullptr) {
        return;
    }

    RenderingDevice *rendering_device = RenderingServer::get_singleton()->get_rendering_device();
    if (rendering_device == nullptr) {
        return;
    }

    RenderSceneBuffersRD *scene_buffers = Object::cast_to<RenderSceneBuffersRD>(
            p_render_data->get_render_scene_buffers().ptr());
    if (scene_buffers == nullptr) {
        return;
    }

    RID color_rid = scene_buffers->get_color_texture();

    frame_counter++;
    if (frame_counter % LOG_EVERY_N_FRAMES == 0) {
        UtilityFunctions::print("BloomGlareEffect render callback fired, frame ", frame_counter);
    }

    // TODO: bright-pass threshold extraction -> forward FFT (Stockham,
    // horizontal then vertical) -> complex multiply against the baked
    // PSFProvider kernel FFT -> inverse FFT -> composite back onto
    // color_rid. See docs/project_outline.md and docs/Glare-bloom-1995.pdf.
}
