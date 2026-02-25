# Query Agent

## Overview

The Query Agent is an intelligent SQL query generator and optimizer that enables natural language querying of data stored in ClickHouse. It translates human questions into optimized SQL queries and provides insights into the data.

## Agent Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Query Agent                              │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │            Core Intelligence Layer               │   │
│  │                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────┐ │   │
│  │  │  NL-to-SQL   │  │  Query       │  │  Schema  │ │   │
│  │  │    Engine    │  │  Optimizer   │  │  Crawler │ │   │
│  │  └──────────────┘  └──────────────┘  └──────────┘ │   │
│  │                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐               │   │
│  │  │   LLM Core   │  │   Context    │               │   │
│  │  │ (Claude/GPT) │  │   Manager    │               │   │
│  │  └──────────────┘  └──────────────┘               │   │
│  └────────────────────────────────────────────────────┘   │
│                          │                                 │
│  ┌───────────────────────┼───────────────────────────────┐ │
│  │                       │                               │ │
│  │  ┌────────────────────▼─────────────────────┐        │ │
│  │  │         Skills & Tools                  │        │ │
│  │  │                                          │        │ │
│  │  │  • Natural Language Processing           │        │ │
│  │  │  • SQL Generation                       │        │ │
│  │  │  • Query Optimization                  │        │ │
│  │  │  • Result Formatting                    │        │ │
│  │  │  • Data Visualization                  │        │ │
│  │  │  • Query Caching                       │        │ │
│  │  │  • Schema Understanding                │        │ │
│  │  │  • Query Explanation                   │        │ │
│  │  └──────────────────────────────────────────┘        │ │
│  │                       │                               │ │
│  └───────────────────────┼───────────────────────────────┘ │
│                          │                                 │
│  ┌───────────────────────▼───────────────────────────────┐ │
│  │              External Integrations                    │ │
│  │                                                     │ │
│  │  • ClickHouse Database                             │ │
│  │  • PostgreSQL (schema metadata)                    │ │
│  │  • Redis (query cache)                             │ │
│  │  • Grafana (visualizations)                        │ │
│  │  • Slack/Telegram (notifications)                  │ │
│  │  • OpenAI/Anthropic (LLM)                         │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Agent Capabilities

### 1. Natural Language to SQL

**Query Translation:**
- Parse natural language questions
- Understand user intent
- Generate appropriate SQL queries
- Handle complex joins and aggregations
- Support ClickHouse-specific syntax

**Supported Query Types:**
- Simple SELECT queries
- Aggregations (COUNT, SUM, AVG, etc.)
- Filtering and sorting
- Grouping and window functions
- Time-based queries
- Subqueries and CTEs
- JOIN operations

### 2. Query Optimization

**Optimization Strategies:**
- Analyze query execution plans
- Suggest index usage
- Optimize JOIN order
- Recommend partition pruning
- Identify inefficient patterns
- Suggest materialized views

**Performance Tuning:**
- Add LIMIT clauses
- Optimize WHERE clauses
- Use appropriate functions
- Minimize data scanned
- Leverage ClickHouse features

### 3. Schema Understanding

**Schema Crawler:**
- Scan database metadata
- Understand table relationships
- Identify foreign keys
- Catalog column types
- Build knowledge graph

**Schema Features:**
- Table discovery
- Column type inference
- Relationship mapping
- Business logic extraction
- Data quality assessment

### 4. Query Explanation

**Natural Language Explanation:**
- Explain what the query does
- Break down each component
- Highlight key operations
- Identify potential issues
- Suggest improvements

**Execution Plan Analysis:**
- Explain ClickHouse execution plan
- Identify bottlenecks
- Suggest optimizations
- Estimate query cost

### 5. Result Formatting

**Format Options:**
- JSON (default)
- CSV
- Excel
- HTML tables
- Markdown tables
- Plain text

**Visualization Options:**
- Charts (line, bar, pie)
- Tables
- Heatmaps
- Time series
- Pivot tables

### 6. Query Caching

