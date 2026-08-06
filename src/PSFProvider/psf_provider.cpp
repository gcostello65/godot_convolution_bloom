#include "psf_provider.hpp"

using namespace godot;

void PSFProvider::_bind_methods() {
    ClassDB::bind_method(
            D_METHOD("set_kernel_texture", "texture"),
            &PSFProvider::set_kernel_texture);
    ClassDB::bind_method(
            D_METHOD("get_kernel_texture"),
            &PSFProvider::get_kernel_texture);
    ClassDB::bind_method(
            D_METHOD("bake"),
            &PSFProvider::bake);

    ADD_PROPERTY(
            PropertyInfo(
                    Variant::OBJECT,
                    "kernel_texture",
                    PROPERTY_HINT_RESOURCE_TYPE,
                    "Texture2D"
            ),
            "set_kernel_texture",
            "get_kernel_texture");
}

PSFProvider::PSFProvider() {
}

PSFProvider::~PSFProvider() {
}

void PSFProvider::set_kernel_texture(const Ref<Texture2D> &p_kernel_texture) {
    kernel_texture = p_kernel_texture;
}

Ref<Texture2D> PSFProvider::get_kernel_texture() const {
    return kernel_texture;
}

void PSFProvider::bake() {
    // TODO: normalize kernel_texture and produce a padded, centered
    // kernel buffer here (see implementation guide Part 5 S5.1).
}
