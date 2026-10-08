# AR INFOTEK Big Data VAC - v7 Student Session-by-Session Lab

## Purpose

v7 keeps the successful HDFS-fixed infrastructure from v6 but changes the student workflow to a session-by-session model.

Students start each technology only when that session begins, perform the meaningful commands themselves, observe the result, and then connect it to the next technology.

## Recommended operating model

### Trainer / Lab Administrator before the workshop

Run:

```powershell
.\PRE-FLIGHT-CHECK.ps1
.\SETUP-WINDOWS-PREREQUISITES.cmd
.\scripts\INSTALL-LAB-BASE.ps1
```

The existing v6 all-in-one scripts remain available for trainer recovery/reset. Do not use them as the normal student workflow.

### Students during Day 1

| Session | Topic | Student action |
|---|---|---|
| 1 | Architecture | Concept + architecture drawing |
| 2 | HDFS | Start HDFS, run HDFS commands, inspect distributed storage |
| 3 | PostgreSQL | Start PostgreSQL, query and modify e-commerce data |
| 4 | NiFi | Start NiFi, create ingestion flows |
| 5 | Kafka | Start Kafka, create topic, producer, consumer, group and inspect offsets |
| 6 | Debezium | Start/register connector, make DB changes and observe CDC events |
| 7 | Flink | Start Flink, build/submit simple Kafka processing job |
| 8 | Integration | Verify and demonstrate end-to-end flow |

## Important

Do not run every `START` script at the same time. Start only the components required for the current session. If a later session depends on an earlier service, the guide will tell you to keep that service running.

## Day 1 architecture

```text
PostgreSQL -> Debezium -> Kafka -> Flink -> Processed Output
       \                         
        \-> NiFi -> HDFS / files
```

HDFS, PostgreSQL, Kafka, NiFi, Debezium and Flink are pre-containerized so installation does not consume the workshop. Students still perform the meaningful configuration and data-flow operations.
