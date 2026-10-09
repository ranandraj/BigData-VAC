CREATE TABLE IF NOT EXISTS customers(
 customer_id VARCHAR(20) PRIMARY KEY, name VARCHAR(100), city VARCHAR(100), state VARCHAR(100), registration_date DATE, customer_segment VARCHAR(30)
);
CREATE TABLE IF NOT EXISTS products(
 product_id VARCHAR(20) PRIMARY KEY, product_name VARCHAR(150), category VARCHAR(100), price NUMERIC(12,2)
);
CREATE TABLE IF NOT EXISTS orders(
 order_id VARCHAR(20) PRIMARY KEY, customer_id VARCHAR(20), order_date DATE, created_at TIMESTAMP, total_amount NUMERIC(12,2), status VARCHAR(30)
);
CREATE TABLE IF NOT EXISTS order_items(
 order_item_id VARCHAR(30) PRIMARY KEY, order_id VARCHAR(20) REFERENCES orders(order_id), product_id VARCHAR(20), quantity INT, unit_price NUMERIC(12,2), discount_pct NUMERIC(5,2)
);
CREATE TABLE IF NOT EXISTS payments(
 payment_id VARCHAR(30) PRIMARY KEY, order_id VARCHAR(20), payment_time TIMESTAMP, payment_method VARCHAR(30), amount NUMERIC(12,2), status VARCHAR(30)
);
CREATE TABLE IF NOT EXISTS clickstream_events(event_id VARCHAR(30) PRIMARY KEY, event_time TIMESTAMP, user_id VARCHAR(20), session_id VARCHAR(30), event_type VARCHAR(40), product_id VARCHAR(20), page VARCHAR(40), order_id VARCHAR(20), amount NUMERIC(12,2));

-- Apache Iceberg JDBC Catalog metadata for Trino.
-- PostgreSQL stores catalog metadata; HDFS stores Iceberg data and metadata files.
CREATE TABLE IF NOT EXISTS iceberg_tables (
  catalog_name VARCHAR(255) NOT NULL,
  table_namespace VARCHAR(255) NOT NULL,
  table_name VARCHAR(255) NOT NULL,
  metadata_location VARCHAR(1000),
  previous_metadata_location VARCHAR(1000),
  iceberg_type VARCHAR(5),
  PRIMARY KEY (catalog_name, table_namespace, table_name)
);

CREATE TABLE IF NOT EXISTS iceberg_namespace_properties (
  catalog_name VARCHAR(255) NOT NULL,
  namespace VARCHAR(255) NOT NULL,
  property_key VARCHAR(255),
  property_value VARCHAR(1000),
  PRIMARY KEY (catalog_name, namespace, property_key)
);