**Cache Strategy:**
- Cache query results
- Store query patterns
- LRU eviction policy
- TTL-based expiration
- Cache invalidation on data changes

**Cache Benefits:**
- Reduce database load
- Improve response time
- Handle concurrent queries
- Scale query throughput

### 7. Query History

**History Features:**
- Track all queries
- Analyze query patterns
- Identify popular queries
- Surface similar queries
- Provide query suggestions

**Analytics:**
- Query frequency
- Execution time trends
- Error rates
- User behavior insights

### 8. Data Insights

**Automated Insights:**
- Identify trends
- Detect anomalies
- Find correlations
- Surface key metrics
- Generate summaries

**Proactive Analysis:**
- Trend analysis
- Seasonality detection
- Outlier detection
- KPI monitoring
- Automated reports

## Agent Interface

### Natural Language Commands

```
"Show me the top 10 users by revenue last month"
"What's the average order value by day?"
"Compare sales between this week and last week"
"Find users who haven't logged in for 30 days"
"Show the trend of active users over time"
```

### API Endpoints

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

app = FastAPI()

class QueryRequest(BaseModel):
    question: str
    database: Optional[str] = "aidatalabs"
    user_id: str
    organization_id: str
    format: Optional[str] = "json"
    limit: Optional[int] = 1000

class QueryResponse(BaseModel):
    query_id: str
    sql: str
    explanation: str
    results: List[Dict[str, Any]]
    row_count: int
    execution_time_ms: float
    cached: bool

class SchemaResponse(BaseModel):
    tables: List[Dict[str, Any]]
    relationships: List[Dict[str, Any]]

class SuggestionResponse(BaseModel):
    suggestions: List[str]
    related_queries: List[str]

class OptimizeRequest(BaseModel):
    sql: str

class OptimizeResponse(BaseModel):
    optimized_sql: str
    improvements: List[str]
    estimated_speedup: float

@app.post("/api/v1/query/execute", response_model=QueryResponse)
async def execute_query(request: QueryRequest):
    """Execute a natural language query"""
    pass

@app.post("/api/v1/query/optimize", response_model=OptimizeResponse)
async def optimize_query(request: OptimizeRequest):
    """Optimize a SQL query"""
    pass

@app.get("/api/v1/query/schema", response_model=SchemaResponse)
async def get_schema(database: str = "aidatalabs"):
    """Get database schema"""
    pass

@app.get("/api/v1/query/suggestions", response_model=SuggestionResponse)
async def get_suggestions(
    user_id: str,
    database: str = "aidatalabs",
    limit: int = 5
):
    """Get query suggestions"""
    pass

@app.get("/api/v1/query/history")
async def get_query_history(
    user_id: str,
    limit: int = 50
):
    """Get user query history"""
    pass

@app.post("/api/v1/query/explain")
async def explain_query(sql: str):
    """Explain a SQL query"""
    pass

@app.get("/api/v1/query/insights")
async def get_insights(
    table: str,
    time_range: str = "7d"
):
    """Get data insights for a table"""
    pass
```

## Agent Configuration

### Environment Variables

```bash
# OpenClaw
OPENCLAW_GATEWAY_URL="https://gateway.openclaw.ai"
OPENCLAW_GATEWAY_TOKEN="your-token"

# LLM Configuration
LLM_PROVIDER="anthropic"  # or "openai", "zai"
LLM_MODEL="claude-3-opus"
LLM_TEMPERATURE=0.3
LLM_MAX_TOKENS=4096

# ClickHouse
CLICKHOUSE_HOST="clickhouse-0.clickhouse"
CLICKHOUSE_PORT=9000
CLICKHOUSE_USER="aidatalabs"
CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD}"
CLICKHOUSE_DATABASE="aidatalabs"

# PostgreSQL (schema metadata)
POSTGRES_HOST="postgres"
POSTGRES_PORT=5432
POSTGRES_USER="aidatalabs"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
POSTGRES_DB="aidatalabs"

# Redis (query cache)
REDIS_HOST="redis"
REDIS_PORT=6379
REDIS_PASSWORD="${REDIS_PASSWORD}"
REDIS_TTL=3600

