# Volume Control Plugin - Comprehensive Windows Build Script
# Usage: .\build_plugin.ps1 [Debug|Release]
# Run with: PowerShell -ExecutionPolicy Bypass -File build_plugin.ps1 [Debug|Release]

param(
    [string]$BuildType = 'Release'
)

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BuildDir = Join-Path $ScriptDir 'build_vs'
$JuceDir = Join-Path (Split-Path -Parent $ScriptDir) 'JUCE'

# Print header
Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " Volume Control Plugin - Windows Build Script " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Building in $BuildType configuration" -ForegroundColor Cyan

# Step 1: Check prerequisites
Write-Host "`n→ Checking prerequisites..." -ForegroundColor Yellow

# Check execution policy
$policy = Get-ExecutionPolicy -Scope Process
if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
    Write-Host "WARNING: PowerShell execution policy is set to $policy" -ForegroundColor Yellow
    Write-Host "If you receive a policy error, run this command first:" -ForegroundColor Gray
    Write-Host "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process" -ForegroundColor Gray
}

# Check Visual Studio
$vsFound = $false
$vsVersion = ''
# Try Visual Studio 2022
if (Test-Path 'C:\Program Files\Microsoft Visual Studio\2022') {
    $vsFound = $true
    $vsVersion = '2022'
    $vsGenerator = 'Visual Studio 17 2022'
    Write-Host "✓ Visual Studio 2022 found" -ForegroundColor Green
}
# Try Visual Studio 2019 if 2022 wasn't found
elseif (Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2019') {
    $vsFound = $true
    $vsVersion = '2019'
    $vsGenerator = 'Visual Studio 16 2019'
    Write-Host "✓ Visual Studio 2019 found" -ForegroundColor Green
}
else {
    Write-Host "ERROR: Visual Studio 2019 or 2022 not found" -ForegroundColor Red
    Write-Host "Please install Visual Studio with 'Desktop development with C++' workload" -ForegroundColor White
    Write-Host "Download from: https://visualstudio.microsoft.com/downloads/" -ForegroundColor White
    exit 1
}

# Check CMake
try {
    $cmakeVersion = (cmake --version) | Select-Object -First 1
    Write-Host "✓ $cmakeVersion" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: CMake not found" -ForegroundColor Red
    Write-Host "Please install CMake 3.15 or higher" -ForegroundColor White
    Write-Host "Download from: https://cmake.org/download/" -ForegroundColor White
    exit 1
}

# Check JUCE
if (-not (Test-Path $JuceDir)) {
    Write-Host "ERROR: JUCE not found at $JuceDir" -ForegroundColor Red
    Write-Host "Please make sure the JUCE framework is in the parent directory of this project" -ForegroundColor White
    Write-Host "Clone it with: git clone https://github.com/juce-framework/JUCE.git" -ForegroundColor White
    exit 1
}
Write-Host "✓ JUCE found at $JuceDir" -ForegroundColor Green
Write-Host "✓ All prerequisites satisfied" -ForegroundColor Green

# Step 2: Create build directory
Write-Host "`n→ Creating build directory..." -ForegroundColor Yellow
if (Test-Path $BuildDir) {
    Write-Host "Cleaning previous build artifacts..." -ForegroundColor Gray
    Remove-Item -Path "$BuildDir\*" -Recurse -Force -ErrorAction SilentlyContinue
}
else {
    New-Item -Path $BuildDir -ItemType Directory -Force | Out-Null
}
Write-Host "✓ Build directory ready at $BuildDir" -ForegroundColor Green

# Step 3: Run CMake
Write-Host "`n→ Running CMake configuration..." -ForegroundColor Yellow
Push-Location $BuildDir

# Create the CMake arguments array
$cmakeArgs = @(
    '-G',
    "`"$vsGenerator`"",
    '-A',
    'x64',
    "-DCMAKE_BUILD_TYPE=$BuildType",
    "-DJUCE_DIR=$JuceDir",
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
    Write-Host "✓ CMake configuration completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: CMake failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Step 4: Build
Write-Host "`n→ Building project ($BuildType)..." -ForegroundColor Yellow

# Create the build arguments array
$buildArgs = @(
    '--build',
    '.',
    '--config',
    $BuildType
)

Write-Host "Running: cmake --build . --config $BuildType" -ForegroundColor Gray

try {
    # Run CMake build
    & cmake @buildArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Write-Host "✓ Build completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Build failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# Step 5: Show results
Write-Host "`n→ Build Results:" -ForegroundColor Yellow
$PluginPath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\VST3\VolumeControlPlugin.vst3"
$StandalonePath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\Standalone\VolumeControlPlugin.exe"

if (Test-Path $PluginPath) {
    Write-Host "✓ VST3 Plugin built successfully" -ForegroundColor Green
    Write-Host "Location: $PluginPath" -ForegroundColor White
}
else {
    Write-Host "ERROR: VST3 Plugin not found at expected location. Build may have failed" -ForegroundColor Red
}

if (Test-Path $StandalonePath) {
    Write-Host "✓ Standalone App built successfully" -ForegroundColor Green
    Write-Host "Location: $StandalonePath" -ForegroundColor White
}
else {
    Write-Host "ERROR: Standalone application not found at expected location. Build may have failed" -ForegroundColor Red
}

# Step 6: Installation instructions
Write-Host "`n→ Installation Instructions:" -ForegroundColor Yellow
Write-Host "To load the plugin in your DAW:" -ForegroundColor White
Write-Host "1. Copy the .vst3 folder to your VST3 directory:" -ForegroundColor White
Write-Host "   C:\Program Files\Common Files\VST3" -ForegroundColor Gray
Write-Host "2. Rescan for plugins in your DAW" -ForegroundColor White
Write-Host "3. Look for 'Volume Control Plugin' in the effects list" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "To test the plugin without a DAW, run the standalone application:" -ForegroundColor White
Write-Host "   $StandalonePath" -ForegroundColor Gray

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " Build Completed Successfully" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan