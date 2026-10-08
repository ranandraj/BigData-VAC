[CmdletBinding()]
param(
    [switch]$SkipWslDistro
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Relaunch-Elevated {
    $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"{0}"' -f $PSCommandPath))
    if ($SkipWslDistro) { $args += '-SkipWslDistro' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList ($args -join ' ')
    exit 0
}

if (-not (Test-IsAdmin)) {
    Write-Host 'Administrator permission is required. Requesting elevation...' -ForegroundColor Yellow
    Relaunch-Elevated
}

Write-Host "`n=== AR INFOTEK - WINDOWS / WSL PREREQUISITE SETUP ===" -ForegroundColor Cyan

$os = Get-CimInstance Win32_OperatingSystem
$build = [int]$os.BuildNumber
if ($build -lt 19041) {
    throw "Windows build $build is not supported. Windows 10 2004/build 19041 or newer is required."
}
if (-not [Environment]::Is64BitOperatingSystem) {
    throw '64-bit Windows is required.'
}

Write-Host "Windows: $($os.Caption) build $build" -ForegroundColor Gray

function Get-FeatureState([string]$Name) {
    try {
        return (Get-WindowsOptionalFeature -Online -FeatureName $Name -ErrorAction Stop).State
    } catch {
        return 'Unknown'
    }
}

function Enable-WindowsFeatureSafe([string]$Name, [string]$FriendlyName) {
    $state = Get-FeatureState $Name
    if ($state -eq 'Enabled') {
        Write-Host "[OK] $FriendlyName already enabled" -ForegroundColor Green
        return $false
    }

    Write-Host "[SETUP] Enabling $FriendlyName ..." -ForegroundColor Cyan
    & dism.exe /online /enable-feature /featurename:$Name /all /norestart
    $code = $LASTEXITCODE
    if ($code -notin @(0,3010)) {
        throw "DISM failed for $FriendlyName with exit code $code. Run Windows Update and retry."
    }
    Write-Host "[OK] $FriendlyName enabled" -ForegroundColor Green
    return ($code -eq 3010)
}

$rebootRequired = $false
$rebootRequired = (Enable-WindowsFeatureSafe 'Microsoft-Windows-Subsystem-Linux' 'Windows Subsystem for Linux') -or $rebootRequired
$rebootRequired = (Enable-WindowsFeatureSafe 'VirtualMachinePlatform' 'Virtual Machine Platform') -or $rebootRequired

# Make sure the Windows hypervisor is allowed to start. This does not install Hyper-V itself.
Write-Host '[SETUP] Configuring hypervisor launch mode...' -ForegroundColor Cyan
& bcdedit.exe /set hypervisorlaunchtype auto | Out-Host
if ($LASTEXITCODE -eq 0) {
    Write-Host '[OK] Hypervisor launch mode = auto' -ForegroundColor Green
} else {
    Write-Host '[WARN] Could not set hypervisorlaunchtype automatically.' -ForegroundColor Yellow
}

# Check firmware virtualization. This cannot be enabled by Windows if BIOS/UEFI has it disabled.
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
if ($cpu.VirtualizationFirmwareEnabled) {
    Write-Host '[OK] CPU virtualization is enabled in firmware' -ForegroundColor Green
} else {
    $wslRuntimeWorks = $false
    $wslProbe = Join-Path $env:WINDIR 'System32\wsl.exe'
    if (Test-Path $wslProbe) {
        & $wslProbe --status *> $null
        $wslRuntimeWorks = ($LASTEXITCODE -eq 0)
    }
    if ($wslRuntimeWorks) {
        Write-Host '[WARN] Windows did not report firmware virtualization through WMI, but WSL is operational.' -ForegroundColor Yellow
        Write-Host 'The installer will continue. If Docker/WSL later fails to start, verify Intel VT-x/AMD-V/SVM in BIOS/UEFI.' -ForegroundColor Yellow
    } else {
        Write-Host '[ACTION REQUIRED] CPU virtualization is disabled or not reported and WSL is not operational.' -ForegroundColor Red
        Write-Host 'Enable Intel VT-x/AMD-V/SVM in BIOS/UEFI. Windows cannot turn firmware virtualization on.' -ForegroundColor Yellow
    }
}

# Refresh feature state after DISM.
$wslState = Get-FeatureState 'Microsoft-Windows-Subsystem-Linux'
$vmpState = Get-FeatureState 'VirtualMachinePlatform'
Write-Host "WSL feature state: $wslState" -ForegroundColor Gray
Write-Host "Virtual Machine Platform state: $vmpState" -ForegroundColor Gray

if ($wslState -ne 'Enabled' -or $vmpState -ne 'Enabled') {
    $rebootRequired = $true
}

# wsl.exe is normally present in System32. If the feature has just been enabled, it may only be usable after restart.
$wslCmd = Join-Path $env:WINDIR 'System32\wsl.exe'
if (Test-Path $wslCmd) {
    Write-Host '[OK] wsl.exe found' -ForegroundColor Green
} else {
    Write-Host '[WARN] wsl.exe is not available yet. A Windows restart may be required.' -ForegroundColor Yellow
    $rebootRequired = $true
}

if (-not $rebootRequired -and (Test-Path $wslCmd)) {
    Write-Host '[SETUP] Updating WSL...' -ForegroundColor Cyan
    & $wslCmd --update --web-download
    if ($LASTEXITCODE -ne 0) {
        Write-Host '[WARN] WSL update returned a non-zero code. Continuing with installed WSL components.' -ForegroundColor Yellow
    }

    & $wslCmd --set-default-version 2
    if ($LASTEXITCODE -eq 0) {
        Write-Host '[OK] WSL default version set to 2' -ForegroundColor Green
    } else {
        Write-Host '[WARN] Could not set WSL default version yet. Restart and rerun this script.' -ForegroundColor Yellow
        $rebootRequired = $true
    }

    if (-not $SkipWslDistro) {
        $distros = & $wslCmd --list --quiet 2>$null
        if (-not $distros -or ($distros -join '') -match 'No installed distributions') {
            Write-Host '[SETUP] Installing Ubuntu WSL distribution for the lab host...' -ForegroundColor Cyan
            & $wslCmd --install -d Ubuntu --web-download
            if ($LASTEXITCODE -eq 0) {
                Write-Host '[OK] Ubuntu WSL distribution installed.' -ForegroundColor Green
            } else {
                Write-Host '[WARN] Ubuntu distribution installation did not complete. Docker Desktop can still use WSL 2 after restart.' -ForegroundColor Yellow
            }
        } else {
            Write-Host '[OK] A WSL distribution is already installed' -ForegroundColor Green
        }
    }
}

# Detect common pending-reboot indicators.
$pending = $false
$keys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
)
foreach ($key in $keys) {
    if (Test-Path $key) { $pending = $true }
}
if ($pending) { $rebootRequired = $true }

Write-Host "`n=== WINDOWS PREREQUISITE RESULT ===" -ForegroundColor Cyan
if ($rebootRequired) {
    Write-Host '[REBOOT REQUIRED] Restart Windows before continuing.' -ForegroundColor Yellow
    Write-Host 'After restart, run INSTALL-BIGDATA-LAB.ps1 again.' -ForegroundColor Yellow
    exit 3010
}

Write-Host '[READY] WSL 2 and Virtual Machine Platform prerequisites are ready.' -ForegroundColor Green
exit 0
