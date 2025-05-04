# Volume Control Plugin - Simple Windows Build Script
# This script builds the VolumeControlPlugin using Visual Studio and CMake
# Run with: PowerShell -ExecutionPolicy Bypass -File build_simple.ps1

# Configuration
$BuildType = 'Release'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BuildDir = Join-Path $ScriptDir 'build_vs'
$JuceDir = Join-Path (Split-Path -Parent $ScriptDir) 'JUCE'

# Print header
Write-Host ""
Write-Host "===== VOLUME CONTROL PLUGIN - WINDOWS BUILD SCRIPT =====" -ForegroundColor Cyan
Write-Host "This script will build the VST3 plugin and standalone application" -ForegroundColor White

# Check for PowerShell execution policy
try {
    $policy = Get-ExecutionPolicy -Scope Process
    Write-Host "Current execution policy: $policy" -ForegroundColor Gray
    if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
        Write-Host "WARNING: PowerShell execution policy may prevent this script from running" -ForegroundColor Yellow
        Write-Host "If you get an execution policy error, run this command first:" -ForegroundColor Yellow
        Write-Host "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process" -ForegroundColor Gray
    }
} catch {
    # Skip execution policy check if it fails for some reason
}

# Step 1: Check prerequisites
Write-Host ""
Write-Host "===== Checking Prerequisites =====" -ForegroundColor Cyan

# Check Visual Studio 
$vsFound = $false
$vsVersion = ''
$vsGenerator = ''
# Try Visual Studio 2022
if (Test-Path 'C:\Program Files\Microsoft Visual Studio\2022') {
    $vsFound = $true
    $vsVersion = '2022'
    $vsGenerator = 'Visual Studio 17 2022'
    Write-Host "Visual Studio 2022 found" -ForegroundColor Green
}
# Try Visual Studio 2019 if 2022 wasn't found
elseif (Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2019') {
    $vsFound = $true
    $vsVersion = '2019'
    $vsGenerator = 'Visual Studio 16 2019'
    Write-Host "Visual Studio 2019 found" -ForegroundColor Green
}
else {
    Write-Host "ERROR: Visual Studio 2019 or 2022 not found" -ForegroundColor Red
    Write-Host "Please install Visual Studio 2019 or 2022 with 'Desktop development with C++' workload" -ForegroundColor White
    Write-Host "Download from: https://visualstudio.microsoft.com/downloads/" -ForegroundColor White
    exit 1
}

# Check CMake
try {
    $cmakeVersion = (cmake --version) | Select-Object -First 1
    Write-Host "CMake found: $cmakeVersion" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: CMake not found" -ForegroundColor Red
    Write-Host "Please install CMake 3.15 or newer" -ForegroundColor White
    Write-Host "Download from: https://cmake.org/download/" -ForegroundColor White
    exit 1
}

# Check JUCE
if (-not (Test-Path $JuceDir)) {
    Write-Host "ERROR: JUCE not found at $JuceDir" -ForegroundColor Red
    Write-Host "Please make sure the JUCE framework is in the parent directory of this project" -ForegroundColor White
    Write-Host "You can clone it with: git clone https://github.com/juce-framework/JUCE.git" -ForegroundColor White
    exit 1
}
Write-Host "JUCE found at $JuceDir" -ForegroundColor Green

# Step 2: Create build directory
Write-Host ""
Write-Host "===== Creating Build Directory =====" -ForegroundColor Cyan
if (Test-Path $BuildDir) {
    Write-Host "Build directory already exists. Cleaning old build files..." -ForegroundColor Gray
    try {
        Remove-Item -Path (Join-Path $BuildDir '*') -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Build directory cleaned" -ForegroundColor Green
    }
    catch {
        Write-Host "WARNING: Could not clean build directory completely. Continuing anyway" -ForegroundColor Yellow
    }
}
else {
    try {
        New-Item -Path $BuildDir -ItemType Directory -Force | Out-Null
        Write-Host "Build directory created" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Failed to create build directory" -ForegroundColor Red
        exit 1
    }
}

# Step 3: Configure with CMake
Write-Host ""
Write-Host "===== Configuring with CMake =====" -ForegroundColor Cyan
Push-Location $BuildDir

$cmakeArgs = @(
    '-G',
    "`"$vsGenerator`"",
    '-A',
    'x64',
    "-DCMAKE_BUILD_TYPE=$BuildType",
    '..'
)

Write-Host "Running: cmake with Visual Studio generator" -ForegroundColor Gray

try {
    # Run CMake configure
    & cmake @cmakeArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: CMake configuration failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Write-Host "CMake configuration successful" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to configure with CMake" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Step 4: Build the project
Write-Host ""
Write-Host "===== Building Project =====" -ForegroundColor Cyan
Write-Host "Building in $BuildType configuration" -ForegroundColor Yellow

try {
    # Create the build arguments array
    $buildArgs = @(
        '--build',
        '.',
        '--config',
        $BuildType
    )
    
    Write-Host "Running: cmake --build . --config $BuildType" -ForegroundColor Gray
    
    # Run CMake build
    & cmake @buildArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Write-Host "Build successful" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to build project" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# Step 5: Show build results
Write-Host ""
Write-Host "===== Build Results =====" -ForegroundColor Cyan

# Check for VST3 plugin
$vst3Path = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\VST3\VolumeControlPlugin.vst3"
if (Test-Path $vst3Path) {
    Write-Host "VST3 Plugin built successfully" -ForegroundColor Green
    Write-Host "Location: $vst3Path" -ForegroundColor White
}
else {
    Write-Host "ERROR: VST3 Plugin not found at expected location. Build may have failed" -ForegroundColor Red
}

# Check for Standalone app
$standalonePath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\Standalone\VolumeControlPlugin.exe"
if (Test-Path $standalonePath) {
    Write-Host "Standalone application built successfully" -ForegroundColor Green
    Write-Host "Location: $standalonePath" -ForegroundColor White
}
else {
    Write-Host "ERROR: Standalone application not found at expected location. Build may have failed" -ForegroundColor Red
}

# Instructions for using the plugin
Write-Host ""
Write-Host "===== Next Steps =====" -ForegroundColor Cyan
Write-Host "To use the VST3 plugin in your DAW:" -ForegroundColor White
Write-Host "1. Copy the .vst3 folder to your VST3 directory:" -ForegroundColor White
Write-Host "   C:\Program Files\Common Files\VST3" -ForegroundColor Gray
Write-Host "2. Rescan for plugins in your DAW" -ForegroundColor White
Write-Host "3. Look for 'Volume Control Plugin' in your plugins list" -ForegroundColor White
Write-Host ""
Write-Host "To test the plugin without a DAW:" -ForegroundColor White
Write-Host "Run the standalone application:" -ForegroundColor White
$standalonePathMessage = "   " + $standalonePath
Write-Host $standalonePathMessage -ForegroundColor Gray

Write-Host ""
Write-Host "===== Build Complete =====" -ForegroundColor Cyan