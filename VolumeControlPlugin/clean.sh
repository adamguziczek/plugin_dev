#!/bin/bash
# clean.sh - Clean script for VolumeControlPlugin
# 
# This script cleans the build directory, removing all generated files.
# Use this script when you want to do a fresh build or when troubleshooting
# build issues.

# Set up colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print a message with a colored prefix
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Clean the build directory
clean_build_dir() {
    info "Cleaning build directory..."
    
    if [ ! -d "build" ]; then
        warning "Build directory does not exist. Nothing to clean."
        return 0
    fi
    
    # Ask for confirmation before removing the build directory
    read -p "Are you sure you want to remove the build directory? (y/n) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Clean operation cancelled."
        return 0
    fi
    
    # Remove the build directory
    if rm -rf build; then
        success "Build directory removed successfully."
    else
        error "Failed to remove build directory."
        exit 1
    fi
}

# Main function
main() {
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}  VolumeControlPlugin Clean Script    ${NC}"
    echo -e "${BLUE}=======================================${NC}"
    
    clean_build_dir
    
    echo -e "\n${GREEN}Clean process completed!${NC}"
    echo -e "You can now run ./build.sh to do a fresh build."
}

# Run the main function
main