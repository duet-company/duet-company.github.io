# Building Real-Time Analytics with ClickHouse

ClickHouse is a columnar database designed for high-performance analytical queries on large datasets. In this guide, we'll explore how to build real-time analytics systems using ClickHouse, focusing on sub-second query performance, efficient data ingestion, and scalable architecture.

## Why ClickHouse for Real-Time Analytics

ClickHouse excels at analytical workloads due to several key advantages:

- **Columnar storage:** Reduces I/O by only reading required columns
- **Vectorized execution:** Processes data in batches using CPU SIMD instructions
- **Primary index with optional secondary indexes:** Enables fast point queries
- **MergeTree engine family:** Optimized for write-heavy workloads with efficient merges
- **Compression:** Reduces storage costs by 5-10x compared to row-oriented databases
- **SQL support:** Familiar query language with powerful analytical functions

**Performance characteristics:**
- Scan speed: 1-10 GB/s per core (depending on compression)
- Query latency: 10-100ms for most analytical queries on billions of rows
- Ingestion rate: 100K-1M+ rows/sec per node
- Compression ratio: 5-10x compared to uncompressed data

## Core Architecture Components

A typical real-time analytics pipeline with ClickHouse consists of:

1. **Data collection layer:** Event streaming from applications, sensors, APIs
2. **Buffer layer:** Kafka, RabbitMQ, or message queue for decoupling
3. **Ingestion layer:** ClickHouse native protocols or batch import
4. **Storage layer:** ClickHouse cluster with replication
5. **Query layer:** Application servers, BI tools, API endpoints

```
Applications → Message Queue → ClickHouse → Analytics/BI
               (Kafka)         Cluster
                                   ↓
                              Materialized Views
                                   ↓
                            Aggregated Tables
```

## ClickHouse Installation and Setup

### Installation Options

**Option 1: Docker (Recommended for Development)**
```bash
docker run -d \
  --name clickhouse-server \
  -p 8123:8123 \
  -p 9000:9000 \
  --ulimit nofile=262144:262144 \
  -v $(pwd)/data:/var/lib/clickhouse \
  clickhouse/clickhouse-server:latest
```

**Option 2: Package Manager (Production)**
```bash
# Debian/Ubuntu
sudo apt-get install -y apt-transport-https ca-certificates dirmngr
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8919F6BD2B48D754

echo "deb https://packages.clickhouse.com/deb stable main" | sudo tee \
  /etc/apt/sources.list.d/clickhouse.list

sudo apt-get update
sudo apt-get install -y clickhouse-server clickhouse-client

# Start service
sudo clickhouse start
```

**Option 3: Kubernetes (Clustered Deployment)**
```yaml
# clickhouse-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: clickhouse
spec:
  serviceName: clickhouse
  replicas: 3
  selector:
    matchLabels:
      app: clickhouse
  template:
    metadata:
      labels:
        app: clickhouse
    spec:
      containers:
      - name: clickhouse
        image: clickhouse/clickhouse-server:latest
        ports:
        - containerPort: 9000  # Native protocol
        - containerPort: 8123  # HTTP interface
        volumeMounts:
        - name: data
          mountPath: /var/lib/clickhouse
        resources:
          requests:
            memory: "4Gi"
            cpu: "2"
          limits:
            memory: "8Gi"
            cpu: "4"
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 100Gi
```

### Basic Configuration

**config.xml:**
```xml
<clickhouse>
    <!-- Listen on all interfaces -->
    <listen_host>::</listen_host>

    <!-- HTTP interface -->
    <http_port>8123</http_port>

    <!-- Native protocol -->
    <tcp_port>9000</tcp_port>

    <!-- MySQL compatibility (optional) -->
    <mysql_port>9004</mysql_port>

    <!-- PostgreSQL compatibility (optional) -->
    <postgresql_port>9005</postgresql_port>

    <!-- Logging -->
    <logger>
        <level>information</level>
        <log>/var/log/clickhouse/clickhouse-server.log</log>
        <errorlog>/var/log/clickhouse/clickhouse-server.err.log</errorlog>
        <size>100M</size>
        <count>10</count>
    </logger>

    <!-- User directories -->
    <users_config>/etc/clickhouse-server/users.xml</users_config>
    <default_profile>default</default_profile>
    <default_database>default</default_database>

    <!-- Data directory -->
    <path>/var/lib/clickhouse/</path>
</clickhouse>
```

