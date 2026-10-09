# Session 6 - PostgreSQL Change Data Capture with Debezium

**Duration:** 60 minutes

## Objective

Capture a PostgreSQL data change and observe it as a Kafka event.

## 1. Check Debezium

```powershell
Invoke-RestMethod http://localhost:8083/connectors
```

The connector should include:

```text
ecommerce-postgres
```

## 2. Inspect connector status

```powershell
Invoke-RestMethod http://localhost:8083/connectors/ecommerce-postgres/status | ConvertTo-Json -Depth 10
```

Look for `RUNNING`.

## 3. Observe the CDC topic

```powershell
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic ecommerce.public.orders --from-beginning --max-messages 3
```

## 4. Make a controlled database change

Open PostgreSQL:

```powershell
docker exec -it ecommerce-postgres psql -U ecommerce -d ecommerce
```

First inspect:

```sql
SELECT order_id, status, total_amount
FROM orders
WHERE order_id = '<order-id>';
```

Update the selected row:

```sql
UPDATE orders
SET status = 'SHIPPED'
WHERE order_id = '<order-id>';
```

Exit and consume the CDC topic again:

```powershell
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic ecommerce.public.orders --from-beginning --max-messages 10
```

## 5. Identify the CDC event

Find the record containing the changed order. Identify the Debezium envelope fields such as the operation indicator and the new row data.

## Checkpoint

Explain the flow:

```text
PostgreSQL UPDATE
       ↓
WAL / logical change
       ↓
Debezium
       ↓
Kafka CDC topic
```

## Evidence

Capture the PostgreSQL change and the corresponding Kafka CDC message.
