# AR INFOTEK Big Data VAC: PostgreSQL CDC with Debezium and Kafka

**Project:** Advanced Big Data Engineering & Real-Time E-Commerce
Analytics\
**Environment:** Windows 11, PowerShell, Docker Compose\
**Work documented:** 8 October 2026\
**Status:** Debezium connector is running and an update event was
reported as sent. Kafka consumer verification on the expected topic is
the next step.

## 1. Objective

Configure Change Data Capture (CDC) for the e-commerce PostgreSQL
database using Debezium and Kafka. The goal is to capture row-level
database changes, such as an order status update, and publish them as
Kafka events so downstream streaming tools such as Apache Flink can
consume them.

Expected flow:

``` text
PostgreSQL (ecommerce)
        |
        | transaction log / logical replication
        v
Debezium PostgreSQL Connector
        |
        | change event
        v
Kafka topic: ecommerce.public.orders
        |
        v
Kafka consumer / downstream stream processing
```

The topic name above is derived from the configured topic prefix
`ecommerce` and the table `public.orders`. Confirm it against the actual
Kafka topic list if the consumer receives no output.

## 2. Environment and configuration

The commands below were run from the extracted lab package directory:

``` text
C:\Users\ranan\Downloads\AR_INFOTEK_BigData_VAC_v13_FINAL_REVISED_FIXED_CLICKSTREAM\v13work
```

Relevant services and endpoints:

  Component                                       Details
  ----------------------------------------------- --------------------------------------------
  PostgreSQL                                      Docker container `ecommerce-postgres`
  Database                                        `ecommerce`
  Database user                                   `ecommerce`
  Debezium / Kafka Connect REST API               `http://localhost:8083`
  Debezium connector                              `ecommerce-postgres`
  Kafka bootstrap address inside Docker network   `kafka:29092`
  Kafka consumer utility                          `/opt/kafka/bin/kafka-console-consumer.sh`

The running connector configuration in the logs included:

``` properties
topic.prefix=ecommerce
table.include.list=public.customers,public.products,public.orders,public.order_items,public.payments
```

This means Debezium is configured to capture changes from the listed
tables. For the `public.orders` table, the expected topic name under the
standard schema topic naming strategy is:

``` text
ecommerce.public.orders
```

## 3. Checked the Debezium connector status

The connector status was queried from PowerShell:

``` powershell
Invoke-RestMethod http://localhost:8083/connectors/ecommerce-postgres/status |
    ConvertTo-Json -Depth 10
```

The response reported:

-   Connector name: `ecommerce-postgres`
-   Connector state: `RUNNING`
-   Task ID: `0`
-   Task state: `RUNNING`
-   Connector version: `3.7.0.Final`
-   Connector type: `source`

**Result:** The connector and its task were running when checked. This
confirms that Kafka Connect had not reported the connector or task as
failed at that time. It does not, by itself, prove that a particular
consumer is subscribed to the correct topic.

## 4. Updated a PostgreSQL order to generate a CDC event

Connected to PostgreSQL using:

``` powershell
docker exec -it ecommerce-postgres psql -U ecommerce -d ecommerce
```

The following SQL update was executed:

``` sql
UPDATE orders
SET status = 'CDC_TEST'
WHERE order_id = 'O00002'
RETURNING order_id, status, total_amount;
```

The database returned the row with these values:

``` text
order_id | status   | total_amount
---------+----------+-------------
O00002   | CDC_TEST | 541005.00
```

A further update was executed:

``` sql
UPDATE orders
SET status = 'SHIPPED'
WHERE order_id = 'O00002'
RETURNING order_id, status, total_amount;
```

The database returned:

``` text
order_id | status  | total_amount
---------+---------+-------------
O00002   | SHIPPED | 541005.00
```

**Result:** PostgreSQL confirmed that the row was updated. This
establishes that the database-side test change occurred; Kafka consumer
output must be checked separately.

Exit the PostgreSQL shell with:

``` sql
\q
```

## 5. Checked Debezium logs

The recent Debezium logs were inspected with:

``` powershell
docker logs --tail 80 debezium
```

The logs showed that:

-   Debezium found a previously stored offset.
-   A new snapshot was skipped because a completed snapshot was already
    recorded.
-   Streaming started from the stored log sequence number (LSN).
-   The PostgreSQL replication stream was processing messages.
-   A log entry reported **1 record sent**, with `messageType=UPDATE`.
-   Kafka Connect subsequently reported committing offsets for
    acknowledged messages.

**Interpretation:** The logs provide evidence that Debezium processed
and sent an update record. The console consumer still needs to be tested
against the correct topic to verify that the event is visible to the
user.

### Why the consumer may appear empty