## Data Modeling for Analytics

### Choosing the Right Table Engine

ClickHouse offers multiple table engines optimized for different use cases:

| Engine | Use Case | Pros | Cons |
|--------|----------|------|------|
| **MergeTree** | General-purpose analytics | Fast writes, efficient merges | No replication alone |
| **ReplicatedMergeTree** | Production clusters | Replication, data safety | Requires ZooKeeper |
| **SummingMergeTree** | Pre-aggregated data | Automatic aggregation | Limited sum operations |
| **AggregatingMergeTree** | Advanced aggregation | Complex aggregates | Requires special functions |
| **CollapsingMergeTree** | Upserts/deletes | Supports row updates | Requires sign column |
| **VersionedCollapsingMergeTree** | Row versioning | Handles out-of-order data | Higher overhead |
| **ReplacingMergeTree** | Latest state | Automatic deduplication | Non-deterministic until merge |
| **Distributed** | Query federation | Splits queries across cluster | No data storage |

### Schema Design Best Practices

**Example: Event Tracking Schema**
```sql
-- Create database
CREATE DATABASE analytics;

-- Use the database
USE analytics;

-- Raw events table (ReplicatedMergeTree)
CREATE TABLE events ON CLUSTER '{cluster}' (
    -- Primary metadata
    event_id String,
    event_time DateTime,
    event_date Date MATERIALIZED toDate(event_time),

    -- Event details
    event_type LowCardinality(String),
    event_name String,

    -- User context
    user_id String,
    session_id String,
    device_type LowCardinality(String),
    os_type LowCardinality(String),
    browser LowCardinality(String),

    -- Request context
    request_method LowCardinality(String),
    request_path String,
    request_params String,
    response_status UInt16,
    response_time_ms UInt32,

    -- Custom properties (as map)
    properties Map(String, String),

    -- Geographic data (if available)
    country_code LowCardinality(FixedString(2)),
    city String,

    -- Technical fields
    ip_address IPv4,

    -- For deduplication
    _insert_time DateTime DEFAULT now()
) ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/events',
    '{replica}'
)
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_date, event_type, user_id, event_time)
TTL event_date + INTERVAL 90 DAY DELETE
SETTINGS
    index_granularity = 8192;
```

**Key design decisions:**

1. **PARTITION BY toYYYYMM(event_date):** Monthly partitions for efficient data pruning
2. **ORDER BY (event_date, event_type, user_id, event_time):** Optimal for time-series queries with user filtering
3. **TTL event_date + INTERVAL 90 DAY DELETE:** Automatic data retention
4. **LowCardinality(String):** Reduces memory for repetitive values
5. **Map(String, String) properties:** Flexible schema for custom fields

**Aggregated events table (SummingMergeTree):**
```sql
CREATE TABLE events_daily_agg ON CLUSTER '{cluster}' (
    event_date Date,
    event_type LowCardinality(String),
    event_name String,
    device_type LowCardinality(String),
    country_code LowCardinality(FixedString(2)),

    -- Metrics (will be summed)
    event_count UInt32 MATERIALIZED 1,
    unique_users UInt32,
    response_time_sum UInt64,
    response_time_max UInt32,
    error_count UInt32 MATERIALIZED
        multiIf(response_status >= 500, 1, 0),

    -- For merge
    _insert_time DateTime DEFAULT now()
) ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_date, event_type, event_name, device_type, country_code)
TTL event_date + INTERVAL 365 DAY DELETE;

-- Materialized view to populate aggregated table
CREATE MATERIALIZED VIEW events_daily_agg_mv TO events_daily_agg AS
SELECT
    event_date,
    event_type,
    event_name,
    device_type,
    country_code,
    uniqExact(user_id) AS unique_users,
    sum(response_time_ms) AS response_time_sum,
    max(response_time_ms) AS response_time_max,
    1 AS event_count,
    _insert_time
FROM events
GROUP BY
    event_date,
    event_type,
    event_name,
    device_type,
    country_code,
    _insert_time;
```

