$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\..\.."
Write-Host '=== SESSION 6: START DEBEZIUM CDC ===' -ForegroundColor Cyan
docker compose up -d postgres kafka debezium
for($i=0;$i -lt 40;$i++){ try { Invoke-RestMethod http://localhost:8083/connectors 2>$null | Out-Null; $ok=$true } catch {$ok=$false}; if($ok){break}; Start-Sleep 2 }
if(-not $ok){throw 'Debezium REST API did not become ready.'}
Write-Host 'Debezium REST API is ready.' -ForegroundColor Green
Write-Host 'Run REGISTER-DEBEZIUM.ps1 next.' -ForegroundColor Yellow
