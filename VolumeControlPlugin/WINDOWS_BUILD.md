# Windows Build Guide for Volume Control Plugin

This guide provides step-by-step instructions for building the Volume Control Plugin on Windows using PowerShell scripts.

## Prerequisites

Before building the plugin, ensure you have the following installed on your Windows system:

1. **Visual Studio 2019 or 2022** with "Desktop development with C++" workload
   - Download from: [Visual Studio Downloads](https://visualstudio.microsoft.com/downloads/)
   - During installation, make sure to select "Desktop development with C++" workload
   - Also select the latest "Windows 10 SDK" component

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

### Important: Project Location

For successful Windows builds, the project must be located on a Windows path:

- Do NOT run build scripts from WSL paths like `\\wsl.localhost\...`
- Avoid system directories like `C:\Windows\System32\...`
- Recommended locations: `C:\Dev\VolumeControlPlugin` or `C:\Users\YourName\Projects\VolumeControlPlugin`

### Option 1: Using the Simple Build Script (Recommended)

1. **Open PowerShell** as Administrator
   - Right-click on PowerShell and select "Run as Administrator"

2. **Navigate to the project directory**
   ```powershell
   cd C:\path\to\VolumeControlPlugin  # Use a Windows path, not WSL path
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
   cd C:\path\to\VolumeControlPlugin
   ```

3. **Run the build script with your preferred configuration**
   ```powershell
   # For Release build (default)
   .\build_plugin.ps1
   
   # For Debug build
   .\build_plugin.ps1 Debug
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

### Compiler Not Found

**Issue**: "No CMAKE_C_COMPILER could be found" or "No CMAKE_CXX_COMPILER could be found"  
**Solution**:
- Make sure Visual Studio is installed with "Desktop development with C++" workload
- Install/reinstall the Windows 10 SDK from Visual Studio Installer
- Run Visual Studio at least once to complete any first-run setup
- Check if antivirus is blocking cl.exe or vcvarsall.bat
- Run the build script as Administrator
- The script will attempt a fallback configuration if the primary method fails

### WSL Path Error

**Issue**: "Cannot build directly from WSL path", "UNC paths are not supported"  
**Solution**:
- You cannot run the Windows build scripts from a WSL path (\\wsl.localhost\...)
- Clone the repository to a native Windows path:
  ```powershell
  git clone https://github.com/your-repo/VolumeControlPlugin.git C:\Dev\VolumeControlPlugin
  cd C:\Dev\VolumeControlPlugin
  ```

### System Directory Warning

**Issue**: "You're running from a system directory"  
**Solution**:
- Avoid running build scripts from system directories like C:\Windows\System32
- Move your project to a standard development location like C:\Dev or C:\Projects

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
- Make sure you have the latest Windows build scripts that include compiler detection fixes
- Check the console output for specific error messages

## Advanced: Manual Build without Scripts

If you prefer to build manually, you need to set up the Visual Studio environment first:

1. **Open a Command Prompt window**

2. **Set up the Visual Studio environment**:
   ```cmd
   "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
   ```
   (Adjust the path according to your Visual Studio installation location and version)

3. **Create a build directory**:
   ```cmd
   mkdir build_manual
   cd build_manual
   ```

4. **Configure with CMake**:
   ```cmd
   cmake -G "Visual Studio 16 2019" -A x64 ..
   ```

5. **Build the project**:
   ```cmd
   cmake --build . --config Release
   ```

6. **Find the built plugin**:
   ```
   build_manual\VolumeControlPlugin_artefacts\Release\VST3\VolumeControlPlugin.vst3
   ```

## Cross-Platform Development

This project supports both Windows and Linux development:

- You can develop primarily on Linux using the Linux build scripts
- You can build natively on Windows using these PowerShell scripts
- The same codebase works on both platforms without cross-compilation

When working across platforms, just remember:
- Build on Windows using a Windows path (not a WSL path)
- Build on Linux using the native Linux build script (build.sh)

## Need Help?

If you encounter any issues not covered in this guide:

1. Check the script output for detailed error messages
2. Make sure all prerequisites are correctly installed
3. Try running the script with `-Verbose` for more detailed logging:
   ```powershell
   .\build_simple.ps1 -Verbose