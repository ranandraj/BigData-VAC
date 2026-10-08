# Session 5 - Apache Kafka

## Start
```powershell
.\scripts\session\04-START-KAFKA.ps1
```

## List topics
```powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --list
```

## Create your own topic
Replace ROLLNO:
```powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --create --if-not-exists --topic student-ROLLNO-events --partitions 3 --replication-factor 1
```

## Producer
```powershell
docker exec -it kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:29092 --topic student-ROLLNO-events
```

Send:
`product_view,101,501`
`cart_added,101,501`
`order_created,101,501`
`payment_completed,101,501`

## Consumer
Open another PowerShell window:
```powershell
docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic student-ROLLNO-events --from-beginning --group student-ROLLNO-group
```

## Inspect partitions and offsets
```powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --describe --topic student-ROLLNO-events
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka:29092 --describe --group student-ROLLNO-group
```
