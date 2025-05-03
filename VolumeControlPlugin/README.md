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

#### Linux/WSL Dependencies

When building on Linux or WSL (Windows Subsystem for Linux), additional system dependencies are required. The `setup_scripts.sh` script can automatically install these dependencies on Debian/Ubuntu-based systems:

```bash
# Make the setup script executable
chmod +x setup_scripts.sh

# Run the script and follow the prompts
./setup_scripts.sh
```

See [README_BUILD.md](./README_BUILD.md) for detailed information about required dependencies.

### Build Steps

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

## Usage

1. Load the plugin in your favorite DAW (Digital Audio Workstation)
2. Adjust the volume using the vertical slider
3. The volume setting will be saved with your project

## Development

This plugin demonstrates basic audio plugin development with JUCE, including:

- Audio processing (volume control)
- Custom UI with a slider
- Parameter handling
- State saving/loading

Feel free to use this as a starting point for your own audio plugin projects.

## Detailed Documentation

For more detailed build instructions, dependency information, and troubleshooting:

- [README_BUILD.md](./README_BUILD.md) - Comprehensive build instructions