$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\..\.."
Write-Host '=== SESSION 4: START NIFI ===' -ForegroundColor Cyan
docker compose up -d nifi
Write-Host 'NiFi: https://localhost:8443/nifi' -ForegroundColor Green
Write-Host 'Username: admin   Password: BigDataLab123!' -ForegroundColor Yellow
