$ErrorActionPreference="Continue"
Set-Location "$PSScriptRoot\.."
Write-Host "=== BIG DATA LAB RESET ===" -ForegroundColor Yellow
Write-Host "This removes containers AND all Big Data lab volumes/data." -ForegroundColor Red
$answer = Read-Host "Type RESET to continue"
if ($answer -ne "RESET") { Write-Host "Cancelled."; exit 0 }
docker compose down -v --remove-orphans
docker system prune -f
Write-Host "Lab reset completed. Run INSTALL-DAY1.ps1 to rebuild Day 1." -ForegroundColor Green
