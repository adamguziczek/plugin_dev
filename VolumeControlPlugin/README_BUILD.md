# Building the Volume Control Plugin

This document provides detailed instructions for building the Volume Control Plugin using the provided build scripts.

## Build Scripts Overview

The following build scripts are provided to automate the build process:

- `setup_scripts.sh` - Makes all build scripts executable and installs required dependencies
- `build.sh` - Builds the Linux plugin (default configuration)
- `build_release.sh` - Builds an optimized version of the Linux plugin for production use
- `build_windows.sh` - Builds a Windows VST3 plugin using cross-compilation (for FL Studio and other Windows DAWs)
- `clean.sh` - Cleans the build directories

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

### Windows Cross-Compilation Dependencies (Optional)

To build Windows VST3 plugins from Linux/WSL (useful for FL Studio compatibility), you'll need:

- **MinGW-w64** - Cross-compiler toolchain for building Windows binaries
- **binutils-mingw-w64** - Binutils for MinGW-w64
- **g++-mingw-w64** - G++ for MinGW-w64

The `setup_scripts.sh` script can install these dependencies when you select the Windows cross-compilation option.

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
- Optionally set up Windows cross-compilation tools

### 2. Building the Plugin

#### Linux Build (Default)

To build the Linux version of the plugin:

```bash
./build.sh
```

The build script will:
- Check prerequisites
- Create a build directory
- Run CMake to configure the project
- Build the plugin
- Display the location of the built plugin files

Note: The Linux build creates plugins that can only be used in Linux DAWs, not Windows applications like FL Studio.

#### Windows Build (Cross-compilation)

To build a Windows VST3 plugin that can be used in FL Studio and other Windows DAWs:

```bash
./build_windows.sh
```

This script will:
- Check for MinGW-w64 prerequisites
- Create a separate build_windows directory
- Configure CMake with the MinGW-w64 toolchain
- Build a Windows-compatible VST3 plugin
- Display the location of the built Windows VST3 plugin

After building the Windows VST3, you can copy it to your Windows VST3 directory (typically `C:\Program Files\Common Files\VST3`) and use it in FL Studio or other Windows DAWs.

#### Release Build (Optimized)

To build an optimized version of the Linux plugin for production use:

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

Note: The Windows build script (`build_windows.sh`) always uses the Release configuration for optimized builds.

### 3. Cleaning the Build

If you need to clean the build directories (e.g., for a fresh build or to troubleshoot build issues), run:

```bash
./clean.sh
```

The script will ask for confirmation before removing the build directories.

## Build Output

### Linux Build

After a successful Linux build, the plugin files will be available in the `build` directory under their respective format folders:

- **VST3**: `build/VolumeControlPlugin_artefacts/VST3/`
- **AU** (macOS only): `build/VolumeControlPlugin_artefacts/AU/`
- **Standalone**: `build/VolumeControlPlugin_artefacts/Standalone/`

### Linux Release Build

After a successful Linux release build, the optimized plugin files will be available in the `build_release` directory:

- **VST3**: `build_release/VolumeControlPlugin_artefacts/VST3/`
- **AU** (macOS only): `build_release/VolumeControlPlugin_artefacts/AU/`
- **Standalone**: `build_release/VolumeControlPlugin_artefacts/Standalone/`

### Windows Build

After a successful Windows cross-compilation build, the Windows VST3 plugin will be available in:

- **Windows VST3**: `build_windows/VolumeControlPlugin_artefacts/VST3/`

This Windows VST3 plugin can be copied to a Windows system and used in any VST3-compatible host, including FL Studio.

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
   
6. **Windows cross-compilation errors**
   - Ensure MinGW-w64 is properly installed: `sudo apt-get install mingw-w64 binutils-mingw-w64 g++-mingw-w64`
   - Verify MinGW compiler is in the PATH: `which x86_64-w64-mingw32-gcc`
   - Run `./clean.sh` to clean the build directories, then try again with `./build_windows.sh`

### Advanced Troubleshooting

For more detailed debugging:

1. Navigate to the build directory: `cd build` (or `cd build_windows` for Windows builds)
2. Run CMake with verbose output: `cmake -DCMAKE_VERBOSE_MAKEFILE=ON ..`
3. Build with verbose output: `cmake --build . --verbose`

### WSL-Specific Issues

When building in WSL (Windows Subsystem for Linux), you might encounter issues with library paths. The CMakeLists.txt file includes explicit include and link directories for GTK, WebKit2GTK, and libcurl to address these issues. If you still encounter problems:

1. Verify that all dependencies are installed: `./setup_scripts.sh`
2. Check if the include paths in CMakeLists.txt match your system
3. For GTK-related errors, try: `pkg-config --cflags gtk+-3.0` to see the correct include paths
4. For WebKit2GTK errors, try: `pkg-config --cflags webkit2gtk-4.1` to see the correct include paths
5. For libcurl errors, try: `pkg-config --cflags libcurl` to see the correct include paths

### Windows VST3 Compatibility Issues

If your Windows VST3 plugin built with cross-compilation doesn't work in FL Studio:

1. Make sure you're using the plugin built with `./build_windows.sh`, not the Linux version
2. Check that you've copied the entire `.vst3` folder (not just the .dll file inside)
3. Place the VST3 in the standard Windows VST3 directory: `C:\Program Files\Common Files\VST3`
4. Restart FL Studio and rescan for plugins
5. Check FL Studio's plugin manager to see if there are any loading errors

## Advanced Usage

### Custom Build Options

You can pass custom CMake options by modifying the build script or running CMake manually:

```bash
# For Linux builds
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..  # For release build
# or
cmake -DCMAKE_BUILD_TYPE=Debug ..    # For debug build
cmake --build .

# For Windows cross-compilation
cd build_windows
cmake -DCMAKE_TOOLCHAIN_FILE=../mingw-w64-toolchain.cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
```

### Building for Specific Formats

By default, the plugin is built for all supported formats (VST3, AU, Standalone). If you want to build for specific formats only, you can modify the `FORMATS` line in `CMakeLists.txt`.

### Cross-Compilation Notes

The cross-compilation process uses MinGW-w64 to build Windows binaries from Linux. This has some limitations:

1. Only VST3 format is supported for Windows cross-compilation
2. Some JUCE features might not work the same as when compiled natively on Windows
3. Static linking is used to minimize external dependencies

For production Windows plugins, you may want to consider building natively on Windows with Visual Studio, but the cross-compiled VST3 should work well for testing and development.

## Further Resources

- [JUCE Documentation](https://juce.com/learn/)
- [CMake Documentation](https://cmake.org/documentation/)
- [Linux Dependencies for JUCE](https://github.com/juce-framework/JUCE/blob/master/docs/Linux%20Dependencies.md)
- [MinGW-w64 Cross Compiler](https://www.mingw-w64.org/)