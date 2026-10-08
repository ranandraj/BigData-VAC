$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\..\.."
Write-Host '=== SESSION 2: START HDFS ===' -ForegroundColor Cyan
docker compose up -d namenode datanode1 datanode2 datanode3
& .\scripts\WAIT-HDFS-DATANODES.ps1
if ($LASTEXITCODE -ne 0) { throw 'HDFS DataNodes did not become ready.' }
Write-Host 'HDFS is ready. Now students perform the HDFS commands from Student-Lab.' -ForegroundColor Green
