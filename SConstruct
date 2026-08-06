#!/usr/bin/env python
import os
import sys

env = SConscript("godot-cpp/SConstruct")
extension_name = "bloomglareeffect"

# For reference:
# - CCFLAGS are compilation flags shared between C and C++
# - CFLAGS are for C-specific compilation flags
# - CXXFLAGS are for C++-specific compilation flags
# - CPPFLAGS are for pre-processor flags
# - CPPDEFINES are for pre-processor defines
# - LINKFLAGS are for linking flags

# Recursively include all C++ sources and header folders under src/.
source_dirs = []
sources = []
for root, dirs, files in os.walk("src"):
    dirs[:] = [directory for directory in dirs if not directory.startswith(".")]
    source_dirs.append(root)
    sources.extend(
        os.path.join(root, file)
        for file in files
        if file.endswith(".cpp")
    )

env.Append(CPPPATH=source_dirs)

if env["platform"] == "macos":
    framework_name = "lib{}.{}.{}.framework".format(extension_name, env["platform"], env["target"])
    framework_dir = "demo/bin/{}".format(framework_name)
    framework_binary = "lib{}.{}.{}".format(extension_name, env["platform"], env["target"])
    library = env.SharedLibrary(
        "{}/{}".format(framework_dir, framework_binary),
        source=sources,
    )

    def write_macos_framework_plist(target, source, env):
        plist_path = str(target[0])
        os.makedirs(os.path.dirname(plist_path), exist_ok=True)
        with open(plist_path, "w", encoding="utf-8") as plist:
            plist.write("""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>{binary}</string>
    <key>CFBundleIdentifier</key>
    <string>org.godotengine.bloomglareeffect</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>{name}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.12</string>
</dict>
</plist>
""".format(binary=framework_binary, name=framework_name[:-10]))

    plist = env.Command(
        "{}/Resources/Info.plist".format(framework_dir),
        [],
        write_macos_framework_plist,
    )
elif env["platform"] == "ios":
    if env["ios_simulator"]:
        library = env.StaticLibrary(
            "demo/bin/lib{}.{}.{}.simulator.a".format(extension_name, env["platform"], env["target"]),
            source=sources,
        )
    else:
        library = env.StaticLibrary(
            "demo/bin/lib{}.{}.{}.a".format(extension_name, env["platform"], env["target"]),
            source=sources,
        )
else:
    library = env.SharedLibrary(
        "demo/bin/lib{}{}{}".format(extension_name, env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )

if env["platform"] == "macos":
    Default([library, plist])
else:
    Default(library)
