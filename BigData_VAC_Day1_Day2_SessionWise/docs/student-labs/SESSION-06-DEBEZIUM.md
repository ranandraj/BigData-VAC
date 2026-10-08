# Session 6 - PostgreSQL CDC with Debezium

## Start
```powershell
.\scripts\session\05-START-DEBEZIUM.ps1
.\scripts\session\05-REGISTER-DEBEZIUM.ps1
```

The connector should report `RUNNING`.

## Inspect connector
```powershell
Invoke-RestMethod http://localhost:8083/connectors/ecommerce-postgres/status
```

## Make a database change
```powershell
docker exec -it ecommerce-postgres psql -U ecommerce -d ecommerce
```

```sql
INSERT INTO orders(order_id,customer_id,product_id,quantity,amount,status) VALUES ('CDC01','C002','P003',2,5000,'CREATED');
UPDATE orders SET status='PAID' WHERE order_id='CDC01';
```

## Observe Kafka CDC topic
First list topics:
```powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --list
```

The Debezium topic prefix is `ecommerce`. Inspect the generated orders topic and consume from the beginning.

Explain: source database -> transaction change -> Debezium -> Kafka event.
