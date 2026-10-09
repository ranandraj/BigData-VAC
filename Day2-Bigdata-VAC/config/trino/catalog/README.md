# Trino Iceberg Catalog

The lab uses Apache Iceberg with:

- PostgreSQL as the Iceberg JDBC metadata catalog
- HDFS as the storage layer
- Apache Parquet as the data file format
- Trino as the SQL query engine

No MinIO service and no Iceberg REST service are required.

Warehouse:

`hdfs://namenode:8020/ecommerce/iceberg`

The JDBC catalog metadata tables are initialized in the course PostgreSQL database.
