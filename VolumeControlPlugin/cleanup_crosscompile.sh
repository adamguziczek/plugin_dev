#!/bin/bash
# cleanup_crosscompile.sh - Remove unnecessary cross-compilation files
# 
# This script removes files that were used for attempted cross-compilation.
# These approaches have been replaced by the VSCode Remote Development workflow.

echo "Cleaning up cross-compilation files..."

# List of files to remove
FILES_TO_REMOVE=(
    "mingw-w64-toolchain.cmake"
    "msvc-toolchain.cmake"
    "Windows-MSVC-WSL.cmake"
    "build_windows.sh"
    "build_windows_msvc.sh"
    "build_windows_alt.sh"
    "clean_and_rebuild.sh"
)

# List of directories to remove
DIRS_TO_REMOVE=(
    "build_windows"
    "build_windows_msvc"
    "build_windows_alt"
)

# Remove files
for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$file" ]; then
        echo "Removing file: $file"
        rm "$file"
    else
        echo "File not found, skipping: $file"
    fi
done

# Remove directories
for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [ -d "$dir" ]; then
        echo "Removing directory: $dir"
        rm -rf "$dir"
    else
        echo "Directory not found, skipping: $dir"
    fi
done

echo "Clean-up complete. The project has been simplified for VSCode Remote Development."
echo "See VSCode_README.md for instructions on how to build using Visual Studio."