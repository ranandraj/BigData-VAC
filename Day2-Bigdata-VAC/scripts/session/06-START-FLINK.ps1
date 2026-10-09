Set-Location "$PSScriptRoot\..\.."; $dc=(Get-Command docker-compose.exe -ErrorAction Stop).Source; & $dc up -d flink-jobmanager flink-taskmanager
