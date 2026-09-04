---
topic: 08-elasticache
type: revision
source: 08-elasticache
tags: [revision, generated]
---

# Revision — 08 – ElastiCache (Redis / Memcached)

> [!abstract] Night-before read · ~6 min · self-contained
> Everything you need is here — no need to jump back mid-revision.
> Full teaching explanations, Terraform and diagrams: **[[08-elasticache]]**
> *Generated from the note by `_scripts/build_revision.py` — do not edit.*
## The shape of it

> [!info] Exam TL;DR
> - **Cache = in-memory key-value store** in front of the DB. On a read: check cache → **hit** returns instantly; **miss** → read DB, then populate cache. Slashes DB load + latency for read-heavy, repeated queries.
> - **Redis** = single-threaded, but **HA (replication + Multi-AZ auto-failover)**, **persistence**, **backup/restore**, **rich data types** (sorted sets, lists, hashes, geospatial), **pub/sub**, transactions.
> - **Memcached** = **multi-threaded** (big multi-core nodes), **simple** key-value only, **no** persistence/replication/failover/backup — pure ephemeral cache that scales out.
> - **Pick Redis** for HA / durability / complex data (leaderboards, sessions, pub/sub). **Pick Memcached** for the simplest, multi-threaded, scale-horizontally object cache.
> - **Caching strategies:** *lazy loading / cache-aside* (populate on miss) vs *write-through* (populate on write); use **TTL** to bound staleness.
> - **Auto Discovery is Memcached-only** — the client connects to one node and learns all the others. AWS states it is **not** available for Valkey or Redis OSS.
> - **Valkey** = the newer open-source Redis fork AWS backs; same feature profile as Redis for the exam.
> - **Read the question for engine-exclusive signals, not the use case.** "Multi-threaded" and "node discovery" are Memcached-only; persistence / replication / failover / sorted sets are Redis-only. One exclusive signal decides it.

## Facts, limits & pricing

