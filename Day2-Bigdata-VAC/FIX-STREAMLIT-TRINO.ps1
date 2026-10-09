[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$AppFile = Join-Path $Root 'streamlit\app.py'

if (-not (Test-Path $AppFile)) {
    throw "Cannot find $AppFile. Run this script from the extracted v13work package."
}

$BackupFile = "$AppFile.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $AppFile $BackupFile
$content = Get-Content $AppFile -Raw
$pattern = "catalog\s*=\s*['""]iceberg['""]\s*,\s*schema\s*=\s*['""]ecommerce['""]"

if ($content -match $pattern) {
    $content = [regex]::Replace($content, $pattern, "catalog='postgresql',schema='public'")
    Set-Content -Path $AppFile -Value $content -Encoding utf8
} elseif ($content -notmatch "catalog\s*=\s*['""]postgresql['""]\s*,\s*schema\s*=\s*['""]public['""]") {
    throw "Could not identify the Trino connection in streamlit\app.py. No automatic change was made."
}

Write-Host "Source connection:" -ForegroundColor Cyan
Select-String -Path $AppFile -Pattern 'def trino_conn'

Write-Host "`nRebuilding and recreating only Streamlit..." -ForegroundColor Cyan
Write-Host "`nVerifying the running container..." -ForegroundColor Cyan

# 1. Write the Python validation logic out to a safe temporary script file
$TempPyFile = Join-Path $Root 'verify_temp.py'
@'
from pathlib import Path
import re, sys
s = Path("/app/app.py").read_text(encoding="utf-8-sig")
m = re.search(r"def trino_conn\(\):.*?(?=\ndef |\Z)", s, re.S)
if not m:
    m = re.search(r"def trino_conn\(catalog=.*?(?=\ndef |\Z)", s, re.S)
if not m:
    print("ERROR: trino_conn() was not found")
    sys.exit(1)
print(m.group(0).strip())
if not re.search(r"catalog\s*=\s*['\"]postgresql['\"]\s*,\s*schema\s*=\s*['\"]public['\"]", m.group(0)):
    print("ERROR: operational Trino connection is not postgresql.public")
    sys.exit(1)
print("PASS: operational connection uses postgresql.public")
'@ | Set-Content -Path $TempPyFile -Encoding utf8

# 2. Copy the validation script into the container and execute it
docker-compose cp $TempPyFile streamlit:/app/verify_temp.py
docker-compose exec -T streamlit python /app/verify_temp.py
$VerifyStatus = $LASTEXITCODE

# 3. Clean up the temporary files from both host and container
Remove-Item -Path $TempPyFile -Force -ErrorAction SilentlyContinue
docker-compose exec -T streamlit rm -f /app/verify_temp.py

# 4. Enforce the validation check result
if ($VerifyStatus -ne 0) { throw "Container verification failed." }
