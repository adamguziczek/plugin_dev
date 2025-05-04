# Volume Control Plugin - Simple Windows Build Script
# This script builds the VolumeControlPlugin using Visual Studio and CMake
# Run with: PowerShell -ExecutionPolicy Bypass -File build_simple.ps1

# Set default configuration
$BuildType = "Release"
# Accept Debug as parameter if provided
if ($args[0] -eq "Debug") {
    $BuildType = "Debug"
}

# Display header
Write-Host ""
Write-Host "===== VOLUME CONTROL PLUGIN - WINDOWS BUILD SCRIPT =====" -ForegroundColor Cyan
Write-Host "This script will build the VST3 plugin and standalone application"
Write-Host "Current execution policy: $(Get-ExecutionPolicy)"
Write-Host ""

# Display step header
function Show-Step {
    param([string]$message)
    Write-Host ""
    Write-Host "===== $message =====" -ForegroundColor Cyan
}

# Check for prerequisites
Show-Step "Checking Prerequisites"

# Check for Visual Studio
$vsFound = $false
$vsVersion = ""
$cmakeGenerator = ""

# Try to find Visual Studio 2022
$vs2022Path = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe"
if (Test-Path $vs2022Path) {
    Write-Host "Visual Studio 2022 found" -ForegroundColor Green
    $vsFound = $true
    $vsVersion = "2022"
    $cmakeGenerator = "Visual Studio 17 2022"
} else {
    Write-Host "Visual Studio 2022 not found" -ForegroundColor Yellow
    
    # Try to find Visual Studio 2019
    $vs2019Path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe"
    if (Test-Path $vs2019Path) {
        Write-Host "Visual Studio 2019 found" -ForegroundColor Green
        $vsFound = $true
        $vsVersion = "2019"
        $cmakeGenerator = "Visual Studio 16 2019"
    } else {
        Write-Host "Visual Studio 2019 not found" -ForegroundColor Yellow
    }
}

if (-not $vsFound) {
    Write-Host "ERROR: No compatible Visual Studio installation found." -ForegroundColor Red
    Write-Host "Please install Visual Studio 2019 or 2022 with C++ development workload." -ForegroundColor Red
    exit 1
}

# Check for CMake
$cmakeVersion = (cmake --version | Select-Object -First 1).ToString()
if ($cmakeVersion -match "cmake version") {
    Write-Host "CMake found: $cmakeVersion" -ForegroundColor Green
} else {
    Write-Host "ERROR: CMake not found. Please install CMake." -ForegroundColor Red
    exit 1
}

# Check for JUCE
$juceDir = Join-Path (Get-Item .).Parent.FullName "JUCE"
if (Test-Path $juceDir) {
    Write-Host "JUCE found at $juceDir" -ForegroundColor Green
} else {
    Write-Host "ERROR: JUCE not found at $juceDir" -ForegroundColor Red
    exit 1
}

# Create build directory
Show-Step "Creating Build Directory"
$buildDir = "build_vs"
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
    Write-Host "Build directory created" -ForegroundColor Green
} else {
    Write-Host "Build directory already exists" -ForegroundColor Green
}

# Navigate to build directory
Push-Location $buildDir

# Configure with CMake
Show-Step "Configuring with CMake"
Write-Host "Running: cmake with $cmakeGenerator generator" -ForegroundColor Yellow

# Create the command as an array
$configureArgs = @(
    "-G", "$cmakeGenerator",
    "-A", "x64",
    ".."
)

# Execute the configuration
Write-Host "Running: cmake $configureArgs" -ForegroundColor DarkGray
$configureProcess = Start-Process cmake -ArgumentList $configureArgs -NoNewWindow -PassThru -Wait
if ($configureProcess.ExitCode -ne 0) {
    Write-Host "ERROR: CMake configuration failed with exit code $($configureProcess.ExitCode)" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Build the project
Show-Step "Building Project ($BuildType)"

# Build the project
$buildArgs = @(
    "--build", ".",
    "--config", "$BuildType"
)
Write-Host "Running: cmake $buildArgs" -ForegroundColor DarkGray
$buildProcess = Start-Process cmake -ArgumentList $buildArgs -NoNewWindow -PassThru -Wait
if ($buildProcess.ExitCode -ne 0) {
    Write-Host "ERROR: Build failed with exit code $($buildProcess.ExitCode)" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Return to the original directory
Pop-Location

# Show success message
Show-Step "Build Complete!"
Write-Host "The Volume Control Plugin has been successfully built in $BuildType configuration." -ForegroundColor Green
Write-Host ""

# Display plugin locations
Write-Host "Plugin locations:" -ForegroundColor Cyan

# VST3 path
$vst3Path = Join-Path $buildDir "VolumeControlPlugin_artefacts\$BuildType\VST3\VolumeControlPlugin.vst3"
if (Test-Path $vst3Path) {
    Write-Host "VST3 Plugin: " -NoNewline
    Write-Host "$vst3Path" -ForegroundColor Gray
} else {
    Write-Host "VST3 Plugin: Not found at expected location" -ForegroundColor Red
}

# Standalone path
$standalonePath = Join-Path $buildDir "VolumeControlPlugin_artefacts\$BuildType\Standalone\VolumeControlPlugin.exe"
if (Test-Path $standalonePath) {
    Write-Host "Standalone App: " -NoNewline
    Write-Host "$standalonePath" -ForegroundColor Gray
} else {
    Write-Host "Standalone App: Not found at expected location" -ForegroundColor Red
}

# Final instructions
Write-Host ""
Write-Host "To use the VST3 plugin:" -ForegroundColor Cyan
Write-Host "1. Copy the VST3 file to your VST3 plugins directory" -ForegroundColor White
Write-Host "   (Usually C:\Program Files\Common Files\VST3)" -ForegroundColor Gray
Write-Host "2. Restart your DAW to detect the new plugin" -ForegroundColor White
Write-Host ""
Write-Host "To run the standalone application:" -ForegroundColor Cyan
Write-Host "Simply double-click the executable file" -ForegroundColor White