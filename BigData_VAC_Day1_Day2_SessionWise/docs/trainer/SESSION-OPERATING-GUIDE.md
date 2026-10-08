# Trainer Operating Guide

## Before Day 1

1. Prepare WSL2 and Docker on every lab machine.
2. Copy the v7 package.
3. Run `PRE-FLIGHT-CHECK.ps1`.
4. Run `scripts/INSTALL-LAB-BASE.ps1`.
5. Verify that the HDFS-fixed configuration is retained.
6. Test Sessions 2-8 once before students arrive.

## During the workshop

Do not start all services at the beginning. Start the current session's service(s).

Keep earlier services running when the next session needs them. For example, PostgreSQL must remain running for Debezium.

## Teaching rule

The automation should remove installation pain, not remove learning. Students should type and interpret the HDFS, SQL and Kafka commands and create the NiFi flow themselves.

## Recovery

The original v6 `INSTALL-DAY1.ps1`, `START-DAY1.ps1`, `STOP-DAY1.ps1` and `RESET-LAB.ps1` remain available for trainer recovery. Use them only when a lab machine needs a complete reset/rebuild.
