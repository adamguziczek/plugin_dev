#!/bin/bash
# build_windows_msvc.sh - Build script for creating Windows-compatible VST3 plugins using MSVC cross-compiler
# 
# This script builds the VolumeControlPlugin for Windows using Microsoft's Visual C++ compiler
# which is officially supported by JUCE (unlike MinGW)

# Set up colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Current script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="${SCRIPT_DIR}"
JUCE_DIR="${ROOT_DIR}/../JUCE"
BUILD_DIR="${ROOT_DIR}/build_windows_msvc"

# Create log file with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${ROOT_DIR}/build_windows_msvc_${TIMESTAMP}.log"

# Initialize log file
touch "$LOG_FILE"
echo "VolumeControlPlugin Windows MSVC Build Log (${TIMESTAMP})" > "$LOG_FILE"
echo "====================================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Log function that outputs to both console and log file
log_output() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Print a message with a colored prefix
info() {
    log_output "${BLUE}[INFO]${NC} $1"
}

success() {
    log_output "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    log_output "${YELLOW}[WARNING]${NC} $1"
}

error() {
    log_output "${RED}[ERROR]${NC} $1"
}

# Check for WSL in multiple ways to improve detection reliability
check_wsl() {
    # Method 1: Check /proc/version for Microsoft
    if grep -q Microsoft /proc/version; then
        return 0
    fi
    
    # Method 2: Check for WSL environment variable
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        return 0
    fi
    
    # Method 3: Check for Windows mounts
    if [ -d "/mnt/c" ] && [ -d "/mnt/c/Windows" ]; then
        return 0
    fi
    
    # Not in WSL
    return 1
}

# Check MSVC prerequisites
check_prerequisites() {
    info "Checking prerequisites for Windows MSVC cross-compilation..."
    
    # Check for WSL using improved detection method
    if ! check_wsl; then
        error "This script is designed to run in Windows Subsystem for Linux (WSL)."
        echo "The MSVC cross-compilation requires access to Visual Studio installed on Windows."
        echo ""
        warning "You appear to not be running in WSL or WSL was not detected properly."
        warning "If you are running in WSL, please try these troubleshooting steps:"
        echo "1. Make sure you can access Windows files: ls /mnt/c"
        echo "2. Try opening a dedicated WSL terminal outside of VS Code"
        echo "3. Try running: wsl --set-default-version 2 (from PowerShell as admin)"
        echo "4. If you have access to /mnt/c, you can continue anyway by setting:"
        echo "   export WSL_DETECTED=1"
        echo "   Then run this script again."
        
        # Allow override for environments where detection fails but Windows paths work
        if [ "$WSL_DETECTED" = "1" ]; then
            warning "WSL detection override is set. Proceeding anyway..."
        else
            exit 1
        fi
    fi
    
    # Check for MSVC_BASE_PATH environment variable
    if [ -z "$MSVC_BASE_PATH" ]; then
        error "MSVC_BASE_PATH environment variable is not set."
        echo "This should point to your MSVC installation (usually inside Visual Studio)."
        echo "Example: export MSVC_BASE_PATH=\"/mnt/c/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.30.30705\""
        exit 1
    fi
    
    # Check for WINDOWS_KITS_BASE_PATH environment variable
    if [ -z "$WINDOWS_KITS_BASE_PATH" ]; then
        error "WINDOWS_KITS_BASE_PATH environment variable is not set."
        echo "This should point to your Windows SDK installation."
        echo "Example: export WINDOWS_KITS_BASE_PATH=\"/mnt/c/Program Files (x86)/Windows Kits/10\""
        exit 1
    fi
    
    # Check if MSVC directories exist
    if [ ! -d "$MSVC_BASE_PATH" ]; then
        error "MSVC directory not found at $MSVC_BASE_PATH"
        echo "Please check your MSVC_BASE_PATH environment variable."
        exit 1
    fi
    
    if [ ! -d "$WINDOWS_KITS_BASE_PATH" ]; then
        error "Windows Kits directory not found at $WINDOWS_KITS_BASE_PATH"
        echo "Please check your WINDOWS_KITS_BASE_PATH environment variable."
        exit 1
    fi
    
    # Check for cl.exe (MSVC compiler)
    if [ ! -f "${MSVC_BASE_PATH}/bin/Hostx64/x64/cl.exe" ]; then
        error "MSVC compiler (cl.exe) not found at ${MSVC_BASE_PATH}/bin/Hostx64/x64/cl.exe"
        echo "Please check your MSVC_BASE_PATH environment variable."
        exit 1
    fi
    
    # Check if CMake is installed
    if ! command -v cmake &> /dev/null; then
        error "CMake not found. Please install it using:"
        echo "sudo apt-get install cmake"
        exit 1
    fi
    
    # Check CMake version
    local cmake_version=$(cmake --version | grep -oP "(?<=version )[0-9]+\.[0-9]+")
    local cmake_major=$(echo $cmake_version | cut -d. -f1)
    local cmake_minor=$(echo $cmake_version | cut -d. -f2)
    
    if [ "$cmake_major" -lt 3 ] || ([ "$cmake_major" -eq 3 ] && [ "$cmake_minor" -lt 15 ]); then
        error "CMake version 3.15 or higher is required. Found version $cmake_version."
        exit 1
    fi
    
    # Check if JUCE directory exists
    if [ ! -d "$JUCE_DIR" ]; then
        error "JUCE directory not found at $JUCE_DIR"
        info "Check that JUCE is located at $JUCE_DIR, or modify this script to point to its location."
        exit 1
    fi
    
    info "Using CMake version $cmake_version"
    success "All prerequisites satisfied!"
}