# Cache Configuration
QUERY_CACHE_ENABLED=true
QUERY_CACHE_SIZE=10000
QUERY_CACHE_TTL=3600

# Query Limits
MAX_QUERY_ROWS=100000
MAX_QUERY_TIMEOUT=300
MAX_CONCURRENT_QUERIES=50
```

### Agent Manifest

```yaml
name: query-agent
version: 1.0.0
description: Natural language to SQL query generator and optimizer

capabilities:
  - natural_language_to_sql
  - query_optimization
  - schema_understanding
  - query_explanation
  - result_formatting
  - query_caching
  - query_history
  - data_insights

integrations:
  - clickhouse
  - postgresql
  - redis
  - grafana
  - openai
  - anthropic

permissions:
  - database:read
  - query_logs:write
  - cache:read_write

safety:
  require_approval:
    - query_rows > 100000
    - query_timeout > 300
    - schema_changes
  auto_cancel:
    - dangerous_queries
    - full_table_scans
  explain_by_default: true
```

## Query Translation Examples

### Example 1: Simple Query

**User Input:**
```
"Show me the top 10 users by revenue"
```

**Generated SQL:**
```sql
SELECT
    user_id,
    full_name,
    email,
    SUM(revenue) AS total_revenue
FROM user_revenue
WHERE date >= now() - INTERVAL 30 DAY
GROUP BY user_id, full_name, email
ORDER BY total_revenue DESC
LIMIT 10
```

**Explanation:**
- Filters to last 30 days of data
- Groups by user and sums revenue
- Orders by total revenue descending
- Returns top 10 users

### Example 2: Time Series

**User Input:**
```
"Show daily active users for the last week"
```

**Generated SQL:**
```sql
SELECT
    toDate(created_at) AS date,
    COUNT(DISTINCT user_id) AS active_users
FROM user_sessions
WHERE created_at >= now() - INTERVAL 7 DAY
GROUP BY date
ORDER BY date ASC
```

**Explanation:**
- Extracts date from timestamps
- Counts distinct users per day
- Filters to last 7 days
- Orders chronologically

### Example 3: Comparison

**User Input:**
```
"Compare sales between this week and last week"
```

**Generated SQL:**
```sql
SELECT
    toDate(order_date) AS date,
    SUM(CASE
        WHEN order_date >= now() - INTERVAL 7 DAY
        THEN amount
        ELSE 0
    END) AS this_week_sales,
    SUM(CASE
        WHEN order_date >= now() - INTERVAL 14 DAY
        AND order_date < now() - INTERVAL 7 DAY
        THEN amount
        ELSE 0
    END) AS last_week_sales
FROM orders
WHERE order_date >= now() - INTERVAL 14 DAY
GROUP BY date
ORDER BY date ASC
```

**Explanation:**
- Uses CASE statements for conditional aggregation
- Sums sales for current week and previous week
- Enables direct comparison
- Orders by date

### Example 4: Complex Join

**User Input:**
```
"Find users who made a purchase but haven't logged in for 30 days"
```

**Generated SQL:**
```sql
SELECT DISTINCT
    u.user_id,
    u.email,
    u.full_name,
    MAX(p.purchase_date) AS last_purchase,
    MAX(s.login_date) AS last_login,
    datediff('day', MAX(s.login_date), now()) AS days_since_login
FROM users u
JOIN purchases p ON u.user_id = p.user_id
LEFT JOIN user_sessions s ON u.user_id = s.user_id
WHERE p.purchase_date >= now() - INTERVAL 90 DAY
GROUP BY u.user_id, u.email, u.full_name
HAVING MAX(s.login_date) < now() - INTERVAL 30 DAY
ORDER BY last_purchase DESC
```

**Explanation:**
- Joins users with purchases and sessions
- Filters users with recent purchases
- Groups by user and aggregates dates
- HAVING clause filters users inactive for 30 days

## Query Optimization

### Before Optimization

```sql
SELECT
    *
FROM user_events
WHERE date >= now() - INTERVAL 30 DAY
  AND event_type = 'click'
