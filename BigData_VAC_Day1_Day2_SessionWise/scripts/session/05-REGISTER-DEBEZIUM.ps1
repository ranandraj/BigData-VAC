$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\..\.."
$base='http://localhost:8083'
$body=Get-Content .\config\debezium\postgres-connector.json -Raw
try { Invoke-RestMethod "$base/connectors/ecommerce-postgres" -Method Delete -ErrorAction SilentlyContinue | Out-Null } catch {}
Invoke-RestMethod "$base/connectors" -Method Post -ContentType 'application/json' -Body $body | Out-Null
Start-Sleep 5
$status=Invoke-RestMethod "$base/connectors/ecommerce-postgres/status"
Write-Host ("Connector: {0}; task: {1}" -f $status.connector.state,$status.tasks[0].state) -ForegroundColor Green
if($status.connector.state -ne 'RUNNING' -or $status.tasks[0].state -ne 'RUNNING'){ throw 'Debezium connector is not RUNNING.' }
