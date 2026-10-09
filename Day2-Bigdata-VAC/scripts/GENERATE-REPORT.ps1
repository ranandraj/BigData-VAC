$ErrorActionPreference='Stop'
Set-Location "$PSScriptRoot\.."
$out=Join-Path $PWD 'reports\management_report.csv'
$sql="SELECT status, sales_channel, count(*) AS orders, round(sum(total_amount),2) AS revenue, round(avg(total_amount),2) AS average_order_value FROM iceberg.ecommerce.orders GROUP BY status, sales_channel ORDER BY revenue DESC"
& docker.exe exec trino trino --server http://trino:8080 --catalog iceberg --schema ecommerce --output-format CSV_HEADER --execute $sql | Out-File -Encoding utf8 $out
Write-Host "Report written to $out" -ForegroundColor Green
