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

### Build Steps

1. Make sure you have the JUCE framework in the parent directory of this project
2. Create a build directory:
   ```
   mkdir build
   cd build
   ```
3. Run CMake:
   ```
   cmake ..
   ```
4. Build the plugin:
   ```
   cmake --build .
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