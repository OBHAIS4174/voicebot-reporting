#!/bin/bash
# Run this ONCE on the REPORTING SERVER HOST after importing the snapshot.
# Pre-requisites:
#   1. MySQL installed on this host (sudo apt install mysql-server)
#   2. mysql-replica/my.cnf copied to /etc/mysql/conf.d/replica.cnf and MySQL restarted
#   3. Snapshot imported: mysql -uroot -p voice_assistant < snapshot_*.sql
#   4. BINLOG_FILE and BINLOG_POS taken from the snapshot dump header (see prepare-source.sh output)

set -e

SOURCE_HOST="${SOURCE_HOST:-172.16.0.240}"   # voicebot-application server IP
REPL_USER="${REPL_USER:-replicator}"
REPL_PASSWORD="${REPL_PASSWORD:?REPL_PASSWORD is required}"
BINLOG_FILE="${BINLOG_FILE:?BINLOG_FILE is required (e.g. mysql-bin.000003)}"
BINLOG_POS="${BINLOG_POS:?BINLOG_POS is required (e.g. 1234)}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-}"

if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
    MYSQL_CMD="mysql -uroot -p${MYSQL_ROOT_PASSWORD}"
else
    MYSQL_CMD="mysql -uroot"
fi

echo "Configuring replica to replicate from ${SOURCE_HOST}..."

$MYSQL_CMD <<SQL
STOP REPLICA;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='${SOURCE_HOST}',
  SOURCE_PORT=3306,
  SOURCE_USER='${REPL_USER}',
  SOURCE_PASSWORD='${REPL_PASSWORD}',
  SOURCE_LOG_FILE='${BINLOG_FILE}',
  SOURCE_LOG_POS=${BINLOG_POS};
START REPLICA;
SHOW REPLICA STATUS\G
SQL

echo ""
echo "Done. Check 'Seconds_Behind_Source' above — it should reach 0 within seconds."
echo "To monitor: mysql -uroot -e 'SHOW REPLICA STATUS\G' | grep Seconds_Behind_Source"
