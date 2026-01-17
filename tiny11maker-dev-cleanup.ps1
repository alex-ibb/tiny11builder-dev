# ============================================================================
# Tiny11 Dev Edition - Cleanup Script
# ============================================================================
# This script cleans up any residual state from a previous/interrupted build:
# - Unmounts loaded registry hives
# - Unmounts any mounted WIM images
# - Deletes temporary folders (scratchdir, tiny11)
# ============================================================================

param (
    [switch]$Force,          # Skip confirmation prompts
    [switch]$KeepLogs        # Keep log files
)

# Check for admin privileges
$adminSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
$adminGroup = $adminSID.Translate([System.Security.Principal.NTAccount])
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

if (-not $myWindowsPrincipal.IsInRole($adminRole)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

$scriptDir = $PSScriptRoot
$Host.UI.RawUI.WindowTitle = "Tiny11 Dev Edition - Cleanup"

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Tiny11 Dev Edition - Cleanup Script" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Define paths to check (both script directory and D:\ root in case of path issues)
$pathsToCheck = @(
    @{ Base = $scriptDir; Name = "Script Directory" },
    @{ Base = "D:"; Name = "D:\ Root (fallback)" }
)

$cleanupRequired = $false
$detectedItems = @()

Write-Host "Scanning for residual state..." -ForegroundColor Yellow
Write-Host ""

# Check for loaded registry hives
$hives = @('zCOMPONENTS', 'zDEFAULT', 'zNTUSER', 'zSOFTWARE', 'zSYSTEM')
$loadedHives = @()
foreach ($hive in $hives) {
    $result = reg query "HKLM\$hive" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $loadedHives += $hive
        $cleanupRequired = $true
    }
}
if ($loadedHives.Count -gt 0) {
    Write-Host "  [!] Loaded registry hives: $($loadedHives -join ', ')" -ForegroundColor Yellow
    $detectedItems += "Registry hives: $($loadedHives -join ', ')"
}

# Check for mounted WIM images
$mountedImages = Get-WindowsImage -Mounted -ErrorAction SilentlyContinue
if ($mountedImages) {
    foreach ($img in $mountedImages) {
        Write-Host "  [!] Mounted WIM: $($img.MountPath)" -ForegroundColor Yellow
        $detectedItems += "Mounted WIM: $($img.MountPath)"
        $cleanupRequired = $true
    }
}

# Check for temp folders
foreach ($pathInfo in $pathsToCheck) {
    $scratchDir = Join-Path $pathInfo.Base "scratchdir"
    $tiny11Dir = Join-Path $pathInfo.Base "tiny11"
    
    if (Test-Path $scratchDir) {
        $size = [math]::Round((Get-ChildItem $scratchDir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 0)
        Write-Host "  [!] Temp folder: $scratchDir (~$size MB)" -ForegroundColor Yellow
        $detectedItems += "Folder: $scratchDir"
        $cleanupRequired = $true
    }
    if (Test-Path $tiny11Dir) {
        $size = [math]::Round((Get-ChildItem $tiny11Dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 0)
        Write-Host "  [!] Temp folder: $tiny11Dir (~$size MB)" -ForegroundColor Yellow
        $detectedItems += "Folder: $tiny11Dir"
        $cleanupRequired = $true
    }
}

Write-Host ""

if (-not $cleanupRequired) {
    Write-Host "No cleanup required. Environment is clean." -ForegroundColor Green
    exit 0
}

Write-Host "Cleanup required for $($detectedItems.Count) item(s)." -ForegroundColor Yellow
Write-Host ""

# Confirmation prompt
if (-not $Force) {
    $response = Read-Host "Proceed with cleanup? (yes/no)"
    if ($response -ne 'yes') {
        Write-Host "Cleanup cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "Starting cleanup..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Unload registry hives
Write-Host "[1/3] Unloading registry hives..." -ForegroundColor White
foreach ($hive in $loadedHives) {
    Write-Host "  Unloading HKLM\$hive..." -NoNewline
    [gc]::Collect()
    Start-Sleep -Milliseconds 500
    $result = reg unload "HKLM\$hive" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " RETRY" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        [gc]::Collect()
        [gc]::WaitForPendingFinalizers()
        reg unload "HKLM\$hive" 2>&1 | Out-Null
    }
}

# Step 2: Unmount WIM images
Write-Host "[2/3] Unmounting WIM images..." -ForegroundColor White
$mountedImages = Get-WindowsImage -Mounted -ErrorAction SilentlyContinue
if ($mountedImages) {
    foreach ($img in $mountedImages) {
        Write-Host "  Unmounting $($img.MountPath)..." -NoNewline
        try {
            Dismount-WindowsImage -Path $img.MountPath -Discard -ErrorAction Stop | Out-Null
            Write-Host " OK" -ForegroundColor Green
        } catch {
            Write-Host " Using DISM..." -ForegroundColor Yellow
            dism /Unmount-Image /MountDir:"$($img.MountPath)" /Discard 2>&1 | Out-Null
        }
    }
} else {
    Write-Host "  No mounted images found." -ForegroundColor Gray
}

# Step 3: Delete temp folders
Write-Host "[3/3] Deleting temporary folders..." -ForegroundColor White
foreach ($pathInfo in $pathsToCheck) {
    $scratchDir = Join-Path $pathInfo.Base "scratchdir"
    $tiny11Dir = Join-Path $pathInfo.Base "tiny11"
    
    if (Test-Path $scratchDir) {
        Write-Host "  Deleting $scratchDir..." -NoNewline
        Remove-Item -Path $scratchDir -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path $scratchDir) {
            Write-Host " PARTIAL (some files locked)" -ForegroundColor Yellow
        } else {
            Write-Host " OK" -ForegroundColor Green
        }
    }
    if (Test-Path $tiny11Dir) {
        Write-Host "  Deleting $tiny11Dir..." -NoNewline
        if ($KeepLogs -and (Test-Path "$tiny11Dir\*.log")) {
            Get-ChildItem $tiny11Dir -Exclude "*.log" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host " OK (logs kept)" -ForegroundColor Green
        } else {
            Remove-Item -Path $tiny11Dir -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path $tiny11Dir) {
                Write-Host " PARTIAL (some files locked)" -ForegroundColor Yellow
            } else {
                Write-Host " OK" -ForegroundColor Green
            }
        }
    }
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Cleanup complete!" -ForegroundColor Green
Write-Host "  You can now run tiny11maker-engineer.ps1" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan
