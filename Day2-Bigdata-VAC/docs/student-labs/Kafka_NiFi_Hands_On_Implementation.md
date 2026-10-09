# Apache Kafka Hands-on Implementation
## AR INFOTEK Big Data VAC: Kafka and NiFi Integration

## 1. Objective

Verify that the Kafka service in the Docker-based Big Data VAC package is running, create and inspect the `ecommerce-events` topic, test Kafka using a console producer and consumer, and connect the NiFi Session 4 flow to Kafka using the generated e-commerce `orders.csv` dataset.

The target data path is:

```text
orders.csv
    |
    v
Apache NiFi
    |
    v
GetFile
    |
    v
ConvertRecord (CSV to JSON)
    |
    v
UpdateAttribute
    |
    v
RouteOnAttribute
    |
    v
PublishKafka
    |
    v
Kafka topic: ecommerce-events
    |
    v
Flink and downstream analytics
```

The manual producer/consumer exercise is a Kafka connectivity test. The NiFi-to-Kafka flow is the intended data-ingestion path for the VAC.

---

## 2. Environment and service names

The implementation discussed uses Docker Compose and the Kafka service/container named:

```text
kafka
```

The Kafka broker address used by containers on the Docker network is:

```text
kafka:29092
```

The NiFi input directory configured for this exercise is:

```text
/labdata/nifi-session4
```

The input file is:

```text
orders.csv
```

The Kafka topic is:

```text
ecommerce-events
```

Run Docker commands from PowerShell in the directory containing the package's `docker-compose.yml` when using Docker Compose commands.

---

## 3. Check whether Kafka is running

Run:

```powershell
docker compose ps kafka
```

Look for the Kafka service and a running status such as `Up`.

You can also check the container directly:

```powershell
docker ps --filter "name=kafka"
```

A running container alone does not prove that the broker is ready to accept requests. Test Kafka by listing topics:

```powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh `
  --bootstrap-server kafka:29092 `
  --list
```

If the command returns a topic list without a connection error, the broker is responding to this request.

### If Kafka is stopped

From the directory containing `docker-compose.yml`, run:

```powershell
docker compose up -d kafka
```

Check the status again:

```powershell
docker compose ps kafka
```

Then repeat the topic-list command.

> Use the service/container names and ports from the actual package. The `kafka:29092` address is the internal Docker-network address used in this implementation; it is not necessarily the address to use from applications running directly on Windows.

---

## 4. Create the e-commerce topic

Create the topic used by the NiFi flow:

```powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh `
  --create `
  --topic ecommerce-events `
  --bootstrap-server kafka:29092 `
  --partitions 3 `
  --replication-factor 1
```

If the topic already exists, Kafka may report that it already exists. In that case, do not repeatedly try to create it; inspect the existing topic.

List topics:

```powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh `
  --bootstrap-server kafka:29092 `
  --list
```

Confirm that the list includes:

```text
ecommerce-events
```

### Describe the topic

```powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh `
  --bootstrap-server kafka:29092 `
  --describe `
  --topic ecommerce-events
```

For the topic created with the command above, expect three partitions and a replication factor of one. This is a single-broker training setup, not a production replication configuration.

---

## 5. Hands-on: test Kafka with a console consumer and producer

This exercise checks Kafka independently before troubleshooting NiFi.

### Terminal 1: start a consumer

Open a PowerShell terminal and run:

```powershell
docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh `
  --bootstrap-server kafka:29092 `
  --topic ecommerce-events `
  --from-beginning
```

Leave this terminal open. It waits for messages.

### Terminal 2: start a producer

Open a second PowerShell terminal and run:

```powershell
docker exec -it kafka /opt/kafka/bin/kafka-console-producer.sh `
  --bootstrap-server kafka:29092 `
  --topic ecommerce-events
```

Enter these test messages one at a time, pressing Enter after each:

```json
{"order_id":1001,"customer_id":101,"amount":2500,"status":"PLACED"}
{"order_id":1002,"customer_id":102,"amount":8500,"status":"PLACED"}
{"order_id":1003,"customer_id":103,"amount":1200,"status":"SHIPPED"}
```

### Expected result

The consumer terminal should display the messages. This verifies the basic path:

```text
Console Producer
       |
       v
