$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\.."
Write-Host '=== AR INFOTEK BIG DATA VAC v7 - SESSION STARTER ===' -ForegroundColor Cyan
Write-Host '1 HDFS  2 PostgreSQL  3 NiFi  4 Kafka  5 Debezium  6 Flink  7 Integration'
$n=Read-Host 'Enter session number'
switch($n){
 '1' { & .\scripts\session\01-START-HDFS.ps1 }
 '2' { & .\scripts\session\02-START-POSTGRES.ps1 }
 '3' { & .\scripts\session\03-START-NIFI.ps1 }
 '4' { & .\scripts\session\04-START-KAFKA.ps1 }
 '5' { & .\scripts\session\05-START-DEBEZIUM.ps1; & .\scripts\session\05-REGISTER-DEBEZIUM.ps1 }
 '6' { & .\scripts\session\06-START-FLINK.ps1 }
 '7' { & .\scripts\session\07-VERIFY-INTEGRATION.ps1 }
 default { throw 'Invalid session number.' }
}
