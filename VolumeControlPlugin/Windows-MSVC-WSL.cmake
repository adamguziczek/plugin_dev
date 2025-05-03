# Windows-MSVC-WSL.cmake
# Specialized CMake configuration for cross-compiling with Microsoft Visual C++ from WSL
#
# This file sets up MSVC compiler and linker with proper path translations for 
# cross-compilation from WSL to Windows. 

# Set system name to Windows for cross-compilation
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_VERSION 10.0)
set(CMAKE_SYSTEM_PROCESSOR "x86_64")

# Explicitly disable pkg-config for Windows builds
set(PKG_CONFIG_EXECUTABLE "")

# Force static linking for Windows
set(BUILD_SHARED_LIBS OFF)

# Set architecture explicitly (critical for VST3 support)
set(JUCE_TARGET_ARCHITECTURE "x86_64" CACHE STRING "Target architecture for JUCE" FORCE)
set(VST3_ARCHITECTURE "x86_64" CACHE STRING "VST3 architecture" FORCE)

# Disable JUCE's runtime architecture detection which fails in cross-compilation
set(JUCE_DISABLE_RUNTIME_ARCH_DETECTION ON CACHE BOOL "Disable runtime architecture detection" FORCE)

# Configure Windows-specific JUCE settings
set(JUCE_WINDOWS ON CACHE BOOL "Building for Windows" FORCE)
set(JUCE_WASAPI 1 CACHE BOOL "Enable WASAPI" FORCE)
set(JUCE_DIRECTSOUND 1 CACHE BOOL "Enable DirectSound" FORCE)
set(JUCE_ENABLE_WIN_MEDIA_FORMAT 1 CACHE BOOL "Enable Windows Media Format" FORCE)

# Disable GTK for Windows builds
set(JUCE_ENABLE_X11 OFF CACHE BOOL "Disable X11" FORCE)

# Force static builds to avoid DLL issues
set(JUCE_BUILD_SHARED_LIBS OFF CACHE BOOL "Build static libs" FORCE)

# Path translation functions for converting between WSL and Windows paths
function(wsl_to_windows_path wsl_path out_var)
    string(REGEX REPLACE "^/mnt/([a-z])" "\\1:" windows_path "${wsl_path}")
    string(REGEX REPLACE "/" "\\\\" windows_path "${windows_path}")
    set(${out_var} "${windows_path}" PARENT_SCOPE)
endfunction()

# Setup MSVC paths based on environment variables
set(MSVC_BASE_PATH "$ENV{MSVC_BASE_PATH}" CACHE PATH "Path to MSVC installation")
set(WINDOWS_KITS_BASE_PATH "$ENV{WINDOWS_KITS_BASE_PATH}" CACHE PATH "Path to Windows SDK installation")

# Verify environment is set up properly
if(NOT MSVC_BASE_PATH)
    message(FATAL_ERROR 
        "MSVC_BASE_PATH environment variable not set.\n"
        "Run: export MSVC_BASE_PATH=\"/mnt/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/MSVC/YOUR_VERSION\"")
endif()

if(NOT WINDOWS_KITS_BASE_PATH)
    message(FATAL_ERROR 
        "WINDOWS_KITS_BASE_PATH environment variable not set.\n"
        "Run: export WINDOWS_KITS_BASE_PATH=\"/mnt/c/Program Files (x86)/Windows Kits/10\"")
endif()

# Set the Windows SDK version - this should match your installed Windows SDK
set(WINDOWS_SDK_VERSION "10.0.19041.0" CACHE STRING "Windows SDK version")

# Convert paths to Windows format for includes and libraries
wsl_to_windows_path("${MSVC_BASE_PATH}" MSVC_BASE_PATH_WINDOWS)
wsl_to_windows_path("${WINDOWS_KITS_BASE_PATH}" WINDOWS_KITS_BASE_PATH_WINDOWS)

