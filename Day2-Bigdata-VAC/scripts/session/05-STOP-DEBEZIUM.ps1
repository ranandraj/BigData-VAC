Set-Location "$PSScriptRoot\..\.."; $dc=(Get-Command docker-compose.exe -ErrorAction Stop).Source; & $dc stop debezium
