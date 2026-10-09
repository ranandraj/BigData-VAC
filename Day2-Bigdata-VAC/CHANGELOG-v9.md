# Changelog v9

## Flink SQL Client revision

- Removed custom Java Flink application and Maven build.
- Removed the previous `flink/job` source tree from the runtime package.
- Added Flink 2.1.1 Session Cluster.
- Added `sql-client` service.
- Added Kafka SQL connector to the shared Flink image.
- Added `sql/flink/ecommerce-realtime.sql`.
- Added `scripts/RUN-FLINK-SQL.ps1`.
- Added `scripts/VERIFY-FLINK-SQL.ps1`.
- Updated installer to stop immediately on critical build/startup failures.
- Installer no longer submits a Flink job implicitly.
- Added classroom guide for Flink SQL Client.

## Processing retained

The SQL job keeps the workshop's e-commerce processing goals: event-time processing, one-minute windows, orders/minute, revenue, active users, cart events, product views, completed payments and rule-based high-value order detection.
