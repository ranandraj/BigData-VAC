$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\..\.."
Write-Host '=== SESSION 7: START FLINK ===' -ForegroundColor Cyan
docker compose build flink-jobmanager flink-taskmanager
docker compose up -d flink-jobmanager flink-taskmanager
for($i=0;$i -lt 40;$i++){ try { Invoke-RestMethod http://localhost:8081/overview 2>$null | Out-Null; $ok=$true } catch {$ok=$false}; if($ok){break}; Start-Sleep 2 }
if(-not $ok){throw 'Flink REST API did not become ready.'}
Write-Host 'Flink is ready: http://localhost:8081' -ForegroundColor Green
Write-Host 'The Day 1 Kafka stream job is in flink/job.' -ForegroundColor Yellow