### Partitioning Strategy

**Good partitioning:**
- Time-based: Daily, weekly, or monthly depending on data volume
- Cardinality: 100-1000 partitions total (not per table)
- Balance: Query pruning benefits vs. merge overhead

**Example: Time-based partitioning**
```sql
-- Daily partitions (high write volume)
PARTITION BY event_date

-- Monthly partitions (moderate write volume)
PARTITION BY toYYYYMM(event_date)

-- Yearly partitions (archival data)
PARTITION BY toYYYY(event_date)
```

**Avoid:**
- High-cardinality columns (user_id, session_id) → thousands of partitions
- Too granular partitions (hourly) → merge overhead dominates

### Primary Key and Sorting Key

The ORDER BY clause defines the primary key and sorting order:

```sql
-- Simple primary key
ORDER BY (event_date, user_id)

-- Compound primary key for multi-column filtering
ORDER BY (event_date, event_type, user_id)

-- Granularity control
SETTINGS index_granularity = 8192  -- Default: 8192 rows per data mark
```

**Guidelines:**
- First columns: Most frequently filtered in WHERE clause
- Second columns: Join keys or grouping columns
- Last columns: Range queries or ORDER BY columns

## Data Ingestion Strategies

### Ingestion Options

| Method | Throughput | Latency | Use Case |
|--------|-----------|---------|----------|
| **INSERT streaming** | 100K-1M rows/sec | 100-500ms | Real-time, low-latency |
| **Batch INSERT** | 1-10M rows/batch | 1-5s | Hourly/daily loads |
| **clickhouse-local** | N/A | N/A | ETL, data processing |
| **Kafka Engine** | 100K-1M rows/sec | 100-500ms | Streaming from Kafka |
| **S3/URL table function** | High | Variable | One-time imports |

### Streaming Insert (Recommended for Real-Time)

**HTTP interface:**
```bash
curl -X POST 'http://localhost:8123/?query=INSERT%20INTO%20analytics.events%20FORMAT%20JSONEachRow' \
  --data-binary @events.json
```

**ClickHouse client:**
```bash
clickhouse-client --query="INSERT INTO analytics.events FORMAT JSONEachRow" < events.json
```

**Batch insert for high throughput:**
```sql
-- Insert multiple rows in one statement
INSERT INTO analytics.events FORMAT JSONEachRow
{"event_id":"1","event_time":"2026-02-27 10:00:00","event_type":"page_view",...}
{"event_id":"2","event_time":"2026-02-27 10:00:01","event_type":"click",...}
...
{"event_id":"1000","event_time":"2026-02-27 10:00:59","event_type":"scroll",...}
```

### Kafka Integration

**Create Kafka table:**
```sql
CREATE TABLE events_kafka (
    event_id String,
    event_time DateTime,
    event_type String,
    user_id String,
    -- ... other columns
) ENGINE = Kafka()
SETTINGS
    kafka_broker_list = 'kafka-1:9092,kafka-2:9092,kafka-3:9092',
    kafka_topic_list = 'events',
    kafka_group_name = 'clickhouse_consumer',
    kafka_format = 'JSONEachRow',
    kafka_num_consumers = 3,
    kafka_max_block_size = 65536;
```

**Create materialized view to consume from Kafka:**
```sql
CREATE MATERIALIZED VIEW events_consumer TO analytics.events AS
SELECT
    parseDateTime(JSONExtractString(_message, 'event_time')) AS event_time,
    JSONExtractString(_message, 'event_id') AS event_id,
    JSONExtractString(_message, 'event_type') AS event_type,
    JSONExtractString(_message, 'user_id') AS user_id,
    -- ... other columns
FROM events_kafka;
```

### Batch Import from Files

**Import from CSV:**
```bash
clickhouse-client --query="
    INSERT INTO analytics.events
    FORMAT CSVWithNames
" < events.csv
```

**Import from JSON:**
```bash
clickhouse-client --query="
    INSERT INTO analytics.events
    FORMAT JSONEachRow
" < events.json
```

