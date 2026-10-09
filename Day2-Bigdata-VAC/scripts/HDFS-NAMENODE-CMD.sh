#!/usr/bin/env bash
set -e
mkdir -p /data/name
if [ ! -f /data/name/current/VERSION ]; then /opt/hadoop/bin/hdfs namenode -format -force -nonInteractive; fi
exec /opt/hadoop/bin/hdfs namenode
