-- AR INFOTEK Big Data VAC
-- Flink SQL real-time e-commerce analytics
-- Source: Kafka topic ecommerce-events
-- Outputs: ecommerce-metrics and ecommerce-anomalies

SET 'pipeline.name' = 'AR-INFOTEK-Ecommerce-Realtime-Analytics';
SET 'parallelism.default' = '1';
SET 'execution.runtime-mode' = 'streaming';
SET 'table.dml-sync' = 'false';

CREATE TABLE ecommerce_events (
    event_id STRING,
    event_time TIMESTAMP(3),
    user_id STRING,
    session_id STRING,
    event_type STRING,
    product_id STRING,
    page STRING,
    order_id STRING,
    amount DECIMAL(18,2),
    WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'ecommerce-events',
    'properties.bootstrap.servers' = 'kafka:29092',
    'properties.group.id' = 'flink-sql-ecommerce-v13',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json',
    'json.ignore-parse-errors' = 'true'
);

-- Normalize, filter and map the incoming event stream before aggregation.
CREATE VIEW ecommerce_events_clean AS
SELECT
    event_id,
    event_time,
    user_id,
    session_id,
    event_type,
    product_id,
    page,
    order_id,
    COALESCE(amount, CAST(0 AS DECIMAL(18,2))) AS amount
FROM ecommerce_events
WHERE event_type IN ('product_view','cart_added','checkout_started','order_created','payment_completed');

CREATE TABLE ecommerce_metrics (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    total_events BIGINT,
    orders_per_minute BIGINT,
    revenue DECIMAL(20,2),
    active_users BIGINT,
    cart_events BIGINT,
    product_views BIGINT,
    completed_payments BIGINT
) WITH (
    'connector' = 'kafka',
    'topic' = 'ecommerce-metrics',
    'properties.bootstrap.servers' = 'kafka:29092',
    'format' = 'json'
);

CREATE TABLE ecommerce_anomalies (
    event_id STRING,
    event_time TIMESTAMP(3),
    user_id STRING,
    order_id STRING,
    amount DECIMAL(18,2),
    event_type STRING,
    anomaly_type STRING,
    threshold DECIMAL(18,2)
) WITH (
    'connector' = 'kafka',
    'topic' = 'ecommerce-anomalies',
    'properties.bootstrap.servers' = 'kafka:29092',
    'format' = 'json'
);

-- Submit both streaming outputs as one Flink job.
EXECUTE STATEMENT SET
BEGIN

-- Continuous one-minute e-commerce KPI stream.
INSERT INTO ecommerce_metrics
SELECT
    window_start,
    window_end,
    COUNT(*) AS total_events,
    COUNT(CASE WHEN event_type = 'order_created' THEN 1 END) AS orders_per_minute,
    CAST(COALESCE(SUM(CASE WHEN event_type = 'order_created' THEN amount ELSE CAST(0 AS DECIMAL(18,2)) END), CAST(0 AS DECIMAL(38,2))) AS DECIMAL(20,2)) AS revenue,
    COUNT(DISTINCT user_id) AS active_users,
    COUNT(CASE WHEN event_type = 'cart_added' THEN 1 END) AS cart_events,
    COUNT(CASE WHEN event_type = 'product_view' THEN 1 END) AS product_views,
    COUNT(CASE WHEN event_type = 'payment_completed' THEN 1 END) AS completed_payments
FROM TABLE(
    TUMBLE(TABLE ecommerce_events_clean, DESCRIPTOR(event_time), INTERVAL '1' MINUTE)
)
GROUP BY window_start, window_end;

-- Rule-based high-value order detection.
INSERT INTO ecommerce_anomalies
SELECT
    event_id,
    event_time,
    user_id,
    order_id,
    amount,
    event_type,
    'HIGH_VALUE_ORDER' AS anomaly_type,
    CAST(50000 AS DECIMAL(18,2)) AS threshold
FROM ecommerce_events_clean
WHERE event_type = 'order_created'
  AND amount >= CAST(50000 AS DECIMAL(18,2));

END;
