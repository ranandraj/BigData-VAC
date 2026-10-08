$ErrorActionPreference="Continue"
Set-Location "$PSScriptRoot\.."
Write-Host "=== HDFS DIAGNOSTICS ===" -ForegroundColor Cyan
docker compose ps -a namenode datanode1 datanode2 datanode3
Write-Host "`n--- NameNode logs ---" -ForegroundColor Yellow
docker compose logs --tail=250 namenode
Write-Host "`n--- NameNode process ---" -ForegroundColor Yellow
docker exec hdfs-namenode bash -lc "ps -ef | grep -E 'NameNode|java' | grep -v grep"
Write-Host "`n--- NameNode HTTP ---" -ForegroundColor Yellow
docker exec hdfs-namenode bash -lc "curl -I http://127.0.0.1:9870/ 2>&1"
