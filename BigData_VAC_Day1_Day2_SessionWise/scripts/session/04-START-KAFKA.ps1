$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\..\.."
Write-Host '=== SESSION 5: START KAFKA ===' -ForegroundColor Cyan
docker compose up -d kafka
for($i=0;$i -lt 30;$i++){ docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --list 2>$null; if($LASTEXITCODE -eq 0){break}; Start-Sleep 2 }
if($LASTEXITCODE -ne 0){throw 'Kafka did not become ready.'}
Write-Host 'Kafka is ready.' -ForegroundColor Green
