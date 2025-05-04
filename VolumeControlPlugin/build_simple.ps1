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
$cmakeGenerator = "Visual Studio 16 2019"  # Default generator

# Display header
Write-Host ""
Write-Host "===== VOLUME CONTROL PLUGIN - WINDOWS BUILD SCRIPT =====" -ForegroundColor Cyan
Write-Host "This script will build the VST3 plugin and standalone application"
Write-Host "Current execution policy: $(Get-ExecutionPolicy)"
Write-Host ""

# Check if running from WSL path
$currentPath = Get-Location
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

# Set appropriate generator based on VS version
if ($vsVersion -eq "2022") {
    $cmakeGenerator = "Visual Studio 17 2022"
} elseif ($vsVersion -eq "2019") {
    $cmakeGenerator = "Visual Studio 16 2019"
} elseif ($vsVersion -eq "2017") {
    $cmakeGenerator = "Visual Studio 15 2017" 
} else {
    $cmakeGenerator = "Visual Studio 16 2019" # Default fallback
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

# Configure with CMake
Write-Host "===== Configuring with CMake =====" -ForegroundColor Cyan
$vcvarsArgs = "x64"
Write-Host "Running: cmd.exe /c `"$vcvarsPath`" $vcvarsArgs `&`& cmake with Visual Studio generator"

try {
    # Run CMake inside a cmd.exe process with Visual Studio environment set up
    $cmakeConfigureCmd = "cmake -G `"$cmakeGenerator`" -A x64 .."
    $cmdArgs = "/c `"$vcvarsPath`" $vcvarsArgs & cd $buildDir & $cmakeConfigureCmd"
    
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput "cmake_configure_output.log" -RedirectStandardError "cmake_configure_error.log"
    
    if ($process.ExitCode -ne 0) {
        $errorOutput = Get-Content "cmake_configure_error.log" -ErrorAction SilentlyContinue
        $output = Get-Content "cmake_configure_output.log" -ErrorAction SilentlyContinue
        
        Write-Host "CMake configuration output:" -ForegroundColor Yellow
        if ($output) { $output | ForEach-Object { Write-Host $_ } }
        
        Write-Host "CMake configuration error:" -ForegroundColor Red
        if ($errorOutput) { $errorOutput | ForEach-Object { Write-Host $_ } }
        
        Write-Host "ERROR: CMake configuration failed with exit code $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
    
    # Display the output for debugging
    $output = Get-Content "cmake_configure_output.log" -ErrorAction SilentlyContinue
    $output | ForEach-Object { Write-Host $_ }
    
} catch {
    Write-Host "ERROR: Failed to configure project with CMake: $_" -ForegroundColor Red
    exit 1
}
Write-Host "CMake configuration completed successfully" -ForegroundColor Green
Write-Host ""

# Build the project
Write-Host "===== Building Project ($BuildType Configuration) =====" -ForegroundColor Cyan
try {
    # Run build inside a cmd.exe process with Visual Studio environment set up
    $cmakeBuildCmd = "cmake --build . --config $BuildType"
    $cmdArgs = "/c `"$vcvarsPath`" $vcvarsArgs & cd $buildDir & $cmakeBuildCmd"
    
    Write-Host "Running: $cmakeBuildCmd"
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -NoNewWindow -Wait -PassThru
    
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