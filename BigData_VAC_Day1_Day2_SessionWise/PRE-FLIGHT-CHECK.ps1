$ErrorActionPreference = 'Continue'
$Pass=0;$Warn=0;$Fail=0
function P($n,$m){$script:Pass++;Write-Host "[PASS] $n : $m" -ForegroundColor Green}
function W($n,$m){$script:Warn++;Write-Host "[WARN] $n : $m" -ForegroundColor Yellow}
function F($n,$m){$script:Fail++;Write-Host "[FAIL] $n : $m" -ForegroundColor Red}
function S($x){Write-Host "`n--- $x ---" -ForegroundColor Cyan}
function Is-Admin {
    $id=[Security.Principal.WindowsIdentity]::GetCurrent()
    $p=New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
Write-Host "`n=== AR INFOTEK BIG DATA LAB PRE-FLIGHT ===" -ForegroundColor Cyan

S "SYSTEM"
if(Is-Admin){P "Administrator" "Elevated"}else{F "Administrator" "Run PRE-FLIGHT-CHECK.cmd as Administrator"}
$os=Get-CimInstance Win32_OperatingSystem;$build=[int]$os.BuildNumber
if($build -ge 19041){P "Windows" "$($os.Caption), build $build"}else{F "Windows" "Build 19041+ required"}
if([Environment]::Is64BitOperatingSystem){P "Architecture" "64-bit"}else{F "Architecture" "64-bit required"}
$cpu=Get-CimInstance Win32_Processor;$cores=($cpu|Measure-Object NumberOfLogicalProcessors -Sum).Sum
if($cores -ge 4){P "CPU" "$cores logical processors"}elseif($cores -ge 2){W "CPU" "$cores; 4+ recommended"}else{F "CPU" "$cores; insufficient"}
$ram=[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)
if($ram -ge 32){P "RAM" "$ram GB"}elseif($ram -ge 16){W "RAM" "$ram GB; Day 1/Day 2 staged mode"}elseif($ram -ge 8){W "RAM" "$ram GB; selected services only"}else{F "RAM" "$ram GB"}
$c=Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'";$free=[math]::Round($c.FreeSpace/1GB,1)
if($free -ge 80){P "Disk" "$free GB free"}elseif($free -ge 50){W "Disk" "$free GB; 80+ preferred"}else{F "Disk" "$free GB free"}
$virt=($cpu|Where-Object {$_.VirtualizationFirmwareEnabled}).Count -gt 0
if($virt){P "Firmware virtualization" "Enabled (VT-x/AMD-V/SVM)"}else{
  $wslRuntimeOk=$false
  if(Test-Path $wslPath){ & $wslPath --status *> $null; $wslRuntimeOk=($LASTEXITCODE -eq 0) }
  docker info *> $null; $dockerRuntimeOk=($LASTEXITCODE -eq 0)
  if($wslRuntimeOk -or $dockerRuntimeOk){W "Firmware virtualization" "Not reported by WMI, but WSL/Docker virtualization is operational"}
  else{F "Firmware virtualization" "Disabled/not reported and WSL/Docker is not operational. Enable VT-x/AMD-V/SVM in BIOS/UEFI."}
}

S "WINDOWS / WSL"
$wsl=Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
$vmp=Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
if($wsl.State -eq "Enabled"){P "WSL feature" "Enabled"}elseif($wsl.State -eq "Enable Pending"){W "WSL feature" "Enable pending restart"}else{F "WSL feature" "Disabled. Run INSTALL-BIGDATA-LAB.ps1 as Administrator."}
if($vmp.State -eq "Enabled"){P "Virtual Machine Platform" "Enabled"}elseif($vmp.State -eq "Enable Pending"){W "Virtual Machine Platform" "Enable pending restart"}else{F "Virtual Machine Platform" "Disabled. Run INSTALL-BIGDATA-LAB.ps1 as Administrator."}
$wslPath=Join-Path $env:WINDIR 'System32\wsl.exe'
if(Test-Path $wslPath){P "wsl.exe" "$wslPath"}else{F "wsl.exe" "Not found; Windows restart/update may be required"}
if(Test-Path $wslPath){
  $wslStatus=& $wslPath --status 2>&1
  if($LASTEXITCODE -eq 0){P "WSL runtime" "Responding"}else{W "WSL runtime" "Not ready yet; run WSL setup after restart"}
  & $wslPath --list --verbose 2>&1 | Out-Host
}
$hyper=(& bcdedit.exe /enum '{current}' 2>$null | Select-String 'hypervisorlaunchtype')
if($hyper -match 'Auto'){P "Hypervisor launch" "Auto"}else{W "Hypervisor launch" "Not set to Auto. Installer will configure it."}

S "DOCKER"
if(Get-Command docker.exe -EA SilentlyContinue){
 P "Docker CLI" "Available"
 docker compose version 2>$null | Out-Host
 if($LASTEXITCODE -eq 0){P "Compose" "v2 available"}else{F "Compose" "Unavailable"}
 docker info *> $null
 if($LASTEXITCODE -eq 0){
  P "Engine" "Running"
  try{
   $i=docker info --format '{{json .}}'|ConvertFrom-Json
   $dm=[math]::Round($i.MemTotal/1GB,1);$dc=$i.NCPU
   Write-Host "Docker resources: $dm GB RAM, $dc CPUs"
   if($dm -ge 12){P "Docker memory" "$dm GB"}elseif($dm -ge 8){W "Docker memory" "$dm GB; staged mode"}else{W "Docker memory" "$dm GB; limited"}
  }catch{W "Docker resources" "Could not read"}
 }else{W "Engine" "Not running. Start Docker Desktop."}
}else{W "Docker CLI" "Not installed. Installer can install Docker Desktop if winget is available."}

S "PORTS"
$ports=@{9870="HDFS UI";8020="HDFS RPC";9864="DataNode1";9865="DataNode2";9866="DataNode3";5432="PostgreSQL";9092="Kafka";8083="Debezium";8443="NiFi";8081="Flink";27017="MongoDB";8080="Trino";8501="Streamlit";8085="Airflow"}
foreach($kv in $ports.GetEnumerator()){if(Get-NetTCPConnection -LocalPort $kv.Key -State Listen -EA SilentlyContinue){W "Port $($kv.Key)" "$($kv.Value) already in use"}else{P "Port $($kv.Key)" "Available"}}

S "INSTALLER TOOLS"
if(Get-Command winget.exe -EA SilentlyContinue){P "Winget" "Available"}else{W "Winget" "Not available; Docker Desktop must be installed manually"}

S "RESOURCE PLAN"
if($ram -ge 32){P "Day 1/Day 2 plan" "Complete staged plan supported"}elseif($ram -ge 16){P "Day 1/Day 2 plan" "Recommended operating mode"}else{W "Day 1/Day 2 plan" "Use only selected services"}

Write-Host "`nSUMMARY: PASS=$Pass WARN=$Warn FAIL=$Fail" -ForegroundColor Cyan
if($Fail -eq 0){Write-Host "READY: review WARN items, then run INSTALL-BIGDATA-LAB.ps1." -ForegroundColor Green}else{Write-Host "NOT READY: run INSTALL-BIGDATA-LAB.ps1 as Administrator. It can repair WSL/Virtual Machine Platform automatically; BIOS virtualization must be enabled manually." -ForegroundColor Red}