## Query Optimization Techniques

### Query Performance Analysis

**EXPLAIN plan:**
```sql
EXPLAIN PLAN
SELECT
    event_type,
    count() AS event_count,
    avg(response_time_ms) AS avg_response_time
FROM analytics.events
WHERE event_date BETWEEN '2026-02-20' AND '2026-02-26'
GROUP BY event_type
ORDER BY event_count DESC;
```

**EXPLAIN pipeline (detailed):**
```sql
EXPLAIN PIPELINE
SELECT user_id, count() AS event_count
FROM analytics.events
WHERE event_date = today()
GROUP BY user_id
ORDER BY event_count DESC
LIMIT 10;
```

### Partition Pruning

**Effective query (uses partition pruning):**
```sql
-- Queries only relevant partitions
SELECT *
FROM analytics.events
WHERE event_date BETWEEN '2026-02-20' AND '2026-02-26';
```

**Ineffective query (scans all partitions):**
```sql
-- Function on partition column prevents pruning
SELECT *
FROM analytics.events
WHERE toYYYYMM(event_date) = 202602;
```

**Solution:**
```sql
-- Use partition column directly
SELECT *
FROM analytics.events
WHERE event_date >= '2026-02-01' AND event_date < '2026-03-01';
```

### Using Materialized Views for Pre-Aggregation

**Real-time rollups with materialized view:**
```sql
-- Create pre-aggregated table
CREATE TABLE events_hourly_agg (
    event_hour DateTime,
    event_type LowCardinality(String),
    event_count UInt32,
    unique_users UInt32,
    response_time_avg Float64
) ENGINE = AggregatingMergeTree()
ORDER BY (event_hour, event_type);

-- Create materialized view
CREATE MATERIALIZED VIEW events_hourly_agg_mv
AS
SELECT
    toStartOfHour(event_time) AS event_hour,
    event_type,
    countState() AS event_count,
    uniqExactState(user_id) AS unique_users,
    avgState(response_time_ms) AS response_time_avg
FROM analytics.events
GROUP BY event_hour, event_type;

-- Query pre-aggregated data (much faster)
SELECT
    event_hour,
    event_type,
    countMerge(event_count) AS event_count,
    uniqExactMerge(unique_users) AS unique_users,
    avgMerge(response_time_avg) AS avg_response_time
FROM events_hourly_agg
WHERE event_hour >= now() - INTERVAL 24 HOUR
GROUP BY event_hour, event_type;
```

### Skip Indexes for Faster Queries

**Minmax index (built-in):**
```sql
-- Automatically created on all columns in ORDER BY
SELECT *
FROM analytics.events
WHERE event_date = '2026-02-27';  -- Uses minmax index
```

**Bloom filter index (manual):**
```sql
-- Add bloom filter to user_id
ALTER TABLE analytics.events
ADD INDEX idx_user_id_bloom user_id TYPE bloom_filter GRANULARITY 4;

-- Query uses bloom filter
SELECT count()
FROM analytics.events
WHERE user_id = 'user_12345';
```

**Set index:**
```sql
-- Add set index for fast IN queries
ALTER TABLE analytics.events
ADD INDEX idx_event_type_set event_type TYPE set(2) GRANULARITY 4;

-- Query uses set index
SELECT count()
FROM analytics.events
WHERE event_type IN ('page_view', 'click', 'scroll');
```

## Real-Time Analytics Examples

### Time-Series Analytics

**Events per minute (last hour):**
```sql
SELECT
    toStartOfMinute(event_time) AS minute,
    count() AS events_per_minute
FROM analytics.events
WHERE event_time >= now() - INTERVAL 1 HOUR
GROUP BY minute
ORDER BY minute;
```

**Rolling window (5-minute rolling average):**
```sql
SELECT
    minute,
    events_per_minute,
    avg(events_per_minute) OVER (
        ORDER BY minute
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_5min
FROM (
    SELECT
        toStartOfMinute(event_time) AS minute,
        count() AS events_per_minute
    FROM analytics.events
    WHERE event_time >= now() - INTERVAL 1 HOUR
    GROUP BY minute
)
ORDER BY minute;
```