ORDER BY timestamp DESC
LIMIT 1000
```

**Issues:**
- SELECT * retrieves all columns
- No index hint
- Scans entire date range

### After Optimization

```sql
SELECT
    event_id,
    user_id,
    event_type,
    timestamp
FROM user_events
WHERE
    date >= toDate(now() - INTERVAL 30 DAY)
    AND date <= toDate(now())
    AND event_type = 'click'
ORDER BY timestamp DESC
LIMIT 1000
SETTINGS
    max_threads = 4,
    max_memory_usage = 10000000000
```

**Improvements:**
- SELECT only necessary columns
- Date range filters enable partition pruning
- Explicit thread and memory settings

### Optimization Suggestions

1. **Add WHERE clause filters** to limit data scanned
2. **Use LIMIT** to prevent large result sets
3. **Select specific columns** instead of SELECT *
4. **Leverage partitioning** with date filters
5. **Use materialized views** for common aggregations
6. **Avoid subqueries** in WHERE clauses
7. **Use appropriate join types**
8. **Set query settings** for performance tuning

## Schema Understanding

### Schema Metadata Storage

```sql
CREATE TABLE IF NOT EXISTS schema_metadata (
    table_name String,
    column_name String,
    column_type String,
    is_nullable UInt8,
    default_value String,
    description String,
    is_primary_key UInt8,
    is_foreign_key UInt8,
    foreign_table String,
    foreign_column String,
    index_type String,
    sampled_values Array(String),
    min_value String,
    max_value String,
    distinct_count UInt64,
    null_count UInt64,
    updated_at DateTime64(3)
) ENGINE = ReplacingMergeTree()
ORDER BY (table_name, column_name)
TTL updated_at + INTERVAL 7 DAY
```

### Relationship Mapping

```sql
CREATE TABLE IF NOT EXISTS table_relationships (
    source_table String,
    source_column String,
    target_table String,
    target_column String,
    relationship_type String,  -- 'one_to_one', 'one_to_many', 'many_to_many'
    confidence Float64,
    discovered_at DateTime64(3)
) ENGINE = ReplacingMergeTree()
ORDER BY (source_table, source_column, target_table)
```

### Schema Crawler Logic

```python
async def crawl_schema():
    """Crawl database schema and build metadata"""
    tables = await get_all_tables()

    for table in tables:
        columns = await get_table_columns(table)

        for column in columns:
            # Store column metadata
            await store_column_metadata(table, column)

        # Sample data
        sample_data = await sample_table_data(table, limit=100)
        await store_sample_data(table, sample_data)

        # Find relationships
        relationships = await find_relationships(table)
        for rel in relationships:
            await store_relationship(rel)
```

## Query Caching

### Cache Key Generation

```python
def generate_cache_key(
    sql: str,
    user_id: str,
    organization_id: str
) -> str:
    """Generate cache key for query"""
    normalized_sql = sql.strip().lower()
    key_data = f"{user_id}:{organization_id}:{hashlib.md5(normalized_sql.encode()).hexdigest()}"
    return key_data
```

### Cache Storage

```python
import redis
import json
from datetime import datetime, timedelta

redis_client = redis.Redis(host='redis', port=6379, decode_responses=True)

async def cache_query(
    cache_key: str,
    results: List[Dict],
    ttl: int = 3600
):
    """Cache query results"""
    cache_data = {
        'results': results,
        'row_count': len(results),
        'cached_at': datetime.utcnow().isoformat(),
        'ttl': ttl
    }
    redis_client.setex(
        cache_key,
        ttl,
        json.dumps(cache_data)
    )

async def get_cached_query(cache_key: str) -> Optional[Dict]:
    """Get cached query results"""
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached)
    return None
```

### Cache Invalidation

```python
async def invalidate_cache_on_data_change(
    table: str,
    operation: str  # 'INSERT', 'UPDATE', 'DELETE'
):
    """Invalidate cache for table"""
    # Get all cached queries that reference this table
    pattern = f"*:{table}:*"
    keys = redis_client.keys(pattern)

    # Delete cached results
    for key in keys:
        redis_client.delete(key)
