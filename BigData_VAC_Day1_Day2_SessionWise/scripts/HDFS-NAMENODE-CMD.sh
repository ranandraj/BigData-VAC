#!/usr/bin/env bash
set -Eeuo pipefail
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export PATH=/opt/hadoop/bin:/opt/hadoop/sbin:$PATH
HDFS=/opt/hadoop/bin/hdfs

if [ ! -x "$HDFS" ]; then
  echo "[HDFS][FATAL] Hadoop executable not found at $HDFS"
  echo "[HDFS] Contents of /opt/hadoop/bin:"
  ls -la /opt/hadoop/bin 2>&1 || true
  exit 20
fi

mkdir -p /data/namenode
chown -R hadoop:hadoop /data/namenode

if [ ! -f /data/namenode/current/VERSION ]; then
  echo "[HDFS] Formatting NameNode filesystem..."
  su -s /bin/bash hadoop -c "export HADOOP_HOME=/opt/hadoop HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop PATH=/opt/hadoop/bin:/opt/hadoop/sbin:\$PATH; \"$HDFS\" namenode -format -force -nonInteractive"
fi

chown -R hadoop:hadoop /data/namenode
echo "[HDFS] Starting NameNode..."
exec su -s /bin/bash hadoop -c "export HADOOP_HOME=/opt/hadoop HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop PATH=/opt/hadoop/bin:/opt/hadoop/sbin:\$PATH; exec \"$HDFS\" namenode"
