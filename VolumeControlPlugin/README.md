# Volume Control Plugin

A simple volume control audio plugin built with the JUCE framework. This plugin provides a basic volume control with a slider UI.

## Features

- Simple volume control with a vertical slider
- Supports values from 0.0 (silence) to 1.0 (full volume)
- Default value of 0.7 (70%)
- Double-click the slider to reset to default value
- State saving/loading (plugin settings are preserved between sessions)

## Supported Formats

- VST3
- AU (Audio Unit - macOS only)
- Standalone application

## Building the Plugin

### Prerequisites

- CMake (version 3.15 or higher)
- C++ compiler with C++17 support
- JUCE framework (included as a subdirectory)

### Platform-Specific Requirements

#### Windows Requirements

- **Visual Studio 2022 Community Edition** with "Desktop development with C++" workload installed
  - Download from: https://visualstudio.microsoft.com/vs/community/
  - During installation, you MUST select the "Desktop development with C++" workload
  - This includes necessary compilers, libraries, and Windows SDK

- **Visual Studio Developer PowerShell**
  - Building on Windows requires the specialized PowerShell that comes with Visual Studio
  - Regular PowerShell will not have the necessary environment variables set for C++ development
  - Find it in the Start menu as "Developer PowerShell for VS 2022"

#### Linux/WSL Dependencies

When building on Linux or WSL (Windows Subsystem for Linux), additional system dependencies are required. The `setup_scripts.sh` script can automatically install these dependencies on Debian/Ubuntu-based systems:

```bash
# Make the setup script executable
chmod +x setup_scripts.sh

# Run the script and follow the prompts
./setup_scripts.sh
```

### Build Steps for Linux

1. Make sure you have the JUCE framework in the parent directory of this project
2. Run the setup script to prepare for building:
   ```
   chmod +x setup_scripts.sh
   ./setup_scripts.sh
   ```
3. Build the plugin using the build script:
   ```
   ./build.sh
   ```

For a release (optimized) build:
   ```
   ./build_release.sh
   ```

The built plugins will be available in the `build` directory under their respective format folders.

### Build Steps for Windows

1. Install Visual Studio 2022 with C++ development workload

2. Open "Developer PowerShell for VS 2022" from the Start menu

3. If developing in WSL, navigate to the WSL path:
   ```powershell
   cd \\wsl.localhost\Ubuntu\path\to\VolumeControlPlugin
   ```

4. Run the build script:
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1
   ```

The built plugin will be available at:
```
C:\Temp\VolumeControlPlugin\build_vs\VolumeControlPlugin_artefacts\Release\VST3\VolumeControlPlugin.vst3
```

> **IMPORTANT**: Using regular PowerShell instead of Developer PowerShell will likely result in build failures due to missing environment variables and tools.

## Using the Built Plugin

1. After building, find the VST3 plugin at the location shown in the build output
2. Copy it to your VST3 directory or configure your DAW to find it in the build location
3. Load the plugin in your favorite DAW (Digital Audio Workstation)
4. Adjust the volume using the vertical slider
5. The volume setting will be saved with your project

## Development

This plugin demonstrates basic audio plugin development with JUCE, including:

- Audio processing (volume control)
- Custom UI with a slider
- Parameter handling
- State saving/loading

Feel free to use this as a starting point for your own audio plugin projects.

## Detailed Documentation

For more detailed build instructions, troubleshooting, and advanced configuration:

- [README_BUILD.md](./README_BUILD.md) - Comprehensive build instructions for both Windows and Linux
- [WSL_TO_WINDOWS_BUILD.md](./WSL_TO_WINDOWS_BUILD.md) - Detailed guide for building from WSL to Windows