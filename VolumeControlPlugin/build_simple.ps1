# Volume Control Plugin - Simple Windows Build Script
# This script builds the VolumeControlPlugin using Visual Studio and CMake
# Run with: PowerShell -ExecutionPolicy Bypass -File build_simple.ps1

# Configuration
$BuildType = 'Release'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BuildDir = Join-Path $ScriptDir 'build_vs'
$JuceDir = Join-Path (Split-Path -Parent $ScriptDir) 'JUCE'

# Helper functions
function Write-ColorText {
    param (
        [string]$Text,
        [string]$Color = 'White'
    )
    
    Write-Host $Text -ForegroundColor $Color
}

function Write-Step {
    param (
        [string]$Text
    )
    
    Write-Host "`n===== $Text =====" -ForegroundColor Cyan
}

function Write-Success {
    param (
        [string]$Text
    )
    
    Write-Host "✓ $Text" -ForegroundColor Green
}

function Write-Warning {
    param (
        [string]$Text
    )
    
    Write-Host "WARNING: $Text" -ForegroundColor Yellow
}

function Write-Error {
    param (
        [string]$Text
    )
    
    Write-Host "ERROR: $Text" -ForegroundColor Red
}

# Print header
Write-Step 'VOLUME CONTROL PLUGIN - WINDOWS BUILD SCRIPT'
Write-Host 'This script will build the VST3 plugin and standalone application' -ForegroundColor White

# Check for PowerShell execution policy
try {
    $policy = Get-ExecutionPolicy -Scope Process
    Write-Host "Current execution policy: $policy" -ForegroundColor Gray
    if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
        Write-Warning 'PowerShell execution policy may prevent this script from running'
        Write-Host 'If you get an execution policy error, run this command first:' -ForegroundColor Yellow
        Write-Host 'Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process' -ForegroundColor Gray
    }
} catch {
    # Skip execution policy check if it fails for some reason
}

# Step 1: Check prerequisites
Write-Step 'Checking Prerequisites'

# Check Visual Studio 
$vsFound = $false
$vsVersion = ''
# Try Visual Studio 2022
if (Test-Path 'C:\Program Files\Microsoft Visual Studio\2022') {
    $vsFound = $true
    $vsVersion = '2022'
    $vsGenerator = 'Visual Studio 17 2022'
    Write-Success 'Visual Studio 2022 found'
}
# Try Visual Studio 2019 if 2022 wasn't found
elseif (Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2019') {
    $vsFound = $true
    $vsVersion = '2019'
    $vsGenerator = 'Visual Studio 16 2019'
    Write-Success 'Visual Studio 2019 found'
}
else {
    Write-Error 'Visual Studio 2019 or 2022 not found'
    Write-Host 'Please install Visual Studio 2019 or 2022 with "Desktop development with C++" workload' -ForegroundColor White
    Write-Host 'Download from: https://visualstudio.microsoft.com/downloads/' -ForegroundColor White
    exit 1
}

# Check CMake
try {
    $cmakeVersion = (cmake --version) | Select-Object -First 1
    Write-Success "CMake found: $cmakeVersion"
}
catch {
    Write-Error 'CMake not found'
    Write-Host 'Please install CMake 3.15 or newer' -ForegroundColor White
    Write-Host 'Download from: https://cmake.org/download/' -ForegroundColor White
    exit 1
}

# Check JUCE
if (-not (Test-Path $JuceDir)) {
    Write-Error "JUCE not found at $JuceDir"
    Write-Host 'Please make sure the JUCE framework is in the parent directory of this project' -ForegroundColor White
    Write-Host 'You can clone it with: git clone https://github.com/juce-framework/JUCE.git' -ForegroundColor White
    exit 1
}
Write-Success "JUCE found at $JuceDir"

# Step 2: Create build directory
Write-Step 'Creating Build Directory'
if (Test-Path $BuildDir) {
    Write-Host 'Build directory already exists. Cleaning old build files...' -ForegroundColor Gray
    try {
        Remove-Item -Path (Join-Path $BuildDir '*') -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success 'Build directory cleaned'
    }
    catch {
        Write-Warning 'Could not clean build directory completely. Continuing anyway'
    }
}
else {
    try {
        New-Item -Path $BuildDir -ItemType Directory -Force | Out-Null
        Write-Success 'Build directory created'
    }
    catch {
        Write-Error "Failed to create build directory: $_"
        exit 1
    }
}

# Step 3: Configure with CMake
Write-Step 'Configuring with CMake'
Push-Location $BuildDir

# Create the CMake arguments array
$cmakeArgs = @(
    '-G',
    "`"$vsGenerator`"",
    '-A',
    'x64',
    "-DCMAKE_BUILD_TYPE=$BuildType",
    '..'
)

Write-Host 'Running: cmake with Visual Studio generator' -ForegroundColor Gray

try {
    # Run CMake configure
    & cmake @cmakeArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "CMake configuration failed with exit code $LASTEXITCODE"
        Pop-Location
        exit 1
    }
    Write-Success 'CMake configuration successful'
}
catch {
    Write-Error "Failed to configure with CMake: $_"
    Pop-Location
    exit 1
}

# Step 4: Build the project
Write-Step 'Building Project'
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
        Write-Error "Build failed with exit code $LASTEXITCODE"
        Pop-Location
        exit 1
    }
    Write-Success 'Build successful'
}
catch {
    Write-Error "Failed to build project: $_"
    Pop-Location
    exit 1
}
Pop-Location

# Step 5: Show build results
Write-Step 'Build Results'

# Check for VST3 plugin
$vst3Path = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\VST3\VolumeControlPlugin.vst3"
if (Test-Path $vst3Path) {
    Write-Success 'VST3 Plugin built successfully'
    Write-Host "Location: $vst3Path" -ForegroundColor White
}
else {
    Write-Error 'VST3 Plugin not found at expected location. Build may have failed'
}

# Check for Standalone app
$standalonePath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\Standalone\VolumeControlPlugin.exe"
if (Test-Path $standalonePath) {
    Write-Success 'Standalone application built successfully'
    Write-Host "Location: $standalonePath" -ForegroundColor White
}
else {
    Write-Error 'Standalone application not found at expected location. Build may have failed'
}

# Instructions for using the plugin
Write-Step 'Next Steps'
Write-Host 'To use the VST3 plugin in your DAW:' -ForegroundColor White
Write-Host '1. Copy the .vst3 folder to your VST3 directory:' -ForegroundColor White
Write-Host '   C:\Program Files\Common Files\VST3' -ForegroundColor Gray
Write-Host '2. Rescan for plugins in your DAW' -ForegroundColor White
Write-Host '3. Look for "Volume Control Plugin" in your plugins list' -ForegroundColor White
Write-Host '' -ForegroundColor White
Write-Host 'To test the plugin without a DAW:' -ForegroundColor White
Write-Host 'Run the standalone application:' -ForegroundColor White
Write-Host "   $standalonePath" -ForegroundColor Gray

Write-Step 'Build Complete'