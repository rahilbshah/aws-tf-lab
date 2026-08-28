---
topic: 08-elasticache
domain: performance
related_note: 08-elasticache
tags: [flashcards/database]
---

# Cards for [[08-elasticache]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What problem does an in-memory cache like ElastiCache solve?
?
Read-heavy, repeated queries hammer the database with disk I/O. A cache stores results in RAM keyed by the query, so the app checks the cache first — a HIT returns in microseconds without touching the DB, cutting latency and database load dramatically. Only a MISS goes to the DB.

Redis vs Memcached — which is single- vs multi-threaded?
?
Memcached is MULTI-threaded (scales up on large multi-core nodes). Redis is SINGLE-threaded for command execution (one core per node; scale out via cluster-mode sharding). Common trap — people assume Redis is the multi-threaded one.

Which of Redis/Memcached supports HA, persistence, and backup?
?
Redis (and Valkey): replication, Multi-AZ with automatic failover, persistence (snapshots/AOF), and backup/restore. Memcached: none of these — it's ephemeral RAM only, so a node loss = its data is gone.

When do you choose Memcached over Redis?
?
When you want the simplest possible model, large nodes with multiple cores/threads, easy scale-out/in, and a pure ephemeral object cache — and you do NOT need persistence, replication, failover, backup, or complex data types.

When do you choose Redis over Memcached?
?
When you need high availability (replication + Multi-AZ failover), persistence/backup, complex data structures (sorted sets, lists, hashes, geospatial), pub/sub, or transactions — e.g. session stores, leaderboards, real-time counters, messaging.

What is lazy loading (cache-aside)?
?
The app reads from the cache first; on a MISS it queries the database, then writes the result into the cache (usually with a TTL) so the next read is a hit. Only requested data is cached; downside is the first read (and any miss) is slow and data can be stale until it expires/evicts.

Lazy loading vs write-through caching?
?
Lazy loading (cache-aside): populate the cache only on a miss — caches just what's used, but risks stale/missing data. Write-through: write to the cache AND the DB on every write — cache is always fresh, but writes are slower and you cache data that may never be read. TTL bounds staleness in both.

Which engine + feature powers a real-time leaderboard, and why?
?
Redis sorted sets (ZADD / ZREVRANGE). They keep a ranked set in memory and return top-N in microseconds — a relational ORDER BY over millions of rows per request would be too slow, and Memcached (simple key-value) can't do it.

Why is Memcached a bad choice for a session store?
?
It has no persistence, replication, or failover — if a node reboots or is replaced during scaling, all sessions on it are lost and users get logged out. Session data needs Redis (replication group + Multi-AZ + persistence) so it survives node failure.

Does adding a cache help a write-heavy workload?
?
No — caches accelerate READS (repeated, read-heavy queries). If the bottleneck is heavy writes, or each request needs strongly consistent fresh data, a cache doesn't help and lazy loading can serve stale data. Match caching to read-heavy, repeat-query patterns.

What is Valkey in ElastiCache?
?
The AWS-backed open-source fork of Redis (created after Redis's license change). ElastiCache offers Valkey, Redis OSS, and Memcached; Valkey is feature-compatible with Redis (HA, persistence, data types) and often cheaper. For SAA-C03, treat the choice as "Redis vs Memcached."

What is Auto Discovery, and which ElastiCache engine has it?
?
**Memcached only** — AWS states it is not available for Valkey or Redis OSS. The client connects to one node, retrieves the list of all nodes in the cluster, and then connects to any of them. Every node keeps metadata about all the others, refreshed whenever nodes are added or removed, so you never hard-code node endpoints. It needs an ElastiCache client library with Auto Discovery support.

A question says "multi-threaded, sub-millisecond, needs automatic node discovery, simple key-value." Which engine?
?
Memcached. Both "multi-threaded" and "node discovery / Auto Discovery" are Memcached-exclusive signals. Don't let the words "session store" or "cache" pull you to Redis — count the engine-exclusive signals rather than the use case.

Which signals in a question point uniquely at Redis rather than Memcached?
?
Persistence, backup/snapshot & restore, replication, Multi-AZ automatic failover, read replicas, pub/sub, transactions, and any rich data type (sorted sets/leaderboards, hashes, geospatial). Any ONE of those rules out Memcached.

Which signals point uniquely at Memcached rather than Redis?
?
Multi-threaded / "use all the cores of a large node", Auto Discovery of nodes, and "simplest possible ephemeral object cache, data loss on node failure is acceptable." Scaling by simply adding nodes with client-side sharding also leans Memcached.
