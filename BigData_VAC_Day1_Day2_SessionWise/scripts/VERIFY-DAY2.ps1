Set-Location "$PSScriptRoot\.."
Write-Host "=== DAY 2 VERIFICATION ===" -ForegroundColor Cyan
docker compose ps
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfsadmin -report
docker exec mongodb mongosh --quiet --eval "db.adminCommand('ping')"
try { Invoke-WebRequest http://localhost:8080/v1/info -UseBasicParsing | Select-Object StatusCode } catch { Write-Host "Trino not ready" }
try { Invoke-RestMethod http://localhost:8081/overview | Out-Host } catch { Write-Host "Flink not ready" }
Write-Host "Streamlit: http://localhost:8501"
Write-Host "Airflow: http://localhost:8085"