# Create build directory
create_build_directory() {
    info "Creating Windows MSVC build directory..."
    
    if [ ! -d "$BUILD_DIR" ]; then
        mkdir -p "$BUILD_DIR"
        success "Windows MSVC build directory created at $BUILD_DIR"
    else
        info "Windows MSVC build directory already exists at $BUILD_DIR"
    fi
}

# Run CMake configuration
run_cmake_config() {
    info "Running CMake to configure the Windows MSVC project..."
    
    cd "$BUILD_DIR"
    
    # Clean any previous failed builds
    info "Cleaning previous build artifacts..."
    rm -rf CMakeCache.txt CMakeFiles cmake_install.cmake
    
    cmake_command=(
        cmake
        -DCMAKE_TOOLCHAIN_FILE="../msvc-toolchain.cmake"
        -DCMAKE_BUILD_TYPE=Release
        -DJUCE_WINDOWS=TRUE
        -DJUCE_DIR="$JUCE_DIR"
        -DCMAKE_VERBOSE_MAKEFILE=ON
        -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY
        ..
    )
    
    info "Running: ${cmake_command[*]}"
    
    if "${cmake_command[@]}"; then
        success "CMake configuration completed successfully."
    else
        error "CMake configuration failed."
        exit 1
    fi
    
    cd "$ROOT_DIR"
}

# Build the plugin
build_plugin() {
    info "Building the Windows plugin with MSVC..."
    
    local num_jobs=$(nproc)
    info "Building with $num_jobs parallel jobs"
    
    cd "$BUILD_DIR"
    
    if cmake --build . --config Release --parallel "$num_jobs"; then
        success "Build completed successfully."
    else
        error "Build failed."
        exit 1
    fi
    
    cd "$ROOT_DIR"
}

# Copy the plugin to a Windows-accessible location (optional)
copy_to_windows() {
    info "Checking if we should copy the plugin to a Windows-accessible location..."
    
    # We're in WSL
    local vst3_path=$(find "$BUILD_DIR" -name "*.vst3" -type d | head -n 1)
    if [ -n "$vst3_path" ]; then
        # Prompt for the copy
        echo ""
        read -p "Do you want to copy the VST3 plugin to your Windows VST3 directory? (y/n) " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            local win_username=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
            local win_vst3_dir="/mnt/c/Program Files/Common Files/VST3"
            
            if [ -d "$win_vst3_dir" ]; then
                info "Copying to $win_vst3_dir..."
                local plugin_name=$(basename "$vst3_path")
                
                # Only copy if we have permission
                if [ -w "$win_vst3_dir" ]; then
                    cp -r "$vst3_path" "$win_vst3_dir"
                    success "Copied plugin to Windows VST3 directory."
                else
                    warning "Cannot write to $win_vst3_dir, permission denied."
                    info "To manually copy:"
                    echo "cp -r \"$vst3_path\" \"$win_vst3_dir\""
                fi
            else
                warning "Windows VST3 directory not found at $win_vst3_dir"
                info "To manually copy once in Windows:"
                echo "1. Locate your plugin at: $(wslpath -w "$vst3_path")"
                echo "2. Copy it to: C:\\Program Files\\Common Files\\VST3"
            fi
        fi
    fi
}

