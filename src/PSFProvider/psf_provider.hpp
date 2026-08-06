#ifndef PSF_PROVIDER_H
#define PSF_PROVIDER_H

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/classes/texture2d.hpp>

namespace godot {

    class PSFProvider : public Resource {
        GDCLASS(PSFProvider, Resource)

    private:
        Ref<Texture2D> kernel_texture;

    protected:
        static void _bind_methods();

    public:
        PSFProvider();
        ~PSFProvider();

        void set_kernel_texture(const Ref<Texture2D> &p_kernel_texture);
        Ref<Texture2D> get_kernel_texture() const;

        void bake();
    };

}

#endif // PSF_PROVIDER_H
