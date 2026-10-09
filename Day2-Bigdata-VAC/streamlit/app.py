import streamlit as st
import pandas as pd
from pymongo import MongoClient
from trino.dbapi import connect
from datetime import datetime
import json
from kafka import KafkaConsumer

st.set_page_config(page_title='E-Commerce Big Data Analytics', layout='wide')
st.title('E-Commerce Big Data Analytics Dashboard')
st.caption('AR INFOTEK v13 | End-to-End Local Big Data Lab')

@st.cache_resource
def mongo(): return MongoClient('mongodb://mongodb:27017',serverSelectionTimeoutMS=3000)['ecommerce_analytics']

def sync_flink_results(db):
    consumer = KafkaConsumer('ecommerce-metrics','ecommerce-anomalies', bootstrap_servers='kafka:29092', group_id='streamlit-dashboard-v13', auto_offset_reset='latest', enable_auto_commit=True, consumer_timeout_ms=300)
    metrics=db.realtime_metrics; alerts=db.alerts
    for msg in consumer:
        try:
            doc=json.loads(msg.value.decode('utf-8'))
            if msg.topic == 'ecommerce-metrics': metrics.update_one({'window_start':doc.get('window_start')},{'$set':doc},upsert=True)
            else: alerts.update_one({'event_id':doc.get('event_id')},{'$set':doc},upsert=True)
        except Exception:
            pass
    consumer.close()
@st.cache_resource
def trino_conn(catalog='postgresql', schema='public'):
    return connect(host='trino', port=8080, user='lab', catalog=catalog, schema=schema)

def tq(sql, catalog='postgresql', schema='public'):
    cur = trino_conn(catalog, schema).cursor()
    cur.execute(sql)
    rows = cur.fetchall()
    cols = [d[0] for d in cur.description]
    return pd.DataFrame(rows, columns=cols)

try:
    db = mongo()
    db.command('ping')
    mongo_ok = True
    try:
        sync_flink_results(db)
    except Exception as exc:
        st.caption(f"Flink-to-MongoDB synchronization is waiting: {exc}")
except Exception:
    mongo_ok = False
try:
    tq('SELECT 1'); trino_ok=True
except Exception: trino_ok=False

c1,c2=st.columns(2); c1.metric('Trino', 'Connected' if trino_ok else 'Waiting'); c2.metric('MongoDB', 'Connected' if mongo_ok else 'Waiting')
if not trino_ok:
    st.warning('Trino or the PostgreSQL operational catalog is not ready. Check the Trino and PostgreSQL services, then refresh.')
    st.stop()

k=tq('''SELECT count(*) total_orders, round(sum(total_amount),2) revenue, count(DISTINCT customer_id) customers, round(avg(total_amount),2) aov FROM orders''').iloc[0]
a,b,c,d=st.columns(4); a.metric('Total Orders',f"{int(k.total_orders):,}"); b.metric('Revenue',f"₹{float(k.revenue):,.0f}"); c.metric('Customers',f"{int(k.customers):,}"); d.metric('Average Order Value',f"₹{float(k.aov):,.0f}")

st.subheader('Sales Analytics')
sales=tq('''SELECT order_date, round(sum(total_amount),2) revenue, count(*) orders FROM orders GROUP BY order_date ORDER BY order_date''')
if not sales.empty: st.line_chart(sales.set_index('order_date')[['revenue','orders']])

left,right=st.columns(2)
with left:
    st.subheader('Top Products')
    st.dataframe(tq('''SELECT p.product_name, p.category, sum(oi.quantity) units_sold, round(sum(oi.quantity*oi.unit_price*(1-oi.discount_pct/100)),2) revenue FROM order_items oi JOIN products p ON oi.product_id=p.product_id GROUP BY p.product_name,p.category ORDER BY revenue DESC LIMIT 10'''),use_container_width=True)
with right:
    st.subheader('Order Status')
    st.bar_chart(tq('SELECT status,count(*) orders FROM orders GROUP BY status').set_index('status'))

st.subheader('Sales Channel')
try:
    st.dataframe(
        tq(
            "SELECT sales_channel, count(*) orders, round(sum(total_amount),2) revenue "
            "FROM orders GROUP BY sales_channel ORDER BY revenue DESC",
            catalog='iceberg',
            schema='ecommerce'
        ),
        use_container_width=True
    )
except Exception:
    st.info('Run .\\scripts\\INIT-ANALYTICS.ps1, then the Session 9 schema-evolution step or Airflow workflow to create and populate the Iceberg sales_channel column.')

st.subheader('Customer Analytics')
st.dataframe(tq('''SELECT c.customer_id,c.name,c.city,count(o.order_id) orders,round(sum(o.total_amount),2) revenue FROM customers c LEFT JOIN orders o ON c.customer_id=o.customer_id GROUP BY c.customer_id,c.name,c.city ORDER BY revenue DESC NULLS LAST LIMIT 15'''),use_container_width=True)

st.subheader('Real-Time Analytics from Flink')
if mongo_ok:
    metrics=list(db.realtime_metrics.find({}, {'_id':0}).sort('window_start',-1).limit(20))
    if metrics:
        m=pd.DataFrame(metrics).sort_values('window_start'); st.line_chart(m.set_index('window_start')[['orders_per_minute','revenue','active_users','cart_events']]); st.dataframe(m.tail(10),use_container_width=True)
    else: st.info('No Flink metric windows received yet. Start the Flink job and generate events.')
    alerts=list(db.alerts.find({}, {'_id':0}).sort('event_time',-1).limit(20))
    st.subheader('Alerts / High-Value Orders')
    st.dataframe(pd.DataFrame(alerts),use_container_width=True) if alerts else st.info('No high-value order alerts yet.')

st.subheader('Order Conversion Funnel')
funnel=tq("SELECT event_type,count(*) events FROM clickstream_events WHERE event_type IN ('product_view','cart_added','checkout_started','order_created','payment_completed') GROUP BY event_type ORDER BY events DESC")
st.dataframe(funnel,use_container_width=True)

st.subheader('Management Report Snapshot')
report=tq('''SELECT status,count(*) orders,round(sum(total_amount),2) revenue FROM orders GROUP BY status ORDER BY revenue DESC''')
st.dataframe(report,use_container_width=True)




