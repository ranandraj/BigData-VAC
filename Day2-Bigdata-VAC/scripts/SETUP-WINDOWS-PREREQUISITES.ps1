[CmdletBinding()]
param([switch]$SkipWsl)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
function Test-Admin { $id=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=New-Object Security.Principal.WindowsPrincipal($id); $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
if(-not (Test-Admin)){Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',('"{0}"' -f $PSCommandPath); exit 0}
Write-Host '=== AR INFOTEK v13 Windows prerequisites ===' -ForegroundColor Cyan
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
Write-Host '[OK] PowerShell LocalMachine execution policy = Bypass' -ForegroundColor Green
function Ensure-WindowsFeature([string]$Name,[string]$Label){
  $f=Get-WindowsOptionalFeature -Online -FeatureName $Name -ErrorAction Stop
  if($f.State -eq 'Enabled') { Write-Host "[OK] $Label already enabled - skipping" -ForegroundColor Green; return }
  Write-Host "[ACTION] Enabling $Label..." -ForegroundColor Cyan
  Enable-WindowsOptionalFeature -Online -FeatureName $Name -All -NoRestart | Out-Host
}
if(-not $SkipWsl){
  Ensure-WindowsFeature 'Microsoft-Windows-Subsystem-Linux' 'WSL'
  Ensure-WindowsFeature 'VirtualMachinePlatform' 'Virtual Machine Platform'
  $bcd=& (Join-Path $env:WINDIR 'System32\bcdedit.exe') /enum '{current}' 2>$null | Out-String
  if($bcd -match 'hypervisorlaunchtype\s+Auto'){Write-Host '[OK] Hypervisor launch type already Auto - skipping' -ForegroundColor Green}
  else { & (Join-Path $env:WINDIR 'System32\bcdedit.exe') /set hypervisorlaunchtype auto | Out-Host }
  $wsl=Join-Path $env:WINDIR 'System32\wsl.exe'
  if(Test-Path $wsl){
    & $wsl --status | Out-Host
    & $wsl --set-default-version 2 | Out-Host
  }
}
function Add-MachinePath([string]$Dir){
  if(-not (Test-Path $Dir)){return}
  $old=[Environment]::GetEnvironmentVariable('Path','Machine'); $parts=@($old -split ';' | Where-Object {$_ -and $_.Trim()});
  if(-not ($parts | Where-Object { $_.TrimEnd('\\') -ieq $Dir.TrimEnd('\\') })){ [Environment]::SetEnvironmentVariable('Path', (($parts+$Dir) -join ';'),'Machine'); Write-Host "[PATH] Added $Dir" -ForegroundColor Green }
  if(-not (($env:Path -split ';') | Where-Object { $_.TrimEnd('\\') -ieq $Dir.TrimEnd('\\') })){ $env:Path += ";$Dir" }
}
$dockerCandidates=@("$env:ProgramFiles\Docker\Docker\resources\bin","$env:LOCALAPPDATA\Programs\DockerDesktop\resources\bin","$env:ProgramFiles\Docker\resources\bin")
foreach($d in $dockerCandidates){ Add-MachinePath $d }
$dockerExe=(Get-Command docker.exe -ErrorAction SilentlyContinue).Source
if(-not $dockerExe){foreach($d in $dockerCandidates){if(Test-Path (Join-Path $d 'docker.exe')){$dockerExe=Join-Path $d 'docker.exe';break}}}
if(-not $dockerExe){Write-Host '[ACTION REQUIRED] Docker Desktop is not installed. Install Docker Desktop for Windows with the WSL2 backend, start it, then rerun this script.' -ForegroundColor Yellow; Write-Host 'Official installer: https://www.docker.com/products/docker-desktop/' -ForegroundColor Gray; exit 20}
$composeExe=(Get-Command docker-compose.exe -ErrorAction SilentlyContinue).Source
if(-not $composeExe){foreach($d in $dockerCandidates){if(Test-Path (Join-Path $d 'docker-compose.exe')){$composeExe=Join-Path $d 'docker-compose.exe';Add-MachinePath $d;break}}}
if(-not $composeExe){
  $dir="$env:ProgramFiles\Docker"; New-Item -ItemType Directory -Force $dir | Out-Null
  $url='https://github.com/docker/compose/releases/download/v5.6.0/docker-compose-windows-x86_64.exe'; $dest=Join-Path $dir 'docker-compose.exe'
  if(Test-Path $dest){$composeExe=$dest; Write-Host '[OK] docker-compose.exe already installed - skipping download' -ForegroundColor Green}
  else {Write-Host '[SETUP] Downloading Docker Compose standalone executable v5.6.0...' -ForegroundColor Cyan; Start-BitsTransfer -Source $url -Destination $dest; Add-MachinePath $dir; $composeExe=$dest}
}
if(-not $composeExe){throw 'docker-compose.exe was not found or installed.'}
Write-Host "[OK] docker.exe = $dockerExe" -ForegroundColor Green
Write-Host "[OK] docker-compose.exe = $composeExe" -ForegroundColor Green
& $dockerExe --version; & $composeExe version
Write-Host 'WSL2 is used only as Docker Desktop backend. No Ubuntu WSL distribution is required.' -ForegroundColor Gray
exit 0
