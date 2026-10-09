[CmdletBinding()]
param([switch]$SkipWsl)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
Set-Location $PSScriptRoot

$setup=Join-Path $PSScriptRoot 'scripts\SETUP-WINDOWS-PREREQUISITES.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup @($(if($SkipWsl){'-SkipWsl'}))
if($LASTEXITCODE -eq 3010){Write-Host 'Restart Windows and rerun this script.' -ForegroundColor Yellow; exit 3010}
if($LASTEXITCODE -ne 0){throw "Prerequisite setup failed with exit code $LASTEXITCODE"}

$env:Path=[Environment]::GetEnvironmentVariable('Path','Machine')+';'+[Environment]::GetEnvironmentVariable('Path','User')
$docker=(Get-Command docker.exe -ErrorAction SilentlyContinue).Source
$compose=(Get-Command docker-compose.exe -ErrorAction SilentlyContinue).Source
if(-not $docker -or -not $compose){throw 'docker.exe and docker-compose.exe must be available in PATH.'}

& $docker info 1>$null 2>$null
if($LASTEXITCODE -ne 0){
  Write-Host 'Start Docker Desktop and wait for the engine, then rerun this script.' -ForegroundColor Yellow
  exit 21
}

Write-Host '=== AR INFOTEK v13 FINAL REVISED - CLEAN E-COMMERCE BIG DATA LAB ===' -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# Flink Kafka SQL connector
# -----------------------------------------------------------------------------
$connector=Join-Path $PSScriptRoot 'flink-sql\lib\flink-sql-connector-kafka-5.0.0-2.1.jar'
$connectorUrl='https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/5.0.0-2.1/flink-sql-connector-kafka-5.0.0-2.1.jar'

function Test-JarFile([string]$Path){
  if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){ return $false }
  try {
    $bytes=[System.IO.File]::ReadAllBytes($Path)
    return ($bytes.Length -ge 2 -and $bytes[0] -eq 0x50 -and $bytes[1] -eq 0x4B)
  } catch { return $false }
}

