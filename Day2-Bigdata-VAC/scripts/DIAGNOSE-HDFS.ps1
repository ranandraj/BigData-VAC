$ErrorActionPreference="Continue"
Set-Location "$PSScriptRoot\.."
$dc=(Get-Command docker-compose.exe -ErrorAction Stop).Source
Write-Host "=== HDFS DIAGNOSTICS ===" -ForegroundColor Cyan
& $dc ps -a namenode datanode1 datanode2 datanode3
Write-Host "`n--- NameNode logs ---" -ForegroundColor Yellow
& $dc logs --tail=250 namenode
Write-Host "`n--- NameNode process ---" -ForegroundColor Yellow
& docker.exe exec hdfs-namenode bash -lc "ps -ef | grep -E 'NameNode|java' | grep -v grep"
Write-Host "`n--- NameNode HTTP ---" -ForegroundColor Yellow
& docker.exe exec hdfs-namenode bash -lc "curl -I http://127.0.0.1:9870/ 2>&1"
