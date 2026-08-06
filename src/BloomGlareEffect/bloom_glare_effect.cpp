#include "bloom_glare_effect.hpp"

#include <godot_cpp/classes/rendering_device.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/classes/render_scene_buffers.hpp>
#include <godot_cpp/classes/render_scene_buffers_rd.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

namespace {
    constexpr uint64_t LOG_EVERY_N_FRAMES = 60;

    // Loud, obviously-fake colors so the extension's on/off toggle is
    // trivially visible with zero real bloom math implemented yet. Delete
    // this once the actual bright-pass -> FFT -> convolve -> composite
    // pipeline lands and replace the clear below with the real composite.
    constexpr uint64_t PLACEHOLDER_COLOR_HOLD_FRAMES = 30;
    const Color PLACEHOLDER_PALETTE[] = {
        Color(1.0, 0.0, 0.85),  // hot pink
        Color(0.1, 1.0, 0.2),   // lime
        Color(0.1, 0.9, 1.0),   // cyan
        Color(1.0, 0.55, 0.0),  // orange
        Color(0.7, 0.1, 1.0),   // purple
    };
    constexpr int PLACEHOLDER_PALETTE_SIZE = sizeof(PLACEHOLDER_PALETTE) / sizeof(PLACEHOLDER_PALETTE[0]);
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
    //
    // Until that lands, flash a silly placeholder color across the whole
    // frame so it's obvious at a glance whether this effect is enabled.
    // texture_clear() can't be used here: the scene color attachment isn't
    // created with TEXTURE_USAGE_CAN_COPY_TO_BIT, so it's rejected. Clearing
    // via a one-shot framebuffer draw list works regardless of usage bits.
    int palette_index = static_cast<int>((frame_counter / PLACEHOLDER_COLOR_HOLD_FRAMES) % PLACEHOLDER_PALETTE_SIZE);
    uint32_t view_count = scene_buffers->get_view_count();

    TypedArray<RID> fb_textures;
    fb_textures.push_back(color_rid);
    RID framebuffer = rendering_device->framebuffer_create(fb_textures, -1, view_count);
    if (framebuffer.is_valid()) {
        PackedColorArray clear_colors;
        clear_colors.push_back(PLACEHOLDER_PALETTE[palette_index]);
        int64_t draw_list = rendering_device->draw_list_begin(
                framebuffer, RenderingDevice::DRAW_CLEAR_COLOR_ALL, clear_colors);
        if (draw_list != 0) {
            rendering_device->draw_list_end();
        }
        rendering_device->free_rid(framebuffer);
    }
}
