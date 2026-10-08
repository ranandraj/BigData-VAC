$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\..\.."
$jar='flink/job/target/day1-kafka-flink-1.0.0.jar'
if(-not (Test-Path $jar)){throw 'Build the Flink job first using 06-BUILD-FLINK-JOB.ps1'}
docker cp $jar flink-jobmanager:/opt/flink/usrlib/day1-kafka-flink.jar
docker exec flink-jobmanager flink run -d /opt/flink/usrlib/day1-kafka-flink.jar
if($LASTEXITCODE -ne 0){throw 'Flink job submission failed.'}
Write-Host 'Flink Day 1 job submitted.' -ForegroundColor Green
