#!/usr/bin/env bash
set -e
mkdir -p /data/data
exec /opt/hadoop/bin/hdfs datanode