Kafka: ecommerce-events
       |
       v
Console Consumer
```

Stop the producer and consumer with `Ctrl+C` when the exercise is complete.

These are test events entered manually. They are not the generated `orders.csv` records.

---

## 6. Configure the NiFi flow

The NiFi flow being built for Session 4 is:

```text
GetFile
   |
   v
ConvertRecord
   |
   v
UpdateAttribute
   |
   v
RouteOnAttribute
   |
   v
PublishKafka
```

Create a Process Group named:

```text
E-Commerce-NiFi
```

Add the five processors and connect them in the order shown above.

### 6.1 GetFile

The processor configuration shown in the working session used:

| Property | Value |
|---|---|
| Input Directory | `/labdata/nifi-session4` |
| File Filter | `^orders\.csv$` |
| Batch Size | `10` |

The file filter is intended to match only `orders.csv`, rather than ingesting every CSV file in the shared dataset directory.

Place a copy of the package-generated `orders.csv` in the directory mapped to `/labdata/nifi-session4` inside the NiFi container. Use a dedicated input folder so that NiFi does not consume the canonical dataset files needed by other exercises.

If the `GetFile` processor has a `Keep Source File` property in the installed version, set it to `true` for this repeatable training exercise. Confirm the property is available in the processor version before relying on it.

### 6.2 ConvertRecord

The selected Controller Services in the attempted configuration were:

| Property | Selected service |
|---|---|
| Record Reader | `CSVReader` |
| Record Writer | `JsonRecordSetWriter` |
| Include Zero Record FlowFiles | `true` |

Ensure that both `CSVReader` and `JsonRecordSetWriter` are correctly configured and enabled. If the processor is marked `Invalid`, open the validation indicator and fix the reported service or property error before starting the flow.

The intended transformation is:

```text
CSV records
    |
    v
JSON records
```

### 6.3 UpdateAttribute

Add these attributes:

```text
source.system = ecommerce
data.domain = orders
data.type = order
pipeline.stage = nifi
```

These are FlowFile attributes used to identify the data as it moves through the NiFi flow.

### 6.4 RouteOnAttribute

Set the routing strategy to:

```text
Route to Property name
```

Add this dynamic property:

| Property name | Value |
|---|---|
| `order_data` | `${data.type:equals('order')}` |

Connect the `order_data` relationship to `PublishKafka`.

For this exercise, configure the unused `unmatched` relationship according to the NiFi relationship options shown in the installed version. Do not leave a required relationship unhandled.

### 6.5 PublishKafka

Configure `PublishKafka` to send data to the Kafka service inside the Docker network.

| Setting | Intended value |
|---|---|
| Bootstrap servers | `kafka:29092` |
| Topic | `ecommerce-events` |
| Message value | FlowFile content, using the supported content-as-record-value option if available |

The exact property labels and available publishing options depend on the `PublishKafka` processor version installed with the package. Use the processor's validation message to identify any required fields or Controller Services.

The processor showed a warning icon in the NiFi canvas during the attempted setup. Open `PublishKafka` and resolve its validation errors before expecting records to arrive in Kafka.

---

## 7. Verify the NiFi-to-Kafka handoff

### Step 1: start a consumer

In a PowerShell terminal, run:

```powershell
docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh `
  --bootstrap-server kafka:29092 `
  --topic ecommerce-events `
  --from-beginning
```

Leave it running.

### Step 2: start the NiFi flow

Once all processors are valid and the Kafka topic exists, start the NiFi processors. Ensure that `PublishKafka` is valid and configured before sending data from `GetFile`.

### Step 3: supply the generated dataset

Copy the generated `orders.csv` to the directory mapped to:

```text
/labdata/nifi-session4
```

### Step 4: observe NiFi

Check the processors and connections for:

