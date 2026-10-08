$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
Write-Host "Waiting for 3 HDFS DataNodes..." -ForegroundColor Cyan
$deadline=(Get-Date).AddSeconds(180)
$ready=$false
while((Get-Date)-lt $deadline){
  $bad=@()
  foreach($c in @('hdfs-datanode1','hdfs-datanode2','hdfs-datanode3')){
    $s=docker inspect -f '{{.State.Status}}' $c 2>$null
    if($s -eq 'exited' -or $s -eq 'dead'){$bad += $c}
  }
  if($bad.Count -gt 0){
    Write-Host "DataNode container exited: $($bad -join ', ')" -ForegroundColor Red
    docker compose logs --tail=160 datanode1 datanode2 datanode3
    throw "One or more HDFS DataNodes exited."
  }
  $report = docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfsadmin -report 2>$null | Out-String
  if($LASTEXITCODE -eq 0 -and $report -match 'Live datanodes \(3\)'){$ready=$true;break}
  if($report){
    $m=[regex]::Match($report,'Live datanodes \((\d+)\)')
    if($m.Success){Write-Host ("HDFS live DataNodes: " + $m.Groups[1].Value + "/3")}
  }
  Start-Sleep 5
}
if(-not $ready){
  Write-Host "HDFS DataNodes did not become ready. Current report:" -ForegroundColor Red
  docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfsadmin -report 2>&1 | Out-Host
  Write-Host "DataNode logs:" -ForegroundColor Yellow
  docker compose logs --tail=160 datanode1 datanode2 datanode3
  throw "HDFS DataNodes did not become ready within 180 seconds."
}
Write-Host "[OK] All 3 HDFS DataNodes are live." -ForegroundColor Green
