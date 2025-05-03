# MSVC Toolchain file for JUCE projects
# This file enables building Windows VST3 plugins using Microsoft's Visual C++ compiler
# which is officially supported by JUCE (unlike MinGW)

# System information
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Override JUCE architecture detection
# This prevents the need for runtime architecture detection that fails in cross-compilation
set(JUCE_TARGET_ARCHITECTURE "x86_64" CACHE STRING "Target architecture for JUCE" FORCE)
set(VST3_ARCHITECTURE "x86_64" CACHE STRING "VST3 architecture" FORCE)
set(JUCE_WINDOWS TRUE CACHE BOOL "Building for Windows" FORCE)

# Path translation functions for WSL to Windows paths
# Function to convert a WSL path to a Windows path
function(wsl_to_windows_path wsl_path out_var)
    string(REGEX REPLACE "^/mnt/([a-z])" "\\1:" windows_path "${wsl_path}")
    string(REGEX REPLACE "/" "\\\\" windows_path "${windows_path}")
    set(${out_var} "${windows_path}" PARENT_SCOPE)
endfunction()

# Function to convert all WSL paths in a list to Windows paths
function(convert_wsl_paths_to_windows input_var output_var)
    set(windows_paths "")
    foreach(path ${${input_var}})
        if(path MATCHES "^/")
            wsl_to_windows_path("${path}" windows_path)
            list(APPEND windows_paths "${windows_path}")
        else()
            list(APPEND windows_paths "${path}")
        endif()
    endforeach()
    set(${output_var} "${windows_paths}" PARENT_SCOPE)
endfunction()

# Variables to configure MSVC path - adjust these to match your installation
# These are set as environment variables to allow for different paths on different machines
set(MSVC_BASE_PATH "$ENV{MSVC_BASE_PATH}" CACHE PATH "Path to MSVC installation")
set(WINDOWS_KITS_BASE_PATH "$ENV{WINDOWS_KITS_BASE_PATH}" CACHE PATH "Path to Windows SDK installation")

# Convert paths to Windows format
wsl_to_windows_path("${MSVC_BASE_PATH}" MSVC_BASE_PATH_WINDOWS)
wsl_to_windows_path("${WINDOWS_KITS_BASE_PATH}" WINDOWS_KITS_BASE_PATH_WINDOWS)

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

# Configure path conversion for compiler invocation
set(CMAKE_C_COMPILER_WORKS 1)  # Skip compiler test which fails due to path issues
set(CMAKE_CXX_COMPILER_WORKS 1)

# Override compile commands to handle path conversion
set(CMAKE_C_COMPILE_OBJECT "<CMAKE_C_COMPILER> <DEFINES> <INCLUDES> <FLAGS> /Fo<OBJECT> /Fd<TARGET_COMPILE_PDB> /FS -c <SOURCE>")
set(CMAKE_CXX_COMPILE_OBJECT "<CMAKE_CXX_COMPILER> <DEFINES> <INCLUDES> <FLAGS> /Fo<OBJECT> /Fd<TARGET_COMPILE_PDB> /FS -c <SOURCE>")

# Set root paths for find operations
set(CMAKE_FIND_ROOT_PATH 
    "${MSVC_BASE_PATH_WINDOWS}"
    "${WINDOWS_KITS_BASE_PATH_WINDOWS}"
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
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /DWIN32=1 /D_WINDOWS=1 /D_WIN32=1 /D_WIN64=1 /DWIN64=1 /DJUCE_WINDOWS=1 /DJUCE_WASAPI=1 /DJUCE_DIRECTSOUND=1 /EHsc /MP")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /DWIN32=1 /D_WINDOWS=1 /D_WIN32=1 /D_WIN64=1 /DWIN64=1 /DJUCE_WINDOWS=1 /DJUCE_WASAPI=1 /DJUCE_DIRECTSOUND=1 /MP")

# Set the runtime library
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

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

# Disable runtime arch detection which fails during cross-compilation
set(JUCE_DISABLE_RUNTIME_ARCH_DETECTION ON CACHE BOOL "Disable runtime architecture detection" FORCE)

# Enable JUCE support with explicit architecture settings
set(JUCE_WINDOWS ON CACHE BOOL "")

# Workaround for WSL path issues in cross-compilation
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

message(STATUS "MSVC toolchain configured for Windows cross-compilation")
message(STATUS "C compiler: ${CMAKE_C_COMPILER}")
message(STATUS "CXX compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "WSL to Windows path conversion enabled")