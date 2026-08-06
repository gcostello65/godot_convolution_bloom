#include "register_types.hpp"

#include "BloomGlareEffect/bloom_glare_effect.hpp"
#include "PSFProvider/psf_provider.hpp"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_bloomglareeffect_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    GDREGISTER_CLASS(PSFProvider);
    GDREGISTER_CLASS(BloomGlareEffect);
}

void uninitialize_bloomglareeffect_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
}

extern "C" {
// Initialization.
GDExtensionBool GDE_EXPORT bloomglareeffect_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address,
                                                        const GDExtensionClassLibraryPtr p_library,
                                                        GDExtensionInitialization *r_initialization) {
    godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

    init_obj.register_initializer(initialize_bloomglareeffect_module);
    init_obj.register_terminator(uninitialize_bloomglareeffect_module);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

    return init_obj.init();
}
}
