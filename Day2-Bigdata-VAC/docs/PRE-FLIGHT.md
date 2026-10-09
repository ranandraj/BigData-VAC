# v13 Pre-flight checker

Run `PRE-FLIGHT-CHECK.cmd` before installing the lab.

The checker validates:
- `docker.exe` in PATH
- `docker-compose.exe` in PATH
- PowerShell LocalMachine execution policy
- WSL2 executable/status
- Docker Engine availability

The v13 checker does **not** require winget and does **not** install an Ubuntu distribution.

Recommended hardware for the full stack:
- 8 GB RAM minimum, staged startup strongly recommended
- 4+ logical CPU cores
- 40+ GB free disk
- hardware virtualization enabled
- Docker Desktop configured for Linux containers / WSL2 backend
