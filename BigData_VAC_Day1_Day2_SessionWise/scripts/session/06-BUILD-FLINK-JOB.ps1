$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\..\.."
Write-Host '=== BUILD DAY 1 FLINK JOB ===' -ForegroundColor Cyan
$root=(Get-Location).Path
docker run --rm -v "${root}\flink\job:/workspace" -w /workspace maven:3.9-eclipse-temurin-17 mvn -q -DskipTests package
if($LASTEXITCODE -ne 0){throw 'Flink job build failed.'}
Write-Host 'Flink job built: flink/job/target/day1-kafka-flink-1.0.0.jar' -ForegroundColor Green
