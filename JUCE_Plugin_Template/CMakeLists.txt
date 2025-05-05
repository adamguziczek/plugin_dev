# CMakeLists.txt for JUCE Plugin Template
# 
# This is a template for creating JUCE audio plugins.
# Customize the project name, version, formats, and other settings as needed.

# Minimum required CMake version (JUCE requires 3.15)
cmake_minimum_required(VERSION 3.15)

# CUSTOMIZE: Change "YourPluginName" to your actual plugin name
project(YourPluginName VERSION 0.1.0)

# Include JUCE (assumes JUCE is in the parent directory)
# CUSTOMIZE: If JUCE is located elsewhere, update this path
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../JUCE JUCE_build)

# Initialize JUCE plugin
# CUSTOMIZE: Update the plugin details below
juce_add_plugin(${PROJECT_NAME}
    # Plugin version
    VERSION ${PROJECT_VERSION}
    
    # CUSTOMIZE: Select the plugin formats you want to build
    # Options: VST3 AU AUv3 Standalone Unity VST LV2
    FORMATS VST3 AU Standalone
    
    # CUSTOMIZE: Set your plugin name, description, etc.
    PLUGIN_NAME "Your Plugin Name"
    PLUGIN_MANUFACTURER_CODE "YMnf"
    PLUGIN_CODE "Yplg"
    COMPANY_NAME "Your Company"
    COMPANY_WEBSITE "www.yourcompany.com"
    COMPANY_EMAIL "info@yourcompany.com"
    
    # CUSTOMIZE: Plugin description and category
    PLUGIN_DESCRIPTION "Your Plugin Description"
    PLUGIN_MANUFACTURER "Your Company"
    PLUGIN_VST3_CATEGORY "Fx"
    PLUGIN_AU_CATEGORY "kAudioUnitType_Effect"
    
    # CUSTOMIZE: Add a different icon if needed
    # ICON_BIG ...
    # ICON_SMALL ...
    
    # CUSTOMIZE: If your plugin needs a copy protection/splash screen, set to TRUE
    IS_SYNTH FALSE
    NEEDS_MIDI_INPUT FALSE
    NEEDS_MIDI_OUTPUT FALSE
    IS_MIDI_EFFECT FALSE
    EDITOR_WANTS_KEYBOARD_FOCUS FALSE
    COPY_PLUGIN_AFTER_BUILD TRUE
)

# Add your plugin source files
# CUSTOMIZE: Add any additional source files you create
target_sources(${PROJECT_NAME} PRIVATE
    Source/PluginProcessor.cpp
    Source/PluginEditor.cpp
)

# Tell the compiler about JUCE modules you want to use
# CUSTOMIZE: Add or remove JUCE modules as needed
target_compile_definitions(${PROJECT_NAME}
    PUBLIC
    # JUCE_WEB_BROWSER and JUCE_USE_CURL can be disabled if you're not using them
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_VST3_CAN_REPLACE_VST2=0
    
    # CUSTOMIZE: Uncomment to disable assertions in release build
    # JUCE_CHECK_MEMORY_LEAKS=0
    # JUCE_DISABLE_ASSERTIONS=1
)

# Link to the JUCE modules you're using
# CUSTOMIZE: Add or remove JUCE modules as needed
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

# Set C++ standard (JUCE requires C++14 minimum, C++17 recommended)
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_17)

# CUSTOMIZE: Uncomment and modify these options as needed
# Add compiler-specific options
# if(MSVC)
#     # Visual Studio-specific options
#     target_compile_options(${PROJECT_NAME} PRIVATE /W4)
# else()
#     # GCC/Clang options
#     target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra)
# endif()

# CUSTOMIZE: Uncomment to set custom output directories
# set_target_properties(${PROJECT_NAME} PROPERTIES
#     ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
#     LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
#     RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
# )