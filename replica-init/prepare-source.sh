#!/bin/bash
# Run this ONCE on the voicebot-application server (main DB).
# Creates the replication user and dumps a snapshot with binlog position.

set -e

MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}"
REPL_USER="${REPL_USER:-replicator}"
REPL_PASSWORD="${REPL_PASSWORD}"
DB_NAME="${MYSQL_DATABASE:-voice_assistant}"
OUTPUT_FILE="snapshot_$(date +%Y%m%d_%H%M%S).sql"

echo "Creating replication user..."
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<SQL
CREATE USER IF NOT EXISTS '${REPL_USER}'@'%' IDENTIFIED BY '${REPL_PASSWORD}';
GRANT REPLICATION SLAVE ON *.* TO '${REPL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

echo "Taking snapshot with binlog position..."
mysqldump \
  -uroot -p"$MYSQL_ROOT_PASSWORD" \
  --source-data=2 \
  --single-transaction \
  --routines \
  --triggers \
  "$DB_NAME" > "$OUTPUT_FILE"

echo ""
echo "Snapshot saved to: $OUTPUT_FILE"
echo ""
echo "Binlog position (needed for setup-replica.sh):"
grep "CHANGE REPLICATION SOURCE" "$OUTPUT_FILE" | head -1
