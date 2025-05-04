# Building the Volume Control Plugin

This document provides detailed instructions for building the Volume Control Plugin.

## Build Scripts Overview

The following scripts are provided to automate the build process:

### Windows Build Scripts (PowerShell)
- `build_plugin.ps1` - Builds the Windows plugin using Visual Studio
- `build_simple.ps1` - A simplified version of the build script for Windows
- `windows_build_from_wsl.ps1` - Special script for building on Windows while developing in WSL

### Linux Build Scripts (Bash)
- `build.sh` - Builds the Linux plugin (default configuration)
- `build_release.sh` - Builds an optimized version of the Linux plugin for production use
- `clean.sh` - Cleans the build directories

## Prerequisites

Before building the plugin, ensure you have the following prerequisites installed:

- **CMake** (version 3.15 or higher)
- **C++ compiler** with C++17 support 
- **JUCE framework** in the parent directory of this project

### Windows Prerequisites

For building on Windows, you'll need:

- **Windows 10/11**
- **Visual Studio 2019 or later** with "Desktop development with C++" workload installed
- **CMake** (version 3.15 or higher)
- **PowerShell 5.1 or later**

### Linux Prerequisites

When building on Linux, the following system dependencies are required:

- **pkg-config** - For finding package configurations
- **GTK3** development libraries (libgtk-3-dev) - For GUI support
- **WebKit2GTK** development libraries (libwebkit2gtk-4.1-dev) - For web content
- **ALSA** development libraries (libasound2-dev) - For audio support
- **FreeType2** development libraries (libfreetype6-dev) - For font rendering
- **Fontconfig** development libraries (libfontconfig1-dev) - For font configuration
- **OpenGL** development libraries (libgl1-mesa-dev) - For graphics support
- **libcurl** development libraries (libcurl4-openssl-dev) - For network operations
- **X11** development libraries (libx11-dev) - For window management

## Building on Windows with PowerShell

### Quick Start Guide

The easiest way to build the plugin on Windows is using the provided PowerShell scripts:

1. **Open PowerShell** as Administrator
2. **Navigate to the project directory**
3. **Run the build script**:
   ```powershell
   .\build_simple.ps1
   ```

This will build the plugin using the default Release configuration. If you encounter a PowerShell execution policy error, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\build_simple.ps1
```

### Detailed Build Instructions for Windows

1. **Ensure prerequisites are installed**:
   - Visual Studio 2019 or later with "Desktop development with C++" workload
   - CMake 3.15 or higher (check with `cmake --version`)

2. **Verify the JUCE framework**:
   - Ensure the JUCE directory is in the parent directory of VolumeControlPlugin
   - If not, clone JUCE: `git clone https://github.com/juce-framework/JUCE.git`

3. **Open PowerShell** and navigate to the VolumeControlPlugin directory:
   ```powershell
   cd path\to\VolumeControlPlugin
   ```

4. **Run the build script with options**:
   ```powershell
   # For release build (default)
   .\build_plugin.ps1
   
   # For debug build
   .\build_plugin.ps1 Debug
   ```
   
   The `build_plugin.ps1` script will:
   - Check for prerequisites (Visual Studio and CMake)
   - Create a build directory named "build_vs"
   - Configure the project using CMake with Visual Studio generator
   - Build the plugin in the specified configuration (Release by default)
   - Display the location of the built plugin files

5. **Alternative: Use the simplified build script**:
   ```powershell
   .\build_simple.ps1
   ```
   This script performs the same steps with fewer prompts and less verbose output.

6. **Locate the built plugin**:
   After a successful build, the VST3 plugin will be located at:
   ```
   build_vs\VolumeControlPlugin_artefacts\Release\VST3\VolumeControlPlugin.vst3
   ```
   The standalone application will be at:
   ```
   build_vs\VolumeControlPlugin_artefacts\Release\Standalone\VolumeControlPlugin.exe
   ```

## Building from WSL for Windows

If you're developing in WSL (Windows Subsystem for Linux) but need to build for Windows, a special approach is needed since Windows build tools cannot directly access WSL paths.

### Quick Start Guide for WSL-to-Windows Building

1. **Open PowerShell** on Windows
2. **Navigate to your WSL project path**:
   ```powershell
   cd \\wsl.localhost\Ubuntu\path\to\VolumeControlPlugin
   ```
