Set-Location "$PSScriptRoot\..\.."; $dc=(Get-Command docker-compose.exe -ErrorAction Stop).Source; & $dc stop namenode datanode1 datanode2 datanode3
