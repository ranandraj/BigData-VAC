import streamlit as st
from pymongo import MongoClient
st.set_page_config(page_title="E-Commerce Big Data",layout="wide")
st.title("E-Commerce Big Data Analytics")
st.caption("AR INFOTEK Big Data VAC Lab")
try:
    c=MongoClient("mongodb://mongodb:27017",serverSelectionTimeoutMS=1500)
    c.admin.command("ping"); st.success("MongoDB connected")
except Exception: st.warning("MongoDB is running, but analytics data is not loaded yet.")
st.info("Use this dashboard after the Flink/MongoDB analytics exercise.")
