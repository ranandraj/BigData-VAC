$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\..\.."
Write-Host '=== SESSION 3: START POSTGRESQL ===' -ForegroundColor Cyan
docker compose up -d postgres
Write-Host 'Waiting for PostgreSQL...'
for($i=0;$i -lt 30;$i++){ docker exec ecommerce-postgres pg_isready -U ecommerce -d ecommerce 2>$null; if($LASTEXITCODE -eq 0){break}; Start-Sleep 2 }
if($LASTEXITCODE -ne 0){throw 'PostgreSQL did not become ready.'}
Write-Host 'PostgreSQL is ready.' -ForegroundColor Green
