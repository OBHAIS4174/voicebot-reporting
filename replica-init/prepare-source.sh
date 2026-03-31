#!/bin/bash
# Run this ONCE on the VOICEBOT-APPLICATION SERVER HOST (172.16.0.240).
# Pre-requisites:
#   1. mysql/my.cnf deployed to /etc/mysql/conf.d/source.cnf and MySQL restarted
#   2. MySQL is the host MySQL (not Docker)
#
# After running, scp the snapshot file to the reporting server and import it there.

set -e

MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
REPL_USER="${REPL_USER:-replicator}"
REPL_PASSWORD="${REPL_PASSWORD:?REPL_PASSWORD is required}"
DB_NAME="${MYSQL_DATABASE:-voice_assistant}"
OUTPUT_FILE="snapshot_$(date +%Y%m%d_%H%M%S).sql"

echo "Step 1: Creating replication user '${REPL_USER}'..."
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<SQL
CREATE USER IF NOT EXISTS '${REPL_USER}'@'%' IDENTIFIED BY '${REPL_PASSWORD}';
GRANT REPLICATION SLAVE ON *.* TO '${REPL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

echo "Step 2: Taking snapshot with binlog position (this locks briefly)..."
mysqldump \
  -uroot -p"$MYSQL_ROOT_PASSWORD" \
  --source-data=2 \
  --single-transaction \
  --routines \
  --triggers \
  "$DB_NAME" > "$OUTPUT_FILE"

echo ""
echo "Snapshot saved: $OUTPUT_FILE"
echo ""
echo "Binlog position for setup-replica.sh:"
grep "CHANGE REPLICATION SOURCE" "$OUTPUT_FILE" | head -1
echo ""
echo "Next steps:"
echo "  1. scp $OUTPUT_FILE user@172.16.0.242:~/"
echo "  2. On reporting server: mysql -uroot voice_assistant < $OUTPUT_FILE"
echo "  3. On reporting server: run replica-init/setup-replica.sh with the values above"
