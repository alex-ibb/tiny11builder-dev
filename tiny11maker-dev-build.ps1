param (
    [ValidatePattern('^[c-zC-Z]$')]
    [string]$ScratchDisk
)

if (-not $ScratchDisk) {
    $ScratchDisk = $PSScriptRoot -replace '[\\]+$', ''
} else {
    $ScratchDisk = $ScratchDisk + ":"
}

Write-Output "Scratch disk set to $ScratchDisk"

# Check if PowerShell execution is restricted
if ((Get-ExecutionPolicy) -eq 'Restricted') {
    Write-Host "Your current PowerShell Execution Policy is set to Restricted, which prevents scripts from running. Do you want to change it to RemoteSigned? (yes/no)"
    $response = Read-Host
    if ($response -eq 'yes') {
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Confirm:$false
    } else {
        Write-Host "The script cannot be run without changing the execution policy. Exiting..."
        exit
    }
}

# Check and run the script as admin if required
$adminSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
$adminGroup = $adminSID.Translate([System.Security.Principal.NTAccount])
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
if (! $myWindowsPrincipal.IsInRole($adminRole))
{
    Write-Host "Restarting Tiny11 image creator as admin in a new window, you can close this one."
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess);
    exit
}
$isoTimestamp = Get-Date -Format "yyyyMMdd_HHmm"
$isoFileName = "tiny11-dev-$isoTimestamp.iso"
Start-Transcript -Path "$PSScriptRoot\$isoFileName.log" 

$Host.UI.RawUI.WindowTitle = "Tiny11 Dev Edition - Image Creator"
Clear-Host
Write-Host "Welcome to the tiny11 Dev Edition image creator! Release: 01-05-26"
Write-Host "============================================================================"
Write-Host "This version retains the following components for developers:"
Write-Host "  - Edge Browser & Edge WebView2 Runtime"
Write-Host "  - Photos Viewer & Paint (mspaint)"
Write-Host "  - Snipping Tool (Screenshots)"
Write-Host "  - Windows Update & Online Driver Installation"
Write-Host ""
Write-Host "Additional features:"
Write-Host "  - Best performance mode with 5 visual effects:"
Write-Host "    (Font smoothing, window shadow, menu fade, cursor shadow, icon label shadow)"
Write-Host "  - File Explorer: Details view by default, no grouping"
Write-Host "  - Show hidden files and file extensions"
Write-Host "  - Windows Update: DISABLED by default (enable via desktop scripts)"
Write-Host "  - Online driver installation: Enabled"
Write-Host "  - Microsoft PC Manager removed"
Write-Host "  - Extended Wallpapers removed (saves ~300-500MB)"
Write-Host "  - Traditional (Windows 10 style) context menu"
Write-Host "  - Context menu: 'CMD here', 'PowerShell here', 'PS Admin here'"
Write-Host "  - Widgets disabled (saves memory)"
Write-Host "  - Search Highlights disabled (reduces network)"
Write-Host "  - Xbox background services disabled"
Write-Host "  - Windows Search set to Manual (recommend Everything)"
Write-Host "  - Lock Screen: Spotlight/news/tips disabled"
Write-Host "  - Edge: News feed disabled, clean new tab page"
Write-Host "  - README file placed on desktop"
Write-Host "============================================================================"
Write-Host ""

# ============================================================================
# Pre-flight cleanup: Detect and clean residual state from previous runs
# ============================================================================
Write-Host "Checking for residual state from previous builds..." -ForegroundColor Yellow

$cleanupNeeded = $false
$hives = @('zCOMPONENTS', 'zDEFAULT', 'zNTUSER', 'zSOFTWARE', 'zSYSTEM')
$loadedHives = @()

# Check for loaded registry hives
foreach ($hive in $hives) {
    $result = reg query "HKLM\$hive" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $loadedHives += $hive
        $cleanupNeeded = $true
    }
}

# Check for mounted WIM and temp folders
$scratchPath = "$ScratchDisk\scratchdir"
$tiny11Path = "$ScratchDisk\tiny11"
$hasScratch = Test-Path $scratchPath
$hasTiny11 = Test-Path $tiny11Path

