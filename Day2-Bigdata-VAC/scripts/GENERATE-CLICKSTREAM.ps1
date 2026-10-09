param([int]$Count=100)
$ErrorActionPreference='Stop'
Set-Location "$PSScriptRoot\.."
Get-Content .\data\clickstream.json | Select-Object -First $Count | & docker.exe exec -i kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:29092 --topic ecommerce-events
if($LASTEXITCODE -ne 0){throw 'Kafka event publishing failed.'}
Write-Host "Published $Count clickstream events." -ForegroundColor Green