```

## Data Insights

### Trend Analysis

```python
async def analyze_trends(
    table: str,
    column: str,
    time_column: str = 'date',
    time_range: int = 30
) -> Dict:
    """Analyze trends in data"""

    sql = f"""
    SELECT
        toDate({time_column}) AS date,
        AVG({column}) AS avg_value,
        SUM({column}) AS total_value,
        COUNT(*) AS count,
        quantile(0.5)({column}) AS median,
        quantile(0.95)({column}) AS p95
    FROM {table}
    WHERE {time_column} >= now() - INTERVAL {time_range} DAY
    GROUP BY date
    ORDER BY date ASC
    """

    results = await execute_clickhouse_query(sql)

    # Calculate trend
    trend = calculate_trend([r['avg_value'] for r in results])

    # Detect seasonality
    seasonality = detect_seasonality(results)

    # Identify outliers
    outliers = detect_outliers(results, 'avg_value')

    return {
        'trend': trend,
        'seasonality': seasonality,
        'outliers': outliers,
        'data': results
    }
```

### Anomaly Detection

```python
async def detect_anomalies(
    table: str,
    column: str,
    time_column: str = 'date',
    threshold: float = 3.0
) -> List[Dict]:
    """Detect anomalies using Z-score"""

    sql = f"""
    SELECT
        {time_column},
        {column},
        avg({column}) OVER () AS global_mean,
        stddevPop({column}) OVER () AS global_stddev
    FROM {table}
    WHERE {time_column} >= now() - INTERVAL 30 DAY
    """

    results = await execute_clickhouse_query(sql)

    anomalies = []
    for row in results:
        z_score = abs((row[column] - row['global_mean']) / row['global_stddev'])

        if z_score > threshold:
            anomalies.append({
                'timestamp': row[time_column],
                'value': row[column],
                'z_score': z_score,
                'expected': row['global_mean'],
                'deviation': row[column] - row['global_mean']
            })

    return anomalies
```

## Query History Analytics

### Popular Queries

```sql
SELECT
    normalized_sql,
    COUNT(*) AS execution_count,
    AVG(execution_time_ms) AS avg_time_ms,
    SUM(rows_read) AS total_rows_read,
    COUNT(DISTINCT user_id) AS unique_users
FROM query_logs
WHERE created_at >= now() - INTERVAL 30 DAY
GROUP BY normalized_sql
ORDER BY execution_count DESC
LIMIT 100
```

### Slow Queries

```sql
SELECT
    query_id,
    sql,
    execution_time_ms,
    rows_read,
    rows_written,
    memory_usage_bytes,
    user_id,
    created_at
FROM query_logs
WHERE execution_time_ms > 5000
  AND created_at >= now() - INTERVAL 7 DAY
ORDER BY execution_time_ms DESC
LIMIT 50
```

### Query Patterns

```sql
SELECT
    COUNT(*) AS query_count,
    COUNT(DISTINCT user_id) AS unique_users,
    AVG(execution_time_ms) AS avg_time_ms,
    quantile(0.95)(execution_time_ms) AS p95_time_ms,
    SUM(CASE WHEN error_message != '' THEN 1 ELSE 0 END) AS error_count,
    SUM(rows_read) AS total_rows_read
FROM query_logs
WHERE created_at >= now() - INTERVAL 30 DAY
GROUP BY
    substring(sql, 1, 100) AS query_pattern
ORDER BY query_count DESC
LIMIT 100
```

## Workflows

### 1. Natural Language Query Workflow

```
User Question
    │
    ▼
Parse & Understand (NLP)
    │
    ▼
Analyze Schema
    │
    ▼
Generate SQL (LLM)
    │
    ▼
Validate SQL (Safety)
    │
    ▼
Optimize SQL (Optimizer)
    │
    ▼
Check Cache
    │
    ├─ Hit → Return Cached Results
    │
    └─ Miss → Execute Query
                │
                ▼
                Format Results
                │
                ▼
                Cache Results
                │
                ▼
                Log Query
                │
                ▼
                Return Response
