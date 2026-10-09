# Flink SQL Client Guide - v13

## Architecture

```text
Kafka -> Flink SQL Client -> Flink JobManager -> Flink TaskManager
                                      |
                                      +-> Kafka metrics
                                      +-> Kafka anomalies
```

The SQL Client is part of the standard Flink distribution and can submit SQL scripts to a running cluster.

## Start

```powershell
.\scripts\RUN-FLINK-SQL.ps1
```

Or open an interactive session:

```bash
docker exec -it flink-sql-client ./bin/sql-client.sh
```

## SQL script

`sql/flink/ecommerce-realtime.sql`

The script defines the Kafka source, event-time watermark, one-minute window, KPI output and high-value-order output.

## Outputs

- `ecommerce-metrics`
- `ecommerce-anomalies`

## Student sequence

1. Inspect the source table.
2. Identify the watermark.
3. Identify the one-minute window.
4. Identify the KPI aggregations.
5. Identify the high-value order rule.
6. Submit the SQL job.
7. Generate events.
8. Observe the job in the Flink Web UI.
9. Consume the Kafka output topics.
