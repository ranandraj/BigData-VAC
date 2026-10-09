# v13 final delivery corrections

- Fixed Streamlit's default Trino connection to `postgresql.public` for operational tables.
- Kept Iceberg-specific Sales Channel analytics on `iceberg.ecommerce`, with a graceful message when analytical schema evolution has not run.
- Corrected the PostgreSQL source schema in the Iceberg initialization script and Airflow DAG from `postgresql.ecommerce` to `postgresql.public`.
- Fixed Flink SQL submission to use the official image entrypoint and explicitly invoke `bin/sql-client.sh`.
- Added a post-submission check that confirms a Flink job is RUNNING.
- Bumped the Streamlit image tag to `1.1` and changed the installer to rebuild it from the current package source, avoiding stale images.
- Fixed rupee-symbol text encoding in the dashboard.
- Kept database volumes and existing operational data intact during service-specific rebuilds.
