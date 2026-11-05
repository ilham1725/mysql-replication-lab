# mysql-replication-lab

I'm a Linux system administrator with about five years of experience, and MySQL
administration is part of my day-to-day work — installing it, backing it up,
managing users, moving databases between servers. One area I wanted to
understand more deeply is **replication**: how a replica stays in sync with its
source, what to check when it falls behind, and how to tell healthy replication
from broken replication.

This repo is my practice lab for that. It's a small Docker Compose setup that
runs a MySQL 8 source server and one replica with GTID-based replication, so I
can break things and fix them on my laptop instead of learning on a server
somebody depends on. Nothing here is a production recipe — it's where I
practice.

## What's in here

| File | What it does |
| --- | --- |
| `docker-compose.yml` | Two MySQL 8.0 containers: `mysql-master` (server-id 1) and `mysql-replica` (server-id 2), GTID on, replica read-only. Master on port 3307, replica on 3308. |
| `setup-replication.sh` | Creates the replication user on the master and points the replica at the master with `SOURCE_AUTO_POSITION=1`, then starts replication. |
| `verify-replication.sql` | Checks to run after setup: replica thread status, plus a test write on the master that you read back on the replica. |
| `notes/replication-checks.md` | The status and lag checks I keep coming back to, and what the common values actually mean. |

## How I run it

```bash
docker compose up -d
./setup-replication.sh
```

Then run the checks in `verify-replication.sql` (the file says which server
each part runs on).

To start over from a clean slate:

```bash
docker compose down -v
```

## Notes to myself

- The passwords in `docker-compose.yml` and the scripts (`example_root_pw`,
  `repl_example_pw`) are throwaway lab values for a stack that only runs
  locally. They're not used anywhere real.
- GTID auto-positioning is the part I most wanted to practice — no more hunting
  for binlog file names and positions by hand.
- A replica being "up" is not the same as replication working. The I/O thread,
  the SQL thread, and lag are three separate things to check; the notes file
  walks through them.
