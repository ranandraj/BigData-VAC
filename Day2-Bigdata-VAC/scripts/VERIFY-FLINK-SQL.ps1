$ErrorActionPreference='Stop'
Set-Location "$PSScriptRoot\.."
Write-Host '=== Flink SQL verification ===' -ForegroundColor Cyan
try { $overview=Invoke-RestMethod http://localhost:8081/overview; Write-Host "Flink version: $($overview['flink-version'])"; Write-Host "TaskManagers: $($overview['taskmanagers'])" } catch { throw 'Flink REST API is not available.' }
& docker.exe exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --list | Select-String 'ecommerce-metrics|ecommerce-anomalies'
Write-Host 'Use scripts/PUBLISH-SAMPLE-EVENTS.ps1 to publish live events.' -ForegroundColor Green
