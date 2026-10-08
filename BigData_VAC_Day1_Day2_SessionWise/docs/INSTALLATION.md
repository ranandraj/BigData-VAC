# AR INFOTEK Big Data VAC Lab Installation

## 1. Run the pre-flight check

Right-click `PRE-FLIGHT-CHECK.cmd` and choose **Run as administrator**.

The checker validates:

- Windows build and 64-bit architecture
- CPU, RAM and disk
- CPU firmware virtualization (Intel VT-x / AMD-V / SVM)
- Windows Subsystem for Linux feature
- Virtual Machine Platform feature
- `wsl.exe` and WSL runtime
- hypervisor launch configuration
- Docker CLI, Compose and Docker Engine
- required lab ports
- winget availability

## 2. Run the complete installer

Open PowerShell as Administrator and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\INSTALL-BIGDATA-LAB.ps1
```

The installer now performs the following order:

1. Enables Windows Subsystem for Linux.
2. Enables Virtual Machine Platform.
3. Configures `hypervisorlaunchtype auto`.
4. Checks firmware virtualization.
5. Updates WSL and sets WSL 2 as the default.
6. Installs an Ubuntu WSL distribution unless `-SkipWslDistro` is supplied.
7. Stops if Windows requires a restart.
8. Installs Docker Desktop through winget when Docker is missing.
9. Checks that Docker Engine is actually running.
10. Starts Day 1 only.

## 3. Restart handling

Windows may require a restart after enabling WSL or Virtual Machine Platform. The installer does **not** silently restart a lab computer.

It asks:

```text
Restart this computer now? (Y/N)
```

If you choose `Y`, Windows restarts after a short delay. Run the installer again after Windows starts if the installer does not resume automatically.

If you choose `N`, restart Windows manually and run the installer again.

## 4. Firmware virtualization

The installer can enable Windows virtualization components, but it cannot enable CPU virtualization in BIOS/UEFI.

If pre-flight reports:

```text
[FAIL] Firmware virtualization
```

enable one of these in BIOS/UEFI:

- Intel VT-x / Intel Virtualization Technology
- AMD-V / SVM Mode

Then boot Windows and rerun the pre-flight check.

## 5. If WSL is still not ready

Run as Administrator:

```powershell
.\scripts\SETUP-WINDOWS-PREREQUISITES.ps1
```

Then restart Windows and run:

```powershell
wsl --status
wsl --version
```

The installer does not require an Ubuntu shell for the Big Data containers, but an Ubuntu WSL distribution is installed by default to make the lab host easier to verify and troubleshoot.

## 6. Day 1 and Day 2

After Windows and Docker are ready:

```powershell
.\scripts\INSTALL-DAY1.ps1
```

After Day 1:

```powershell
.\scripts\STOP-DAY1.ps1
```

For Day 2:

```powershell
.\scripts\INSTALL-DAY2.ps1
```

After Day 2:

```powershell
.\scripts\STOP-DAY2.ps1
```

## 7. Direct Windows prerequisite repair

For machines where the main installer is blocked before Docker installation, run:

```text
SETUP-WINDOWS-PREREQUISITES.cmd
```

This specifically repairs/checks WSL, Virtual Machine Platform, WSL 2 defaults and hypervisor launch configuration before the Big Data stack is touched.

## HDFS startup reliability fix

The lab uses the official Apache Hadoop 3.4.3 container. Because the current image runs as the non-root `hadoop` user while Docker-created named volumes are initially root-owned, the lab now starts the HDFS containers with a small wrapper that prepares `/data`, assigns ownership to `hadoop`, formats the NameNode once, and then starts the daemon as `hadoop`. This avoids the volume-permission startup failure on Windows/Docker Desktop. DataNodes use separate `/data` volumes and are started only after the NameNode is ready.

If a previous installation has stale failed containers, run:

```powershell
.\scripts\RESET-LAB.ps1
```

Then run:

```powershell
.\scripts\INSTALL-DAY1.ps1
```