```

### 2. Schema Discovery Workflow

```
Scan Database
    │
    ▼
List Tables
    │
    ▼
For Each Table:
    │
    ├─ Get Columns
    ├─ Sample Data
    ├─ Get Indexes
    ├─ Get Constraints
    └─ Find Relationships
    │
    ▼
Build Metadata
    │
    ▼
Store in Knowledge Base
    │
    ▼
Generate Schema Graph
    │
    ▼
Complete
```

## Agent Skills

### NL-to-SQL Skill

**Capabilities:**
- Parse natural language questions
- Understand query intent
- Generate ClickHouse SQL
- Handle complex queries
- Support multiple query types

### Query Optimizer Skill

**Capabilities:**
- Analyze query execution plan
- Suggest index usage
- Optimize query structure
- Estimate query cost
- Provide performance tips

### Schema Crawler Skill

**Capabilities:**
- Discover tables and columns
- Understand data types
- Find relationships
- Build knowledge graph
- Detect data quality issues

### Result Formatter Skill

**Capabilities:**
- Format results as JSON/CSV/HTML
- Generate visualizations
- Create pivot tables
- Export to Excel
- Generate reports

## Safety Guardrails

### Query Limits

**Enforced Limits:**
- Maximum rows: 100,000
- Maximum execution time: 300 seconds
- Maximum memory usage: 10GB
- Maximum concurrent queries: 50 per user

**Protected Operations:**
- DDL statements (CREATE, ALTER, DROP)
- Data modification (INSERT, UPDATE, DELETE)
- Administrative queries (SYSTEM, KILL)
- Full table scans without LIMIT

### Query Validation

**Validation Checks:**
- SQL syntax validation
- Injection detection
- Resource usage estimation
- Permission verification
- Data access control

## Monitoring

### Agent Metrics

**Query Metrics:**
- Total queries executed
- Average query time
- Cache hit rate
- Error rate
- Rows scanned per query

**Performance Metrics:**
- LLM generation time
- SQL generation latency
- Query execution time
- Result formatting time
- End-to-end latency

**User Metrics:**
- Active users
- Queries per user
- Popular query patterns
- User satisfaction

## Development Roadmap

### Phase 1: Core Capabilities (Weeks 7-8)
- [x] Natural language to SQL
- [ ] Query optimization
- [ ] Schema understanding
- [ ] Basic caching

### Phase 2: Advanced Features (Weeks 9-10)
- [ ] Query history
- [ ] Query suggestions
- [ ] Result visualization
- [ ] Data insights

### Phase 3: Intelligence (Weeks 11-12)
- [ ] Trend analysis
- [ ] Anomaly detection
- [ ] Predictive analytics
- [ ] Automated reports

## Testing

### Unit Tests

```python
import pytest

def test_nl_to_sql():
    query = QueryRequest(
        question="Show me top 10 users"
    )
    result = agent.generate_sql(query)
    assert "SELECT" in result.sql
    assert "LIMIT 10" in result.sql

def test_query_optimization():
    request = OptimizeRequest(
        sql="SELECT * FROM table"
    )
    result = agent.optimize_query(request)
    assert "optimized_sql" in result
    assert result.optimized_sql != request.sql

def test_cache():
    query = QueryRequest(
        question="Test query"
    )
    # Execute first time
    result1 = await agent.execute_query(query)
    # Execute second time (should hit cache)
    result2 = await agent.execute_query(query)
    assert result2.cached == True
```

## Documentation

### API Documentation

https://docs.aidatalabs.ai/query-agent/api

### User Guide

https://docs.aidatalabs.ai/query-agent/user-guide

### Query Examples

https://docs.aidatalabs.ai/query-agent/examples

## References

- ClickHouse SQL Reference: https://clickhouse.com/docs/en/sql-reference
- Text-to-SQL Papers: https://arxiv.org/abs/2204.00498
- Query Optimization: https://clickhouse.com/docs/en/sql-reference/optimize
