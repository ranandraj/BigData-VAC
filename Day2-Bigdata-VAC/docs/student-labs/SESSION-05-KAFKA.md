# Session 5 - Apache Kafka Event Streaming

**Duration:** 75 minutes

## Objective

Create topics, inspect partitions and offsets, publish events and consume them.

## 1. List topics

```powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --list
```

## 2. Describe the main event topic

```powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --describe --topic ecommerce-events
```

Record:

- topic name
- partition count
- replication factor

## 3. Produce an event

```powershell
'{"event_id":"LAB-001","event_time":"2026-10-08 10:00:00","user_id":"C001","session_id":"S001","event_type":"product_view","product_id":"P001","page":"/product/P001","order_id":null,"amount":0}' | docker exec -i kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:29092 --topic ecommerce-events
```

## 4. Consume events

```powershell
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic ecommerce-events --from-beginning --max-messages 5
```

## 5. Generate more events

```powershell
.\scripts\GENERATE-CLICKSTREAM.ps1 -Count 100
```

## 6. Inspect another topic

```powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --describe --topic ecommerce-orders
```

## 7. Observe offsets

Run a consumer with a small number of messages and observe that Kafka assigns offsets to records.

## Checkpoint

Explain:

- Broker
- Topic
- Partition
- Offset
- Producer
- Consumer
- Consumer group

## Evidence

Submit the topic description and one consumed event.
