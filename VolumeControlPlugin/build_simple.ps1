# Volume Control Plugin - Simple Windows Build Script
# This script builds the VolumeControlPlugin using Visual Studio and CMake
# Run with: PowerShell -ExecutionPolicy Bypass -File build_simple.ps1

# Get build type from command line argument, default to Release
param(
    [string]$BuildType = "Release"
)

# Configuration
$ErrorActionPreference = "Stop"  # Stop on first error
$vsYears = @(2022, 2019, 2017)   # VS versions to check
$buildDir = "build_vs"           # Build directory
$cmakeGenerator = "Visual Studio 17 2022"  # Default generator

# Display header
Write-Host ""
Write-Host "===== VOLUME CONTROL PLUGIN - WINDOWS BUILD SCRIPT =====" -ForegroundColor Cyan
Write-Host "This script will build the VST3 plugin and standalone application"
Write-Host "Current execution policy: $(Get-ExecutionPolicy)"
Write-Host ""

# Check if running from a system directory
$currentPath = Get-Location
$isSystemDir = $currentPath -like "C:\Windows\*" -or $currentPath -like "C:\Program Files\*" -or $currentPath -like "C:\Program Files (x86)\*"

if ($isSystemDir) {
    Write-Host "WARNING: You're running from a system directory: $currentPath" -ForegroundColor Yellow
    Write-Host "This may cause permission issues or other unexpected behavior." -ForegroundColor Yellow
    Write-Host "It's recommended to move your project to a non-system location like:" -ForegroundColor Yellow
    Write-Host "  - C:\Dev\VolumeControlPlugin" -ForegroundColor White
    Write-Host "  - C:\Projects\VolumeControlPlugin" -ForegroundColor White
    Write-Host "  - C:\Users\YourUsername\Projects\VolumeControlPlugin" -ForegroundColor White
    Write-Host ""
    
    # Ask for confirmation before proceeding
    Write-Host "Do you want to continue anyway? (y/n)" -ForegroundColor White
    $confirm = Read-Host
    
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Build aborted. Please move your project to a non-system directory." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Proceeding with build in system directory..." -ForegroundColor Yellow
    Write-Host ""
}

# Check if running from WSL path
$isWslPath = $currentPath -like "\\wsl.localhost\*" -or $currentPath -like "\\wsl$\*"

if ($isWslPath) {
    Write-Host "WSL PATH DETECTED: $currentPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ERROR: Cannot build directly from WSL path." -ForegroundColor Red
    Write-Host "Windows CMD doesn't support UNC paths as current directories." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please use one of these alternatives:" -ForegroundColor Cyan
    Write-Host "1. Clone the repository to a Windows path (recommended):" -ForegroundColor White
    Write-Host "   git clone <your-repo-url> C:\Dev\VolumeControlPlugin" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Use the Linux build instructions with the native Linux scripts:" -ForegroundColor White
    Write-Host "   See README_BUILD.md for Linux build instructions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Copy project files to a Windows path and build from there:" -ForegroundColor White
    Write-Host "   PowerShell: Copy-Item -Path '\\wsl.localhost\Ubuntu\path\to\VolumeControlPlugin' -Destination 'C:\Temp\VolumeControlPlugin' -Recurse" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Function to find Visual Studio installation
function Find-VisualStudio {
    $vsInstallations = @()
    
    # Try to find Visual Studio installations using vswhere if available
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsInstallations = & $vswhere -prerelease -legacy -format json | ConvertFrom-Json
    }
    
    # If vswhere didn't work, try known paths
    if ($vsInstallations.Count -eq 0) {
        foreach ($year in $vsYears) {
            $paths = @(
                "${env:ProgramFiles(x86)}\Microsoft Visual Studio\$year\Enterprise",
                "${env:ProgramFiles(x86)}\Microsoft Visual Studio\$year\Professional",
                "${env:ProgramFiles(x86)}\Microsoft Visual Studio\$year\Community",
                "${env:ProgramFiles}\Microsoft Visual Studio\$year\Enterprise",
                "${env:ProgramFiles}\Microsoft Visual Studio\$year\Professional",
                "${env:ProgramFiles}\Microsoft Visual Studio\$year\Community"
            )
            
            foreach ($path in $paths) {
                if (Test-Path $path) {
                    $vsInstallations += [PSCustomObject]@{
                        installationPath = $path
                        installationVersion = "$year.0.0.0"
                    }
                }
            }
        }
    }
    
    return $vsInstallations
}

