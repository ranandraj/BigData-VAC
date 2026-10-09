[CmdletBinding()]
param([string]$SqlFile='sql/flink/ecommerce-realtime.sql')

$ErrorActionPreference = 'Stop'
Set-Location "$PSScriptRoot\.."

$dc = (Get-Command docker-compose.exe -ErrorAction Stop).Source

if (-not (Test-Path $SqlFile)) {
    throw "SQL file not found: $SqlFile"
}

Write-Host '=== Starting Flink SQL analytics job ===' -ForegroundColor Cyan

& $dc up -d --no-build --pull never flink-jobmanager flink-taskmanager kafka
if ($LASTEXITCODE -ne 0) { throw 'Flink cluster startup failed.' }

$ready = $false
for ($i = 0; $i -lt 60; $i++) {
    try {
        Invoke-RestMethod -Uri 'http://localhost:8081/overview' -TimeoutSec 3 | Out-Null
        $ready = $true
        break
    } catch {
        Start-Sleep -Seconds 2
    }
}
if (-not $ready) { throw 'Flink JobManager did not become ready at http://localhost:8081.' }

$containerSqlFile = "/opt/sql/$([System.IO.Path]::GetFileName($SqlFile))"

Write-Host "Submitting SQL file: $SqlFile" -ForegroundColor Cyan

# Keep the official Flink image entrypoint so it prepares the runtime environment.
# Passing -f directly as the container command bypasses the SQL client executable.
& $dc run --rm --no-deps --pull never `
    --entrypoint /docker-entrypoint.sh `
    sql-client bin/sql-client.sh -f $containerSqlFile

if ($LASTEXITCODE -ne 0) {
    throw 'Flink SQL submission failed. Check the SQL Client output.'
}

$jobReady = $false
for ($i = 0; $i -lt 15; $i++) {
    try {
        $jobs = Invoke-RestMethod -Uri 'http://localhost:8081/jobs/overview' -TimeoutSec 5
        $running = @($jobs.jobs | Where-Object { $_.state -eq 'RUNNING' })
        if ($running.Count -gt 0) {
            $jobReady = $true
            Write-Host "Running Flink job(s): $($running.Count)" -ForegroundColor Green
            break
        }
    } catch {
        # Retry briefly while the submitted job is registered.
    }
    Start-Sleep -Seconds 2
}

if (-not $jobReady) {
    Write-Warning 'SQL client exited successfully, but no RUNNING job was found. Inspect http://localhost:8081/jobs for submission or runtime errors.'
    exit 1
}

Write-Host '=== Flink SQL job submitted and verified ===' -ForegroundColor Green
Write-Host 'Flink Web UI: http://localhost:8081'
Write-Host 'Metrics topic: ecommerce-metrics'
Write-Host 'Anomaly topic: ecommerce-anomalies'
