$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
Write-Host "=== DAY 1: DISTRIBUTED DATA FOUNDATION + STREAMING ===" -ForegroundColor Cyan

docker compose up -d namenode postgres kafka nifi flink-jobmanager flink-taskmanager
if ($LASTEXITCODE -ne 0) { throw "Base Day 1 services failed to start." }

Write-Host "Waiting for HDFS NameNode..." -ForegroundColor Cyan
$deadline=(Get-Date).AddSeconds(180)
$ready=$false
while((Get-Date)-lt $deadline){
  $status=docker inspect -f '{{.State.Status}}' hdfs-namenode 2>$null
  if($status -eq 'exited' -or $status -eq 'dead') { Write-Host "HDFS NameNode container exited. Showing logs..." -ForegroundColor Red; docker compose logs --tail=200 namenode; throw "HDFS NameNode container exited before becoming ready." }
  if($status -eq 'running'){
    docker exec hdfs-namenode bash -lc "su -s /bin/bash hadoop -c '/opt/hadoop/bin/hdfs dfs -ls /' >/dev/null 2>&1"
    if($LASTEXITCODE -eq 0){$ready=$true;break}
  }
  Start-Sleep 5
}
if(-not $ready){
  Write-Host "HDFS NameNode failed to become ready. Last logs:" -ForegroundColor Red
  docker compose logs --tail=120 namenode
  throw "HDFS NameNode startup failed."
}

docker compose up -d datanode1 datanode2 datanode3 debezium
if ($LASTEXITCODE -ne 0) { docker compose logs --tail=120 namenode datanode1 datanode2 datanode3; throw "HDFS DataNodes/Day 1 streaming services failed to start." }

& "$PSScriptRoot\WAIT-HDFS-DATANODES.ps1"
if ($LASTEXITCODE -ne 0) { throw "HDFS DataNodes are not ready." }

& "$PSScriptRoot\INIT-DAY1.ps1"
if ($LASTEXITCODE -ne 0) { throw "Day 1 initialization failed." }
& "$PSScriptRoot\VERIFY-DAY1.ps1"
if ($LASTEXITCODE -ne 0) { throw "Day 1 verification failed." }
