# Session 4 - Apache NiFi: E-Commerce Ingestion

## Objective
Build practical NiFi ingestion flows that move e-commerce data from files and PostgreSQL into the lab pipeline, then publish selected events to Kafka.

## Practical A - Historical file ingestion

### Flow
```text
GetFile -> UpdateAttribute -> PutFile
```

### Steps
1. Open the NiFi UI at `http://localhost:8443/nifi`.
2. Add `GetFile` and set the input directory to `/labdata`.
3. Add `UpdateAttribute` and create an output-related attribute if required by the exercise.
4. Add `PutFile` and set the directory to `/laboutput/orders`.
5. Connect the processors and enable them.
6. Place or copy `orders.csv` into the input area.
7. Verify the output file under `/laboutput/orders`.

### Checkpoint
Explain what a FlowFile is, what a Processor does, and why the queue between processors is useful.

## Practical B - Route e-commerce data

Build a routing flow using `RouteOnAttribute`.

Example logic:
- CSV files -> CSV processing path
- JSON files -> JSON processing path

Use filename-based attributes such as `${filename:endsWith('.csv')}` and `${filename:endsWith('.json')}`.

### Checkpoint
Demonstrate one CSV file and one JSON file taking different paths.

## Practical C - PostgreSQL ingestion

### Flow
```text
ExecuteSQL -> ConvertRecord -> PutFile
```

Use the PostgreSQL connection configured for the lab.

Example query:
```sql
SELECT * FROM orders LIMIT 100;
```

Configure `ConvertRecord` for a suitable record format and write the result with `PutFile`.

### Checkpoint
Verify that records returned from PostgreSQL appear in the destination directory.

## Practical D - Publish selected events to Kafka

Use NiFi to publish selected e-commerce records to Kafka topic:

```text
ecommerce-events
```

A practical flow can be:

```text
GetFile / database source
        -> record conversion
        -> event formatting
        -> PublishKafka
```

Verify the topic with the Kafka tools from Session 5.

## Student tasks

1. Create the historical file flow.
2. Route CSV and JSON files using `RouteOnAttribute`.
3. Read orders from PostgreSQL with `ExecuteSQL`.
4. Convert the database result into a suitable event/record format.
5. Publish at least one selected e-commerce event to `ecommerce-events`.
6. Capture evidence of the flow and successful output.

## Questions

- What is a FlowFile?
- What is the difference between a Processor and a Connection?
- Why use `RouteOnAttribute` instead of creating two independent input flows?
- What role does `ConvertRecord` play?
- Where does NiFi stop and Kafka begin in this architecture?

## Expected architecture position

```text
Historical Files / PostgreSQL
          |
          v
        NiFi
          |
          v
        Kafka
          |
          v
        Flink
```

Session 4 establishes the ingestion layer used by the streaming sessions that follow.
