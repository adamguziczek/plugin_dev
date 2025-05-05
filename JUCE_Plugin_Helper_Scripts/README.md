# JUCE Plugin Helper Scripts

This folder contains a collection of helper scripts designed to make JUCE audio plugin development easier, especially for cross-platform development between Linux/WSL and Windows.

## Quick Start

### How to Use These Scripts

Simply **drag and drop** these scripts into your JUCE plugin project folder. The scripts are designed to work with a standard JUCE plugin project structure and will help automate the build process.

### Prerequisites

- **CMake** (version 3.15 or higher)
- **C++ compiler** with C++17 support
- **JUCE framework** (should be in the parent directory of your plugin project)

## Included Scripts

| Script | Platform | Description |
| ------ | -------- | ----------- |
| `setup_scripts.sh` | Linux/WSL | Installs dependencies and makes scripts executable |
| `build.sh` | Linux/WSL | Builds the plugin on Linux |
| `clean.sh` | Linux/WSL | Removes build directories on Linux |
| `windows_build_from_wsl.ps1` | Windows | Builds plugin for Windows from WSL |
| `clean.ps1` | Windows | Removes build directories on Windows |

## Workflow

### Linux/WSL Development

1. Make sure JUCE is in the parent directory of your plugin project
2. Run the setup script once to prepare your environment:
   ```
   chmod +x setup_scripts.sh
   ./setup_scripts.sh
   ```
3. Build your plugin:
   ```
   ./build.sh
   ```
4. Clean build directories when needed:
   ```
   ./clean.sh
   ```

### Windows Development from WSL

1. Make sure JUCE is in the parent directory of your plugin project
2. Run the Windows build script from WSL:
   ```
   PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1
   ```
3. Clean Windows build directories when needed:
   ```
   PowerShell -ExecutionPolicy Bypass -File clean.ps1
   ```

## Script Details

### setup_scripts.sh

This script:
- Makes other scripts executable
- Installs required dependencies for Debian/Ubuntu-based systems
- Sets up MSVC cross-compilation environment (if requested)

### build.sh

This script:
- Checks prerequisites (CMake, C++ compiler, JUCE)
- Creates a build directory
- Runs CMake to configure the project
- Builds the plugin with parallel jobs

### clean.sh

This script:
- Removes build directories on Linux (build, build_release, build_windows, etc.)
- Asks for confirmation before removing each directory

### windows_build_from_wsl.ps1

This script:
- Copies files from WSL to a Windows directory
- Configures Visual Studio environment
- Builds the plugin using CMake and Visual Studio
- Provides detailed build output and error handling

### clean.ps1

This script:
- Removes build directories on Windows (build_vs)
- Provides safety checks for system directories
- Asks for confirmation before removing each directory

## Project Structure

For these scripts to work correctly, your project should have a structure similar to:

```
Parent Directory/
├── JUCE/              # JUCE framework
└── YourPlugin/        # Your plugin project
    ├── Source/        # Plugin source code
    ├── CMakeLists.txt # CMake configuration
    ├── setup_scripts.sh
    ├── build.sh
    ├── clean.sh
    ├── windows_build_from_wsl.ps1
    └── clean.ps1
```

## CMakeLists.txt Template

A basic CMakeLists.txt for a JUCE plugin should include:

```cmake
cmake_minimum_required(VERSION 3.15)
project(YourPlugin VERSION 1.0.0)

# Include JUCE
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../JUCE JUCE_build)

# Initialize JUCE
juce_add_plugin(YourPlugin
    VERSION 1.0.0
    FORMATS VST3 AU Standalone
    PRODUCT_NAME "Your Plugin Name"
)

# Add source files
target_sources(YourPlugin PRIVATE
    Source/PluginProcessor.cpp
    Source/PluginEditor.cpp
)

# Add JUCE modules
target_compile_definitions(YourPlugin
    PUBLIC
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_VST3_CAN_REPLACE_VST2=0
)

# Link with JUCE modules
target_link_libraries(YourPlugin
    PRIVATE
    juce::juce_audio_utils
    juce::juce_recommended_config_flags
    juce::juce_recommended_lto_flags
    juce::juce_recommended_warning_flags
)
```

## Troubleshooting

### Common Issues on Linux/WSL

- **Missing Dependencies**: Run `./setup_scripts.sh` to install required dependencies
- **Permission Denied**: Run `chmod +x script_name.sh` to make scripts executable
- **JUCE Not Found**: Ensure JUCE is in the parent directory of your plugin project

### Common Issues on Windows

- **Visual Studio Missing**: Install Visual Studio with "Desktop development with C++" workload
- **Windows SDK Missing**: Install Windows 10 SDK through Visual Studio Installer
- **Build Errors**: Use Developer PowerShell for VS 2022 instead of regular PowerShell

## Further Resources

- [JUCE Framework](https://juce.com/)
- [JUCE CMake API Documentation](https://github.com/juce-framework/JUCE/blob/master/docs/CMake%20API.md)
- [JUCE Tutorials](https://juce.com/learn/tutorials/)
- [Audio Plugin Development Guide](https://docs.juce.com/master/tutorial_create_projucer_basic_plugin.html)