$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\..\.."
docker compose stop datanode1 datanode2 datanode3 namenode
