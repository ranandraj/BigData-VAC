$ErrorActionPreference='Continue'; Write-Host '=== AR INFOTEK v13 PRE-FLIGHT ===' -ForegroundColor Cyan
$docker=Get-Command docker.exe -ErrorAction SilentlyContinue; $compose=Get-Command docker-compose.exe -ErrorAction SilentlyContinue
if($docker){Write-Host "PASS docker.exe: $($docker.Source)" -ForegroundColor Green}else{Write-Host 'FAIL docker.exe missing from PATH' -ForegroundColor Red}
if($compose){Write-Host "PASS docker-compose.exe: $($compose.Source)" -ForegroundColor Green}else{Write-Host 'FAIL docker-compose.exe missing from PATH' -ForegroundColor Red}
Write-Host "ExecutionPolicy LocalMachine: $((Get-ExecutionPolicy -Scope LocalMachine))"
$wsl=Join-Path $env:WINDIR 'System32\wsl.exe'; if(Test-Path $wsl){& $wsl --status}else{Write-Host 'WARN WSL executable not found'}
if($docker){& docker.exe --version}; if($compose){& docker-compose.exe version}; if($docker){docker.exe info *> $null; if($LASTEXITCODE -eq 0){Write-Host 'PASS Docker Engine running' -ForegroundColor Green}else{Write-Host 'WARN Docker Engine not running' -ForegroundColor Yellow}}
