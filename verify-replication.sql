-- verify-replication.sql
-- Three small checks, run in order. Each part says which server it runs on.
-- Root password in this lab: example_root_pw (see docker-compose.yml)

-- ============================================================
-- PART 1 — run on the REPLICA (port 3308)
-- mysql -h 127.0.0.1 -P 3308 -uroot -p
--
-- What I look at in the output:
--   Replica_IO_Running : Yes  (replica is connected and receiving events)
--   Replica_SQL_Running: Yes  (replica is applying what it receives)
--   Seconds_Behind_Source: 0 or a small number; NULL means something is wrong
--   Last_IO_Error / Last_SQL_Error: should be empty
-- ============================================================
SHOW REPLICA STATUS\G

-- Same story from performance_schema (easier to read one column at a time):
SELECT SERVICE_STATE, LAST_ERROR_MESSAGE
FROM performance_schema.replication_connection_status;

SELECT SERVICE_STATE, LAST_ERROR_MESSAGE
FROM performance_schema.replication_applier_status;

-- ============================================================
-- PART 2 — run on the MASTER (port 3307)
-- mysql -h 127.0.0.1 -P 3307 -uroot -p
-- One throwaway table and one row. If replication works, this
-- row must appear on the replica by itself.
-- ============================================================
CREATE DATABASE IF NOT EXISTS lab_check;
CREATE TABLE IF NOT EXISTS lab_check.ping (
    id INT PRIMARY KEY AUTO_INCREMENT,
    note VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO lab_check.ping (note) VALUES ('replication test row');

-- ============================================================
-- PART 3 — run on the REPLICA (port 3308) again
-- The row from Part 2 should be there. If Part 1 looked healthy
-- but this returns nothing, replication is configured but not
-- actually applying — re-check the SQL thread and its error.
-- ============================================================
SELECT * FROM lab_check.ping;

-- Cleanup when you're done playing (run on the MASTER, it replicates):
-- DROP DATABASE lab_check;
