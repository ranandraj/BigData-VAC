# AR INFOTEK Big Data VAC v13 Change Log

## v13 Clean Fixed

- Corrected the Apache Flink 2.1 Kafka SQL connector artifact.
- The Flink image remains `flink:2.1.1-scala_2.12`.
- The compatible Kafka SQL connector is `flink-sql-connector-kafka-5.0.0-2.1.jar`.
- Updated Docker Compose mounts, installer, connector README, and installation documentation consistently.
- Installer now tries `curl.exe` first and `Invoke-WebRequest` second.
- Installer validates that the downloaded file is a real ZIP/JAR by checking the JAR signature before continuing.
- Invalid or partial connector downloads are removed automatically.
- Custom Streamlit image renamed to `ar-infotek-bigdata-v13-streamlit:1.0`.
- Initialization marker renamed to `.v13-initialized`.
- Retains the clean architecture: official Flink image, no custom Flink Dockerfile, no Maven Flink build, and Streamlit as the only custom image.
- Expanded the Session 4 NiFi student practical guide.
