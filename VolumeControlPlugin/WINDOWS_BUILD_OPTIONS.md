# Windows Build Options for VolumeControlPlugin

This document outlines the recommended approaches for building the VolumeControlPlugin for Windows platforms, with detailed instructions for each method. The JUCE framework **only officially supports Microsoft's Visual C++ compiler for Windows builds**.

## Overview of Available Options

Here are the recommended approaches for building Windows VST3 plugins, in order of reliability:

1. **Native Windows Build with Visual Studio** (Recommended) - Building directly on Windows using Visual Studio and CMake
2. **MSVC Cross-Compilation from WSL** - Using Microsoft's Visual C++ compiler from WSL (including VS2019 Community support)
3. **Docker-based Build Environment** - Using a containerized Windows build environment 

**IMPORTANT NOTE**: The MinGW-based cross-compilation approach is not included as an option because JUCE does not support MinGW and it will not work reliably for building Windows plugins.

## 1. Native Windows Build with Visual Studio (Recommended)

This is the **officially supported approach** by JUCE and provides the most reliable results.

### Prerequisites

- Windows 10/11
- [Visual Studio 2019 or 2022](https://visualstudio.microsoft.com/downloads/) with Desktop development with C++ workload
- [CMake](https://cmake.org/download/) (version 3.15 or higher)
- [Git](https://git-scm.com/download/win) for Windows

### Step-by-Step Instructions

1. **Install Visual Studio and required components**:
   - Download and install Visual Studio 2019 or 2022
   - During installation, select "Desktop development with C++" workload
   - Make sure "C++ CMake tools for Windows" is included

2. **Clone the repository in Windows**:
   ```powershell
   git clone https://github.com/your-repo/VolumeControlPlugin.git
   cd VolumeControlPlugin
   ```

3. **Clone JUCE in the parent directory**:
   ```powershell
   cd ..
   git clone https://github.com/juce-framework/JUCE.git
   cd VolumeControlPlugin
   ```

4. **Configure and build using CMake**:
   ```powershell
   # Create a build directory
   mkdir build_win
   cd build_win
   
   # Configure with CMake
   cmake -G "Visual Studio 17 2022" -A x64 ..
   
   # Build
   cmake --build . --config Release
   ```

5. **Locate the built plugin**:
   The VST3 plugin will be in: `build_win\VolumeControlPlugin_artefacts\Release\VST3\`

### Advantages

- Most reliable method as it uses JUCE's officially supported compiler
- Full compatibility with Windows APIs and systems
- Direct access to debugging and profiling tools
- JUCE is fully tested with MSVC and Visual Studio

### Disadvantages

- Requires Windows and Visual Studio (larger environment setup)
- Separate build environment from Linux/MacOS builds

## 2. MSVC Cross-Compilation from WSL

This approach allows you to use Microsoft's Visual C++ compiler (which is officially supported by JUCE) while working from WSL.

### Prerequisites

- Windows 10/11 with WSL2 installed
- Visual Studio 2019 or 2022 installed on Windows
- Ubuntu (or another Linux distribution) running in WSL
- CMake (version 3.15 or higher) installed in WSL

### Step-by-Step Instructions

1. **Install WSL2 and Ubuntu** (if not already installed):
   ```powershell
   # Run in PowerShell as Administrator
   wsl --install
   ```

2. **Install Visual Studio on Windows** (if not already installed):
   - Download and install Visual Studio 2019 or 2022
   - During installation, select "Desktop development with C++" workload

3. **Install build dependencies in WSL**:
   ```bash
   sudo apt update
   sudo apt install cmake build-essential
   ```

4. **Clone the repository in WSL**:
   ```bash
   git clone https://github.com/your-repo/VolumeControlPlugin.git
   cd VolumeControlPlugin
   ```

5. **Clone JUCE in the parent directory**:
   ```bash
   cd ..
   git clone https://github.com/juce-framework/JUCE.git
   cd VolumeControlPlugin
   ```

6. **Set up environment variables to locate MSVC**:
   
   **Option 1: Use the helper script for VS2019 Community** (Recommended):
   ```bash
   # Make the script executable
   chmod +x set_msvc_paths.sh
   
   # Run the script
   ./set_msvc_paths.sh
   ```
   
   **Option 2: Manual setup**:
   
   For Visual Studio 2019 Community:
   ```bash
   # First locate your MSVC version directory (example: 14.29.30133)
   ls "/mnt/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/MSVC/"
   
   # Set the environment variables with your actual version number
   export MSVC_BASE_PATH="/mnt/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/MSVC/14.29.30133"
   export WINDOWS_KITS_BASE_PATH="/mnt/c/Program Files (x86)/Windows Kits/10"
   
   # Save to .bashrc for persistence
   echo "export MSVC_BASE_PATH=\"$MSVC_BASE_PATH\"" >> ~/.bashrc
   echo "export WINDOWS_KITS_BASE_PATH=\"$WINDOWS_KITS_BASE_PATH\"" >> ~/.bashrc
   ```
   
   For Visual Studio 2022 editions:
   ```bash
   # Find your MSVC and Windows SDK paths and adjust these paths accordingly
   export MSVC_BASE_PATH="/mnt/c/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.30.30705"
   export WINDOWS_KITS_BASE_PATH="/mnt/c/Program Files (x86)/Windows Kits/10"
   
   # Save to .bashrc for persistence
   echo "export MSVC_BASE_PATH=\"$MSVC_BASE_PATH\"" >> ~/.bashrc
   echo "export WINDOWS_KITS_BASE_PATH=\"$WINDOWS_KITS_BASE_PATH\"" >> ~/.bashrc
   ```

7. **Make the build script executable**:
   ```bash
   chmod +x build_windows_msvc.sh
   ```

8. **Run the MSVC build script**:
   ```bash
   ./build_windows_msvc.sh
   ```

### Advantages

- Uses JUCE's officially supported compiler (MSVC)
- Better compatibility than MinGW
- Allows development in Linux environment with WSL

### Disadvantages

- Requires both Windows and WSL setup
- More complex environment setup with path mapping
- Limited debugging capabilities compared to native builds


## 4. Docker-based Build Environment

This approach uses Docker to create a consistent build environment with all necessary tools pre-installed.

### Prerequisites

- Docker installed on your system
- Basic familiarity with Docker commands

### Step-by-Step Instructions

1. **Create a Dockerfile for Windows builds**:
   
   Create a file named `Dockerfile.windows` with the following content:

   ```dockerfile
   # Use an image with MSVC and Windows tools
   FROM crazymax/osxcross:latest-windows

   # Install dependencies
   RUN apt-get update && apt-get install -y \
       build-essential \
       cmake \
       git \
       python3 \
       wget \
       unzip

   # Clone JUCE (if not mounted as a volume)
   WORKDIR /src
   RUN git clone https://github.com/juce-framework/JUCE.git

   # Set up build environment
   WORKDIR /src/build

   # Entry point
   ENTRYPOINT ["/bin/bash"]
   ```

2. **Build the Docker image**:
   ```bash
   docker build -t volumecontrolplugin-windows-builder -f Dockerfile.windows .
   ```

3. **Run the build in Docker**:
   ```bash
   docker run -it --rm \
     -v $(pwd):/src/VolumeControlPlugin \
     -v $(pwd)/../JUCE:/src/JUCE \
     volumecontrolplugin-windows-builder \
     -c "cd /src/VolumeControlPlugin && mkdir -p build_docker && cd build_docker && cmake .. && cmake --build . --config Release"
   ```

4. **Locate the built plugin**:
   The VST3 plugin will be in: `build_docker/VolumeControlPlugin_artefacts/Release/VST3/`

### Advantages

- Consistent, isolated build environment
- Can be integrated into CI/CD pipelines
- Works on any platform that supports Docker

### Disadvantages

- More complex setup
- May have performance overhead
- Requires Docker knowledge
- Limited debugging capabilities

## Comparison of Build Approaches

| Approach | JUCE Support | Ease of Setup | Reliability | Debugging | Requirements |
|----------|--------------|---------------|-------------|-----------|--------------|
| Native Windows Build | ✅ Official | Moderate | High | Excellent | Windows, Visual Studio |
| MSVC Cross-Compilation | ✅ Official | Complex | Good | Limited | Windows + WSL, Visual Studio |
| Docker-based | ✅ Official* | Complex | Good | Limited | Docker |

*Depends on the compiler used in the Docker container

## Troubleshooting Common Issues


### MSVC Cross-Compilation Path Issues

**Issue**: "MSVC compiler not found" or similar errors
**Solution**: 

1. **For Visual Studio 2019 Community Edition users**:
   - Use the included helper script to automatically set up paths:
   ```bash
   chmod +x set_msvc_paths.sh
   ./set_msvc_paths.sh
   ```
   - This script will automatically detect your MSVC version and set it properly

2. **For manual path setup**:
   - The MSVC_BASE_PATH must point to the specific version folder, not just the VC folder
   - For example: `/mnt/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/MSVC/14.29.30133`
   - Be sure to look inside your `/mnt/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/MSVC/` directory to find the exact version number

3. **Verify your paths**:
   - Confirm the cl.exe compiler exists in your path: 
   ```bash
   ls "$MSVC_BASE_PATH/bin/Hostx64/x64/cl.exe"
   ```
   - If the file exists, your MSVC path is correct

4. **Verify WSL can access Windows directories properly**:
   - Make sure you're running in a proper WSL shell (not just VS Code's terminal emulation)
   - Ensure you have access to `/mnt/c` and can navigate to your Windows files

### CMake Configuration Errors

**Issue**: CMake cannot find JUCE
**Solution**:

1. Ensure JUCE is cloned in the parent directory
2. Specify JUCE location explicitly:
   ```bash
   cmake -DJUCE_DIR="/path/to/JUCE" ...
   ```

## Conclusion

For the most reliable results, it's recommended to build the VolumeControlPlugin natively on Windows using Visual Studio. If working primarily in Linux, the MSVC cross-compilation approach provides a good balance between JUCE compatibility and Linux-based workflow.

The MinGW approach, while convenient, is likely to encounter issues due to JUCE's lack of official support for this compiler.

## References

- [JUCE CMake API documentation](https://github.com/juce-framework/JUCE/blob/master/docs/CMake%20API.md)
- [JUCE Framework official documentation](https://juce.com/learn/)
- [CMake documentation](https://cmake.org/documentation/)
- [Microsoft Visual C++ documentation](https://docs.microsoft.com/en-us/cpp/)
- [MinGW-w64 documentation](http://mingw-w64.org/doku.php)