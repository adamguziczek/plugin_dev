# build_plugin.ps1 - Simplified JUCE Plugin Build Script for Windows
# Usage: .\build_plugin.ps1 or .\build_plugin.ps1 Debug

param(
    [string]$BuildType = "Release"
)

# Configuration
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BuildDir = Join-Path $ScriptPath "build_vs"
$JuceDir = Join-Path (Split-Path -Parent $ScriptPath) "JUCE"

# Check prerequisites
Write-Host "`n→ Checking prerequisites..." -ForegroundColor Yellow

# Check Visual Studio
$VsPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019"
if (-not (Test-Path $VsPath)) {
    Write-Host "ERROR: Visual Studio 2019 not found at $VsPath" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Visual Studio 2019 found" -ForegroundColor Green

# Check CMake
try {
    $CMakeVersion = (cmake --version) | Select-Object -First 1
    Write-Host "✓ $CMakeVersion" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: CMake not found" -ForegroundColor Red
    exit 1
}

# Check JUCE
if (-not (Test-Path $JuceDir)) {
    Write-Host "ERROR: JUCE not found at $JuceDir" -ForegroundColor Red
    exit 1
}
Write-Host "✓ JUCE found at $JuceDir" -ForegroundColor Green
Write-Host "All prerequisites satisfied!" -ForegroundColor Green

# Create build directory
Write-Host "`n→ Creating build directory..." -ForegroundColor Yellow
if (Test-Path $BuildDir) {
    Write-Host "Cleaning previous build artifacts..." -ForegroundColor Yellow
    Remove-Item -Path "$BuildDir\*" -Recurse -Force -ErrorAction SilentlyContinue
}
else {
    New-Item -Path $BuildDir -ItemType Directory -Force | Out-Null
}
Write-Host "Build directory ready at $BuildDir" -ForegroundColor Green

# Run CMake
Write-Host "`n→ Running CMake configuration..." -ForegroundColor Yellow
Push-Location $BuildDir
$CMakeArgs = @("-G", "Visual Studio 16 2019", "-A", "x64", "-DCMAKE_BUILD_TYPE=$BuildType", "-DJUCE_DIR=$JuceDir", "..")
Write-Host "Executing: cmake $CMakeArgs" -ForegroundColor DarkGray
try {
    & cmake $CMakeArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: CMake configuration failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Write-Host "CMake configuration completed successfully!" -ForegroundColor Green
}
catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "ERROR: CMake failed: $ErrorMsg" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Build
Write-Host "`n→ Building project ($BuildType)..." -ForegroundColor Yellow
$BuildCommand = "cmake --build . --config $BuildType"
Write-Host "Executing: $BuildCommand" -ForegroundColor DarkGray
try {
    & cmake --build . --config $BuildType
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Write-Host "Build completed successfully!" -ForegroundColor Green
}
catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "ERROR: Build failed: $ErrorMsg" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# Show results
Write-Host "`n→ Build Results:" -ForegroundColor Yellow
$PluginPath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\VST3\VolumeControlPlugin.vst3"
$StandalonePath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\Standalone\VolumeControlPlugin.exe"

if (Test-Path $PluginPath) {
    Write-Host "VST3 Plugin: $PluginPath" -ForegroundColor Green
}
else {
    Write-Host "VST3 Plugin not found! Build may have failed." -ForegroundColor Red
}

if (Test-Path $StandalonePath) {
    Write-Host "Standalone App: $StandalonePath" -ForegroundColor Green
}
else {
    Write-Host "Standalone application not found! Build may have failed." -ForegroundColor Red
}

Write-Host "`nTo load the plugin in your DAW:" -ForegroundColor White
Write-Host "1. Copy the .vst3 folder to your VST3 directory (C:\Program Files\Common Files\VST3)" -ForegroundColor White
Write-Host "2. Rescan for plugins in your DAW" -ForegroundColor White
Write-Host "3. Look for 'Volume Control Plugin' in the effects list" -ForegroundColor White

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " Build Completed Successfully!" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan