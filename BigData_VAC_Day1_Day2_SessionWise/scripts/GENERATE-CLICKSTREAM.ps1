param([int]$Count=20)
Set-Location "$PSScriptRoot\.."
for($i=1;$i -le $Count;$i++){
 $j=@{event_id=[guid]::NewGuid().ToString();customer_id="C00"+(($i%5)+1);event_type=@("product_view","cart_add","checkout","payment")[$i%4];product_id="P00"+(($i%3)+1);event_time=(Get-Date).ToString("o")}|ConvertTo-Json -Compress
 $j|docker exec -i kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:29092 --topic ecommerce-events
}