3. **Run the WSL-to-Windows build script**:
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1
   ```

This script will:
- Copy your project files from WSL to a Windows path (default: C:\Temp\VolumeControlPlugin)
- Copy the JUCE directory if needed
- Run the Windows build process
- Show you where to find the built plugin

### Using VSCode Tasks for WSL-to-Windows Builds

If you're using VSCode in WSL, we've added convenient tasks to build from WSL:

1. Open the Command Palette (Ctrl+Shift+P)
2. Type "Tasks: Run Task" and select it
3. Choose one of these options:
   - **WSL to Windows Build (Full)** - Copies all files and builds
   - **WSL to Windows Build (Fast)** - Skips copying for faster iterations

### Detailed Documentation

For complete details on this approach, see the dedicated guide:
[WSL_TO_WINDOWS_BUILD.md](WSL_TO_WINDOWS_BUILD.md)

### Manual Build on Windows

If you prefer to manually run the build commands:

1. **Create a build directory**:
   ```powershell
   mkdir build_vs
   cd build_vs
   ```

2. **Configure with CMake**:
   ```powershell
   cmake -G "Visual Studio 16 2019" -A x64 ..
   ```
   *Note: Use "Visual Studio 17 2022" for Visual Studio 2022*

3. **Build the project**:
   ```powershell
   cmake --build . --config Release
   ```

4. **Find the built plugin**:
   ```
   build_vs\VolumeControlPlugin_artefacts\Release\VST3\VolumeControlPlugin.vst3
   ```

## Building on Linux

### Prerequisites Setup

For Debian/Ubuntu-based systems:

```bash
sudo apt-get update
sudo apt-get install build-essential cmake pkg-config libgtk-3-dev libwebkit2gtk-4.1-dev libasound2-dev libfreetype6-dev libfontconfig1-dev libgl1-mesa-dev libcurl4-openssl-dev libx11-dev
```

### Building with Scripts

1. **Make the build scripts executable**:
   ```bash
   chmod +x build.sh clean.sh
   ```

2. **Build the plugin**:
   ```bash
   ./build.sh
   ```
   
   For an optimized release build:
   ```bash
   ./build_release.sh
   ```

3. **Find the built plugin**:
   The plugin will be available at:
   ```
   build/VolumeControlPlugin_artefacts/VST3/VolumeControlPlugin.vst3
   ```

## Using the VST3 Plugin

After building the plugin, you'll need to install it in the appropriate location:

### Windows

Copy the VST3 plugin to the system VST3 directory:

```powershell
# Create the directory if it doesn't exist
$vst3Dir = "C:\Program Files\Common Files\VST3"
if (-not (Test-Path $vst3Dir)) {
    New-Item -Path $vst3Dir -ItemType Directory -Force
}

# Copy the plugin
Copy-Item -Path "build_vs\VolumeControlPlugin_artefacts\Release\VST3\VolumeControlPlugin.vst3" -Destination $vst3Dir -Recurse -Force
```

### Linux

Copy the VST3 plugin to your user's VST3 directory:

```bash
mkdir -p ~/.vst3
cp -r build/VolumeControlPlugin_artefacts/VST3/VolumeControlPlugin.vst3 ~/.vst3/
```

## Troubleshooting

### Common Issues on Windows

1. **PowerShell execution policy**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   ```

2. **Visual Studio not found**:
   - Ensure Visual Studio is installed with C++ development tools
   - For VS 2022, modify the CMake generator in the script to "Visual Studio 17 2022"

3. **CMake not found**:
   - Install CMake from https://cmake.org/download/
   - Add CMake to your PATH

4. **JUCE not found**:
   - Ensure the JUCE directory is in the parent directory of VolumeControlPlugin
   - Clone JUCE: `git clone https://github.com/juce-framework/JUCE.git`

5. **Build errors**:
   - Clean the build directories: `.\clean.ps1` (or `./clean.sh` on Linux)
   - Try building with the Debug configuration: `.\build_plugin.ps1 Debug`

6. **WSL path errors**:
   - If you see "UNC paths are not supported" or "Cannot build directly from WSL path"
   - Use the `windows_build_from_wsl.ps1` script as described in the WSL-to-Windows section
   - Or clone the repository to a Windows path and build from there

### Common Issues on Linux

1. **Missing dependencies**:
   - Run: `sudo apt-get install build-essential cmake pkg-config libgtk-3-dev libwebkit2gtk-4.1-dev libasound2-dev libfreetype6-dev libfontconfig1-dev libgl1-mesa-dev libcurl4-openssl-dev libx11-dev`

2. **Permission denied on scripts**:
   - Make scripts executable: `chmod +x *.sh`

3. **JUCE not found**:
   - Clone JUCE in the parent directory: `git clone https://github.com/juce-framework/JUCE.git`

## Advanced Customization

### Custom CMake Options

You can pass custom CMake options by modifying the build scripts or running CMake manually.

For example, to set a custom company name:

```powershell
# Windows
cmake -G "Visual Studio 16 2019" -A x64 -DCOMPANY_NAME="YourCompany" ..

# Linux
cmake -DCOMPANY_NAME="YourCompany" ..
```

### Building for Specific Formats

By default, the plugin is built as VST3 and Standalone. To modify this, edit the `FORMATS` line in `CMakeLists.txt`.