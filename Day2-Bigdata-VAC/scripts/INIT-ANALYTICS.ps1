$ErrorActionPreference='Stop'
Set-Location "$PSScriptRoot\.."

Write-Host 'Preparing HDFS analytical storage...' -ForegroundColor Cyan
& docker.exe exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /ecommerce/iceberg

Write-Host 'Waiting for Trino...' -ForegroundColor Cyan
$deadline=(Get-Date).AddMinutes(3)
$ready=$false
while((Get-Date) -lt $deadline){
  try { Invoke-RestMethod http://localhost:8080/v1/info -ErrorAction Stop | Out-Null; $ready=$true; break } catch { Start-Sleep 3 }
}
if(-not $ready){throw 'Trino did not become ready.'}

function Invoke-TrinoSql([string]$Sql){
  $headers=@{'X-Trino-User'='lab';'X-Trino-Catalog'='iceberg';'X-Trino-Schema'='ecommerce'}
  $r=Invoke-WebRequest -Uri 'http://localhost:8080/v1/statement' -Method Post -Headers $headers -ContentType 'text/plain' -Body $Sql
  while($true){
    $j=$r.Content | ConvertFrom-Json
    if($j.error){throw ($j.error.message)}
    if(-not $j.nextUri){break}
    Start-Sleep -Milliseconds 300
    $r=Invoke-WebRequest -Uri $j.nextUri -Method Get -Headers $headers
  }
}

Invoke-TrinoSql 'CREATE SCHEMA IF NOT EXISTS iceberg.ecommerce WITH (location = ''hdfs://namenode:8020/ecommerce/iceberg/ecommerce'')'

# Operational data becomes Parquet-backed Iceberg tables on HDFS.
Invoke-TrinoSql 'CREATE TABLE IF NOT EXISTS iceberg.ecommerce.customers (customer_id VARCHAR, name VARCHAR, city VARCHAR, state VARCHAR, registration_date DATE, customer_segment VARCHAR) WITH (format = ''PARQUET'')'
Invoke-TrinoSql 'CREATE TABLE IF NOT EXISTS iceberg.ecommerce.products (product_id VARCHAR, product_name VARCHAR, category VARCHAR, price DECIMAL(12,2)) WITH (format = ''PARQUET'')'
Invoke-TrinoSql 'CREATE TABLE IF NOT EXISTS iceberg.ecommerce.orders (order_id VARCHAR, customer_id VARCHAR, order_date DATE, created_at TIMESTAMP, total_amount DECIMAL(12,2), status VARCHAR) WITH (format = ''PARQUET'', partitioning = ARRAY[''day(order_date)''])'
Invoke-TrinoSql 'CREATE TABLE IF NOT EXISTS iceberg.ecommerce.order_items (order_item_id VARCHAR, order_id VARCHAR, product_id VARCHAR, quantity INTEGER, unit_price DECIMAL(12,2), discount_pct DECIMAL(5,2)) WITH (format = ''PARQUET'')'
Invoke-TrinoSql 'CREATE TABLE IF NOT EXISTS iceberg.ecommerce.payments (payment_id VARCHAR, order_id VARCHAR, payment_time TIMESTAMP, payment_method VARCHAR, amount DECIMAL(12,2), status VARCHAR) WITH (format = ''PARQUET'')'
Invoke-TrinoSql 'CREATE TABLE IF NOT EXISTS iceberg.ecommerce.clickstream_events (event_id VARCHAR, event_time TIMESTAMP, user_id VARCHAR, session_id VARCHAR, event_type VARCHAR, product_id VARCHAR, page VARCHAR, order_id VARCHAR, amount DECIMAL(12,2)) WITH (format = ''PARQUET'', partitioning = ARRAY[''day(event_time)''])'

foreach($t in @('customers','products','orders','order_items','payments','clickstream_events')){
  Invoke-TrinoSql "DELETE FROM iceberg.ecommerce.$t"
}

Invoke-TrinoSql 'INSERT INTO iceberg.ecommerce.customers SELECT customer_id, name, city, state, registration_date, customer_segment FROM postgresql.public.customers'
Invoke-TrinoSql 'INSERT INTO iceberg.ecommerce.products SELECT product_id, product_name, category, price FROM postgresql.public.products'
Invoke-TrinoSql 'INSERT INTO iceberg.ecommerce.orders SELECT order_id, customer_id, order_date, created_at, total_amount, status FROM postgresql.public.orders'
Invoke-TrinoSql 'INSERT INTO iceberg.ecommerce.order_items SELECT order_item_id, order_id, product_id, quantity, unit_price, discount_pct FROM postgresql.public.order_items'
Invoke-TrinoSql 'INSERT INTO iceberg.ecommerce.payments SELECT payment_id, order_id, payment_time, payment_method, amount, status FROM postgresql.public.payments'
Invoke-TrinoSql 'INSERT INTO iceberg.ecommerce.clickstream_events SELECT event_id, event_time, user_id, session_id, event_type, product_id, page, order_id, amount FROM postgresql.public.clickstream_events'

Write-Host '[OK] PostgreSQL operational data copied to partitioned Parquet-backed Iceberg tables on HDFS.' -ForegroundColor Green
Write-Host '[OK] Session 9 will demonstrate Iceberg schema evolution by adding sales_channel to orders.' -ForegroundColor Green
