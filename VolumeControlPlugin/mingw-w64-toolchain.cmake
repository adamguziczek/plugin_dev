# DEPRECATED: MinGW-w64 Toolchain

message(FATAL_ERROR 
"MinGW-w64 is not supported for JUCE projects and has been deprecated in this project.

JUCE does not officially support MinGW and this approach will not work reliably.
Please use one of the following recommended approaches instead:

1. MSVC Cross-Compilation from WSL
   Use the msvc-toolchain.cmake and build_windows_msvc.sh script

2. Native Windows Build with Visual Studio
   Build directly on Windows using Visual Studio and CMake

For detailed instructions, see:
WINDOWS_BUILD_OPTIONS.md")