# Set toolchain executables
set(CMAKE_C_COMPILER "${MSVC_BASE_PATH}/bin/Hostx64/x64/cl.exe")
set(CMAKE_CXX_COMPILER "${MSVC_BASE_PATH}/bin/Hostx64/x64/cl.exe")
set(CMAKE_RC_COMPILER "${WINDOWS_KITS_BASE_PATH}/bin/${WINDOWS_SDK_VERSION}/x64/rc.exe")
set(CMAKE_MT_COMPILER "${WINDOWS_KITS_BASE_PATH}/bin/${WINDOWS_SDK_VERSION}/x64/mt.exe")
set(CMAKE_LINKER "${MSVC_BASE_PATH}/bin/Hostx64/x64/link.exe")
set(CMAKE_LIB "${MSVC_BASE_PATH}/bin/Hostx64/x64/lib.exe")

# Skip compiler tests that will fail in cross-compilation
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Set the runtime library type for Windows
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

# Set file extensions for Windows
set(CMAKE_EXECUTABLE_SUFFIX ".exe")
set(CMAKE_SHARED_LIBRARY_PREFIX "")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dll")
set(CMAKE_STATIC_LIBRARY_PREFIX "")
set(CMAKE_STATIC_LIBRARY_SUFFIX ".lib")
set(CMAKE_IMPORT_LIBRARY_PREFIX "")
set(CMAKE_IMPORT_LIBRARY_SUFFIX ".lib")

# Setup include paths for Windows SDK and MSVC
include_directories(
    "${MSVC_BASE_PATH}/include"
    "${WINDOWS_KITS_BASE_PATH}/Include/${WINDOWS_SDK_VERSION}/ucrt"
    "${WINDOWS_KITS_BASE_PATH}/Include/${WINDOWS_SDK_VERSION}/um"
    "${WINDOWS_KITS_BASE_PATH}/Include/${WINDOWS_SDK_VERSION}/shared"
    "${WINDOWS_KITS_BASE_PATH}/Include/${WINDOWS_SDK_VERSION}/winrt"
    "${WINDOWS_KITS_BASE_PATH}/Include/${WINDOWS_SDK_VERSION}/cppwinrt"
)

# Setup library paths
link_directories(
    "${MSVC_BASE_PATH}/lib/x64"
    "${WINDOWS_KITS_BASE_PATH}/Lib/${WINDOWS_SDK_VERSION}/ucrt/x64"
    "${WINDOWS_KITS_BASE_PATH}/Lib/${WINDOWS_SDK_VERSION}/um/x64"
)

# Windows-specific compiler flags
set(MSVC_FLAGS
    /DWIN32=1
    /D_WINDOWS=1
    /D_WIN32=1
    /D_WIN64=1
    /DWIN64=1
    /DJUCE_WINDOWS=1
    /DJUCE_WASAPI=1
    /DJUCE_DIRECTSOUND=1
    /nologo
    /EHsc
    /MP
    /W4
    /wd4996    # Disable deprecation warnings
    /wd4267    # Disable conversion warnings
    /bigobj    # Support large object files
)

# Add Windows-specific flags to compiler
set(CMAKE_CXX_FLAGS "${MSVC_FLAGS}")
set(CMAKE_C_FLAGS "${MSVC_FLAGS}")

# Release build flags
set(CMAKE_CXX_FLAGS_RELEASE "/O2 /Ob2 /DNDEBUG /GL")
set(CMAKE_C_FLAGS_RELEASE "/O2 /Ob2 /DNDEBUG /GL")

# Debug build flags
set(CMAKE_CXX_FLAGS_DEBUG "/Zi /Ob0 /Od /RTC1 /D_DEBUG")
set(CMAKE_C_FLAGS_DEBUG "/Zi /Ob0 /Od /RTC1 /D_DEBUG")

# Disable Linux flags for Windows builds
set(CMAKE_SHARED_LIBRARY_RUNTIME_C_FLAG "")
set(CMAKE_SHARED_LIBRARY_RUNTIME_C_FLAG_SEP "")
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")

# JUCE-specific settings
set(JUCE_CURL_ENABLED OFF CACHE BOOL "Disable CURL" FORCE)
set(JUCE_WEB_BROWSER OFF CACHE BOOL "Disable web browser" FORCE)

message(STATUS "MSVC Cross-Compilation Environment configured for WSL->Windows:")
message(STATUS "  - Architecture: x86_64")
message(STATUS "  - C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "  - Windows SDK: ${WINDOWS_SDK_VERSION}")
message(STATUS "  - VST3 Architecture: ${VST3_ARCHITECTURE}")