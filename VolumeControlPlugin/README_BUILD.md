# Building the Volume Control Plugin

This document provides detailed instructions for building the Volume Control Plugin using the provided build scripts.

## Build Scripts Overview

The following build scripts are provided to automate the build process:

- `setup_scripts.sh` - Makes all build scripts executable and installs required dependencies
- `build.sh` - Builds the plugin (default configuration)
- `build_release.sh` - Builds an optimized version of the plugin for production use
- `clean.sh` - Cleans the build directory

## Prerequisites

Before building the plugin, ensure you have the following prerequisites installed:

- **CMake** (version 3.15 or higher)
- **C++ compiler** with C++17 support (g++ or clang++)
- **JUCE framework** in the parent directory of this project

### Linux/WSL Dependencies

When building on Linux or WSL (Windows Subsystem for Linux), the following system dependencies are required:

- **pkg-config** - For finding package configurations
- **GTK3** development libraries (libgtk-3-dev) - For GUI support
- **WebKit2GTK** development libraries (libwebkit2gtk-4.1-dev) - For web content
- **ALSA** development libraries (libasound2-dev) - For audio support
- **FreeType2** development libraries (libfreetype6-dev) - For font rendering
- **Fontconfig** development libraries (libfontconfig1-dev) - For font configuration
- **OpenGL** development libraries (libgl1-mesa-dev) - For graphics support
- **libcurl** development libraries (libcurl4-openssl-dev) - For network operations
- **X11** development libraries (libx11-dev) - For window management

The `setup_scripts.sh` script can automatically install these dependencies on Debian/Ubuntu-based systems, including WSL. For other Linux distributions, you'll need to install equivalent packages manually.

## Step-by-Step Build Instructions

### 1. Initial Setup

After cloning the repository, make the build scripts executable and install dependencies:

```bash
# Navigate to the VolumeControlPlugin directory
cd VolumeControlPlugin

# Make the setup script executable
chmod +x setup_scripts.sh

# Run the setup script to make all scripts executable and install dependencies
./setup_scripts.sh
```

The setup script will:
- Make all build scripts executable
- Detect if you're running in WSL
- Offer to install required dependencies (recommended for first-time setup)
- Provide guidance for WSL-specific configurations

### 2. Building the Plugin

#### Default Build

To build the plugin with default settings, simply run the build script:

```bash
./build.sh
```

The build script will:
- Check prerequisites
- Create a build directory
- Run CMake to configure the project
- Build the plugin
- Display the location of the built plugin files

#### Release Build (Optimized)

To build an optimized version of the plugin for production use:

```bash
./build_release.sh
```

The release build script will:
- Check prerequisites
- Create a separate build_release directory
- Run CMake with Release configuration (optimized)
- Build the plugin with optimizations enabled
- Display the location of the built plugin files

The release build produces smaller, faster plugin binaries that are suitable for distribution and production use.

### 3. Cleaning the Build

If you need to clean the build directory (e.g., for a fresh build or to troubleshoot build issues), run:

```bash
./clean.sh
```

The script will ask for confirmation before removing the build directory.

## Build Output

### Default Build

After a successful default build, the plugin files will be available in the `build` directory under their respective format folders:

- **VST3**: `build/VolumeControlPlugin_artefacts/VST3/`
- **AU** (macOS only): `build/VolumeControlPlugin_artefacts/AU/`
- **Standalone**: `build/VolumeControlPlugin_artefacts/Standalone/`

### Release Build

After a successful release build, the optimized plugin files will be available in the `build_release` directory under their respective format folders:

- **VST3**: `build_release/VolumeControlPlugin_artefacts/VST3/`
- **AU** (macOS only): `build_release/VolumeControlPlugin_artefacts/AU/`
- **Standalone**: `build_release/VolumeControlPlugin_artefacts/Standalone/`

## Troubleshooting

### Common Issues

1. **CMake not found or version too old**
   - Install CMake 3.15 or higher: [CMake Download Page](https://cmake.org/download/)

2. **C++ compiler not found**
   - Install g++ or clang++
   - On Ubuntu/Debian: `sudo apt-get install g++`
   - On macOS: Install Xcode Command Line Tools: `xcode-select --install`

3. **JUCE framework not found**
   - Ensure the JUCE directory is in the parent directory of the VolumeControlPlugin
   - If needed, clone JUCE: `git clone https://github.com/juce-framework/JUCE.git`

4. **Missing dependencies on Linux/WSL**
   - Run `./setup_scripts.sh` and answer yes to install dependencies
   - For manual installation on Debian/Ubuntu: `sudo apt-get install build-essential cmake pkg-config libgtk-3-dev libwebkit2gtk-4.1-dev libasound2-dev libfreetype6-dev libfontconfig1-dev libgl1-mesa-dev libcurl4-openssl-dev libx11-dev`

5. **Build errors**
   - Run `./clean.sh` to clean the build directory
   - Try building again with `./build.sh`
   - Check the error messages for specific issues

### Advanced Troubleshooting

For more detailed debugging:

1. Navigate to the build directory: `cd build`
2. Run CMake with verbose output: `cmake -DCMAKE_VERBOSE_MAKEFILE=ON ..`
3. Build with verbose output: `cmake --build . --verbose`

### WSL-Specific Issues

When building in WSL (Windows Subsystem for Linux), you might encounter issues with library paths. The CMakeLists.txt file includes explicit include and link directories for GTK and WebKit2GTK to address these issues. If you still encounter problems:

1. Verify that all dependencies are installed: `./setup_scripts.sh`
2. Check if the include paths in CMakeLists.txt match your system
3. For GTK-related errors, try: `pkg-config --cflags gtk+-3.0` to see the correct include paths
4. For WebKit2GTK errors, try: `pkg-config --cflags webkit2gtk-4.1` to see the correct include paths

## Advanced Usage

### Custom Build Options

You can pass custom CMake options by modifying the build script or running CMake manually:

```bash
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..  # For release build
# or
cmake -DCMAKE_BUILD_TYPE=Debug ..    # For debug build
cmake --build .
```

### Building for Specific Formats

By default, the plugin is built for all supported formats (VST3, AU, Standalone). If you want to build for specific formats only, you can modify the `FORMATS` line in `CMakeLists.txt`.

## Further Resources

- [JUCE Documentation](https://juce.com/learn/)
- [CMake Documentation](https://cmake.org/documentation/)
- [Linux Dependencies for JUCE](https://github.com/juce-framework/JUCE/blob/master/docs/Linux%20Dependencies.md)