### Funnel Analysis

**User conversion funnel:**
```sql
-- Funnel stages: page_view → product_view → add_to_cart → purchase
WITH funnel_stages AS (
    SELECT
        user_id,
        event_name,
        min(event_time) AS first_event_time
    FROM analytics.events
    WHERE event_name IN ('page_view', 'product_view', 'add_to_cart', 'purchase')
    GROUP BY user_id, event_name
),
funnel AS (
    SELECT
        user_id,
        anyIf('page_view', event_name = 'page_view') AS stage1,
        anyIf('product_view', event_name = 'product_view') AS stage2,
        anyIf('add_to_cart', event_name = 'add_to_cart') AS stage3,
        anyIf('purchase', event_name = 'purchase') AS stage4
    FROM funnel_stages
    GROUP BY user_id
)
SELECT
    count() AS total_users,
    countIf(stage1 = 'page_view') AS stage1_users,
    countIf(stage2 = 'product_view') AS stage2_users,
    countIf(stage3 = 'add_to_cart') AS stage3_users,
    countIf(stage4 = 'purchase') AS stage4_users,
    round(stage2_users * 100.0 / stage1_users, 2) AS stage1_to_stage2_pct,
    round(stage3_users * 100.0 / stage2_users, 2) AS stage2_to_stage3_pct,
    round(stage4_users * 100.0 / stage3_users, 2) AS stage3_to_stage4_pct
FROM funnel;
```

### Cohort Analysis

**Monthly user cohorts:**
```sql
WITH user_cohorts AS (
    SELECT
        user_id,
        toStartOfMonth(min(event_time)) AS cohort_month
    FROM analytics.events
    WHERE event_name = 'page_view'
    GROUP BY user_id
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        toStartOfMonth(e.event_time) AS activity_month,
        countDistinct(c.user_id) AS active_users
    FROM user_cohorts c
    JOIN analytics.events e ON c.user_id = e.user_id
    GROUP BY c.cohort_month, activity_month
)
SELECT
    cohort_month,
    sumIf(active_users, activity_month = cohort_month) AS month_0_users,
    sumIf(active_users, activity_month = cohort_month + INTERVAL 1 MONTH) AS month_1_users,
    sumIf(active_users, activity_month = cohort_month + INTERVAL 2 MONTH) AS month_2_users,
    sumIf(active_users, activity_month = cohort_month + INTERVAL 3 MONTH) AS month_3_users,
    round(month_1_users * 100.0 / month_0_users, 2) AS m1_retention_pct,
    round(month_2_users * 100.0 / month_0_users, 2) AS m2_retention_pct,
    round(month_3_users * 100.0 / month_0_users, 2) AS m3_retention_pct
FROM cohort_activity
GROUP BY cohort_month
ORDER BY cohort_month;
```

### Anomaly Detection

**Z-score based anomaly detection:**
```sql
WITH metrics AS (
    SELECT
        event_date,
        event_type,
        count() AS event_count
    FROM analytics.events
    WHERE event_date >= now() - INTERVAL 30 DAY
    GROUP BY event_date, event_type
),
stats AS (
    SELECT
        event_type,
        avg(event_count) AS mean_events,
        stddevPop(event_count) AS stddev_events
    FROM metrics
    GROUP BY event_type
)
SELECT
    m.event_date,
    m.event_type,
    m.event_count,
    s.mean_events,
    s.stddev_events,
    round((m.event_count - s.mean_events) / s.stddev_events, 2) AS z_score,
    CASE
        WHEN abs((m.event_count - s.mean_events) / s.stddev_events) > 3
        THEN 'ANOMALY'
        ELSE 'NORMAL'
    END AS status
FROM metrics m
JOIN stats s ON m.event_type = s.event_type
WHERE m.event_date >= now() - INTERVAL 7 DAY
ORDER BY abs((m.event_count - s.mean_events) / s.stddev_events) DESC;
```

## Performance Tuning

### Memory Management

**Max memory usage per query:**
```sql
-- Set maximum memory per query (in bytes)
SET max_memory_usage = 10000000000;  -- 10GB

-- Set maximum memory usage for all queries
SET max_memory_usage_all = 20000000000;  -- 20GB
```

