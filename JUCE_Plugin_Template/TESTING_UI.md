# Testing Your Plugin UI Without a DAW

There are two primary methods to test your plugin's UI during development without loading it in a full Digital Audio Workstation (DAW):

1. Using the Standalone application format
2. Using JUCE's AudioPluginHost

Both methods are explained in detail below.

## Method 1: Using the Standalone Application

The plugin template is already configured to build a standalone application version of your plugin. This creates a regular application that you can run directly without a DAW.

### Building the Standalone Application

The standalone application is built along with the other plugin formats when you run the build script:

```bash
# Linux/WSL
./build.sh

# Windows (from WSL)
PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1
```

### Running the Standalone Application

After building, you can find the standalone application at:

**Linux/WSL:**
```
build/YourPluginName_artefacts/Standalone/YourPluginName
```

Run it with:
```bash
./build/YourPluginName_artefacts/Standalone/YourPluginName
```

**Windows:**
```
build_vs\YourPluginName_artefacts\Release\Standalone\YourPluginName.exe
```

Run it by double-clicking the .exe file or from PowerShell/CMD:
```powershell
& "build_vs\YourPluginName_artefacts\Release\Standalone\YourPluginName.exe"
```

### Advantages of the Standalone Format

- No additional setup required
- Tests your plugin in a simplified but real audio processing environment
- Shows both the UI and audio processing capability
- Can test with audio input/output

### Customizing the Standalone Application

By default, the standalone application includes basic audio device selection and settings. 
You can customize its behavior by modifying your plugin code or using these JUCE preprocessor definitions in your CMakeLists.txt:

```cmake
target_compile_definitions(${PROJECT_NAME}
    PUBLIC
    JUCE_STANDALONE_APPLICATION=1
    # Uncomment to use specific settings:
    # JUCE_STANDALONE_FILTER_WINDOW_TITLE="My Custom Title"
    # JUCE_STANDALONE_FILTER_WINDOW_SIZE_X=800
    # JUCE_STANDALONE_FILTER_WINDOW_SIZE_Y=600
)
```

## Method 2: Using JUCE's AudioPluginHost

JUCE comes with a built-in plugin host application called AudioPluginHost that can load and test your plugins.

### Building AudioPluginHost

1. Navigate to the JUCE extras directory:
   ```bash
   cd ../JUCE/extras/AudioPluginHost
   ```

2. Create a build directory and run CMake:
   ```bash
   mkdir -p build
   cd build
   cmake ..
   ```

3. Build the host:
   ```bash
   cmake --build .
   ```

### Running Your Plugin in AudioPluginHost

1. Launch the AudioPluginHost from:
   - Linux: `JUCE/extras/AudioPluginHost/build/AudioPluginHost`
   - Windows: `JUCE\extras\AudioPluginHost\build\Release\AudioPluginHost.exe`

2. In AudioPluginHost, go to "Options" → "Edit the list of available plugins..."

3. Add your build directory to the scan paths:
   - Linux: `/path/to/YourPluginName/build/YourPluginName_artefacts/VST3`
   - Windows: `C:\path\to\YourPluginName\build_vs\YourPluginName_artefacts\Release\VST3`

4. Click "Scan for new or updated VST3 plugins"

5. Create a new graph with "File" → "New"

6. Right-click on the graph editor and add your plugin

### Advantages of Using AudioPluginHost

- More representative of a real plugin host environment
- Can test plugin connections to other plugins
- Includes tools for analyzing plugin behavior
- Supports testing automation and parameter changes
- Built specifically for testing JUCE plugins

## Debugging Your Plugin UI

### In Visual Studio Code

1. Add a launch configuration in `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Standalone Plugin",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/build/YourPluginName_artefacts/Standalone/YourPluginName",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        }
    ]
}
```

2. Set breakpoints in your UI code

3. Start debugging with F5 or the debug button

### In Visual Studio (Windows)

1. Open the generated Visual Studio solution in `build_vs/`

2. Set the Standalone project as the startup project

3. Set breakpoints in your UI code

4. Press F5 to start debugging

## Creating Automated UI Tests

For more advanced testing, you can create automated UI tests using JUCE's UnitTestRunner:

1. Create a new file in your Source directory, e.g., `UITests.cpp`

2. Write UI tests that programmatically interact with your UI components:

```cpp
#include <JuceHeader.h>
#include "PluginProcessor.h"
#include "PluginEditor.h"

class UITests : public juce::UnitTest
{
public:
    UITests() : UnitTest("Plugin UI Tests") {}

    void runTest() override
    {
        beginTest("UI Component Creation");
        
        YourPluginAudioProcessor processor;
        YourPluginAudioProcessorEditor editor(processor);
        
        // Test UI component properties
        expectEquals(editor.getWidth(), 400);
        expectEquals(editor.getHeight(), 300);
        
        // Add more UI tests as needed
    }
};

static UITests uiTests;
```

3. Add these tests to your build system