if(Test-JarFile $connector){
  Write-Host '[OK] Flink Kafka SQL connector already present - skipping download' -ForegroundColor Green
} else {
  if(Test-Path -LiteralPath $connector){ Remove-Item -Force -LiteralPath $connector }
  Write-Host '[SETUP] Downloading Flink Kafka SQL connector 5.0.0-2.1 once...' -ForegroundColor Cyan
  New-Item -ItemType Directory -Force (Split-Path $connector) | Out-Null

  $downloaded=$false
  $curl=(Get-Command curl.exe -ErrorAction SilentlyContinue)
  if($curl){
    Write-Host '[SETUP] Trying curl.exe...' -ForegroundColor DarkCyan
    & $curl.Source -L --fail --silent --show-error --retry 3 --retry-delay 3 --connect-timeout 20 --max-time 180 -o $connector $connectorUrl
    if($LASTEXITCODE -eq 0 -and (Test-JarFile $connector)){ $downloaded=$true }
  }

  if(-not $downloaded){
    if(Test-Path -LiteralPath $connector){ Remove-Item -Force -LiteralPath $connector }
    Write-Host '[SETUP] Trying Invoke-WebRequest...' -ForegroundColor DarkCyan
    try {
      Invoke-WebRequest -UseBasicParsing -Uri $connectorUrl -OutFile $connector -TimeoutSec 180
      if(Test-JarFile $connector){ $downloaded=$true }
    } catch { }
  }

  if(-not $downloaded){
    if(Test-Path -LiteralPath $connector){ Remove-Item -Force -LiteralPath $connector }
    throw "Could not download the Flink Kafka SQL connector. Download the correct artifact from $connectorUrl and place it at $connector, then rerun the installer."
  }
  Write-Host '[OK] Flink Kafka SQL connector downloaded and validated.' -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# Streamlit application image
# -----------------------------------------------------------------------------
# Always build from the current package source. Docker layer caching keeps
# repeat builds efficient, while preventing a stale local image from being reused.
$streamlitImage='ar-infotek-bigdata-v13-streamlit:1.1'
Write-Host '[SETUP] Building Streamlit from the current .\\streamlit source...' -ForegroundColor Cyan
& $compose build streamlit
if($LASTEXITCODE -ne 0){ throw 'Streamlit image build failed. Installation stopped.' }

$imageId = @(& $docker image ls --quiet --filter "reference=$streamlitImage" 2>$null) | Select-Object -First 1
if([string]::IsNullOrWhiteSpace([string]$imageId)){
  throw "Streamlit image build returned success, but $streamlitImage is not present in the local Docker image store."
}
Write-Host "[OK] Streamlit image built successfully: $streamlitImage" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Pull registry images sequentially with retries before Compose startup.
# This avoids a first-run stampede of concurrent Docker Hub pulls, which can
# trigger TLS handshake timeouts on Windows/Docker Desktop connections.
# -----------------------------------------------------------------------------
$registryImages = @(
  'apache/hadoop:3.4.3',
  'postgres:16',
  'apache/kafka:4.3.1',
  'quay.io/debezium/connect:3.7',
  'apache/nifi:2.12.0',
  'flink:2.1.1-scala_2.12',
  'mongo:8',
  'trinodb/trino:483',
  'apache/airflow:3.3.2'
)

function Test-LocalImage([string]$Image){
  $old=$ErrorActionPreference
  $ErrorActionPreference='Continue'
  $ids=@(& $docker image ls --quiet --filter "reference=$Image" 2>$null)
  $code=$LASTEXITCODE
  $ErrorActionPreference=$old
  return ($code -eq 0 -and -not [string]::IsNullOrWhiteSpace([string]($ids | Select-Object -First 1)))
}

function Pull-ImageWithRetry([string]$Image,[int]$Attempts=4){
  if(Test-LocalImage $Image){
    Write-Host "[OK] Docker image already present: $Image" -ForegroundColor Green
    return
  }

  for($attempt=1; $attempt -le $Attempts; $attempt++){
    Write-Host "[SETUP] Pulling $Image (attempt $attempt/$Attempts) ..." -ForegroundColor Cyan
    $old=$ErrorActionPreference
    $ErrorActionPreference='Continue'
    & $docker pull $Image
    $code=$LASTEXITCODE
    $ErrorActionPreference=$old

    if($code -eq 0 -and (Test-LocalImage $Image)){
      Write-Host "[OK] Pulled: $Image" -ForegroundColor Green
      return
    }

    if($attempt -lt $Attempts){
      Write-Host "[WARN] Pull failed for $Image. Waiting 15 seconds before retry..." -ForegroundColor Yellow
      Start-Sleep -Seconds 15
    }
  }

  throw "Could not pull Docker image $Image after $Attempts attempts. Check Docker Hub connectivity/TLS, then rerun the installer."
}

Write-Host '[SETUP] Preparing required registry images sequentially...' -ForegroundColor Cyan
foreach($img in $registryImages){ Pull-ImageWithRetry $img }

# All registry images are now local, so Compose must not perform implicit pulls.
Write-Host '[SETUP] Starting the 15-service lab with --no-build --pull never ...' -ForegroundColor Cyan
$old=$ErrorActionPreference
$ErrorActionPreference='Continue'
& $compose up -d --no-build --pull never
$startupCode=$LASTEXITCODE
$ErrorActionPreference=$old
if($startupCode -ne 0){throw 'Container startup failed. All registry images were pre-pulled, so check docker-compose logs and container status.'}

$marker=Join-Path $PSScriptRoot '.v13-initialized'
if(Test-Path -LiteralPath $marker){
  Write-Host '[OK] Initial lab data already initialized - skipping one-time initialization' -ForegroundColor Green
} else {
  & "$PSScriptRoot\scripts\INIT-LAB.ps1"
  if($LASTEXITCODE -ne 0){throw 'Lab data initialization failed.'}

  & "$PSScriptRoot\scripts\INIT-ANALYTICS.ps1"
  if($LASTEXITCODE -ne 0){throw 'Analytical table initialization failed.'}

  New-Item -ItemType File -Force $marker | Out-Null
  Write-Host '[OK] One-time lab initialization completed.' -ForegroundColor Green
}

& "$PSScriptRoot\scripts\VERIFY-ALL.ps1"
if($LASTEXITCODE -ne 0){throw 'Lab verification reported a failure.'}

Write-Host '=== v13 INSTALLATION COMPLETE - NETWORK HARDENED ===' -ForegroundColor Green
Write-Host 'Flink SQL job is not submitted automatically.'
Write-Host 'Run: .\scripts\RUN-FLINK-SQL.ps1' -ForegroundColor Yellow
