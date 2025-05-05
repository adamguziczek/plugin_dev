# CMakeLists.txt for ThreeBandEQ Plugin
# 
# A simple 3-band equalizer plugin using JUCE

# Minimum required CMake version (JUCE requires 3.15)
cmake_minimum_required(VERSION 3.15)

# Project name and version
project(ThreeBandEQ VERSION 0.1.0)

# Include JUCE (assumes JUCE is in the parent directory)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../JUCE JUCE_build)

# Initialize JUCE plugin
juce_add_plugin(${PROJECT_NAME}
    # Plugin version
    VERSION ${PROJECT_VERSION}
    
    # Plugin formats to build
    FORMATS VST3 AU Standalone
    
    # Plugin details
    PLUGIN_NAME "3 Band EQ"
    PLUGIN_MANUFACTURER_CODE "KODU"
    PLUGIN_CODE "3BEQ"
    COMPANY_NAME "KODU Audio"
    COMPANY_WEBSITE "www.koduaudio.com"
    COMPANY_EMAIL "info@koduaudio.com"
    
    # Plugin description and category
    PLUGIN_DESCRIPTION "Simple 3-band equalizer"
    PLUGIN_MANUFACTURER "KODU Audio"
    PLUGIN_VST3_CATEGORY "Fx"
    PLUGIN_AU_CATEGORY "kAudioUnitType_Effect"
    
    # Plugin capabilities
    IS_SYNTH FALSE
    NEEDS_MIDI_INPUT FALSE
    NEEDS_MIDI_OUTPUT FALSE
    IS_MIDI_EFFECT FALSE
    EDITOR_WANTS_KEYBOARD_FOCUS FALSE
    COPY_PLUGIN_AFTER_BUILD TRUE
)

# Add your plugin source files
target_sources(${PROJECT_NAME} PRIVATE
    Source/PluginProcessor.cpp
    Source/PluginEditor.cpp
)

# Tell the compiler about JUCE modules you want to use
target_compile_definitions(${PROJECT_NAME}
    PUBLIC
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_VST3_CAN_REPLACE_VST2=0
)

# Link to the JUCE modules you're using
target_link_libraries(${PROJECT_NAME}
    PRIVATE
    juce::juce_audio_basics
    juce::juce_audio_devices
    juce::juce_audio_formats
    juce::juce_audio_plugin_client
    juce::juce_audio_processors
    juce::juce_audio_utils
    juce::juce_core
    juce::juce_data_structures
    juce::juce_dsp
    juce::juce_events
    juce::juce_graphics
    juce::juce_gui_basics
    juce::juce_gui_extra
    
    PUBLIC
    juce::juce_recommended_config_flags
    juce::juce_recommended_lto_flags
    juce::juce_recommended_warning_flags
)

# Set C++ standard
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_17)