if ($loadedHives.Count -gt 0 -or $hasScratch -or $hasTiny11) {
    Write-Host ""
    Write-Host "Residual state detected:" -ForegroundColor Yellow
    if ($loadedHives.Count -gt 0) {
        Write-Host "  - Loaded registry hives: $($loadedHives -join ', ')" -ForegroundColor Yellow
    }
    if ($hasScratch) {
        Write-Host "  - Temp folder: $scratchPath" -ForegroundColor Yellow
    }
    if ($hasTiny11) {
        Write-Host "  - Temp folder: $tiny11Path" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Performing automatic cleanup..." -ForegroundColor Cyan
    
    # Unload registry hives
    foreach ($hive in $loadedHives) {
        Write-Host "  Unloading HKLM\$hive..." -NoNewline
        [gc]::Collect()
        [gc]::WaitForPendingFinalizers()
        Start-Sleep -Milliseconds 500
        reg unload "HKLM\$hive" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host " OK" -ForegroundColor Green
        } else {
            Start-Sleep -Seconds 2
            reg unload "HKLM\$hive" 2>&1 | Out-Null
            Write-Host " Done" -ForegroundColor Green
        }
    }
    
    # Unmount any mounted WIM
    $mountedImages = Get-WindowsImage -Mounted -ErrorAction SilentlyContinue
    if ($mountedImages) {
        foreach ($img in $mountedImages) {
            if ($img.MountPath -like "*scratchdir*") {
                Write-Host "  Unmounting WIM at $($img.MountPath)..." -NoNewline
                try {
                    Dismount-WindowsImage -Path $img.MountPath -Discard -ErrorAction Stop | Out-Null
                    Write-Host " OK" -ForegroundColor Green
                } catch {
                    dism /Unmount-Image /MountDir:"$($img.MountPath)" /Discard 2>&1 | Out-Null
                    Write-Host " Done" -ForegroundColor Green
                }
            }
        }
    }
    
    # Delete temp folders
    if ($hasScratch) {
        Write-Host "  Deleting $scratchPath..." -NoNewline
        Remove-Item -Path $scratchPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host " OK" -ForegroundColor Green
    }
    if ($hasTiny11) {
        Write-Host "  Deleting $tiny11Path..." -NoNewline
        Remove-Item -Path $tiny11Path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host " OK" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Cleanup complete! Starting fresh build..." -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "  No residual state found. Environment is clean." -ForegroundColor Green
    Write-Host ""
}

$hostArchitecture = $Env:PROCESSOR_ARCHITECTURE
New-Item -ItemType Directory -Force -Path "$ScratchDisk\tiny11\sources" | Out-Null
do {
    $DriveLetter = Read-Host "Please enter the drive letter for the Windows 11 image"
    if ($DriveLetter -match '^[c-zC-Z]$') {
        $DriveLetter = $DriveLetter + ":"
        Write-Output "Drive letter set to $DriveLetter"
    } else {
        Write-Output "Invalid drive letter. Please enter a letter between C and Z."
    }
} while ($DriveLetter -notmatch '^[c-zC-Z]:$')

if ((Test-Path "$DriveLetter\sources\boot.wim") -eq $false -or (Test-Path "$DriveLetter\sources\install.wim") -eq $false) {
    if ((Test-Path "$DriveLetter\sources\install.esd") -eq $true) {
        Write-Host "Found install.esd, converting to install.wim..."
        Get-WindowsImage -ImagePath $DriveLetter\sources\install.esd
        $index = Read-Host "Please enter the image index"
        Write-Host ' '
        Write-Host 'Converting install.esd to install.wim. This may take a while...'
        Export-WindowsImage -SourceImagePath $DriveLetter\sources\install.esd -SourceIndex $index -DestinationImagePath $ScratchDisk\tiny11\sources\install.wim -Compressiontype Maximum -CheckIntegrity
    } else {
        Write-Host "Can't find Windows OS Installation files in the specified Drive Letter.."
        Write-Host "Please enter the correct DVD Drive Letter.."
        exit
    }
}

Write-Host "Copying Windows image..."
Copy-Item -Path "$DriveLetter\*" -Destination "$ScratchDisk\tiny11" -Recurse -Force | Out-Null
Set-ItemProperty -Path "$ScratchDisk\tiny11\sources\install.esd" -Name IsReadOnly -Value $false > $null 2>&1
Remove-Item "$ScratchDisk\tiny11\sources\install.esd" > $null 2>&1
Write-Host "Copy complete!"
Start-Sleep -Seconds 2
Clear-Host
Write-Host "Getting image information:"
Get-WindowsImage -ImagePath $ScratchDisk\tiny11\sources\install.wim
$index = Read-Host "Please enter the image index"
Write-Host "Mounting Windows image. This may take a while."
$wimFilePath = "$ScratchDisk\tiny11\sources\install.wim"
& takeown "/F" $wimFilePath 
& icacls $wimFilePath "/grant" "$($adminGroup.Value):(F)"
try {
    Set-ItemProperty -Path $wimFilePath -Name IsReadOnly -Value $false -ErrorAction Stop
} catch {
    
}
New-Item -ItemType Directory -Force -Path "$ScratchDisk\scratchdir" > $null
Mount-WindowsImage -ImagePath $ScratchDisk\tiny11\sources\install.wim -Index $index -Path $ScratchDisk\scratchdir

$imageIntl = & dism /English /Get-Intl "/Image:$($ScratchDisk)\scratchdir"
$languageLine = $imageIntl -split '\n' | Where-Object { $_ -match 'Default system UI language : ([a-zA-Z]{2}-[a-zA-Z]{2})' }

if ($languageLine) {
    $languageCode = $Matches[1]
    Write-Host "Default system UI language code: $languageCode"
} else {
    Write-Host "Default system UI language code not found."
}

$imageInfo = & 'dism' '/English' '/Get-WimInfo' "/wimFile:$($ScratchDisk)\tiny11\sources\install.wim" "/index:$index"
$lines = $imageInfo -split '\r?\n'

foreach ($line in $lines) {
    if ($line -like '*Architecture : *') {
        $architecture = $line -replace 'Architecture : ',''
        # If the architecture is x64, replace it with amd64
        if ($architecture -eq 'x64') {
            $architecture = 'amd64'
        }
        Write-Host "Architecture: $architecture"
        break
    }
}

if (-not $architecture) {
    Write-Host "Architecture information not found."
}

Write-Host "Mounting complete! Performing removal of applications..."

$packages = & 'dism' '/English' "/image:$($ScratchDisk)\scratchdir" '/Get-ProvisionedAppxPackages' |
    ForEach-Object {
        if ($_ -match 'PackageName : (.*)') {
            $matches[1]
        }
    }

# Dev Edition: Retained apps (NOT in this list):
#   - Microsoft.Windows.Photos_ (Photo Viewer)
#   - Microsoft.Paint_ (mspaint - not a provisioned app, it's a system component)
#   - Microsoft.ScreenSketch_ (Snipping Tool)
#   - Edge and WebView2 (handled separately - NOT removed in this version)

$packagePrefixes = 'Clipchamp.Clipchamp_', 'Microsoft.BingNews_', 'Microsoft.BingWeather_', 'Microsoft.GamingApp_', 'Microsoft.GetHelp_', 'Microsoft.Getstarted_', 'Microsoft.MicrosoftOfficeHub_', 'Microsoft.MicrosoftSolitaireCollection_', 'Microsoft.People_', 'Microsoft.PowerAutomateDesktop_', 'Microsoft.Todos_', 'Microsoft.WindowsAlarms_', 'microsoft.windowscommunicationsapps_', 'Microsoft.WindowsFeedbackHub_', 'Microsoft.WindowsMaps_', 'Microsoft.WindowsSoundRecorder_', 'Microsoft.Xbox.TCUI_', 'Microsoft.XboxGamingOverlay_', 'Microsoft.XboxGameOverlay_', 'Microsoft.XboxSpeechToTextOverlay_', 'Microsoft.YourPhone_', 'Microsoft.ZuneMusic_', 'Microsoft.ZuneVideo_', 'MicrosoftCorporationII.MicrosoftFamily_', 'MicrosoftCorporationII.QuickAssist_', 'MicrosoftTeams_', 'Microsoft.549981C3F5F10_', 'Microsoft.Windows.Copilot', 'MSTeams_', 'Microsoft.OutlookForWindows_', 'Microsoft.Windows.Teams_', 'Microsoft.Copilot_', 'Microsoft.MicrosoftPCManager_'

$packagesToRemove = $packages | Where-Object {
    $packageName = $_
    # Remove if package name starts with ANY of the listed prefixes
    ($packagePrefixes | Where-Object { $packageName -like "$_*" }).Count -gt 0
}
foreach ($package in $packagesToRemove) {
    Write-Host "Removing: $package ..." -NoNewline
    & 'dism' '/English' "/image:$($ScratchDisk)\scratchdir" '/Remove-ProvisionedAppxPackage' "/PackageName:$package" | Out-Null
    Write-Host " Done"
}

# ============================================================================
# Dev Edition: KEEP Edge Browser and Edge WebView2 Runtime
# The following Edge removal code is COMMENTED OUT
# ============================================================================
Write-Host ""
Write-Host "[Dev Edition] Keeping Edge Browser and Edge WebView2 Runtime..."
Write-Host ""

# Remove-Item -Path "$ScratchDisk\scratchdir\Program Files (x86)\Microsoft\Edge" -Recurse -Force | Out-Null
# Remove-Item -Path "$ScratchDisk\scratchdir\Program Files (x86)\Microsoft\EdgeUpdate" -Recurse -Force | Out-Null
# Remove-Item -Path "$ScratchDisk\scratchdir\Program Files (x86)\Microsoft\EdgeCore" -Recurse -Force | Out-Null
# & 'takeown' '/f' "$ScratchDisk\scratchdir\Windows\System32\Microsoft-Edge-Webview" '/r' | Out-Null
# & 'icacls' "$ScratchDisk\scratchdir\Windows\System32\Microsoft-Edge-Webview" '/grant' "$($adminGroup.Value):(F)" '/T' '/C' | Out-Null
# Remove-Item -Path "$ScratchDisk\scratchdir\Windows\System32\Microsoft-Edge-Webview" -Recurse -Force | Out-Null

Write-Host "Removing OneDrive:"
& 'takeown' '/f' "$ScratchDisk\scratchdir\Windows\System32\OneDriveSetup.exe" | Out-Null
& 'icacls' "$ScratchDisk\scratchdir\Windows\System32\OneDriveSetup.exe" '/grant' "$($adminGroup.Value):(F)" '/T' '/C' | Out-Null
Remove-Item -Path "$ScratchDisk\scratchdir\Windows\System32\OneDriveSetup.exe" -Force | Out-Null

Write-Host "Removing Microsoft PC Manager:"
# Remove PC Manager if present (typically in Program Files)
$pcManagerPaths = @(
    "$ScratchDisk\scratchdir\Program Files\Microsoft PC Manager",
    "$ScratchDisk\scratchdir\Program Files (x86)\Microsoft PC Manager"
)
foreach ($path in $pcManagerPaths) {
    if (Test-Path $path) {
        Write-Host "Found PC Manager at: $path"
        & 'takeown' '/f' $path '/r' | Out-Null
        & 'icacls' $path '/grant' "$($adminGroup.Value):(F)" '/T' '/C' | Out-Null
        Remove-Item -Path $path -Recurse -Force | Out-Null
        Write-Host "PC Manager removed from: $path"
    }
}
Write-Host "Removal complete!"

# ============================================================================
# Dev Edition: Remove Extended Wallpapers to save disk space (~300-500MB)
# ============================================================================
Write-Host "Removing Extended Wallpapers to save disk space..."
$wallpaperPackages = & 'dism' '/English' "/image:$($ScratchDisk)\scratchdir" '/Get-Packages' | 
    Select-String -Pattern 'Microsoft-Windows-Wallpaper-Content-Extended' | 
    ForEach-Object { ($_ -split ':')[1].Trim() }

foreach ($pkg in $wallpaperPackages) {
    if ($pkg) {
        Write-Host "Removing: $pkg"
        & 'dism' '/English' "/image:$($ScratchDisk)\scratchdir" '/Remove-Package' "/PackageName:$pkg" '/NoRestart' | Out-Null
    }
}
Write-Host "Extended Wallpapers removed!"

Start-Sleep -Seconds 2
Clear-Host
Write-Host "Loading registry..."
reg load HKLM\zCOMPONENTS $ScratchDisk\scratchdir\Windows\System32\config\COMPONENTS | Out-Null
reg load HKLM\zDEFAULT $ScratchDisk\scratchdir\Windows\System32\config\default | Out-Null
reg load HKLM\zNTUSER $ScratchDisk\scratchdir\Users\Default\ntuser.dat | Out-Null
reg load HKLM\zSOFTWARE $ScratchDisk\scratchdir\Windows\System32\config\SOFTWARE | Out-Null
reg load HKLM\zSYSTEM $ScratchDisk\scratchdir\Windows\System32\config\SYSTEM | Out-Null
# Load UsrClass.dat for HKCU\Software\Classes settings (context menu, etc.)
reg load HKLM\zUSRCLASS "$ScratchDisk\scratchdir\Users\Default\AppData\Local\Microsoft\Windows\UsrClass.dat" | Out-Null
Write-Host "Bypassing system requirements(on the system image):"
& 'reg' 'add' 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' '/v' 'SV1' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' '/v' 'SV2' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' '/v' 'SV1' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' '/v' 'SV2' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\LabConfig' '/v' 'BypassCPUCheck' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\LabConfig' '/v' 'BypassRAMCheck' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\LabConfig' '/v' 'BypassSecureBootCheck' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\LabConfig' '/v' 'BypassStorageCheck' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\LabConfig' '/v' 'BypassTPMCheck' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\MoSetup' '/v' 'AllowUpgradesWithUnsupportedTPMOrCPU' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null

# ============================================================================
# Dev Edition: Set to Best Performance with User-Selected Visual Effects
# Based on user's screenshot selection (5 items enabled)
# ============================================================================
Write-Host "Configuring visual effects (custom selection from user)..."

# Set to Custom mode (3 = Custom)
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' '/v' 'VisualFXSetting' '/t' 'REG_DWORD' '/d' '3' '/f' | Out-Null

# ============================================================================
# UserPreferencesMask bitmap explanation:
# This is an 8-byte (64-bit) value controlling visual effects
# Byte layout (little-endian): [0][1][2][3][4][5][6][7]
#
# User selected effects:
#   [x] Smooth edges of screen fonts (FontSmoothing - separate registry key)
#   [x] Show shadows under windows (DropShadow - Byte 0, Bit 2)
#   [x] Fade or slide menus into view (MenuFade - Byte 0, Bit 1)
#   [x] Show shadows under mouse pointer (CursorShadow - Byte 1, Bit 5)
#   [x] Use drop shadows for icon labels (ListviewShadow - separate registry key)
#
# UserPreferencesMask value: 9032038010000000
#   Byte 0 = 90: DropShadow(bit2) + MenuFade(bit1) + other bits
#   Byte 1 = 32: CursorShadow(bit5)
#   Byte 2 = 03: Base settings
#   Byte 3 = 80: Base settings
#   Bytes 4-7 = 10000000: Base settings
# ============================================================================

# Set UserPreferencesMask with user's selected effects
& 'reg' 'add' 'HKLM\zNTUSER\Control Panel\Desktop' '/v' 'UserPreferencesMask' '/t' 'REG_BINARY' '/d' '9032038010000000' '/f' | Out-Null

# 1. [x] Smooth edges of screen fonts
& 'reg' 'add' 'HKLM\zNTUSER\Control Panel\Desktop' '/v' 'FontSmoothing' '/t' 'REG_SZ' '/d' '2' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Control Panel\Desktop' '/v' 'FontSmoothingType' '/t' 'REG_DWORD' '/d' '2' '/f' | Out-Null

# 2. [x] Use drop shadows for icon labels on desktop
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'ListviewShadow' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null

# Disable all other visual effects explicitly
& 'reg' 'add' 'HKLM\zNTUSER\Control Panel\Desktop' '/v' 'DragFullWindows' '/t' 'REG_SZ' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Control Panel\Desktop\WindowMetrics' '/v' 'MinAnimate' '/t' 'REG_SZ' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'ListviewAlphaSelect' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'TaskbarAnimations' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'IconsOnly' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\DWM' '/v' 'EnableAeroPeek' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\DWM' '/v' 'AlwaysHibernateThumbnails' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null

# Enable window border visibility (ColorPrevalence=1 shows accent color on title bars and borders)
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\DWM' '/v' 'ColorPrevalence' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
# Ensure DWM composition is enabled (required for window shadows and effects)
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\DWM' '/v' 'Composition' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null

# Set VisualEffects individual settings
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\AnimateMinMax' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ComboBoxAnimation' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ControlAnimations' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\CursorShadow' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DragFullWindows' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DropShadow' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DWMAeroPeekEnabled' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DWMEnabled' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DWMSaveThumbnailEnabled' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\FontSmoothing' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ListBoxSmoothScrolling' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ListviewAlphaSelect' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ListviewShadow' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\MenuAnimation' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\SelectionFade' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\TaskbarAnimations' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ThumbnailsOrIcon' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\TooltipAnimation' '/v' 'DefaultApplied' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null

Write-Host "Visual effects configured:"
Write-Host "  [x] Smooth edges of screen fonts"
Write-Host "  [x] Show shadows under windows"
Write-Host "  [x] Fade or slide menus into view"
Write-Host "  [x] Show shadows under mouse pointer"
Write-Host "  [x] Use drop shadows for icon labels on desktop"

# ============================================================================
# Dev Edition: Configure File Explorer default view
# ============================================================================
Write-Host "Configuring File Explorer default view (Details, no grouping)..."

# Set default folder view to Details for all folders
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'FolderContentsInfoTip' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'ShowInfoTip' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null

# Disable grouping by default
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'GroupView' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null

# Set Details view as default for various folder types
# Generic folder
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' '/v' 'FolderType' '/t' 'REG_SZ' '/d' 'NotSpecified' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' '/v' 'LogicalViewMode' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' '/v' 'Mode' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' '/v' 'IconSize' '/t' 'REG_DWORD' '/d' '16' '/f' | Out-Null

# Disable grouping - set GroupBy to empty (Prop:System.Null)
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' '/v' 'GroupBy' '/t' 'REG_SZ' '/d' 'System.Null' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' '/v' 'GroupByDirection' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' '/v' 'GroupByKey:FMTID' '/t' 'REG_SZ' '/d' '{00000000-0000-0000-0000-000000000000}' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' '/v' 'GroupByKey:PID' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null

# Set sorting by Name (ascending)
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' '/v' 'Sort' '/t' 'REG_BINARY' '/d' '0000000000000000000000000000000001000000000000000000000000000000010000004e0061006d0065000000' '/f' | Out-Null

# Configure specific folder views
# Documents/General items folder
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\1\Shell' '/v' 'FolderType' '/t' 'REG_SZ' '/d' 'NotSpecified' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\1\Shell' '/v' 'LogicalViewMode' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\1\Shell' '/v' 'Mode' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\1\Shell' '/v' 'GroupBy' '/t' 'REG_SZ' '/d' 'System.Null' '/f' | Out-Null

# Computer/This PC
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\1\ComDlg' '/v' 'LogicalViewMode' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\1\ComDlg' '/v' 'Mode' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null

# Additional Explorer settings for better file browsing
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'Hidden' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'HideFileExt' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'ShowSuperHidden' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null

# Show seconds in taskbar clock
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'ShowSecondsInSystemClock' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null

# Hide taskbar search box (SearchboxTaskbarMode: 0=hidden, 1=icon, 2=box)
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Search' '/v' 'SearchboxTaskbarMode' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null

# Set taskbar alignment to left (0=left, 1=center)
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'TaskbarAl' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null

# Combine taskbar buttons when taskbar is full (TaskbarGlomLevel: 0=always, 1=when full, 2=never)
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'TaskbarGlomLevel' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null

Write-Host "File Explorer configured: Details view, no grouping, show hidden files, show file extensions, taskbar clock shows seconds!"
Write-Host "Taskbar configured: Search hidden, left-aligned, combine when full!"

Write-Host "Disabling Sponsored Apps:"
& 'reg' 'add' 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'OemPreInstalledAppsEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'PreInstalledAppsEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SilentInstalledAppsEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' '/v' 'DisableWindowsConsumerFeatures' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'ContentDeliveryAllowed' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start' '/v' 'ConfigureStartPins' '/t' 'REG_SZ' '/d' '{"pinnedList": [{}]}' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'ContentDeliveryAllowed' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'ContentDeliveryAllowed' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'FeatureManagementEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'OemPreInstalledAppsEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'PreInstalledAppsEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'PreInstalledAppsEverEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SilentInstalledAppsEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SoftLandingEnabled' '/t' 'REG_DWORD' '/d' '0' '/f'| Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SubscribedContentEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SubscribedContent-310093Enabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SubscribedContent-338388Enabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SubscribedContent-338389Enabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SubscribedContent-338393Enabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SubscribedContent-353694Enabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SubscribedContent-353696Enabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SubscribedContentEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SystemPaneSuggestionsEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\PushToInstall' '/v' 'DisablePushToInstall' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\MRT' '/v' 'DontOfferThroughWUAU' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'delete' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions' '/f' 2>&1 | Out-Null
& 'reg' 'delete' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps' '/f' 2>&1 | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' '/v' 'DisableConsumerAccountStateContent' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' '/v' 'DisableCloudOptimizedContent' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
Write-Host "Enabling Local Accounts on OOBE:"
& 'reg' 'add' 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' '/v' 'BypassNRO' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
Copy-Item -Path "$PSScriptRoot\autounattend-dev.xml" -Destination "$ScratchDisk\scratchdir\Windows\System32\Sysprep\autounattend.xml" -Force | Out-Null

# ============================================================================
# Dev Edition: Create README file on default user's desktop
# ============================================================================
Write-Host "Creating README file on default user desktop..."
$defaultDesktop = "$ScratchDisk\scratchdir\Users\Default\Desktop"
if (-not (Test-Path $defaultDesktop)) {
    New-Item -ItemType Directory -Force -Path $defaultDesktop | Out-Null
}
$readmePath = "$PSScriptRoot\README.ENGINEER.md"
if (Test-Path $readmePath) {
    Copy-Item -Path $readmePath -Destination "$defaultDesktop\tiny11-dev-README.md" -Force | Out-Null
    Write-Host "README file created on desktop!"
} else {
    # Create a basic readme if the full one doesn't exist
    $basicReadme = @"
# Tiny11 Dev Edition

Welcome to Tiny11 Dev Edition!

## Key Features

- Edge Browser and WebView2 retained
- Windows Update disabled by default (800-day pause on first boot)
- Desktop scripts provided to enable updates
- Traditional context menu (Windows 10 style)
- Developer shortcuts: CMD here / PowerShell here / PS Admin here
- File Explorer: Details view, show hidden files and extensions
- Best performance mode + 5 key visual effects

## Recommended

### Everything - Fast File Search
Windows Search is set to Manual. Recommend installing Everything:
https://www.voidtools.com/downloads/

Everything features:
- Millisecond search speed
- Very low resource usage
- Regex support
- Completely free

## More Info

See README.ENGINEER.md for full documentation.

Build Date: $(Get-Date -Format 'yyyy-MM-dd')
"@
    $basicReadme | Out-File -FilePath "$defaultDesktop\tiny11-dev-README.md" -Encoding UTF8
    Write-Host "Basic README file created on desktop!"
}

# ============================================================================
# Dev Edition: Desktop helper scripts (Enable/Resume Windows Update)
# ============================================================================
Write-Host "Creating Windows Update helper scripts on desktop..."

$enableWU = @"
# Requires Administrator privileges - Right-click and "Run as Administrator"
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'ERROR: This script requires Administrator privileges!' -ForegroundColor Red
    Write-Host 'Please right-click the script and select "Run with PowerShell as Administrator"' -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host 'Enabling Windows Update services (Manual)...'
Set-Service -Name wuauserv -StartupType Manual
Set-Service -Name UsoSvc -StartupType Manual
Set-Service -Name WaaSMedicSvc -StartupType Manual

Write-Host 'Allowing Windows Update (policies)...'
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -Type DWord -Value 1
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'AUOptions' -Type DWord -Value 2

Write-Host 'Done. If updates are paused, open Settings -> Windows Update -> Resume updates.' -ForegroundColor Green
pause
"@

$enableAndResumeWU = @"
# Requires Administrator privileges - Right-click and "Run as Administrator"
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'ERROR: This script requires Administrator privileges!' -ForegroundColor Red
    Write-Host 'Please right-click the script and select "Run with PowerShell as Administrator"' -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host 'Enabling Windows Update services (Manual)...'
Set-Service -Name wuauserv -StartupType Manual
Set-Service -Name UsoSvc -StartupType Manual
Set-Service -Name WaaSMedicSvc -StartupType Manual

Write-Host 'Allowing Windows Update (policies)...'
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -Type DWord -Value 0

Write-Host 'Clearing pause flags (resume updates)...'
$ux = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
if (Test-Path $ux) {
  Remove-ItemProperty -Path $ux -Name 'PauseFeatureUpdatesStartTime' -ErrorAction SilentlyContinue
  Remove-ItemProperty -Path $ux -Name 'PauseFeatureUpdatesEndTime' -ErrorAction SilentlyContinue
  Remove-ItemProperty -Path $ux -Name 'PauseQualityUpdatesStartTime' -ErrorAction SilentlyContinue
  Remove-ItemProperty -Path $ux -Name 'PauseQualityUpdatesEndTime' -ErrorAction SilentlyContinue
  Remove-ItemProperty -Path $ux -Name 'PauseUpdatesStartTime' -ErrorAction SilentlyContinue
  Remove-ItemProperty -Path $ux -Name 'PauseUpdatesExpiryTime' -ErrorAction SilentlyContinue
}

Write-Host 'Done. You can now Check for updates.' -ForegroundColor Green
pause
"@

$enableWU | Out-File -FilePath "$defaultDesktop\Enable-WindowsUpdate.ps1" -Encoding UTF8 -Force
$enableAndResumeWU | Out-File -FilePath "$defaultDesktop\Enable-And-Resume-WindowsUpdate.ps1" -Encoding UTF8 -Force
Write-Host "Windows Update helper scripts created on desktop!"

Write-Host "Disabling Reserved Storage:"
& 'reg' 'add' 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' '/v' 'ShippedWithReserves' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
Write-Host "Disabling BitLocker Device Encryption"
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Control\BitLocker' '/v' 'PreventDeviceEncryption' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
Write-Host "Disabling Chat icon:"
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat' '/v' 'ChatIcon' '/t' 'REG_DWORD' '/d' '3' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'TaskbarMn' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null

# ============================================================================
# Dev Edition: KEEP Edge registry entries
# The following Edge registry removal code is COMMENTED OUT
# ============================================================================
# Write-Host "Removing Edge related registries"
# reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f | Out-Null
# reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" /f | Out-Null

Write-Host "Disabling OneDrive folder backup"
& 'reg' 'add' "HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive" '/v' 'DisableFileSyncNGSC' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
Write-Host "Disabling Telemetry:"
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' '/v' 'Enabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy' '/v' 'TailoredExperiencesWithDiagnosticDataEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' '/v' 'HasAccepted' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Input\TIPC' '/v' 'Enabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' '/v' 'RestrictImplicitInkCollection' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' '/v' 'RestrictImplicitTextCollection' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore' '/v' 'HarvestContacts' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Personalization\Settings' '/v' 'AcceptedPrivacyPolicy' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' '/v' 'AllowTelemetry' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null
Write-Host "Prevents installation or DevHome and Outlook:"
& 'reg' 'add' 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate' '/v' 'workCompleted' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate' '/v' 'workCompleted' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'delete' 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' '/f' | Out-Null
& 'reg' 'delete' 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate' '/f' | Out-Null
Write-Host "Disabling Copilot"
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' '/v' 'TurnOffWindowsCopilot' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' '/v' 'HubsSidebarEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer' '/v' 'DisableSearchBoxSuggestions' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
Write-Host "Prevents installation of Teams:"
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Teams' '/v' 'DisableInstallation' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
Write-Host "Prevent installation of New Outlook":
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Mail' '/v' 'PreventRun' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null

# ============================================================================
# Dev Edition: Disable Windows Widgets (saves memory and network)
# ============================================================================
Write-Host "Disabling Windows Widgets..."
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Dsh' '/v' 'AllowNewsAndInterests' '/t' 'REG_DWORD' '/d' '0' '/f' 2>&1 | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests' '/v' 'value' '/t' 'REG_DWORD' '/d' '0' '/f' 2>&1 | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' '/v' 'TaskbarDa' '/t' 'REG_DWORD' '/d' '0' '/f' 2>&1 | Out-Null
# Note: Do NOT disable WpnService (Windows Push Notifications) 鈥?it affects system/app notifications.
Write-Host "Widgets disabled!"

# ============================================================================
# Dev Edition: Disable Search Highlights (reduces network requests)
# ============================================================================
Write-Host "Disabling Search Highlights..."
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search' '/v' 'EnableDynamicContentInWSB' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\SearchSettings' '/v' 'IsDynamicSearchBoxEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Feeds\DSB' '/v' 'ShowDynamicContent' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
Write-Host "Search Highlights disabled!"

# ============================================================================
# Dev Edition: Disable Xbox background services
# ============================================================================
Write-Host "Disabling Xbox background services..."
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\XblAuthManager' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\XblGameSave' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\XboxGipSvc' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\XboxNetApiSvc' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null
Write-Host "Xbox services disabled!"

# ============================================================================
# Dev Edition: Disable additional unnecessary services
# ============================================================================
Write-Host "Disabling additional unnecessary services..."

# Fax - rarely used in modern environments
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\Fax' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null

# Remote Registry - security risk, allows remote registry modification
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\RemoteRegistry' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null

# Geolocation Service - desktop dev machine doesn't need location
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\lfsvc' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null

# Retail Demo Service - only for store demos
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\RetailDemo' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null

# Connected User Experiences and Telemetry (DiagTrack) - main telemetry service
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\DiagTrack' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null

# Diagnostic Policy Service - problem detection (sends data to Microsoft)
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\DPS' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null

# Diagnostic Service Host - diagnostic components host
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\WdiServiceHost' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null

# Diagnostic System Host - system diagnostic host
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\WdiSystemHost' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null

Write-Host "Additional services disabled (Fax, RemoteRegistry, Geolocation, RetailDemo, Telemetry, Diagnostics)!"

# ============================================================================
# Dev Edition: Set Windows Search to Manual (recommend Everything)
# ============================================================================
Write-Host "Setting Windows Search service to Manual start..."
Write-Host "  (Recommend installing Everything from https://www.voidtools.com/ for faster search)"
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\WSearch' '/v' 'Start' '/t' 'REG_DWORD' '/d' '3' '/f' | Out-Null
# Also disable Windows Search indexing by default
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search' '/v' 'AllowCortana' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search' '/v' 'DisableWebSearch' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
Write-Host "Windows Search set to Manual. Install Everything for better file search!"

# ============================================================================
# Dev Edition: Disable Lock Screen Spotlight (weather, news, tips)
# ============================================================================
Write-Host "Disabling Lock Screen Spotlight and tips..."
# Disable Windows Spotlight on lock screen
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'RotatingLockScreenEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'RotatingLockScreenOverlayEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SubscribedContent-338387Enabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
# Disable fun facts, tips on lock screen
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' '/v' 'SubscribedContent-338389Enabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
# Disable lock screen tips and tricks
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' '/v' 'DisableWindowsSpotlightFeatures' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' '/v' 'DisableSoftLanding' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' '/v' 'DisableWindowsSpotlightOnActionCenter' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' '/v' 'DisableWindowsSpotlightWindowsWelcomeExperience' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
# Disable lock screen app notifications (weather/news etc. on lock screen)
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\System' '/v' 'DisableLockScreenAppNotifications' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
# Set lock screen to picture instead of Spotlight
& 'reg' 'add' 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Lock Screen' '/v' 'SlideshowEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
Write-Host "Lock Screen Spotlight disabled!"

# ============================================================================
# Dev Edition: Configure Edge browser settings (disable news feed)
# ============================================================================
Write-Host "Configuring Edge browser (disabling news feed on new tab)..."
# Disable Edge new tab page news feed
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' '/v' 'NewTabPageContentEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' '/v' 'NewTabPageQuickLinksEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' '/v' 'NewTabPageHideDefaultTopSites' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
# Disable Edge sidebar (Copilot, Discover, etc.)
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' '/v' 'HubsSidebarEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
# Disable Edge first run experience
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' '/v' 'HideFirstRunExperience' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
# Disable Edge collections and shopping features
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' '/v' 'EdgeCollectionsEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' '/v' 'EdgeShoppingAssistantEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
# Disable Edge follow feature
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' '/v' 'EdgeFollowEnabled' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
# Set new tab page to blank-ish
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' '/v' 'NewTabPageLocation' '/t' 'REG_SZ' '/d' 'about:blank' '/f' | Out-Null
Write-Host "Edge browser configured: News feed disabled, clean new tab page!"

# ============================================================================
# Dev Edition: Force Windows 11 to use traditional context menu
# Note: HKCU\Software\Classes is stored in UsrClass.dat, not ntuser.dat
#       So we write to zUSRCLASS (which is UsrClass.dat loaded as a hive)
# ============================================================================
Write-Host "Enabling traditional (Windows 10 style) context menu..."
& 'reg' 'add' 'HKLM\zUSRCLASS\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' '/ve' '/t' 'REG_SZ' '/d' '' '/f' | Out-Null
Write-Host "Traditional context menu enabled!"

# ============================================================================
# Dev Edition: Add context menu items for developers
# ============================================================================
Write-Host "Adding developer context menu items..."

# 1. CMD here - Directory Background (right-click on empty space)
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\Background\shell\cmdhere' '/ve' '/t' 'REG_SZ' '/d' 'CMD here' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\Background\shell\cmdhere' '/v' 'Icon' '/t' 'REG_SZ' '/d' 'cmd.exe' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\Background\shell\cmdhere\command' '/ve' '/t' 'REG_SZ' '/d' 'cmd.exe /s /k pushd "%V"' '/f' | Out-Null

# 2. CMD here - Directory/Folder (right-click on folder)
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\shell\cmdhere' '/ve' '/t' 'REG_SZ' '/d' 'CMD here' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\shell\cmdhere' '/v' 'Icon' '/t' 'REG_SZ' '/d' 'cmd.exe' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\shell\cmdhere\command' '/ve' '/t' 'REG_SZ' '/d' 'cmd.exe /s /k pushd "%V"' '/f' | Out-Null

# 3. PowerShell here - Directory Background
# Using -LiteralPath with single quotes handles Chinese, spaces, brackets, $ signs
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\Background\shell\pshere' '/ve' '/t' 'REG_SZ' '/d' 'PowerShell here' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\Background\shell\pshere' '/v' 'Icon' '/t' 'REG_SZ' '/d' 'powershell.exe' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\Background\shell\pshere\command' '/ve' '/t' 'REG_SZ' '/d' 'cmd /c pushd "%V" && start powershell -NoExit' '/f' | Out-Null

# 4. PowerShell here - Directory/Folder
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\shell\pshere' '/ve' '/t' 'REG_SZ' '/d' 'PowerShell here' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\shell\pshere' '/v' 'Icon' '/t' 'REG_SZ' '/d' 'powershell.exe' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\shell\pshere\command' '/ve' '/t' 'REG_SZ' '/d' 'cmd /c pushd "%V" && start powershell -NoExit' '/f' | Out-Null

# 5. PowerShell here (Admin) - Directory Background
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\Background\shell\psadmin' '/ve' '/t' 'REG_SZ' '/d' 'PowerShell here (Admin)' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\Background\shell\psadmin' '/v' 'Icon' '/t' 'REG_SZ' '/d' 'powershell.exe' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\Background\shell\psadmin' '/v' 'HasLUAShield' '/t' 'REG_SZ' '/d' '' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\Background\shell\psadmin\command' '/ve' '/t' 'REG_SZ' '/d' 'powershell.exe -Command \"Start-Process powershell -Verb RunAs -ArgumentList ''-NoExit -Command Set-Location -LiteralPath ''''%V''''''\"' '/f' | Out-Null

# 6. PowerShell here (Admin) - Directory/Folder
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\shell\psadmin' '/ve' '/t' 'REG_SZ' '/d' 'PowerShell here (Admin)' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\shell\psadmin' '/v' 'Icon' '/t' 'REG_SZ' '/d' 'powershell.exe' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\shell\psadmin' '/v' 'HasLUAShield' '/t' 'REG_SZ' '/d' '' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Classes\Directory\shell\psadmin\command' '/ve' '/t' 'REG_SZ' '/d' 'powershell.exe -Command \"Start-Process powershell -Verb RunAs -ArgumentList ''-NoExit -Command Set-Location -LiteralPath ''''%V''''''\"' '/f' | Out-Null

Write-Host "Context menu items added (CMD, PowerShell, PowerShell Admin)!"

# ============================================================================
# Dev Edition: Configure Windows Update behavior
# ============================================================================
Write-Host "Configuring Windows Update (policy-controlled; 800-day pause on first boot)..."

# Set Windows Update services to Manual (3) - allows Settings page to work properly
# (Disabled=4 causes "Error" in Settings page which confuses users)
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\wuauserv' '/v' 'Start' '/t' 'REG_DWORD' '/d' '3' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\UsoSvc' '/v' 'Start' '/t' 'REG_DWORD' '/d' '3' '/f' | Out-Null

# Use Group Policy to control updates (not disable service)
# AUOptions: 2 = Notify before download, 3 = Auto download notify install, 4 = Auto all
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' '/v' 'NoAutoUpdate' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' '/v' 'AUOptions' '/t' 'REG_DWORD' '/d' '2' '/f' | Out-Null

# Prevent automatic restart after updates (user must manually restart)
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' '/v' 'NoAutoRebootWithLoggedOnUsers' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' '/v' 'AlwaysAutoRebootAtScheduledTime' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null

# Create first-boot script to set Pause Updates for 800 days from INSTALL DATE (more accurate than build date)
$setupScriptsDir = "$ScratchDisk\scratchdir\Windows\Setup\Scripts"
New-Item -ItemType Directory -Force -Path $setupScriptsDir | Out-Null

$firstBootPs1 = @"
`$ErrorActionPreference = 'SilentlyContinue'

function Set-WUPause800Days {
    `$start = (Get-Date).ToString('yyyy-MM-ddT00:00:00Z')
    `$end = (Get-Date).AddDays(800).ToString('yyyy-MM-ddT00:00:00Z')
    Write-Output \"[Tiny11 Engineer] Setting Windows Update pause: `$start -> `$end\"

    New-Item -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Force | Out-Null
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseFeatureUpdatesStartTime' -Type String -Value `$start
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseFeatureUpdatesEndTime' -Type String -Value `$end
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseQualityUpdatesStartTime' -Type String -Value `$start
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseQualityUpdatesEndTime' -Type String -Value `$end
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseUpdatesStartTime' -Type String -Value `$start
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseUpdatesExpiryTime' -Type String -Value `$end
}

Set-WUPause800Days
"@

$firstBootPs1Path = Join-Path $setupScriptsDir 'tiny11-dev-FirstBoot.ps1'
$firstBootPs1 | Out-File -FilePath $firstBootPs1Path -Encoding UTF8 -Force

$setupCompleteCmd = @"
@echo off
REM Tiny11 Dev Edition - First boot configuration
powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%WINDIR%\Setup\Scripts\tiny11-dev-FirstBoot.ps1\"
exit /b 0
"@

$setupCompletePath = Join-Path $setupScriptsDir 'SetupComplete.cmd'
$setupCompleteCmd | Out-File -FilePath $setupCompletePath -Encoding ASCII -Force

# Dev Edition: KEEP driver updates enabled for hardware compatibility
# The following lines are COMMENTED OUT to preserve online driver installation
# & 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' '/v' 'ExcludeWUDriversInQualityUpdate' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
# & 'reg' 'add' 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching' '/v' 'SearchOrderConfig' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
Write-Host "Online driver installation: Enabled (for hardware compatibility)"

# Disable Windows Update Medic Service (prevents forced updates)
& 'reg' 'add' 'HKLM\zSYSTEM\ControlSet001\Services\WaaSMedicSvc' '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null

# Additional settings to prevent unexpected restarts
& 'reg' 'add' 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\UX\Settings' '/v' 'ActiveHoursStart' '/t' 'REG_DWORD' '/d' '8' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\UX\Settings' '/v' 'ActiveHoursEnd' '/t' 'REG_DWORD' '/d' '20' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\UX\Settings' '/v' 'IsExpedited' '/t' 'REG_DWORD' '/d' '0' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\UX\Settings' '/v' 'SmartActiveHoursState' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null

# Notify user before downloading updates
& 'reg' 'add' 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' '/v' 'AUOptions' '/t' 'REG_DWORD' '/d' '2' '/f' | Out-Null

Write-Host "Windows Update configured: DISABLED by default; first boot will set 800-day pause. Use desktop scripts to enable when needed."

$tasksPath = "$ScratchDisk\scratchdir\Windows\System32\Tasks"

Write-Host "Deleting scheduled task definition files..."

# Application Compatibility Appraiser
Remove-Item -Path "$tasksPath\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -Force -ErrorAction SilentlyContinue

# Customer Experience Improvement Program (removes the entire folder and all tasks within it)
Remove-Item -Path "$tasksPath\Microsoft\Windows\Customer Experience Improvement Program" -Recurse -Force -ErrorAction SilentlyContinue

# Program Data Updater
Remove-Item -Path "$tasksPath\Microsoft\Windows\Application Experience\ProgramDataUpdater" -Force -ErrorAction SilentlyContinue

# Chkdsk Proxy
Remove-Item -Path "$tasksPath\Microsoft\Windows\Chkdsk\Proxy" -Force -ErrorAction SilentlyContinue

# Windows Error Reporting (QueueReporting)
Remove-Item -Path "$tasksPath\Microsoft\Windows\Windows Error Reporting\QueueReporting" -Force -ErrorAction SilentlyContinue

Write-Host "Task files have been deleted."

# ============================================================================
# Dev Edition: Copy Tiny11-Dev-Toolkit to default desktop
# ============================================================================
Write-Host "Copying Tiny11-Dev-Toolkit to default desktop..."

$toolkitSource = "$PSScriptRoot\Tiny11-Dev-Toolkit"
$defaultDesktop = "$ScratchDisk\scratchdir\Users\Default\Desktop"
$toolkitDest = "$defaultDesktop\Tiny11-Dev-Toolkit"

if (Test-Path $toolkitSource) {
    # Create default desktop if not exists
    New-Item -ItemType Directory -Force -Path $defaultDesktop | Out-Null
    
    # Copy toolkit folder
    Copy-Item -Path $toolkitSource -Destination $defaultDesktop -Recurse -Force
    
    # Copy the script itself into the toolkit (dynamically gets current script path)
    $currentScript = $MyInvocation.MyCommand.Path
    if (Test-Path $currentScript) {
        Copy-Item -Path $currentScript -Destination $toolkitDest -Force
    } else {
        Write-Host "Warning: Could not determine current script path to copy." -ForegroundColor Yellow
    }
    
    # Update README.md with build info
    $readmePath = "$toolkitDest\README.md"
    if (Test-Path $readmePath) {
        $readmeContent = Get-Content $readmePath -Raw
        $buildDate = Get-Date -Format "yyyy-MM-dd HH:mm"
        # Try to get original ISO name from drive label
        try {
            $volume = Get-Volume -DriveLetter ($DriveLetter -replace ':','') -ErrorAction SilentlyContinue
            $isoLabel = if ($volume) { $volume.FileSystemLabel } else { "Windows 11" }
        } catch { $isoLabel = "Windows 11" }
        # Replace unique placeholders
        $readmeContent = $readmeContent -replace '\[ISO_NAME_PLACEHOLDER\]', $isoLabel
        $readmeContent = $readmeContent -replace '\[BUILD_DATE_PLACEHOLDER\]', $buildDate
        $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8 -Force
    }
    
    Write-Host "Tiny11-Dev-Toolkit copied to desktop successfully!"
} else {
    Write-Host "Warning: Tiny11-Dev-Toolkit folder not found at $toolkitSource"
    Write-Host "Desktop toolkit will not be included."
}

Write-Host "Unmounting Registry..."
# Force garbage collection to release any file handles
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
Start-Sleep -Seconds 2

# Unload registry hives with retry logic
$hives = @('zCOMPONENTS', 'zDEFAULT', 'zNTUSER', 'zSOFTWARE', 'zSYSTEM', 'zUSRCLASS')
foreach ($hive in $hives) {
    $retryCount = 0
    $maxRetries = 3
    do {
        $result = reg unload "HKLM\$hive" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Unloaded $hive"
            break
        }
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "  Retry $retryCount for $hive..."
            [gc]::Collect()
            [gc]::WaitForPendingFinalizers()
            Start-Sleep -Seconds 2
        }
    } while ($retryCount -lt $maxRetries)
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  WARNING: Could not unload $hive (may already be unloaded)" -ForegroundColor Yellow
    }
}
Write-Host "Cleaning up image..."
Repair-WindowsImage -Path $ScratchDisk\scratchdir -StartComponentCleanup -ResetBase
Write-Host "Cleanup complete."
Write-Host ' '
Write-Host "Unmounting image..."
Dismount-WindowsImage -Path $ScratchDisk\scratchdir -Save
Write-Host "Exporting image (Index: $index)..."
Write-Host "Source: $ScratchDisk\tiny11\sources\install.wim"
Write-Host "Destination: $ScratchDisk\tiny11\sources\install2.wim"

# Check source file exists and has content
$sourceWim = "$ScratchDisk\tiny11\sources\install.wim"
if (-not (Test-Path $sourceWim)) {
    Write-Error "ERROR: Source install.wim not found!"
    exit 1
}
$sourceSize = (Get-Item $sourceWim).Length
Write-Host "Source install.wim size: $([math]::Round($sourceSize/1GB, 2)) GB"
if ($sourceSize -lt 1GB) {
    Write-Error "ERROR: Source install.wim is too small ($sourceSize bytes). Something went wrong during mounting."
    exit 1
}

# Export with error checking
Write-Host "Running DISM Export-Image..."
try {
    & Dism.exe /Export-Image /SourceImageFile:"$ScratchDisk\tiny11\sources\install.wim" /SourceIndex:$index /DestinationImageFile:"$ScratchDisk\tiny11\sources\install2.wim" /Compress:max
    $dismExitCode = $LASTEXITCODE
    Write-Host "DISM Exit Code: $dismExitCode"
    if ($dismExitCode -ne 0) {
        Write-Error "ERROR: DISM Export failed with exit code $dismExitCode"
        Write-Host "Keeping original install.wim"
        Read-Host "Press Enter to exit"
        exit 1
    }
} catch {
    Write-Error "ERROR: Exception during DISM Export: $_"
    Write-Host "Keeping original install.wim"
    Read-Host "Press Enter to exit"
    exit 1
}

# Verify exported file size
$exportedWim = "$ScratchDisk\tiny11\sources\install2.wim"
if (-not (Test-Path $exportedWim)) {
    Write-Error "ERROR: Exported install2.wim not found!"
    exit 1
}
$exportedSize = (Get-Item $exportedWim).Length
Write-Host "Exported install2.wim size: $([math]::Round($exportedSize/1GB, 2)) GB"
if ($exportedSize -lt 1GB) {
    Write-Error "ERROR: Exported image is too small ($exportedSize bytes). Export may have failed."
    Write-Host "Keeping original install.wim for debugging"
    exit 1
}

Remove-Item -Path "$ScratchDisk\tiny11\sources\install.wim" -Force | Out-Null
Rename-Item -Path "$ScratchDisk\tiny11\sources\install2.wim" -NewName "install.wim" | Out-Null
Write-Host "Windows image completed. Continuing with boot.wim."
Start-Sleep -Seconds 2
Clear-Host
Write-Host "Mounting boot image:"
$wimFilePath = "$ScratchDisk\tiny11\sources\boot.wim" 
& takeown "/F" $wimFilePath | Out-Null
& icacls $wimFilePath "/grant" "$($adminGroup.Value):(F)"
Set-ItemProperty -Path $wimFilePath -Name IsReadOnly -Value $false
Mount-WindowsImage -ImagePath $ScratchDisk\tiny11\sources\boot.wim -Index 2 -Path $ScratchDisk\scratchdir
Write-Host "Loading registry..."
reg load HKLM\zSOFTWARE $ScratchDisk\scratchdir\Windows\System32\config\SOFTWARE
reg load HKLM\zSYSTEM $ScratchDisk\scratchdir\Windows\System32\config\SYSTEM
Write-Host "Bypassing system requirements(on the setup image):"
# Only SYSTEM hive modifications are needed for WinPE/Setup bypass
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\LabConfig' '/v' 'BypassCPUCheck' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\LabConfig' '/v' 'BypassRAMCheck' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\LabConfig' '/v' 'BypassSecureBootCheck' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\LabConfig' '/v' 'BypassStorageCheck' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\LabConfig' '/v' 'BypassTPMCheck' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
& 'reg' 'add' 'HKLM\zSYSTEM\Setup\MoSetup' '/v' 'AllowUpgradesWithUnsupportedTPMOrCPU' '/t' 'REG_DWORD' '/d' '1' '/f' | Out-Null
Write-Host "Tweaking complete!"
Write-Host "Unmounting Registry..."
reg unload HKLM\zSOFTWARE | Out-Null
reg unload HKLM\zSYSTEM | Out-Null
Write-Host "Unmounting image..."
Dismount-WindowsImage -Path $ScratchDisk\scratchdir -Save
Clear-Host
Write-Host "The tiny11 Dev Edition image is now completed. Proceeding with the making of the ISO..."
Write-Host "Copying unattended file for bypassing MS account on OOBE..."
Copy-Item -Path "$PSScriptRoot\autounattend-dev.xml" -Destination "$ScratchDisk\tiny11\autounattend.xml" -Force | Out-Null
Write-Host "Creating ISO image..."
$ADKDepTools = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$hostarchitecture\Oscdimg"
$localOSCDIMGPath = "$PSScriptRoot\oscdimg.exe"

if ([System.IO.Directory]::Exists($ADKDepTools)) {
    Write-Host "Will be using oscdimg.exe from system ADK."
    $OSCDIMG = "$ADKDepTools\oscdimg.exe"
} else {
    Write-Host "ADK folder not found. Will be using bundled oscdimg.exe."
    
    $url = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/3D44737265000/oscdimg.exe"

    if (-not (Test-Path -Path $localOSCDIMGPath)) {
        Write-Host "Downloading oscdimg.exe..."
        Invoke-WebRequest -Uri $url -OutFile $localOSCDIMGPath

        if (Test-Path $localOSCDIMGPath) {
            Write-Host "oscdimg.exe downloaded successfully."
        } else {
            Write-Error "Failed to download oscdimg.exe."
            exit 1
        }
    } else {
        Write-Host "oscdimg.exe already exists locally."
    }

    $OSCDIMG = $localOSCDIMGPath
}

# ISO filename generated at script start
& "$OSCDIMG" '-m' '-o' '-u2' '-udfver102' "-bootdata:2#p0,e,b$ScratchDisk\tiny11\boot\etfsboot.com#pEF,e,b$ScratchDisk\tiny11\efi\microsoft\boot\efisys.bin" "$ScratchDisk\tiny11" "$PSScriptRoot\$isoFileName"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Green
Write-Host "  ISO created: $isoFileName" -ForegroundColor Green
Write-Host "  Location: $PSScriptRoot\$isoFileName" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green
Write-Host ""

# Finishing up
Write-Host "Creation completed! Press any key to perform cleanup..."
# Pause before cleanup
cmd /c pause
Write-Host "Performing Cleanup..."
Remove-Item -Path "$ScratchDisk\tiny11" -Recurse -Force | Out-Null
Remove-Item -Path "$ScratchDisk\scratchdir" -Recurse -Force | Out-Null

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Build complete!" -ForegroundColor Cyan
Write-Host "  Output ISO: $PSScriptRoot\$isoFileName" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan

# Stop the transcript
Stop-Transcript

Write-Host ""
cmd /c pause
exit

