# Session 7 - Apache Flink

## Start
```powershell
.\scripts\session\06-START-FLINK.ps1
```

Open `http://localhost:8081`.

## Build the Day 1 job
```powershell
.\scripts\session\06-BUILD-FLINK-JOB.ps1
```

## Submit
```powershell
.\scripts\session\06-SUBMIT-FLINK-JOB.ps1
```

The job reads `ecommerce-events`, filters `order_created` events, maps them and prints the processed result.

## Generate an event
```powershell
docker exec -it kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:29092 --topic ecommerce-events
```

Send:
`order_created,101,501`

Observe the Flink job output and Flink Web UI.