# Check prerequisites
Write-Host "===== Checking Prerequisites =====" -ForegroundColor Cyan

# Check for Visual Studio
$vsInstallations = Find-VisualStudio
if ($vsInstallations.Count -eq 0) {
    Write-Host "ERROR: Visual Studio not found. Please install Visual Studio with C++ workload" -ForegroundColor Red
    exit 1
}

# Select the newest Visual Studio version
$vs = $vsInstallations | Sort-Object -Property installationVersion -Descending | Select-Object -First 1
$vsVersion = $vs.installationVersion.Split('.')[0]
Write-Host "Visual Studio $vsVersion found at: $($vs.installationPath)"

# Determine Visual Studio year
if ($vsVersion -eq "2022") {
    $cmakeGenerator = "Visual Studio 17 2022"
    $vsYear = "2022"
} elseif ($vsVersion -eq "2019") {
    $cmakeGenerator = "Visual Studio 16 2019"
    $vsYear = "2019"
} elseif ($vsVersion -eq "2017") {
    $cmakeGenerator = "Visual Studio 15 2017"
    $vsYear = "2017"
} else {
    $cmakeGenerator = "Visual Studio 17 2022" # Default fallback
    $vsYear = "2022"
}

# Find Visual C++ compiler paths
$vcToolsetPath = "$($vs.installationPath)\VC\Tools\MSVC"
$vcToolsVersionPath = if (Test-Path $vcToolsetPath) {
    # Get latest VC tools version
    Get-ChildItem -Path $vcToolsetPath -Directory | Sort-Object -Property Name -Descending | Select-Object -First 1 -ExpandProperty FullName
} else {
    Write-Host "WARNING: MSVC tools path not found. Using fallback method for compiler detection." -ForegroundColor Yellow
    $null
}

# Explicitly set compiler paths if found
$clExePath = if ($vcToolsVersionPath) {
    Join-Path $vcToolsVersionPath "bin\Hostx64\x64\cl.exe"
} else {
    $null
}

# Find vcvarsall.bat
$vcvarsPath = ""
$possiblePaths = @(
    "$($vs.installationPath)\VC\Auxiliary\Build\vcvarsall.bat",
    "$($vs.installationPath)\VC\vcvarsall.bat"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $vcvarsPath = $path
        break
    }
}

if ([string]::IsNullOrEmpty($vcvarsPath)) {
    Write-Host "ERROR: Could not find vcvarsall.bat for Visual Studio" -ForegroundColor Red
    exit 1
}

Write-Host "Found vcvarsall.bat at: $vcvarsPath"
if ($clExePath -and (Test-Path $clExePath)) {
    Write-Host "Found MSVC compiler at: $clExePath"
} else {
    Write-Host "WARNING: Could not find MSVC compiler directly. Using vcvarsall.bat environment instead." -ForegroundColor Yellow
}

