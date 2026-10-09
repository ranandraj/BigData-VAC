# v13 Final Delivery Validation Notes

## Corrections included

- Streamlit operational queries use Trino catalog `postgresql`, schema `public`.
- The dashboard's Sales Channel panel queries `iceberg.ecommerce` separately and displays a setup hint if the Iceberg table/column is not ready.
- The dashboard's INR symbol encoding is corrected.
- Iceberg initialization and Airflow source queries use `postgresql.public`.
- Streamlit image tag is `ar-infotek-bigdata-v13-streamlit:1.1`.
- The installer rebuilds the Streamlit image from the current source on every run, so a stale local image does not hide source changes.
- Flink SQL submission preserves `/docker-entrypoint.sh`, invokes `bin/sql-client.sh`, and checks the Flink REST API for a running job.
- `FIX-STREAMLIT-TRINO.ps1` is included for existing extracted installations.

## Recommended first-run commands

Run in PowerShell from the extracted `v13work` folder:

```powershell
.\INSTALL-BIGDATA-LAB.ps1
.\scripts\RUN-FLINK-SQL.ps1
.\scripts\PUBLISH-SAMPLE-EVENTS.ps1
```

Open the dashboard at `http://localhost:8501`.

## Validation performed for this delivery

- Python syntax compilation: Streamlit application and Airflow DAG.
- YAML parse: Docker Compose file and 15 services.
- JSON parse: Debezium connector configuration.
- Static consistency scan: no remaining `postgresql.ecommerce` source references, stale Streamlit image tag in active configuration, or mojibake INR symbol in the source.
- Archive integrity is checked when the delivery ZIP is built.

## Runtime validation

A full Docker runtime test must be run on the target Windows/Docker Desktop machine. The validation above is static and does not claim that containers were started from this environment.
