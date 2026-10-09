# AR INFOTEK Big Data VAC v13 Changelog

## v13 Final Revised E-Commerce Lab

### End-to-end data correctness

- Added first-run PostgreSQL data loading from the supplied CSV datasets.
- Added first-run clickstream JSON loading into PostgreSQL.
- HDFS continues to receive the raw CSV and JSON datasets.
- Debezium now sees populated operational tables during the initial snapshot.

### Day 1 improvements

- Added Flink SQL normalization/filtering/mapping view before aggregation.
- Retained event-time watermarking and one-minute tumbling windows.
- Retained e-commerce KPI metrics and high-value order anomaly detection.

### Day 2 improvements

- Orders Iceberg table is partitioned by `day(order_date)`.
- Clickstream Iceberg table is partitioned by `day(event_time)`.
- Added a hands-on schema evolution exercise with `sales_channel`.
- Streamlit now exposes sales-channel analytics after schema evolution.

### Airflow improvements

Replaced placeholder print-only tasks with actual workflow tasks:

1. Validate Trino, Debezium, Flink and PostgreSQL.
2. Refresh partitioned Iceberg/Parquet analytical data.
3. Apply and populate the `sales_channel` schema evolution.
4. Create Trino analytical views.
5. Generate `reports/management_report.csv`.

### Packaging

- Flink image remains official `flink:2.1.1-scala_2.12`.
- Kafka SQL connector remains `5.0.0-2.1`.
- No custom Flink Dockerfile.
- No Maven Flink application.
- Streamlit is the only custom image.
- Normal startup uses `--no-build`.
- Initialization marker changed to `.v13-initialized`.

## v13.1 installer correction

- Fixed first-run Streamlit image detection.
- The installer no longer uses `docker image inspect` for an absent image.
- First run now cleanly detects that `ar-infotek-bigdata-v13-streamlit:1.0` is absent and builds it from `streamlit/Dockerfile`.
- Subsequent runs detect the local image with `docker image ls --quiet --filter "reference=..."` and skip the build.
- Updated the installation guide to make clear that the Streamlit image is built locally on first run and is not bundled as a prebuilt Docker image.
- Removed stale v9/v11/v12 README and changelog files from the distributable package.


## Installer network hardening update
- Registry images are pre-pulled one at a time before Compose startup.
- Each registry pull retries up to 4 times with a 15-second delay.
- Compose starts with `--pull never` after successful pre-pulls, preventing a second implicit parallel pull.
- This specifically hardens first-run Windows/Docker Desktop setup against Docker Hub TLS handshake timeouts.

### v13 clickstream loader fix
The PostgreSQL initialization script safely handles optional `order_id` and `amount` fields in clickstream JSON events. Non-order events omit these fields, so the loader now checks JSON properties explicitly instead of directly referencing missing PowerShell properties under strict mode.