The connector being `RUNNING` and the logs reporting a sent update do
not guarantee that the consumer terminal will display the event.
Possible causes include:

1.  The consumer is listening to a different topic, such as a manually
    created lab topic, instead of the Debezium table topic.
2.  The consumer was started after an event and was not configured with
    `--from-beginning` to read retained messages.
3.  The expected topic name differs from the actual topic created in
    this lab configuration.
4.  The consumer command or terminal session did not start as intended.

The first diagnostic step is to list topics and confirm the exact topic
name.

## 6. Next step: consume from the Debezium orders topic

Open a **new PowerShell terminal** and run the complete command below.
Leave the consumer running:

``` powershell
docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh `
  --bootstrap-server kafka:29092 `
  --topic ecommerce.public.orders `
  --from-beginning
```

The command uses the Kafka address available inside the Docker network
and reads retained messages from the beginning of the topic.

### Generate a fresh test event

While the consumer remains open, open a **second PowerShell terminal**
and connect to PostgreSQL:

``` powershell
docker exec -it ecommerce-postgres psql -U ecommerce -d ecommerce
```

Execute a new update so the test is unambiguous:

``` sql
UPDATE orders
SET status = 'CDC_TEST_2'
WHERE order_id = 'O00002'
RETURNING order_id, status, total_amount;
```

Expected observation: the consumer should display a JSON change-event
record for `ecommerce.public.orders`. In the event's `after` object,
look for the updated order and a status value of `CDC_TEST_2`. The exact
JSON envelope may vary with connector settings and serialization
configuration.

Stop the consumer with **Ctrl+C** after checking the output. This stops
the console consumer, not the Kafka or Debezium services.

## 7. If no event appears: identify the actual topic

List all Kafka topics:

``` powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh `
  --bootstrap-server kafka:29092 `
  --list
```

Look for the topic corresponding to `public.orders`. If
`ecommerce.public.orders` is listed, inspect it:

``` powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh `
  --bootstrap-server kafka:29092 `
  --describe `
  --topic ecommerce.public.orders
```

If the topic is **not** listed, do not create it manually as the first
fix. Share the complete topic-list output and inspect the connector's
topic naming configuration. Creating a topic with a guessed name could
leave the consumer listening to a topic that Debezium does not publish
to.

If the topic exists but there is still no output, collect these
diagnostics:

``` powershell
Invoke-RestMethod http://localhost:8083/connectors/ecommerce-postgres/status |
    ConvertTo-Json -Depth 10

docker logs --tail 120 debezium
```

Also record the exact consumer command used and the result of the fresh
`CDC_TEST_2` update.

## 8. What has been completed and what remains

### Completed and observed

-   Accessed the PostgreSQL `ecommerce` database in the Docker
    environment.
-   Updated order `O00002` and confirmed the returned row values.
-   Queried the Debezium connector status.
-   Confirmed that connector `ecommerce-postgres` and task `0` reported
    `RUNNING`.
-   Inspected Debezium logs and found evidence of an `UPDATE` record
    being sent and acknowledged offsets being committed.
-   Identified `ecommerce.public.orders` as the expected Debezium topic
    based on `topic.prefix=ecommerce` and the `public.orders` table.

### Pending validation

-   Confirm the actual orders topic exists using Kafka's topic-list
    command.
-   Start the console consumer on the verified topic.
-   Make a fresh database update while the consumer is running.
-   Confirm that the consumer prints the new event and inspect its
    `after` fields.
-   Once this is confirmed, proceed to the next lab step: consume the
    CDC topic from a downstream stream-processing job, such as Apache
    Flink.

## 9. Troubleshooting notes

-   In PowerShell, paste and run the full pipeline command. Do not
    execute `ConvertTo-Json -Depth 10` alone; it is intended to be piped
    from `Invoke-RestMethod`.
-   For multiline PowerShell commands, the backtick must be the final
    character on the line. Avoid trailing spaces after it.
-   Use `kafka:29092` for commands executed inside the Kafka container's
    Docker network, as in the commands above.
-   A PostgreSQL `UPDATE` result confirms a database change, not that
    the consumer has displayed the event.
-   Do not reset connector offsets, delete topics, or recreate the
    connector until the actual topic name and consumer output have been
    checked.

## 10. Success criteria

The Debezium-to-Kafka test is complete when all of the following are
observed:

-   The connector and task are `RUNNING`.
-   The actual Debezium orders topic is identified.
-   A new SQL update changes `O00002` to `CDC_TEST_2`.
-   The Kafka consumer displays the corresponding update event.
-   The event's `after` object contains the changed order data.

At the time this document was prepared, the connector-running status and
Debezium update-send log were observed, but the final console-consumer
output had not yet been confirmed.
