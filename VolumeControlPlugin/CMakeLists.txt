cmake_minimum_required(VERSION 3.15)

project(VolumeControlPlugin VERSION 1.0.0)

# Set architecture settings for cross-compilation
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(JUCE_TARGET_ARCHITECTURE "x86_64" CACHE STRING "Target architecture for JUCE" FORCE)
    set(VST3_ARCHITECTURE "x86_64" CACHE STRING "VST3 architecture" FORCE)
    set(JUCE_DISABLE_RUNTIME_ARCH_DETECTION ON CACHE BOOL "Disable runtime architecture detection" FORCE)
endif()

# Force JUCE to enable X11 and GTK support (for GUI builds on Linux)
set(JUCE_ENABLE_X11 ON)

# === GTK3 Support via pkg-config ===
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK3 REQUIRED gtk+-3.0)

include_directories(${GTK3_INCLUDE_DIRS})
link_directories(${GTK3_LIBRARY_DIRS})
add_definitions(${GTK3_CFLAGS_OTHER})
# ===================================

# === WebKit2GTK 4.1 Support (needed for juce_gui_extra) ===
pkg_check_modules(WEBKIT2GTK REQUIRED webkit2gtk-4.1)

include_directories(${WEBKIT2GTK_INCLUDE_DIRS})
link_directories(${WEBKIT2GTK_LIBRARY_DIRS})
add_definitions(${WEBKIT2GTK_CFLAGS_OTHER})
# ===========================================================

# === libcurl Support (needed for network operations) ===
pkg_check_modules(CURL REQUIRED libcurl)

include_directories(${CURL_INCLUDE_DIRS})
link_directories(${CURL_LIBRARY_DIRS})
add_definitions(${CURL_CFLAGS_OTHER})
# ======================================================

# Include the JUCE CMake utilities
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../JUCE JUCE_build)

# Initialize JUCE
juce_add_plugin(VolumeControlPlugin
    VERSION 1.0.0
    COMPANY_NAME "YourCompany"
    IS_SYNTH FALSE
    NEEDS_MIDI_INPUT FALSE
    NEEDS_MIDI_OUTPUT FALSE
    IS_MIDI_EFFECT FALSE
    EDITOR_WANTS_KEYBOARD_FOCUS FALSE
    COPY_PLUGIN_AFTER_BUILD TRUE
    PLUGIN_MANUFACTURER_CODE Juce
    PLUGIN_CODE Vcpl
    FORMATS AU VST3 Standalone
    PRODUCT_NAME "Volume Control Plugin")

# Generate JUCE header file
juce_generate_juce_header(VolumeControlPlugin)

# Source files
target_sources(VolumeControlPlugin
    PRIVATE
        Source/PluginProcessor.cpp
        Source/PluginEditor.cpp)

# Set C++ standard
target_compile_features(VolumeControlPlugin PRIVATE cxx_std_17)

# Add required JUCE modules
target_link_libraries(VolumeControlPlugin
    PRIVATE
        juce::juce_audio_utils
        ${GTK3_LIBRARIES}
        ${WEBKIT2GTK_LIBRARIES}
        ${CURL_LIBRARIES}
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags)

# Include directories
target_include_directories(VolumeControlPlugin
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/Source
        ${GTK3_INCLUDE_DIRS}
        ${WEBKIT2GTK_INCLUDE_DIRS}
        ${CURL_INCLUDE_DIRS})
