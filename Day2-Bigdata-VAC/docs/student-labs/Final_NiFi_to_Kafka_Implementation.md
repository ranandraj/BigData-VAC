# Final Session 4 Implementation: Apache NiFi to Kafka

## Final Session 4 implementation

```text
Generated E-Commerce CSV
        │
        ▼
     Apache NiFi
        │
        ▼
     GetFile
        │
        ▼
   ConvertRecord
   CSV → JSON
        │
        ▼
  UpdateAttribute
        │
        ▼
 RouteOnAttribute
        │
        ▼
   PublishKafka
        │
        ▼
      Kafka
        │
        ▼
 ecommerce-events
        │
        ▼
      Flink
        │
        ▼
 Real-Time Analytics
        │
        ├──────────────► MongoDB
        │                    │
        │                    ▼
        │               Streamlit
        │
        └──────────────► Kafka metrics/anomalies
```

This is the implementation students will actually use. **Do not use PutFile as the final destination.**

NiFi's `GetFile` is used to ingest the generated file, `ConvertRecord` converts CSV records to JSON, `UpdateAttribute` adds FlowFile metadata, `RouteOnAttribute` performs the routing decision, and `PublishKafka` sends the resulting data to Kafka.

---

## 1. Input data

Use the **already generated e-commerce dataset from the package**.

For Session 4, use:

```text
orders.csv
```

Do not use a manually created sample CSV.

Create a dedicated NiFi input directory:

```text
/labdata/nifi-session4
```

Place/copy the generated:

```text
orders.csv
```

there.

This avoids NiFi consuming the other generated datasets such as:

```text
customers.csv
products.csv
order_items.csv
payments.csv
```

`GetFile` supports a regular-expression file filter, so configure it specifically for `orders.csv`.

---

# 2. Create the NiFi flow

Create Process Group:

```text
E-Commerce-NiFi
```

Inside it create:

```text
GetFile
    ↓
ConvertRecord
    ↓
UpdateAttribute
    ↓
RouteOnAttribute
    ↓
PublishKafka
```

This is the flow students implement.

---

# 3. GetFile

Processor:

```text
GetFile
```

Configure:

| Property | Value |
|---|---|
| Input Directory | `/labdata` |
| File Filter | `.*order.*\.csv` |
| Keep Source File | `true` |
| Recurse Subdirectories | `false` |
| Ignore Hidden Files | `true` |
| Batch Size | `10` |

Keep Source File is set to `true` because this is a training environment and the original generated dataset should remain available for reuse. Normally `GetFile` can delete the source file after ingestion.

Start the processor.

Expected:

```text
orders.csv
     ↓
FlowFile
```

---

# 4. ConvertRecord

Processor:

```text
ConvertRecord
```

Purpose:

```text
CSV → JSON
```

Configure:

### Record Reader

Use:

```text
CSVReader
```

Configure it to read the CSV header.

### Record Writer

Use:

```text
JsonRecordSetWriter
```

So:

```text
orders.csv

order_id,customer_id,order_date,amount,...
```

becomes JSON records.

`ConvertRecord` is designed to convert record-oriented data between formats using a Record Reader and Record Writer.

---

# 5. UpdateAttribute

Processor:

```text
UpdateAttribute
```

Add these properties:

```text
source.system = ecommerce
data.domain = orders
data.type = order
pipeline.stage = nifi
```

Therefore every FlowFile carries metadata such as:

```text
filename = orders.csv
source.system = ecommerce
data.domain = orders
data.type = order
pipeline.stage = nifi
```

These attributes are then used by the next processor.

---

# 6. RouteOnAttribute

Processor:

```text
RouteOnAttribute
```

Configure:

```text
Routing Strategy = Route to Property name
```

Add:

```text
order_data = ${data.type:equals('order')}
```

Therefore:

```text
data.type = order
        ↓
order_data
```

The `RouteOnAttribute` processor routes FlowFiles using NiFi Expression Language against FlowFile attributes.

Connect:

```text
order_data
     ↓
PublishKafka
```

For this final implementation, there is **no need to send the unmatched data anywhere**. Auto-terminate the `unmatched` relationship.

---

# 7. PublishKafka

This is the most important part.

Processor:

```text
PublishKafka
```

Configure the Kafka connection to the Kafka service already running in the package.

Kafka broker:

```text
kafka:29092
```

Topic:

```text
ecommerce-events
```

Use:

```text
Publish Strategy = Use Content as Record Value
```

The purpose is:

```text
NiFi
  ↓
JSON
  ↓
Kafka
  ↓
ecommerce-events
```

`PublishKafka` sends FlowFile content to Kafka.

---

# 8. Final NiFi flow

The students should physically build this:

```text
┌───────────────────┐
│     GetFile       │
│ /labdata/         │
│ nifi-session4     │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│   ConvertRecord   │
│    CSV → JSON     │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│  UpdateAttribute  │
│ source.system     │
│ data.domain       │
│ data.type         │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│ RouteOnAttribute  │
│ data.type=order   │
└─────────┬─────────┘
          │ order_data
          ▼
┌───────────────────┐
│   PublishKafka    │
│ kafka:29092       │
│ ecommerce-events  │
└─────────┬─────────┘
          │
          ▼
     ┌─────────┐
     │  Kafka  │
     └────┬────┘
          │
          ▼
ecommerce-events
```

This is the **actual production path used by the lab**, not a demonstration-only path.

---

# 9. Verify Kafka

From PowerShell:

```powershell
docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh `
  --bootstrap-server kafka:29092 `
  --topic ecommerce-events `
  --from-beginning
```

You should see the orders arriving from NiFi.

The data path is now:

```text
orders.csv
   ↓
NiFi
   ↓
CSV → JSON
   ↓
NiFi metadata
   ↓
NiFi routing
   ↓
Kafka
   ↓
ecommerce-events
```

---

# 10. What happens in the next sessions

This is important because **Session 4 must not be isolated**.

## Session 4

```text
orders.csv
    ↓
NiFi
    ↓
ecommerce-events
```

## Session 5

Students learn:

```text
Kafka
    ↓
Topics
Partitions
Producers
Consumers
Offsets
Consumer Groups
```

and inspect:

```text
ecommerce-events
```

## Session 6

PostgreSQL CDC becomes:

```text
PostgreSQL
    ↓
Debezium
    ↓
Kafka
```

## Session 7

Flink consumes the Kafka data:

```text
Kafka
    ↓
Flink
    ↓
Filtering
Mapping
Transformation
Windowing
Aggregation
```

## Final analytics

```text
                    ┌──► MongoDB ──► Streamlit
                    │
PostgreSQL/Debezium ─► Kafka ─► Flink
                    │
NiFi ───────────────► Kafka ───────┤
                                   │
                                   ├──► Metrics
                                   │
                                   └──► Anomalies
```

So **the NiFi data is genuinely used in the final analytics pipeline**.

There is no separate "demo pipeline" and "actual pipeline." The same `ecommerce-events` Kafka topic is the handoff into the subsequent processing stages.
