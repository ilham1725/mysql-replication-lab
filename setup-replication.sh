#!/usr/bin/env bash
# Set up GTID replication from mysql-master to mysql-replica.
# Assumes the compose stack is up:  docker compose up -d
# Lab-only example passwords - see docker-compose.yml.
set -euo pipefail

ROOT_PW="example_root_pw"
REPL_USER="repl"
REPL_PW="repl_example_pw"

echo "Waiting for mysql-master to accept connections..."
until docker compose exec -T mysql-master mysqladmin ping -uroot -p"${ROOT_PW}" --silent 2>/dev/null; do
  sleep 2
done

echo "Waiting for mysql-replica to accept connections..."
until docker compose exec -T mysql-replica mysqladmin ping -uroot -p"${ROOT_PW}" --silent 2>/dev/null; do
  sleep 2
done

echo "Creating replication user on the master..."
docker compose exec -T mysql-master mysql -uroot -p"${ROOT_PW}" <<SQL
CREATE USER IF NOT EXISTS '${REPL_USER}'@'%' IDENTIFIED WITH caching_sha2_password BY '${REPL_PW}';
GRANT REPLICATION SLAVE ON *.* TO '${REPL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

echo "Pointing the replica at the master (GTID auto-position)..."
docker compose exec -T mysql-replica mysql -uroot -p"${ROOT_PW}" <<SQL
STOP REPLICA;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='mysql-master',
  SOURCE_PORT=3306,
  SOURCE_USER='${REPL_USER}',
  SOURCE_PASSWORD='${REPL_PW}',
  SOURCE_AUTO_POSITION=1,
  GET_SOURCE_PUBLIC_KEY=1;
START REPLICA;
SQL

echo "Done. Current replica status:"
docker compose exec -T mysql-replica mysql -uroot -p"${ROOT_PW}" \
  -e "SHOW REPLICA STATUS\G" | grep -E "Replica_IO_Running|Replica_SQL_Running|Seconds_Behind_Source|Last_Error" || true

echo
echo "Now run the checks in verify-replication.sql to prove data actually flows."
