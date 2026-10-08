#!/usr/bin/env bash
set -Eeuo pipefail
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export PATH=/opt/hadoop/bin:/opt/hadoop/sbin:$PATH
HDFS=/opt/hadoop/bin/hdfs

if [ ! -x "$HDFS" ]; then
  echo "[HDFS][FATAL] Hadoop executable not found at $HDFS"
  ls -la /opt/hadoop/bin 2>&1 || true
  exit 20
fi

mkdir -p /data/datanode
chown -R hadoop:hadoop /data/datanode
echo "[HDFS] Starting DataNode..."
exec su -s /bin/bash hadoop -c "export HADOOP_HOME=/opt/hadoop HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop PATH=/opt/hadoop/bin:/opt/hadoop/sbin:\$PATH; exec \"$HDFS\" datanode"
