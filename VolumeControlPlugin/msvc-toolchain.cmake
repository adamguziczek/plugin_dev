# MSVC Toolchain file for JUCE projects
# This file enables building Windows VST3 plugins using Microsoft's Visual C++ compiler
# which is officially supported by JUCE (unlike MinGW)

# System information
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Variables to configure MSVC path - adjust these to match your installation
# These are set as environment variables to allow for different paths on different machines
set(MSVC_BASE_PATH "$ENV{MSVC_BASE_PATH}" CACHE PATH "Path to MSVC installation")
set(WINDOWS_KITS_BASE_PATH "$ENV{WINDOWS_KITS_BASE_PATH}" CACHE PATH "Path to Windows SDK installation")

# Verify paths are set
if(NOT MSVC_BASE_PATH)
    message(FATAL_ERROR "MSVC_BASE_PATH environment variable not set. Please set it to the base path of your MSVC installation.")
endif()

if(NOT WINDOWS_KITS_BASE_PATH)
    message(FATAL_ERROR "WINDOWS_KITS_BASE_PATH environment variable not set. Please set it to the base path of your Windows SDK installation.")
endif()

# Set the required compilers - using the Microsoft C/C++ compiler
set(CMAKE_C_COMPILER "${MSVC_BASE_PATH}/bin/Hostx64/x64/cl.exe")
set(CMAKE_CXX_COMPILER "${MSVC_BASE_PATH}/bin/Hostx64/x64/cl.exe")
set(CMAKE_RC_COMPILER "${WINDOWS_KITS_BASE_PATH}/bin/10.0.19041.0/x64/rc.exe")
set(CMAKE_MC_COMPILER "${WINDOWS_KITS_BASE_PATH}/bin/10.0.19041.0/x64/mc.exe")
set(CMAKE_MT_COMPILER "${WINDOWS_KITS_BASE_PATH}/bin/10.0.19041.0/x64/mt.exe")
set(CMAKE_LIB_COMPILER "${MSVC_BASE_PATH}/bin/Hostx64/x64/lib.exe")
set(CMAKE_LINKER "${MSVC_BASE_PATH}/bin/Hostx64/x64/link.exe")

# Set root paths for find operations
set(CMAKE_FIND_ROOT_PATH 
    "${MSVC_BASE_PATH}"
    "${WINDOWS_KITS_BASE_PATH}"
)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Ensure DLLs are created with proper extension
set(CMAKE_EXECUTABLE_SUFFIX ".exe")
set(CMAKE_SHARED_LIBRARY_PREFIX "")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dll")
set(CMAKE_STATIC_LIBRARY_PREFIX "")
set(CMAKE_STATIC_LIBRARY_SUFFIX ".lib")
set(CMAKE_IMPORT_LIBRARY_PREFIX "")
set(CMAKE_IMPORT_LIBRARY_SUFFIX ".lib")

# Compiler flags for MSVC
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /DWIN32=1 /D_WINDOWS=1 /D_WIN32=1 /D_WIN64=1 /DWIN64=1 /DJUCE_WINDOWS=1 /DJUCE_WASAPI=1 /DJUCE_DIRECTSOUND=1")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /DWIN32=1 /D_WINDOWS=1 /D_WIN32=1 /D_WIN64=1 /DWIN64=1 /DJUCE_WINDOWS=1 /DJUCE_WASAPI=1 /DJUCE_DIRECTSOUND=1")

# Optimization level for Release builds
set(CMAKE_CXX_FLAGS_RELEASE "/O2 /Ob2 /DNDEBUG")
set(CMAKE_C_FLAGS_RELEASE "/O2 /Ob2 /DNDEBUG")

# Debug build flags
set(CMAKE_CXX_FLAGS_DEBUG "/Zi /Ob0 /Od /RTC1 /D_DEBUG")
set(CMAKE_C_FLAGS_DEBUG "/Zi /Ob0 /Od /RTC1 /D_DEBUG")

# Include paths
include_directories(
    "${MSVC_BASE_PATH}/include"
    "${WINDOWS_KITS_BASE_PATH}/Include/10.0.19041.0/ucrt"
    "${WINDOWS_KITS_BASE_PATH}/Include/10.0.19041.0/um"
    "${WINDOWS_KITS_BASE_PATH}/Include/10.0.19041.0/shared"
    "${WINDOWS_KITS_BASE_PATH}/Include/10.0.19041.0/winrt"
    "${WINDOWS_KITS_BASE_PATH}/Include/10.0.19041.0/cppwinrt"
)

# Library paths
link_directories(
    "${MSVC_BASE_PATH}/lib/x64"
    "${WINDOWS_KITS_BASE_PATH}/Lib/10.0.19041.0/ucrt/x64"
    "${WINDOWS_KITS_BASE_PATH}/Lib/10.0.19041.0/um/x64"
)

# Define build type as Release by default
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# Disable features that might not work well in cross-compilation
set(JUCE_BUILD_MISC_UTILITIES OFF CACHE BOOL "")

# Enable JUCE support
set(JUCE_WINDOWS ON CACHE BOOL "")

message(STATUS "MSVC toolchain configured for Windows cross-compilation")
message(STATUS "C compiler: ${CMAKE_C_COMPILER}")
message(STATUS "CXX compiler: ${CMAKE_CXX_COMPILER}")