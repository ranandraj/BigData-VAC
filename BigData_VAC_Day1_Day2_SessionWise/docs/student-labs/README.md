# AR INFOTEK Big Data VAC v7 - Student Lab

This package uses session-by-session setup. Run only the script for the current session.

## Student workflow

1. Read the session objective.
2. Start the technology using the session script.
3. Run the commands yourself.
4. Observe the result.
5. Explain what happened before moving to the next technology.
6. Do not use the trainer's all-in-one installation script during the lab.

## Day 1 sequence

| Session | Technology | Start script |
|---|---|---|
| 1 | Architecture | No script |
| 2 | HDFS | `scripts/session/01-START-HDFS.ps1` |
| 3 | PostgreSQL | `scripts/session/02-START-POSTGRES.ps1` |
| 4 | NiFi | `scripts/session/03-START-NIFI.ps1` |
| 5 | Kafka | `scripts/session/04-START-KAFKA.ps1` |
| 6 | Debezium CDC | `scripts/session/05-START-DEBEZIUM.ps1`, then `05-REGISTER-DEBEZIUM.ps1` |
| 7 | Flink | `scripts/session/06-START-FLINK.ps1`, then build/submit the job |
| 8 | Integration | `scripts/session/07-VERIFY-INTEGRATION.ps1` |
