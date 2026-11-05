# Replication checks I keep coming back to

Notes to myself from practicing with this lab. All of these run on the
**replica** unless said otherwise.

## The 30-second health check

```sql
SHOW REPLICA STATUS\G
```

Fields I actually read:

- `Replica_IO_Running` — is the replica connected to the master and pulling
  binlog events? `Yes` is good, `Connecting` usually means network, firewall,
  wrong credentials, or the master is down.
- `Replica_SQL_Running` — is the replica applying the events it pulled? When
  this one is `No`, read `Last_SQL_Error` — a failed statement (for example a
  duplicate key from someone writing to the replica) stops it cold.
- `Seconds_Behind_Source` — lag in seconds. Small spikes under load are
  normal; a number that only grows means the replica can't keep up.
  `NULL` = replication threads aren't running, so there is no lag to measure.
- `Retrieved_Gtid_Set` vs `Executed_Gtid_Set` — if the first is ahead of the
  second, events have arrived but not been applied yet.

## When I/O thread won't connect

1. Can the replica reach the master at all? (In this lab: container network.
   On real servers: ping, port 3306, firewall rules.)
2. Is the replication user correct, and does it have `REPLICATION SLAVE`?
3. `Last_IO_Error` names the actual reason most of the time — read it before
   changing anything.

## When SQL thread stops

- Read `Last_SQL_Error` first. Don't just restart it.
- `START REPLICA;` after fixing the cause resumes from where it stopped —
  GTID auto-positioning means I don't have to calculate positions by hand.

## Things this lab taught me

- `read_only` on the replica doesn't stop the replication threads from
  writing — it stops *me* from writing by accident, which is the point.
- Lag is measured against the master's clock when the event was committed,
  so a replica can show lag even on an idle system right after a big single
  transaction lands.
- `SHOW REPLICA STATUS` output is wide and ugly; the
  `performance_schema.replication_*` tables are easier to script against.
