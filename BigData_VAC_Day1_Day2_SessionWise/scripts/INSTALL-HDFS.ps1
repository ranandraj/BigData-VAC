$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
docker compose up -d namenode datanode1 datanode2 datanode3
docker compose ps
Write-Host "HDFS started."