**Memory for JOINs:**
```sql
-- Use smaller table for JOIN optimization
SELECT large_table.*
FROM large_table
JOIN (
    -- Small table in memory
    SELECT user_id, user_segment
    FROM user_segments
    WHERE active = 1
) small_table ON large_table.user_id = small_table.user_id
SETTINGS join_algorithm = 'hash';  -- Hash join (default for small tables)
```

### Parallel Query Execution

**Parallel read from multiple replicas:**
```sql
-- Enable parallel reads from replicas
SELECT count()
FROM analytics.events
WHERE event_date = today()
SETTINGS max_parallel_replicas = 2;
```

**Parallel insert:**
```sql
-- Insert data in parallel
INSERT INTO analytics.events
SELECT * FROM remote('node{1,2,3}', analytics.events, 'default', '***');
```

### Compression Settings

**ZSTD compression (recommended):**
```sql
-- Set compression codec
ALTER TABLE analytics.events
MODIFY SETTING compression_codec = 'ZSTD(3)';  -- Level 1-22, 3 is balanced
```

**Different compression per column:**
```sql
-- Column-specific compression
ALTER TABLE analytics.events
MODIFY COLUMN event_date SETTINGS codec = 'ZSTD(3)';

ALTER TABLE analytics.events
MODIFY COLUMN user_id SETTINGS codec = 'ZSTD(1)';  -- Lower level for faster reads
```

## Monitoring and Maintenance

### System Queries

**Table size:**
```sql
SELECT
    database,
    table,
    sum(rows) AS total_rows,
    formatReadableSize(sum(data_bytes)) AS data_size,
    formatReadableSize(sum(bytes_on_disk)) AS disk_size
FROM system.parts
WHERE active
GROUP BY database, table
ORDER BY data_size DESC;
```

**Query performance:**
```sql
SELECT
    query_duration_ms,
    type,
    query,
    formatReadableSize(memory_usage) AS memory_used
FROM system.query_log
WHERE type = 'QueryFinish'
  AND event_date >= today()
ORDER BY query_duration_ms DESC
LIMIT 10;
```

**Slow queries:**
```sql
SELECT
    query_duration_ms / 1000 AS duration_sec,
    type,
    substring(query, 1, 100) AS query_preview
FROM system.query_log
WHERE type = 'QueryFinish'
  AND query_duration_ms > 10000  -- Queries > 10 seconds
  AND event_date >= today()
ORDER BY query_duration_ms DESC;
```

### Maintenance Operations

**Optimize table (force merge):**
```sql
-- Optimize partitions
OPTIMIZE TABLE analytics.events PARTITION 202602 FINAL;

-- Optimize entire table
OPTIMIZE TABLE analytics.events FINAL;
```

**Check data integrity:**
```sql
-- Check table for corrupted parts
CHECK TABLE analytics.events;
```

**Drop old partitions:**
```sql
-- Drop partitions older than 90 days
ALTER TABLE analytics.events
DROP PARTITION 202511;
```

## Production Deployment Checklist

- [ ] Configure replication with ZooKeeper
- [ ] Set up backup and restore procedures
- [ ] Configure monitoring (Prometheus, Grafana)
- [ ] Set up alerts for query performance
- [ ] Configure TLS for client connections
- [ ] Implement RBAC for access control
- [ ] Configure query logging and audit
- [ ] Set up automated partition management
- [ ] Test failover and recovery
- [ ] Document disaster recovery procedures

## Conclusion

ClickHouse provides exceptional performance for real-time analytics workloads. With proper schema design, efficient data ingestion, and query optimization, you can achieve sub-second query response times even on billions of rows.

Key takeaways:
- Use ReplicatedMergeTree for production clusters
- Partition by time, order by query patterns
- Leverage materialized views for pre-aggregation
- Use skip indexes for frequent filters
- Monitor query performance and optimize hot paths
- Set up automated maintenance and backups

By following the patterns and best practices in this guide, you can build scalable, high-performance real-time analytics systems with ClickHouse that handle millions of events per day while maintaining sub-second query latencies.
