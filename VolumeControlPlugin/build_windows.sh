#!/bin/bash
# build_windows.sh - Build script for creating Windows-compatible VST3 plugins using MinGW cross-compiler
# 
# This script builds the VolumeControlPlugin for Windows using MinGW-w64 cross-compilation from WSL or Linux

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
BUILD_DIR="${ROOT_DIR}/build_windows"

# Create log file with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${ROOT_DIR}/build_windows_${TIMESTAMP}.log"

# Initialize log file
touch "$LOG_FILE"
echo "VolumeControlPlugin Windows Build Log (${TIMESTAMP})" > "$LOG_FILE"
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

# Check MinGW prerequisites
check_prerequisites() {
    info "Checking prerequisites for Windows cross-compilation..."
    
    # Check if MinGW compiler is installed
    if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
        error "MinGW-w64 cross-compiler not found. Please install it using:"
        echo "sudo apt-get install mingw-w64"
        exit 1
    fi
    
    # Check MinGW version
    local mingw_version=$(x86_64-w64-mingw32-gcc --version | head -n1)
    info "Using MinGW-w64: $mingw_version"
    
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
    info "Creating Windows build directory..."
    
    if [ ! -d "$BUILD_DIR" ]; then
        mkdir -p "$BUILD_DIR"
        success "Windows build directory created at $BUILD_DIR"
    else
        info "Windows build directory already exists at $BUILD_DIR"
    fi
}

# Run CMake configuration
run_cmake_config() {
    info "Running CMake to configure the Windows project..."
    
    cd "$BUILD_DIR"
    
    cmake_command=(
        cmake
        -DCMAKE_TOOLCHAIN_FILE="../mingw-w64-toolchain.cmake"
        -DCMAKE_BUILD_TYPE=Release
        -DJUCE_WINDOWS=TRUE
        -DJUCE_MINGW=TRUE
        -DJUCE_DIR="$JUCE_DIR"
        -DCMAKE_VERBOSE_MAKEFILE=ON
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
    info "Building the Windows plugin..."
    
    local num_jobs=$(nproc)
    info "Building with $num_jobs parallel jobs"
    
    cd "$BUILD_DIR"
    
    if cmake --build . --config Release --parallel "$num_jobs"; then
        success "Build completed successfully."
    else
        error "Build failed."
        
        # Check for common cross-compilation errors
        if grep -q "shift count >= width of type" "$BUILD_DIR"/CMakeFiles/CMakeError.log 2>/dev/null; then
            warning "Detected Harfbuzz shift-count overflow errors. These warnings were suppressed in the toolchain file but the build still failed."
            warning "This may indicate additional cross-compilation issues."
        fi
        
        if grep -q "undefined reference" "$BUILD_DIR"/CMakeFiles/CMakeError.log 2>/dev/null; then
            warning "Detected undefined reference errors. This usually indicates missing libraries."
            warning "Check the toolchain file and make sure all required Windows libraries are linked."
        fi
        
        exit 1
    fi
    
    cd "$ROOT_DIR"
}

# Copy the plugin to a Windows-accessible location (optional)
copy_to_windows() {
    info "Checking if we should copy the plugin to a Windows-accessible location..."
    
    if [ -n "$WSLENV" ] || grep -q Microsoft /proc/version; then
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
        if [ -n "$WSLENV" ] || grep -q Microsoft /proc/version; then
            echo "Windows path: $(wslpath -w "$vst3_path")"
        fi
        
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

# Main build process
main() {
    log_output "${BLUE}=============================================${NC}"
    log_output "${BLUE}  VolumeControlPlugin Windows Build Script   ${NC}"
    log_output "${BLUE}=============================================${NC}"
    
    check_prerequisites
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