# JUCE Plugin Template

A complete template for JUCE audio plugin development with build scripts for both Linux/WSL and Windows.

## Quick Start

1. Copy this entire folder to your desired location and rename it to your plugin name
2. Make the shell scripts executable: `chmod +x *.sh`
3. Update the plugin name and other details in:
   - CMakeLists.txt
   - Source/PluginProcessor.h/cpp
   - Source/PluginEditor.h/cpp
4. Build your plugin:
   - Linux/WSL: `./build.sh`
   - Windows (from WSL): `PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1`

## Template Contents

```
JUCE_Plugin_Template/
├── Source/                   # Source code folder
│   ├── PluginProcessor.h     # Audio processor class declaration
│   ├── PluginProcessor.cpp   # Audio processor implementation
│   ├── PluginEditor.h        # UI component class declaration  
│   └── PluginEditor.cpp      # UI component implementation
├── CMakeLists.txt            # CMake build configuration
├── setup_scripts.sh          # Install dependencies
├── build.sh                  # Build script for Linux
├── clean.sh                  # Clean script for Linux
├── windows_build_from_wsl.ps1 # Windows build script from WSL
└── clean.ps1                 # Clean script for Windows
```

## Prerequisites

- **CMake** (version 3.15 or higher)
- **C++ compiler** with C++17 support
- **JUCE framework** (should be in the parent directory of your plugin)

Run `./setup_scripts.sh` to install the necessary dependencies on Linux/Ubuntu systems.

## Customizing the Template

### 1. Update CMakeLists.txt

Edit `CMakeLists.txt` and update these fields:
- Project name (`project(YourPluginName VERSION 0.1.0)`)
- Plugin formats you want to build
- Plugin details (name, manufacturer, etc.)
- JUCE modules you need

### 2. Customize Audio Processing

Edit `Source/PluginProcessor.h` and `Source/PluginProcessor.cpp`:
- Rename the `YourPluginAudioProcessor` class
- Add parameters in the constructor
- Implement your DSP code in the `processBlock()` method
- Add state saving/loading in `getStateInformation()` and `setStateInformation()`

Look for the `CUSTOMIZE:` comments throughout the code for guidance.

### 3. Create a Custom UI (Optional)

Edit `Source/PluginEditor.h` and `Source/PluginEditor.cpp`:
- Rename the `YourPluginAudioProcessorEditor` class
- Add UI components (sliders, buttons, etc.)
- Customize the look and feel in the `paint()` method
- Position UI components in the `resized()` method

The template is configured to use the `GenericAudioProcessorEditor` by default. To use your custom editor, uncomment the related line in `PluginProcessor.cpp`.

## Building Your Plugin

### Linux/WSL

1. Make scripts executable:
   ```
   chmod +x setup_scripts.sh build.sh clean.sh
   ```

2. Install dependencies (first time only):
   ```
   ./setup_scripts.sh
   ```

3. Build the plugin:
   ```
   ./build.sh
   ```

### Windows (from WSL)

1. Build using PowerShell:
   ```
   PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1
   ```

2. Options for faster builds:
   ```
   # Skip copying files (for rebuilds)
   PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1 -SkipCopy
   
   # Force clean rebuild
   PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1 -Force
   ```

## Cleaning Build Directories

- Linux/WSL: `./clean.sh`
- Windows: `PowerShell -ExecutionPolicy Bypass -File clean.ps1`

## Finding the Built Plugin

### Linux/WSL

The built plugin is in the `build` directory:
- VST3: `build/YourPluginName_artefacts/VST3/YourPluginName.vst3`
- Standalone: `build/YourPluginName_artefacts/Standalone/YourPluginName`

### Windows

The built plugin is in the `build_vs` directory:
- VST3: `build_vs/YourPluginName_artefacts/Release/VST3/YourPluginName.vst3`

## Integration with DAWs

### Linux/WSL

Copy the VST3 to the system VST3 directory or configure your DAW to scan the build directory:
```bash
cp -r build/YourPluginName_artefacts/VST3/YourPluginName.vst3 ~/.vst3/
```

### Windows

Copy the VST3 to the system VST3 directory:
```powershell
copy "build_vs\YourPluginName_artefacts\Release\VST3\YourPluginName.vst3" "C:\Program Files\Common Files\VST3\"
```

## Testing Your Plugin UI

You can test your plugin UI without loading it in a DAW! See [TESTING_UI.md](./TESTING_UI.md) for detailed instructions on:

- Using the Standalone application format
- Using JUCE's AudioPluginHost
- Debugging your UI
- Creating automated UI tests

## Next Steps

- Add more parameters to your plugin
- Implement your DSP algorithms
- Create a custom UI with knobs, sliders, and visualization
- Add preset management
- Test in different DAWs

## Resources

- [JUCE Documentation](https://juce.com/learn/documentation)
- [JUCE Tutorials](https://juce.com/learn/tutorials/)
- [JUCE API Reference](https://docs.juce.com/master/index.html)
- [JUCE CMake API](https://github.com/juce-framework/JUCE/blob/master/docs/CMake%20API.md)