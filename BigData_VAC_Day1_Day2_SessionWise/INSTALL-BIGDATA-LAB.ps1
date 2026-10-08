[CmdletBinding()]
param([switch]$SkipWslDistro)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Set-Location $PSScriptRoot

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host 'Administrator permission is required. Requesting elevation...' -ForegroundColor Yellow
    $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"{0}"' -f $PSCommandPath))
    if ($SkipWslDistro) { $args += '-SkipWslDistro' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList ($args -join ' ')
    exit 0
}

Write-Host "=== AR INFOTEK COMPLETE BIG DATA LAB INSTALLER ===" -ForegroundColor Cyan
Write-Host 'This installer configures Windows/WSL first, then Docker, then Day 1.' -ForegroundColor Gray

$setup = Join-Path $PSScriptRoot 'scripts\SETUP-WINDOWS-PREREQUISITES.ps1'
$setupArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$setup)
if ($SkipWslDistro) { $setupArgs += '-SkipWslDistro' }
& powershell.exe @setupArgs
$setupCode = $LASTEXITCODE

if ($setupCode -eq 3010) {
    Write-Host "`nWindows restart is required before Docker/Big Data services can be installed." -ForegroundColor Yellow
    $answer = Read-Host 'Restart this computer now? (Y/N)'
    if ($answer -match '^[Yy]$') {
        Write-Host 'Restarting Windows...' -ForegroundColor Yellow
        shutdown.exe /r /t 5 /c 'AR INFOTEK Big Data Lab prerequisite setup requires a restart.'
        exit 0
    }
    Write-Host 'Please restart Windows, then run INSTALL-BIGDATA-LAB.ps1 again.' -ForegroundColor Yellow
    exit 3010
}
if ($setupCode -ne 0) {
    throw "Windows prerequisite setup failed with exit code $setupCode."
}

$docker = Get-Command docker.exe -ErrorAction SilentlyContinue
if (-not $docker) {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'Docker is not installed and winget.exe is unavailable. Install Docker Desktop manually, then rerun this installer.'
    }

    Write-Host "`n[SETUP] Installing Docker Desktop with winget..." -ForegroundColor Cyan
    & winget.exe install --id Docker.DockerDesktop --exact --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Desktop installation failed with exit code $LASTEXITCODE."
    }

    $docker = Get-Command docker.exe -ErrorAction SilentlyContinue
    if (-not $docker) {
        Write-Host '[ACTION REQUIRED] Docker Desktop was installed, but docker.exe is not visible in this PowerShell session.' -ForegroundColor Yellow
        Write-Host 'Start Docker Desktop, wait until it reports Running, then rerun INSTALL-BIGDATA-LAB.ps1.' -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`n[CHECK] Docker CLI" -ForegroundColor Cyan
docker --version
docker compose version

Write-Host '[CHECK] Docker Engine' -ForegroundColor Cyan
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Docker Desktop is installed but the engine is not running.' -ForegroundColor Yellow
    Write-Host 'Start Docker Desktop and wait until it is fully running, then rerun this installer.' -ForegroundColor Yellow
    exit 0
}

Write-Host "`n[SETUP] Starting Day 1 services..." -ForegroundColor Cyan
& "$PSScriptRoot\scripts\INSTALL-DAY1.ps1"
if ($LASTEXITCODE -ne 0) {
    throw "Day 1 installation failed with exit code $LASTEXITCODE."
}

Write-Host "`n=== INSTALLATION COMPLETE ===" -ForegroundColor Green
Write-Host 'Day 1 is ready.' -ForegroundColor Green
Write-Host 'After Day 1: .\scripts\STOP-DAY1.ps1' -ForegroundColor Gray
Write-Host 'For Day 2:    .\scripts\INSTALL-DAY2.ps1' -ForegroundColor Gray
