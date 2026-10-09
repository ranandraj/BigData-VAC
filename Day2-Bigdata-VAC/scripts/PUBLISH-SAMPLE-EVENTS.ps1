Set-Location "$PSScriptRoot\.."; $events=@(
'{"event_id":"LIVE001","event_time":"2026-10-08 18:00:00","user_id":"C0001","session_id":"S1001","event_type":"product_view","product_id":"P0001","page":"product"}',
'{"event_id":"LIVE002","event_time":"2026-10-08 18:00:05","user_id":"C0001","session_id":"S1001","event_type":"cart_added","product_id":"P0001","page":"cart"}',
'{"event_id":"LIVE003","event_time":"2026-10-08 18:00:10","user_id":"C0001","session_id":"S1001","event_type":"order_created","order_id":"LIVE001","amount":75000,"page":"checkout"}',
'{"event_id":"LIVE004","event_time":"2026-10-08 18:00:15","user_id":"C0002","session_id":"S1002","event_type":"payment_completed","amount":30000,"page":"checkout"}'
); foreach($e in $events){ $e | & docker.exe exec -i kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:29092 --topic ecommerce-events }; Write-Host 'Sample live events published.' -ForegroundColor Green