- Incoming and outgoing FlowFiles
- Read/write counts and byte counts
- Queued FlowFiles
- Processor validation errors or bulletins
- A successful relationship from `RouteOnAttribute` to `PublishKafka`

### Step 5: observe Kafka

Look at the consumer terminal. New messages from NiFi should appear when the flow successfully reads the file, converts the records, routes the FlowFile, and publishes its content.

Because the consumer uses `--from-beginning`, it may also display the manual test messages from the earlier exercise. To distinguish the records, inspect their `order_id` values or use a new test topic for isolated tests.

---

## 8. Troubleshooting from the attempted setup

### A. Kafka container is running, but topic commands fail

Check the container logs:

```powershell
docker logs --tail 100 kafka
```

Wait for the broker to finish starting, then retry the topic-list command. A container status of `Up` alone is not a complete readiness check.

### B. NiFi processors show zero reads and writes

The canvas screenshot showed zero read/write activity and empty queues. This means no data movement had been observed at that point. Check:

1. `orders.csv` exists in the directory visible inside the NiFi container.
2. `GetFile` has the correct input directory and file filter.
3. The file has not already been consumed or moved.
4. `ConvertRecord` and its Controller Services are valid and enabled.
5. `RouteOnAttribute` has the `order_data` property and the outgoing connection is correct.
6. `PublishKafka` is valid and can connect to `kafka:29092`.

### C. GetFile does not pick up the file

The configured values shown in the NiFi screenshot were:

```text
Input Directory: /labdata/nifi-session4
File Filter: ^orders\.csv$
Batch Size: 10
```

Check that the filename is exactly `orders.csv`, with no additional extension such as `.txt`. Also confirm the host directory is mounted to the expected container path.

### D. ConvertRecord is invalid

The selected services were `CSVReader` and `JsonRecordSetWriter`. Open the `Invalid` indicator and read the exact validation message. Configure and enable the required Controller Services. Do not assume the service is ready solely because its name appears in the property field.

### E. PublishKafka has a warning icon

Open the processor and inspect the validation message. Confirm that the required broker/connection settings and topic are supplied. The intended broker address for this Docker-network flow is:

```text
kafka:29092
```

### F. Kafka consumer displays no new NiFi records

Check each stage in order:

```text
GetFile
  -> ConvertRecord
  -> UpdateAttribute
  -> RouteOnAttribute
  -> PublishKafka
  -> ecommerce-events
```

If the consumer displays the manual test events but no dataset records, Kafka is responding; investigate the NiFi flow and its input file next.

---

## 9. Student task checklist

- [ ] Check the Kafka container status.
- [ ] List Kafka topics.
- [ ] Create `ecommerce-events` if it does not already exist.
- [ ] Describe the topic and inspect its partitions.
- [ ] Start a console consumer.
- [ ] Produce three manual test messages.
- [ ] Verify the messages in the consumer.
- [ ] Configure the NiFi processors.
- [ ] Verify that `orders.csv` is available at `/labdata/nifi-session4`.
- [ ] Resolve all NiFi processor validation errors.
- [ ] Start the NiFi flow.
- [ ] Verify that the generated order data reaches `ecommerce-events`.
- [ ] Record any processor errors and how they were resolved.

---

## 10. Final architecture for the VAC

```text
Generated e-commerce orders.csv
             |
             v
           NiFi
             |
             v
      ecommerce-events
             |
             v
           Kafka
             |
             v
           Flink
             |
             v
    Filtering and transformation
             |
             v
       Real-time metrics
       and anomaly events
             |
             v
     MongoDB / Streamlit
```

The manual producer/consumer test verifies Kafka independently. The NiFi-to-Kafka flow is the intended Session 4 handoff into the later Kafka and Flink sessions.

**Implementation status note:** The NiFi canvas was connected in the attempted setup, but the screenshot showed empty queues and zero read/write activity, and `PublishKafka` displayed a warning icon. Therefore, the complete NiFi-to-Kafka data path should be considered verified only after the validation errors are cleared and records from the generated `orders.csv` are observed in the Kafka consumer.
