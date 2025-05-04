# Windows Build Guide for Volume Control Plugin

This guide provides step-by-step instructions for building the Volume Control Plugin on Windows using PowerShell scripts.

## Prerequisites

Before building the plugin, ensure you have the following installed on your Windows system:

1. **Visual Studio 2019 or 2022** with "Desktop development with C++" workload
   - Download from: [Visual Studio Downloads](https://visualstudio.microsoft.com/downloads/)
   - During installation, make sure to select "Desktop development with C++" workload

2. **CMake** (version 3.15 or higher)
   - Download from: [CMake Downloads](https://cmake.org/download/)
   - Make sure to add CMake to your system PATH during installation

3. **PowerShell 5.1 or later** (included with Windows 10/11)

4. **JUCE Framework**
   - The JUCE directory should be in the parent directory of this project
   - If needed, clone it using:
     ```powershell
     cd ..
     git clone https://github.com/juce-framework/JUCE.git
     cd VolumeControlPlugin
     ```

## Building with PowerShell Scripts

Two PowerShell scripts are provided for building the plugin:

- `build_simple.ps1`: A streamlined script with clear output for quick builds
- `build_plugin.ps1`: A more detailed script with comprehensive feedback

### Option 1: Using the Simple Build Script (Recommended)

1. **Open PowerShell** as Administrator
   - Right-click on PowerShell and select "Run as Administrator"

2. **Navigate to the project directory**
   ```powershell
   cd path\to\VolumeControlPlugin
   ```

3. **Run the build script**
   ```powershell
   .\build_simple.ps1
   ```

4. **If you encounter an execution policy error**, run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   .\build_simple.ps1
   ```

5. **Follow the on-screen instructions** to complete the build process

### Option 2: Using the Comprehensive Build Script

1. **Open PowerShell** as Administrator

2. **Navigate to the project directory**
   ```powershell
   cd path\to\VolumeControlPlugin
   ```

3. **Run the build script with your preferred configuration**
   ```powershell
   # For Release build (default)
   .\build_plugin.ps1
   
   # For Debug build
   .\build_plugin.ps1 Debug
   ```

4. **If you encounter an execution policy error**, run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   .\build_plugin.ps1
   ```

## Build Output Locations

After a successful build, you'll find the plugin files in the following locations:

- **VST3 Plugin**:
  ```
  build_vs\VolumeControlPlugin_artefacts\Release\VST3\VolumeControlPlugin.vst3
  ```

- **Standalone Application**:
  ```
  build_vs\VolumeControlPlugin_artefacts\Release\Standalone\VolumeControlPlugin.exe
  ```

For Debug builds, replace `Release` with `Debug` in the paths above.

## Installing the VST3 Plugin

To use the VST3 plugin in your DAW:

1. **Copy the VST3 plugin** to the system VST3 directory:
   ```powershell
   # Create the directory if it doesn't exist
   $vst3Dir = "C:\Program Files\Common Files\VST3"
   if (-not (Test-Path $vst3Dir)) {
       New-Item -Path $vst3Dir -ItemType Directory -Force
   }

   # Copy the plugin
   Copy-Item -Path "build_vs\VolumeControlPlugin_artefacts\Release\VST3\VolumeControlPlugin.vst3" -Destination $vst3Dir -Recurse -Force
   ```

2. **Restart your DAW** or rescan for plugins

3. **Look for "Volume Control Plugin"** in your DAW's plugin list

## Testing with the Standalone Application

You can test the plugin without a DAW by running the standalone application:

```powershell
.\build_vs\VolumeControlPlugin_artefacts\Release\Standalone\VolumeControlPlugin.exe
```

## Cleaning Build Files

To clean all build files and start fresh:

1. **Run the clean script**:
   ```powershell
   .\clean.ps1
   ```

2. **Confirm deletion** when prompted

## Troubleshooting Common Issues

### PowerShell Execution Policy

**Issue**: "Running scripts is disabled on this system"  
**Solution**: Run this command before the build script:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Visual Studio Not Found

**Issue**: "Visual Studio not found" error  
**Solution**: 
- Ensure Visual Studio is installed with "Desktop development with C++" workload
- For VS 2022, the script automatically detects and uses the correct generator

### CMake Not Found

**Issue**: "CMake not found" error  
**Solution**:
- Install CMake from [cmake.org/download](https://cmake.org/download/)
- Ensure CMake is added to your system PATH
- Restart PowerShell after installation

### JUCE Not Found

**Issue**: "JUCE not found" error  
**Solution**:
- Make sure the JUCE directory is in the parent directory of VolumeControlPlugin
- Clone JUCE if needed:
  ```powershell
  cd ..
  git clone https://github.com/juce-framework/JUCE.git
  cd VolumeControlPlugin
  ```

### Build Errors

**Issue**: General build errors  
**Solution**:
- Clean the build directories with `.\clean.ps1`
- Try building with the Debug configuration: `.\build_plugin.ps1 Debug`
- Check Visual Studio logs for more detailed error information

## Advanced: Manual Build without Scripts

If you prefer to build manually:

1. **Create a build directory**:
   ```powershell
   mkdir build_manual
   cd build_manual
   ```

2. **Configure with CMake**:
   ```powershell
   # For Visual Studio 2019
   cmake -G "Visual Studio 16 2019" -A x64 ..
   
   # For Visual Studio 2022
   cmake -G "Visual Studio 17 2022" -A x64 ..
   ```

3. **Build the project**:
   ```powershell
   cmake --build . --config Release
   ```

4. **Find the built plugin**:
   ```
   build_manual\VolumeControlPlugin_artefacts\Release\VST3\VolumeControlPlugin.vst3
   ```

## Need Help?

If you encounter any issues not covered in this guide:

1. Check the full documentation in README_BUILD.md
2. Make sure all prerequisites are correctly installed
3. Try cleaning the build with `.\clean.ps1` and building again