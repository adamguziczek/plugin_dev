# Building VolumeControlPlugin from WSL to Windows

This guide explains how to develop the VolumeControlPlugin in WSL (Windows Subsystem for Linux) using VSCode while building and testing on Windows.

## The Problem

When developing on WSL and trying to build directly for Windows:
- Windows command line tools cannot operate directly on WSL paths (`\\wsl.localhost\...`)
- PowerShell scripts fail with "UNC paths are not supported" errors
- Visual Studio build tools require Windows native paths

## The Solution: WSL to Windows Build Helper

The included `windows_build_from_wsl.ps1` script solves this problem by:
1. Copying your project files from WSL to a Windows directory
2. Copying the JUCE framework if needed
3. Running the Windows build script from the Windows directory
4. Providing the build output location for testing in your DAW

## How to Use

### First-time setup

1. Open PowerShell as Administrator on Windows
2. Navigate to your WSL path where the project is located:
   ```powershell
   cd \\wsl.localhost\Ubuntu\path\to\VolumeControlPlugin
   ```
3. Run the helper script:
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1
   ```
4. By default, this will copy files to `C:\Temp\VolumeControlPlugin`
5. The script will then build the project using `build_simple.ps1`

### Customizing the Windows destination

You can specify a different Windows destination:

```powershell
PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1 -WindowsDestination "C:\Dev\VolumeControlPlugin"
```

### Skipping the copy step for faster builds

If you've already copied the files and only made minor changes:

```powershell
PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1 -SkipCopy
```

### Building with Debug configuration

```powershell
PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1 -BuildType Debug
```

## Workflow Example

Here's a typical development workflow:

1. Develop and edit code in VSCode through WSL
2. When ready to test:
   - In Windows PowerShell, navigate to your WSL project path
   - Run `windows_build_from_wsl.ps1`
3. Test the built plugin in FL Studio or other Windows DAW
4. Continue development in VSCode through WSL
5. For subsequent builds, use the `-SkipCopy` option to build faster

## Finding the Built Plugin

After a successful build, the VST3 plugin will be located at:
```
C:\Temp\VolumeControlPlugin\build_vs\VolumeControlPlugin_artefacts\Release\VST3\VolumeControlPlugin.vst3
```

Copy this to your VST3 directory or configure your DAW to find it at this location.

## Cleaning the Build

To clean the build directory:

```powershell
cd C:\Temp\VolumeControlPlugin
.\clean.ps1
```

## Troubleshooting

### Script Execution Policy Errors

If you get execution policy errors, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Visual Studio Not Found

Make sure Visual Studio with C++ desktop development is installed on your Windows system.

### JUCE Not Found

The script looks for JUCE in the parent directory of your project. Make sure it's correctly located at `../JUCE` relative to your project.

## Alternative Approaches

If this approach doesn't work for you, consider:

1. **Native Windows Development**: Clone the repository to a Windows path and develop directly in Windows
2. **Windows Build Server**: Set up a build process that automatically copies from WSL and builds on Windows
3. **VSCode Remote Development**: Use VSCode's remote development features to edit directly on Windows while using WSL for other tasks

## Need Help?

If you encounter issues with this build process, check:
- The CMakeLists.txt file for any Linux-specific configurations
- Visual Studio installation (make sure C++ desktop development is installed)
- JUCE framework location and accessibility