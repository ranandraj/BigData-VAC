from airflow.sdk import dag, task
from datetime import datetime
@dag(start_date=datetime(2026,1,1), schedule=None, catchup=False, tags=["bigdata","ecommerce"])
def ecommerce_pipeline():
    @task
    def validate(): return "Pipeline validation completed"
    validate()
ecommerce_pipeline()
