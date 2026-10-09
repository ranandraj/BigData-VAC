from airflow.sdk import dag, task
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
import json
import csv
import os

TRINO_URL = "http://trino:8080/v1/statement"
HEADERS = {
    "X-Trino-User": "airflow",
    "X-Trino-Catalog": "iceberg",
    "X-Trino-Schema": "ecommerce",
    "Content-Type": "text/plain",
}


def trino_sql(sql: str):
    req = Request(TRINO_URL, data=sql.encode("utf-8"), headers=HEADERS, method="POST")
    with urlopen(req, timeout=60) as response:
        payload = json.loads(response.read().decode("utf-8"))

    while payload.get("nextUri"):
        with urlopen(payload["nextUri"], timeout=60) as response:
            payload = json.loads(response.read().decode("utf-8"))

    if payload.get("error"):
        raise RuntimeError(payload["error"].get("message", "Trino query failed"))
    return payload


def http_check(url: str, label: str):
    try:
        with urlopen(url, timeout=10) as response:
            if response.status >= 400:
                raise RuntimeError(f"{label} returned HTTP {response.status}")
    except (URLError, HTTPError) as exc:
        raise RuntimeError(f"{label} is not reachable: {exc}") from exc


@dag(
    schedule=None,
    start_date=datetime(2026, 10, 1),
    catchup=False,
    tags=["ar-infotek", "ecommerce", "big-data"],
    description="Real e-commerce analytics workflow: validate, refresh Iceberg/Parquet, run analytics and create a report.",
)
def ecommerce_end_to_end():

    @task
    def verify_sources():
        http_check("http://trino:8080/v1/info", "Trino")
        http_check("http://debezium:8083/connectors", "Debezium")
        http_check("http://flink-jobmanager:8081/overview", "Flink")
        result = trino_sql("SELECT COUNT(*) AS orders FROM postgresql.public.orders")
        print(f"PostgreSQL orders available: {result.get('data', [['0']])[0][0]}")
        print("Source services and PostgreSQL operational data are available.")

    @task
    def refresh_analytical_tables():
        statements = [
            "CREATE SCHEMA IF NOT EXISTS iceberg.ecommerce WITH (location = 'hdfs://namenode:8020/ecommerce/iceberg/ecommerce')",
            "CREATE TABLE IF NOT EXISTS iceberg.ecommerce.orders (order_id VARCHAR, customer_id VARCHAR, order_date DATE, created_at TIMESTAMP, total_amount DECIMAL(12,2), status VARCHAR) WITH (format='PARQUET', partitioning=ARRAY['day(order_date)'])",
            "CREATE TABLE IF NOT EXISTS iceberg.ecommerce.clickstream_events (event_id VARCHAR, event_time TIMESTAMP, user_id VARCHAR, session_id VARCHAR, event_type VARCHAR, product_id VARCHAR, page VARCHAR, order_id VARCHAR, amount DECIMAL(12,2)) WITH (format='PARQUET', partitioning=ARRAY['day(event_time)'])",
            "DELETE FROM iceberg.ecommerce.orders",
            "INSERT INTO iceberg.ecommerce.orders SELECT order_id, customer_id, order_date, created_at, total_amount, status FROM postgresql.public.orders",
            "DELETE FROM iceberg.ecommerce.clickstream_events",
            "INSERT INTO iceberg.ecommerce.clickstream_events SELECT event_id, event_time, user_id, session_id, event_type, product_id, page, order_id, amount FROM postgresql.public.clickstream_events",
        ]
        for sql in statements:
            trino_sql(sql)
        print("Operational e-commerce data refreshed into partitioned Parquet-backed Iceberg tables on HDFS.")

    @task
    def demonstrate_schema_evolution():
        columns = trino_sql("SELECT column_name FROM information_schema.columns WHERE table_schema='ecommerce' AND table_name='orders' ORDER BY ordinal_position")
        names = {row[0] for row in columns.get("data", [])}
        if "sales_channel" not in names:
            trino_sql("ALTER TABLE iceberg.ecommerce.orders ADD COLUMN sales_channel VARCHAR")
            print("Added sales_channel using Iceberg schema evolution.")
        trino_sql("UPDATE iceberg.ecommerce.orders SET sales_channel = CASE WHEN MOD(CAST(substr(order_id, 2) AS BIGINT), 3) = 0 THEN 'WEB' WHEN MOD(CAST(substr(order_id, 2) AS BIGINT), 3) = 1 THEN 'MOBILE' ELSE 'MARKETPLACE' END")
        print("Schema evolution verified and sales_channel populated for the refreshed orders.")

    @task
    def prepare_analytics():
        statements = [
            "CREATE OR REPLACE VIEW iceberg.ecommerce.daily_sales AS SELECT order_date, COUNT(*) AS orders, ROUND(SUM(total_amount),2) AS revenue, ROUND(AVG(total_amount),2) AS average_order_value FROM iceberg.ecommerce.orders GROUP BY order_date",
            "CREATE OR REPLACE VIEW iceberg.ecommerce.customer_sales AS SELECT c.customer_id, c.name, c.city, COUNT(o.order_id) AS orders, ROUND(COALESCE(SUM(o.total_amount),0),2) AS revenue FROM iceberg.ecommerce.customers c LEFT JOIN iceberg.ecommerce.orders o ON c.customer_id=o.customer_id GROUP BY c.customer_id,c.name,c.city",
            "CREATE OR REPLACE VIEW iceberg.ecommerce.realtime_funnel AS SELECT event_type, COUNT(*) AS events FROM iceberg.ecommerce.clickstream_events GROUP BY event_type",
        ]
        for sql in statements:
            trino_sql(sql)
        result = trino_sql("SELECT COUNT(*) AS orders, ROUND(SUM(total_amount),2) AS revenue FROM iceberg.ecommerce.orders")
        print(f"Analytical KPI snapshot: {result.get('data', [])}")

    @task
    def generate_report():
        payload = trino_sql("SELECT status, COUNT(*) AS orders, ROUND(SUM(total_amount),2) AS revenue, ROUND(AVG(total_amount),2) AS average_order_value FROM iceberg.ecommerce.orders GROUP BY status ORDER BY revenue DESC")
        rows = payload.get("data", [])
        output = "/opt/airflow/reports/management_report.csv"
        os.makedirs(os.path.dirname(output), exist_ok=True)
        with open(output, "w", newline="", encoding="utf-8") as handle:
            writer = csv.writer(handle)
            writer.writerow(["status", "orders", "revenue", "average_order_value"])
            writer.writerows(rows)
        print(f"Management report written to {output}")

    verify_sources() >> refresh_analytical_tables() >> demonstrate_schema_evolution() >> prepare_analytics() >> generate_report()


ecommerce_end_to_end()
