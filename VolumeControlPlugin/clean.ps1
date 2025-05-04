# Volume Control Plugin - Windows Clean Script
# This script cleans the build directories created by PowerShell build scripts
# Run with: PowerShell -ExecutionPolicy Bypass -File clean.ps1

# Helper functions
function Write-ColorText {
    param (
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Write-Step {
    param ([string]$Text)
    Write-ColorText "`n===== $Text =====" "Cyan"
}

function Write-Success {
    param ([string]$Text)
    Write-ColorText "✓ $Text" "Green"
}

# Print header
Write-Step "VOLUME CONTROL PLUGIN - CLEAN SCRIPT"
Write-ColorText "This script will clean all build directories" "White"

# Define build directories to clean
$buildDirs = @(
    "build_vs"
)

# Track if any directories were cleaned
$anyCleaned = $false

foreach ($dir in $buildDirs) {
    $fullPath = Join-Path $PSScriptRoot $dir
    
    if (Test-Path $fullPath) {
        Write-ColorText "Found build directory: $dir" "Yellow"
        
        # Ask for confirmation
        $confirm = Read-Host "Are you sure you want to remove the $dir directory? (y/n)"
        
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            try {
                Write-ColorText "Removing $dir..." "Yellow"
                Remove-Item -Path $fullPath -Recurse -Force
                Write-Success "$dir directory removed successfully"
                $anyCleaned = $true
            }
            catch {
                Write-ColorText "Error removing directory: $_" "Red"
            }
        }
        else {
            Write-ColorText "Skipping $dir directory" "Yellow"
        }
    }
    else {
        Write-ColorText "$dir directory does not exist, nothing to clean" "Gray"
    }
}

if ($anyCleaned) {
    Write-Success "Clean completed successfully"
}
else {
    Write-ColorText "No directories were cleaned" "Yellow"
}

Write-Step "Clean Script Complete"