# Escape backslashes in paths for CMake
$escapedClPath = $clExePath -replace '\\', '\\\\'
if ([string]::IsNullOrEmpty($escapedClPath)) {
    # Try to run vcvarsall to get compiler path
    $tempBatch = Join-Path $PWD "temp_find_cl.bat"
    @"
@echo off
call "$vcvarsPath" x64
where cl.exe > cl_path.txt
"@ | Out-File -FilePath $tempBatch -Encoding ASCII
    
    # Run the batch file
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempBatch`"" -NoNewWindow -Wait -PassThru
    
    # Get the compiler path
    if (Test-Path "cl_path.txt") {
        $clExePath = Get-Content "cl_path.txt" -First 1
        $escapedClPath = $clExePath -replace '\\', '\\\\'
        Remove-Item "cl_path.txt"
        Write-Host "Found cl.exe through vcvarsall at: $clExePath"
    } else {
        Write-Host "WARNING: Could not locate cl.exe even with vcvarsall. Build may fail." -ForegroundColor Red
    }
    
    # Clean up the temp batch file
    if (Test-Path $tempBatch) {
        Remove-Item $tempBatch
    }
}

# Check for Windows 10 SDK
$windowsSdkPath = ""
$possibleSdkPaths = @(
    "C:\Program Files (x86)\Windows Kits\10",
    "C:\Program Files\Windows Kits\10"
)

foreach ($path in $possibleSdkPaths) {
    if (Test-Path $path) {
        $windowsSdkPath = $path
        break
    }
}

if (![string]::IsNullOrEmpty($windowsSdkPath)) {
    $sdkIncludePath = Join-Path $windowsSdkPath "Include"
    if (Test-Path $sdkIncludePath) {
        $sdkVersions = Get-ChildItem -Path $sdkIncludePath -Directory | Sort-Object -Property Name -Descending
        if ($sdkVersions.Count -gt 0) {
            $latestSdkVersion = $sdkVersions[0].Name
            Write-Host "Found Windows 10 SDK version $latestSdkVersion"
        } else {
            Write-Host "WARNING: Windows 10 SDK found but no versions detected" -ForegroundColor Yellow
        }
    } else {
        Write-Host "WARNING: Windows 10 SDK found but missing Include directory" -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING: Windows 10 SDK not found. This may cause compiler detection issues." -ForegroundColor Yellow
}

# Check for CMake
try {
    $cmakeVersion = (cmake --version | Select-Object -First 1).TrimStart("cmake version ")
    Write-Host "CMake found: $cmakeVersion"
} catch {
    Write-Host "ERROR: CMake not found. Please install CMake and add it to your PATH" -ForegroundColor Red
    exit 1
}

# Check for JUCE
$juceDir = "..\JUCE"
if (!(Test-Path $juceDir)) {
    Write-Host "ERROR: JUCE not found at $juceDir" -ForegroundColor Red
    exit 1
}
Write-Host "JUCE found at $juceDir"
Write-Host ""

# Create build directory
Write-Host "===== Creating Build Directory =====" -ForegroundColor Cyan
if (!(Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
    Write-Host "Build directory created"
} else {
    Write-Host "Build directory already exists"
}
Write-Host ""

# Write a CMake toolchain file to help with compiler detection
$toolchainFilePath = Join-Path $PWD "vs_toolchain.cmake"

if ([string]::IsNullOrEmpty($escapedClPath)) {
    # Fallback toolchain file with basic settings
@"
# VS Toolchain File (Fallback)
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Force Visual Studio generator to use native environment
set(CMAKE_GENERATOR_TOOLSET "host=x64" CACHE STRING "")
set(CMAKE_GENERATOR_PLATFORM "x64" CACHE STRING "")
"@ | Out-File -FilePath $toolchainFilePath -Encoding ASCII
} else {
    # Full toolchain file with explicit compiler paths
@"
# VS Toolchain File
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Set compiler paths with full paths
set(CMAKE_C_COMPILER "$escapedClPath" CACHE FILEPATH "C compiler")
set(CMAKE_CXX_COMPILER "$escapedClPath" CACHE FILEPATH "C++ compiler")

# Force Visual Studio generator to use native environment
set(CMAKE_GENERATOR_TOOLSET "host=x64" CACHE STRING "")
set(CMAKE_GENERATOR_PLATFORM "x64" CACHE STRING "")
"@ | Out-File -FilePath $toolchainFilePath -Encoding ASCII
}

# Configure with CMake
Write-Host "===== Configuring with CMake =====" -ForegroundColor Cyan

# Properly quote the vcvarsall.bat path to handle spaces
$quotedVcvarsPath = "`"$vcvarsPath`""
Write-Host "Running: cmd.exe with Visual Studio environment and cmake"

try {
    # Create a more comprehensive batch file with environment setup and CMake configuration
    $batchFile = Join-Path $PWD "cmake_config.bat"
    
    # Create a more robust batch file that preserves environment variables
@"
@echo off
echo Setting up Visual Studio environment...
call $quotedVcvarsPath x64
echo Environment setup complete.

echo Verifying compiler detection...
where cl.exe
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: cl.exe not found in PATH!
    exit /b 1
) else (
    echo C/C++ compiler found.
)

echo Current directory: %CD%
if not exist $buildDir mkdir $buildDir
cd $buildDir
echo Changed to build directory: %CD%

echo Running CMake configuration...
rem Set environment variables that help cmake find the compiler
set CC=cl.exe
set CXX=cl.exe

rem Run CMake with explicit compiler specification
cmake -G "$cmakeGenerator" -A x64 -DCMAKE_TOOLCHAIN_FILE=../vs_toolchain.cmake ..

echo CMake configuration completed with exit code: %ERRORLEVEL%
exit /b %ERRORLEVEL%
"@ | Out-File -FilePath $batchFile -Encoding ASCII
    
    # Run the batch file with full verbosity
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batchFile`"" -NoNewWindow -Wait -PassThru
    
    # Clean up the batch file
    if (Test-Path $batchFile) {
        Remove-Item $batchFile
    }
    
    if ($process.ExitCode -ne 0) {
        Write-Host "CMake configuration failed with exit code $($process.ExitCode)" -ForegroundColor Red
        
        # Check for common issues
        Write-Host ""
        Write-Host "Troubleshooting compiler detection:" -ForegroundColor Yellow
        Write-Host "1. Make sure Visual Studio is installed with 'Desktop development with C++' workload" -ForegroundColor White
        Write-Host "2. Try installing/reinstalling the latest Windows 10 SDK from Visual Studio Installer" -ForegroundColor White
        Write-Host "3. Make sure no antivirus is blocking cl.exe" -ForegroundColor White
        Write-Host ""
        
        Write-Host "Trying direct CMake execution as a last resort..." -ForegroundColor Yellow
        
        # Create a very simple direct CMake command batch file
        $directBatchFile = Join-Path $PWD "direct_cmake.bat"
        
@"
@echo off
call $quotedVcvarsPath x64

cd $buildDir

rem Run CMake directly without toolchain file
cmake -G "$cmakeGenerator" -A x64 ..
"@ | Out-File -FilePath $directBatchFile -Encoding ASCII
        
        # Run the direct batch file
        $directProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$directBatchFile`"" -NoNewWindow -Wait -PassThru
        
        # Clean up the direct batch file
        if (Test-Path $directBatchFile) {
            Remove-Item $directBatchFile
        }
        
        if ($directProcess.ExitCode -ne 0) {
            Write-Host "ERROR: All CMake configuration attempts failed." -ForegroundColor Red
            exit 1
        } else {
            Write-Host "Direct CMake configuration successful!" -ForegroundColor Green
        }
    } else {
        Write-Host "CMake configuration completed successfully" -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR: Failed to configure project with CMake: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Clean up toolchain file
if (Test-Path $toolchainFilePath) {
    Remove-Item $toolchainFilePath
}

# Build the project
Write-Host "===== Building Project ($BuildType Configuration) =====" -ForegroundColor Cyan
try {
    # Create a batch file for building to avoid command line issues
    $batchFile = Join-Path $PWD "cmake_build.bat"
    
@"
@echo off
call $quotedVcvarsPath x64
cd $buildDir
cmake --build . --config $BuildType
exit /b %ERRORLEVEL%
"@ | Out-File -FilePath $batchFile -Encoding ASCII
    
    # Run the batch file
    Write-Host "Running: cmake --build . --config $BuildType"
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batchFile`"" -NoNewWindow -Wait -PassThru
    
    # Clean up the batch file
    if (Test-Path $batchFile) {
        Remove-Item $batchFile
    }
    
    if ($process.ExitCode -ne 0) {
        Write-Host "ERROR: Build failed with exit code $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR: Failed to build project: $_" -ForegroundColor Red
    exit 1
}
Write-Host "Build completed successfully" -ForegroundColor Green
Write-Host ""

# Show build results
$vst3Path = "$buildDir\VolumeControlPlugin_artefacts\$BuildType\VST3"
$standalonePath = "$buildDir\VolumeControlPlugin_artefacts\$BuildType\Standalone"

Write-Host "===== Build Complete! =====" -ForegroundColor Cyan
Write-Host "Binaries are located at:"
Write-Host "   VST3 Plugin: $vst3Path" -ForegroundColor Gray
Write-Host "   Standalone: $standalonePath" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Copy the VST3 plugin to your VST3 plugins directory" -ForegroundColor Yellow
Write-Host "2. Run your DAW or host to use the plugin" -ForegroundColor Yellow
Write-Host ""
Write-Host "===== Thank you for using VolumeControlPlugin =====" -ForegroundColor Cyan