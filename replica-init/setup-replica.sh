#!/bin/bash
# Run this ONCE on the reporting server after importing the snapshot.
# Fill in the values from your .env and the snapshot dump header.

set -e

MAIN_DB_IP="${SOURCE_HOST}"          # internal IP of voicebot-application server
REPLICATION_USER="${REPL_USER}"
REPLICATION_PASSWORD="${REPL_PASSWORD}"
BINLOG_FILE="${BINLOG_FILE}"         # from snapshot: e.g. mysql-bin.000003
BINLOG_POS="${BINLOG_POS}"           # from snapshot: e.g. 1234

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
STOP REPLICA;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='${MAIN_DB_IP}',
  SOURCE_PORT=3306,
  SOURCE_USER='${REPLICATION_USER}',
  SOURCE_PASSWORD='${REPLICATION_PASSWORD}',
  SOURCE_LOG_FILE='${BINLOG_FILE}',
  SOURCE_LOG_POS=${BINLOG_POS};
START REPLICA;
SHOW REPLICA STATUS\G
SQL

echo "Replica started. Check 'Seconds_Behind_Source' above — should reach 0."
