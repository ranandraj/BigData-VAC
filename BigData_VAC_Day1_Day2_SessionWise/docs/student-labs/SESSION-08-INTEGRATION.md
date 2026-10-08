# Session 8 - Complete Integration

Run:
```powershell
.\scripts\session\07-VERIFY-INTEGRATION.ps1
```

Then demonstrate the complete flow:

`PostgreSQL -> Debezium -> Kafka -> Flink -> processed output`

Also verify HDFS contains the e-commerce historical/raw data.

## Final questions
1. Why is PostgreSQL called an operational source?
2. What problem does CDC solve?
3. Why is Kafka between Debezium and Flink?
4. What does Flink do that Kafka does not?
5. What is the role of HDFS?
6. What is the role of NiFi?
7. Explain the difference between a Kafka topic, partition and offset.
