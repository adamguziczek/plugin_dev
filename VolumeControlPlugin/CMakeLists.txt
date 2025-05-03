cmake_minimum_required(VERSION 3.15)

project(VolumeControlPlugin VERSION 1.0.0)

# Set architecture settings for cross-compilation
if(CMAKE_SYSTEM_NAME STREQUAL "Windows" OR DEFINED JUCE_WINDOWS)
    set(JUCE_TARGET_ARCHITECTURE "x86_64" CACHE STRING "Target architecture for JUCE" FORCE)
    set(VST3_ARCHITECTURE "x86_64" CACHE STRING "VST3 architecture" FORCE)
    set(JUCE_DISABLE_RUNTIME_ARCH_DETECTION ON CACHE BOOL "Disable runtime architecture detection" FORCE)
    message(STATUS "Windows build detected, skipping Linux dependencies")
    set(WINDOWS_BUILD TRUE)
endif()

# Include the JUCE CMake utilities (do this early to ensure JUCE variables are set)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../JUCE JUCE_build)

# Only include Linux-specific dependencies when not building for Windows
if(NOT DEFINED WINDOWS_BUILD)
    message(STATUS "Linux build detected, including Linux dependencies")
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
endif()

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
    FORMATS VST3 Standalone
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

# Add required JUCE modules (platform-specific)
if(NOT DEFINED WINDOWS_BUILD)
    # Linux build needs additional libraries
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

    # Include directories for Linux
    target_include_directories(VolumeControlPlugin
        PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/Source
            ${GTK3_INCLUDE_DIRS}
            ${WEBKIT2GTK_INCLUDE_DIRS}
            ${CURL_INCLUDE_DIRS})
else()
    # Windows build just needs JUCE modules
    target_link_libraries(VolumeControlPlugin
        PRIVATE
            juce::juce_audio_utils
        PUBLIC
            juce::juce_recommended_config_flags
            juce::juce_recommended_lto_flags
            juce::juce_recommended_warning_flags)

    # Include directories for Windows
    target_include_directories(VolumeControlPlugin
        PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/Source)
endif()

# Platform-specific compiler flags
if(CMAKE_SYSTEM_NAME STREQUAL "Windows" OR DEFINED WINDOWS_BUILD)
    # Remove pthread flag for Windows builds
    target_compile_options(VolumeControlPlugin PRIVATE
        $<$<COMPILE_LANGUAGE:CXX>:/W4 /bigobj /wd4996 /wd4267>
        $<$<COMPILE_LANGUAGE:C>:/W4 /bigobj>)
    
    # Remove any Linux-specific link flags
    set_target_properties(VolumeControlPlugin PROPERTIES
        LINK_FLAGS "/SUBSYSTEM:WINDOWS")
        
    # Ensure we're using correct runtime library
    set_property(TARGET VolumeControlPlugin PROPERTY
        MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
else()
    # Linux-specific flags
    target_compile_options(VolumeControlPlugin PRIVATE
        $<$<COMPILE_LANGUAGE:CXX>:-Wall -Wextra -pthread>
        $<$<COMPILE_LANGUAGE:C>:-Wall -Wextra -pthread>)
endif()