# Display build results
display_results() {
    info "Windows VST3 plugin build completed."
    
    # Find VST3 path
    local vst3_path=$(find "$BUILD_DIR" -name "*.vst3" -type d | head -n 1)
    
    if [ -n "$vst3_path" ]; then
        success "Windows VST3 plugin built successfully at:"
        echo "$vst3_path"
        
        # Windows path in WSL
        echo "Windows path: $(wslpath -w "$vst3_path")"
        
        # Further instructions for use in Windows
        echo ""
        info "To use this plugin in FL Studio on Windows:"
        echo "1. Copy the entire .vst3 folder to your Windows VST3 directory"
        echo "   (typically C:\\Program Files\\Common Files\\VST3)"
        echo "2. Open FL Studio and scan for new plugins"
        echo "3. Look for \"Volume Control Plugin\" in the plugin browser"
    else
        warning "Could not find built VST3 plugin. Check the build output for errors."
    fi
}

# Setting up environment helper
setup_environment_helper() {
    info "The MSVC cross-compilation requires setting up environment variables to locate your Visual Studio installation."
    echo ""
    echo "You need to set the following environment variables:"
    echo ""
    echo "1. MSVC_BASE_PATH - Path to MSVC installation"
    echo "   Example: export MSVC_BASE_PATH=\"/mnt/c/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.30.30705\""
    echo ""
    echo "2. WINDOWS_KITS_BASE_PATH - Path to Windows SDK installation"
    echo "   Example: export WINDOWS_KITS_BASE_PATH=\"/mnt/c/Program Files (x86)/Windows Kits/10\""
    echo ""
    echo "Finding these paths:"
    echo "1. If you have Visual Studio installed on Windows, the MSVC path will be:"
    echo "   C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\VC\\Tools\\MSVC\\<version>"
    echo "   where <version> is something like 14.30.30705"
    echo ""
    echo "2. The Windows Kits path is typically:"
    echo "   C:\\Program Files (x86)\\Windows Kits\\10"
    echo ""
    echo "In WSL, these Windows paths are accessed through /mnt/c/..."
    echo ""
    echo "Once you've identified the correct paths, add these to your ~/.bashrc file:"
    echo "export MSVC_BASE_PATH=\"/mnt/c/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.30.30705\""
    echo "export WINDOWS_KITS_BASE_PATH=\"/mnt/c/Program Files (x86)/Windows Kits/10\""
    echo ""
    
    read -p "Do you want to try setting these variables now? (y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Please enter the path to your MSVC installation in WSL format (/mnt/c/...):"
        read msvc_path
        export MSVC_BASE_PATH="$msvc_path"
        
        echo "Please enter the path to your Windows Kits installation in WSL format (/mnt/c/...):"
        read winkits_path
        export WINDOWS_KITS_BASE_PATH="$winkits_path"
        
        echo "Environment variables set for this session. To make them permanent, add them to your ~/.bashrc file."
        
        # Try again with the new environment variables
        check_prerequisites
    else
        exit 1
    fi
}

# Main build process
main() {
    log_output "${BLUE}=============================================${NC}"
    log_output "${BLUE}  VolumeControlPlugin Windows MSVC Build Script   ${NC}"
    log_output "${BLUE}=============================================${NC}"
    
    # Check prerequisites, and offer to help set up environment if it fails
    if ! check_prerequisites; then
        setup_environment_helper
    fi
    
    create_build_directory
    run_cmake_config
    build_plugin
    display_results
    copy_to_windows
    
    log_output "\n${GREEN}Build process completed.${NC}"
    log_output "\n${BLUE}[INFO]${NC} Complete build log saved to: ${LOG_FILE}"
}

# Redirect all command output to log file as well
exec > >(tee -a "$LOG_FILE") 2>&1

# Run the main function
main

# Final message about log file location
echo ""
echo -e "${BLUE}[INFO]${NC} Full build log available at: ${LOG_FILE}"