- **In-memory** → sub-millisecond latency; data lives in RAM (Memcached loses it on restart; Redis can persist/replicate).
- **Redis threading:** single-threaded for command execution (one core per node) — scale by **cluster mode** (sharding across nodes), not by adding cores. **Memcached:** multi-threaded — scales up on **large multi-core** nodes *and* out by adding nodes.
- **Redis HA:** a **replication group** = 1 primary + up to 5 read replicas; **Multi-AZ with automatic failover** promotes a replica if the primary dies. Supports **backup/snapshot & restore**. **Cluster mode enabled** shards data across multiple primaries (each with replicas) for horizontal scale.
- **Memcached:** no replication, no failover, no persistence, no backup — if a node dies, its data is gone. Scales by partitioning keys across nodes (client-side).
- **Data types:** Redis has strings, lists, sets, **sorted sets** (leaderboards!), hashes, bitmaps, hyperloglog, **geospatial**, plus **pub/sub** and transactions. Memcached: simple strings/objects only.
- **Encryption:** in-transit + at-rest supported on Redis (newer versions); Memcached in-transit on newer versions.
- **Common use cases:** DB query cache, **session store** (Redis, so sessions survive failover), **leaderboards/counters** (Redis sorted sets), **rate limiting**, **pub/sub messaging**, **geospatial** lookups.
- **Valkey:** AWS-backed open-source fork of Redis (after Redis's license change); ElastiCache now offers Valkey, Redis OSS, and Memcached. For SAA-C03 think "Redis vs Memcached"; Valkey ≈ Redis feature-wise and is often cheaper.
- **Auto Discovery (Memcached only):** the app connects to a single node and retrieves the full node list, then connects to any of them — no hard-coded node endpoints, and the list stays correct as nodes are added or removed (every node holds metadata about all the others). It requires an **ElastiCache client library with Auto Discovery support**. AWS explicitly states Auto Discovery is **not available for Valkey or Redis OSS**, which is what makes "node discovery" a Memcached-exclusive signal on the exam.
- Runs in your **VPC** (subnet group in private subnets, SG allowing the app tier) — same private-tier pattern as RDS.

## Comparisons

### Redis vs Memcached (the exam table)

|   | Redis (/ Valkey) | Memcached |
|---|---|---|
| Threading | **Single-threaded** | **Multi-threaded** |
| Persistence | Yes (snapshots/AOF) | **No** (RAM only) |
| Replication / HA | **Yes** | No |
| Multi-AZ auto-failover | **Yes** | No |
| Backup & restore | **Yes** | No |
| Data types | Rich (sorted sets, hashes, geo…) | Simple key-value |
| Pub/Sub, transactions | **Yes** | No |
| Horizontal scale | Cluster mode (sharding) | Add nodes (sharding) |
| **Auto Discovery** | ❌ not available | ✅ **Memcached-only** |
| **Choose when** | Need HA, persistence, complex data, pub/sub | Simplest, multi-core, pure ephemeral cache at scale |

### Caching strategies

| Strategy | How | Trade-off |
|---|---|---|
| **Lazy loading (cache-aside)** | Populate cache only on a miss | Only caches requested data; first read + any miss is slow; stale until evicted → use **TTL** |
| **Write-through** | Write to cache **and** DB on every write | Cache always fresh, but writes are slower and you cache data that may never be read |
| **TTL** | Expire keys after N seconds | Bounds staleness; pairs with lazy loading |

## Worked examples

> [!example] Worked example — read-heavy product page
> A product page runs the same "get product by id" query millions of times; the DB CPU is pegged and latency climbs. Put **ElastiCache** in front with **lazy loading**: the app checks the cache by product-id; on a **miss** it queries RDS/Aurora and stores the result with a **TTL** (say 300s); subsequent reads are **microsecond cache hits** that never touch the DB. DB load drops dramatically. Add read replicas ([[07-rds-aurora]]) only if writes/misses still stress it. This is the canonical "reduce database load / improve read latency" exam answer → ElastiCache.

> [!failure] Failure mode — Memcached for a session store
> A team uses **Memcached** to hold user login sessions. A cache node reboots (or is replaced during scaling) → **all sessions on it are gone** (no persistence, no replication), and users are logged out en masse. Sessions need durability + failover → use **Redis** (replication group, Multi-AZ, persistence). Rule: anything you can't afford to lose on a node failure belongs in **Redis**, not Memcached.

> [!example] Worked example — real-time leaderboard
> A game needs a live top-100 leaderboard updated on every score. A relational `ORDER BY score` over millions of rows per request is too slow. **Redis sorted sets** (`ZADD`/`ZREVRANGE`) maintain a ranked set in memory and return the top-N in microseconds. Memcached can't do this (simple key-value only). Trigger words "leaderboard / ranking / real-time counter" → **Redis**.

## Traps & failure modes

> [!warning] Trap — Memcached for anything needing HA/persistence/complex data
> Memcached is simple, multi-threaded, ephemeral. Need failover, backup, sorted sets, pub/sub, or a session store that survives a node loss → **Redis**. This engine-choice question is the heart of ElastiCache on the exam.

> [!warning] Trap — a question that mixes Redis-sounding *use cases* with Memcached-only *features*
> The hard version of the engine question doesn't say "pick a cache" — it describes a **session store** (which your instinct maps to Redis) while also specifying **multi-threaded** and **automatic node discovery** (both Memcached-only). The use case is a distractor; the engine-exclusive capabilities are the answer. Method: ignore *what it's for* and scan for a capability only one engine has. Multi-threaded / Auto Discovery → **Memcached**. Persistence, replication, Multi-AZ failover, backup, sorted sets, pub/sub → **Redis**. If the question also says data loss on node failure is unacceptable, that's a Redis-only signal and it outranks the others.

> [!warning] Trap — "add a cache" when the problem is writes
> Caches accelerate **reads**. If the bottleneck is heavy **writes** or the data must be strongly consistent per request, a cache doesn't help (and lazy-loading serves stale data). Match the tool to read-heavy, repeat-query workloads.

> [!warning] Trap — Redis is multi-threaded because it's fast
> Redis command execution is **single-threaded** (one core per node); it scales via **cluster-mode sharding**, not more cores. **Memcached** is the multi-threaded one. Reversed often.
