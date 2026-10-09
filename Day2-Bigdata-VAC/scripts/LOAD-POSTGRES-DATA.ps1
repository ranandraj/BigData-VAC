$ErrorActionPreference='Stop'
Set-Location "$PSScriptRoot\.."

function SqlText([object]$Value){
    if($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)){ return 'NULL' }
    return "'" + ([string]$Value).Replace("'", "''") + "'"
}

function JsonValue([object]$Object,[string]$Name){
    # clickstream events intentionally omit order_id and amount for non-order events.
    $property=$Object.PSObject.Properties[$Name]
    if($null -eq $property){ return $null }
    return $property.Value
}

Write-Host '[SETUP] Loading e-commerce CSV datasets into PostgreSQL...' -ForegroundColor Cyan

foreach($f in @('customers.csv','products.csv','orders.csv','order_items.csv','payments.csv')){
    & docker.exe cp ".\data\$f" "ecommerce-postgres:/tmp/$f"
}

& docker.exe exec ecommerce-postgres psql -U ecommerce -d ecommerce -v ON_ERROR_STOP=1 -c "TRUNCATE TABLE order_items, payments, orders, products, customers, clickstream_events RESTART IDENTITY CASCADE;"

foreach($spec in @(
    @{Table='customers'; File='customers.csv'},
    @{Table='products'; File='products.csv'},
    @{Table='orders'; File='orders.csv'},
    @{Table='order_items'; File='order_items.csv'},
    @{Table='payments'; File='payments.csv'}
)){
    $cmd="\copy $($spec.Table) FROM '/tmp/$($spec.File)' WITH (FORMAT csv, HEADER true)"
    & docker.exe exec ecommerce-postgres psql -U ecommerce -d ecommerce -v ON_ERROR_STOP=1 -c $cmd
}

Write-Host '[SETUP] Loading clickstream JSON events into PostgreSQL...' -ForegroundColor Cyan
$rows=@()
Get-Content '.\data\clickstream.json' | ForEach-Object {
    if($_.Trim()) { $rows += ($_ | ConvertFrom-Json) }
}

$sqlPath=Join-Path $PWD 'data\clickstream-load.sql'
$sw=[System.IO.StreamWriter]::new($sqlPath,$false,[System.Text.UTF8Encoding]::new($false))
try {
    $sw.WriteLine('BEGIN;')
    $batch=500
    for($i=0;$i -lt $rows.Count;$i += $batch){
        $end=[Math]::Min($i+$batch,$rows.Count)
        $values=New-Object System.Collections.Generic.List[string]
        for($j=$i;$j -lt $end;$j++){
            $r=$rows[$j]
            $amount=JsonValue $r 'amount'
            $amountSql='NULL'
            if($null -ne $amount -and -not [string]::IsNullOrWhiteSpace([string]$amount)){ $amountSql=[string]$amount }
            $values.Add("($(SqlText (JsonValue $r 'event_id')),$(SqlText (JsonValue $r 'event_time')),$(SqlText (JsonValue $r 'user_id')),$(SqlText (JsonValue $r 'session_id')),$(SqlText (JsonValue $r 'event_type')),$(SqlText (JsonValue $r 'product_id')),$(SqlText (JsonValue $r 'page')),$(SqlText (JsonValue $r 'order_id')),$amountSql)")
        }
        $sw.WriteLine('INSERT INTO clickstream_events(event_id,event_time,user_id,session_id,event_type,product_id,page,order_id,amount) VALUES')
        $sw.WriteLine(($values -join ",`n") + ';')
    }
    $sw.WriteLine('COMMIT;')
} finally { $sw.Dispose() }

& docker.exe cp $sqlPath ecommerce-postgres:/tmp/clickstream-load.sql
& docker.exe exec ecommerce-postgres psql -U ecommerce -d ecommerce -v ON_ERROR_STOP=1 -f /tmp/clickstream-load.sql
Remove-Item -Force $sqlPath

& docker.exe exec ecommerce-postgres psql -U ecommerce -d ecommerce -c "SELECT 'customers' AS table_name,count(*) AS rows FROM customers UNION ALL SELECT 'products',count(*) FROM products UNION ALL SELECT 'orders',count(*) FROM orders UNION ALL SELECT 'order_items',count(*) FROM order_items UNION ALL SELECT 'payments',count(*) FROM payments UNION ALL SELECT 'clickstream_events',count(*) FROM clickstream_events ORDER BY table_name;"
Write-Host '[OK] PostgreSQL operational and clickstream datasets loaded.' -ForegroundColor Green
