# PERF-005: Query Optimization Audit

## Metadata

| Field | Value |
|-------|-------|
| **ID** | PERF-005 |
| **Title** | Conduct Query Optimization Audit |
| **Type** | Technical Debt |
| **Status** | BACKLOG |
| **Priority** | P2 (Medium) |
| **Estimate** | 8 hours |
| **Sprint** | Sprint 7 |
| **Epic** | Performance & Scalability |
| **Assignee** | TBD |
| **Created** | 2025-11-29 |
| **Tags** | `database`, `optimization`, `performance`, `postgresql`, `query-tuning` |
| **Blocks** | - |

## Description

Conduct a comprehensive database query optimization audit to identify and resolve performance bottlenecks. This includes enabling and analyzing pg_stat_statements, identifying slow queries (>100ms), performing EXPLAIN ANALYZE on problematic queries, optimizing indexes, refactoring inefficient queries, and documenting all optimizations with before/after performance measurements.

## Acceptance Criteria

- [ ] **pg_stat_statements Analysis**
  - [ ] Enable pg_stat_statements extension
  - [ ] Configure statement tracking
  - [ ] Collect baseline statistics
  - [ ] Analyze top queries by total time
  - [ ] Identify queries with high execution frequency
- [ ] **Slow Query Identification**
  - [ ] Identify all queries executing > 100ms
  - [ ] Categorize queries by type (SELECT, INSERT, UPDATE, DELETE)
  - [ ] Prioritize by impact (frequency × execution time)
  - [ ] Document top 20 slow queries
  - [ ] Create optimization backlog
- [ ] **Execution Plan Analysis**
  - [ ] Run EXPLAIN ANALYZE on slow queries
  - [ ] Identify sequential scans on large tables
  - [ ] Find missing indexes
  - [ ] Detect inefficient joins
  - [ ] Document analysis findings
- [ ] **Index Optimization**
  - [ ] Audit existing indexes
  - [ ] Identify missing indexes
  - [ ] Create new indexes where beneficial
  - [ ] Remove unused/redundant indexes
  - [ ] Validate index effectiveness
- [ ] **Query Refactoring**
  - [ ] Rewrite inefficient queries
  - [ ] Optimize N+1 query patterns
  - [ ] Implement query result caching where appropriate
  - [ ] Refactor complex subqueries
  - [ ] Test refactored queries
- [ ] **Results Documentation**
  - [ ] Document all changes made
  - [ ] Record before/after performance metrics
  - [ ] Create optimization playbook
  - [ ] Share findings with team
  - [ ] Schedule follow-up audits

## Subtasks

### 1. Setup and Baseline Collection
- [ ] **Enable pg_stat_statements**
  - [ ] Add extension to postgresql.conf
  - [ ] Create extension in database
  - [ ] Configure tracking parameters
  - [ ] Restart PostgreSQL
  - [ ] Verify extension is working
- [ ] **Configure Monitoring**
  - [ ] Setup query logging
  - [ ] Configure slow query log
  - [ ] Enable auto_explain module
  - [ ] Setup log rotation
- [ ] **Collect Baseline Metrics**
  - [ ] Run workload for 24-48 hours
  - [ ] Export pg_stat_statements data
  - [ ] Capture current index usage
  - [ ] Document baseline performance

### 2. Query Analysis and Identification
- [ ] **Analyze pg_stat_statements**
  - [ ] Query top consumers by total_time
  - [ ] Identify queries by mean_time
  - [ ] Find queries with high calls
  - [ ] Export analysis results
- [ ] **Categorize Queries**
  - [ ] Group by query type
  - [ ] Group by table access patterns
  - [ ] Prioritize by impact score
  - [ ] Create optimization roadmap
- [ ] **Document Findings**
  - [ ] Create query inventory
  - [ ] Document problematic patterns
  - [ ] Estimate optimization effort
  - [ ] Set performance targets

### 3. Execution Plan Analysis
- [ ] **Run EXPLAIN ANALYZE**
  - [ ] Execute for all slow queries
  - [ ] Capture execution plans
  - [ ] Identify bottlenecks
  - [ ] Document findings
- [ ] **Analyze Plans**
  - [ ] Identify sequential scans
  - [ ] Find inefficient joins
  - [ ] Detect missing statistics
  - [ ] Identify suboptimal join orders
- [ ] **Index Analysis**
  - [ ] Review existing indexes
  - [ ] Identify unused indexes
  - [ ] Find missing indexes
  - [ ] Check index bloat

### 4. Optimization Implementation
- [ ] **Create Indexes**
  - [ ] Design new indexes
  - [ ] Test index creation
  - [ ] Monitor index build progress
  - [ ] Validate improvements
- [ ] **Refactor Queries**
  - [ ] Rewrite slow queries
  - [ ] Add proper WHERE clauses
  - [ ] Optimize JOINs
  - [ ] Test refactored queries
- [ ] **Update Statistics**
  - [ ] Run ANALYZE on affected tables
  - [ ] Adjust statistics targets
  - [ ] Verify query plans improved
- [ ] **Application Changes**
  - [ ] Update ORM queries
  - [ ] Add query hints if needed
  - [ ] Implement caching
  - [ ] Deploy changes

### 5. Validation and Documentation
- [ ] **Performance Testing**
  - [ ] Measure query execution times
  - [ ] Compare before/after metrics
  - [ ] Run load tests
  - [ ] Validate improvements
- [ ] **Documentation**
  - [ ] Document all changes
  - [ ] Create optimization playbook
  - [ ] Update development guidelines
  - [ ] Share lessons learned
- [ ] **Ongoing Monitoring**
  - [ ] Setup performance dashboards
  - [ ] Configure alerts
  - [ ] Schedule regular audits
  - [ ] Create maintenance runbook

## Implementation Details

### Enable pg_stat_statements

```sql
-- postgresql.conf
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
pg_stat_statements.track_utility = on
pg_stat_statements.save = on

-- After restart, create extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Verify it's working
SELECT * FROM pg_stat_statements LIMIT 5;
```

### Query Analysis Queries

```sql
-- Top 20 queries by total execution time
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time,
    stddev_exec_time,
    rows,
    100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Queries with slowest average execution time
SELECT
    query,
    calls,
    mean_exec_time,
    max_exec_time,
    total_exec_time
FROM pg_stat_statements
WHERE calls > 100
  AND mean_exec_time > 100  -- > 100ms average
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Most frequently called queries
SELECT
    query,
    calls,
    mean_exec_time,
    total_exec_time
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 20;

-- Queries with high variability
SELECT
    query,
    calls,
    mean_exec_time,
    stddev_exec_time,
    max_exec_time,
    stddev_exec_time / NULLIF(mean_exec_time, 0) AS coefficient_of_variation
FROM pg_stat_statements
WHERE calls > 100
  AND stddev_exec_time > mean_exec_time * 0.5  -- High variance
ORDER BY coefficient_of_variation DESC
LIMIT 20;

-- Queries with low cache hit ratio
SELECT
    query,
    calls,
    shared_blks_hit,
    shared_blks_read,
    100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements
WHERE shared_blks_read > 0
ORDER BY hit_percent ASC
LIMIT 20;

-- Reset statistics (after capturing baseline)
SELECT pg_stat_statements_reset();
```

### Index Usage Analysis

```sql
-- Find unused indexes
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexrelname NOT LIKE 'pg_toast%'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Find missing indexes (tables with seq scans)
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    seq_tup_read / NULLIF(seq_scan, 0) AS avg_seq_read,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size
FROM pg_stat_user_tables
WHERE seq_scan > 0
  AND (seq_scan > idx_scan OR idx_scan IS NULL)
ORDER BY seq_tup_read DESC
LIMIT 20;

-- Index bloat estimation
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    round(100 * pg_relation_size(indexrelid) / NULLIF(pg_relation_size(relid), 0), 2) AS index_ratio
FROM pg_stat_user_indexes
JOIN pg_class ON pg_class.oid = indexrelid
ORDER BY pg_relation_size(indexrelid) DESC;

-- Duplicate indexes
SELECT
    a.indrelid::regclass AS table_name,
    a.indexrelid::regclass AS index1,
    b.indexrelid::regclass AS index2,
    a.indkey AS columns
FROM pg_index a
JOIN pg_index b ON a.indrelid = b.indrelid
    AND a.indkey = b.indkey
WHERE a.indexrelid > b.indexrelid
  AND a.indrelid > 16384  -- User tables only
ORDER BY a.indrelid;
```

### EXPLAIN ANALYZE Examples

```sql
-- Basic EXPLAIN ANALYZE
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON)
SELECT s.symbol, s.name, s.current_price, f.pe_ratio, f.market_cap
FROM stocks s
LEFT JOIN financial_metrics f ON s.id = f.stock_id
WHERE s.sector_id = 1
  AND f.pe_ratio < 20
ORDER BY f.market_cap DESC
LIMIT 50;

-- Analyze with timing
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT COUNT(*)
FROM stocks s
JOIN watchlist w ON s.id = w.stock_id
WHERE w.user_id = 123
  AND s.current_price > 10000;

-- Find inefficient joins
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.*, sec.name as sector_name, ind.name as industry_name
FROM stocks s
JOIN sectors sec ON s.sector_id = sec.id
JOIN industries ind ON s.industry_id = ind.id
WHERE s.created_at > NOW() - INTERVAL '7 days';
```

### Index Creation Examples

```sql
-- Create index for filtered queries
CREATE INDEX CONCURRENTLY idx_stocks_sector_price
ON stocks(sector_id, current_price DESC)
WHERE current_price > 0;

-- Create partial index
CREATE INDEX CONCURRENTLY idx_stocks_active
ON stocks(updated_at)
WHERE is_active = true;

-- Create composite index for JOIN queries
CREATE INDEX CONCURRENTLY idx_financial_metrics_stock_pe
ON financial_metrics(stock_id, pe_ratio)
INCLUDE (market_cap, roe);

-- Create index for text search
CREATE INDEX CONCURRENTLY idx_stocks_name_gin
ON stocks USING gin(to_tsvector('english', name));

-- Create index for range queries
CREATE INDEX CONCURRENTLY idx_stocks_price_range
ON stocks USING brin(current_price)
WITH (pages_per_range = 128);
```

### Query Optimization Examples

```python
# monitoring/query_optimizer.py
from sqlalchemy import text
from typing import List, Dict
import logging

logger = logging.getLogger(__name__)

class QueryOptimizer:
    def __init__(self, db_session):
        self.db = db_session

    def analyze_query(self, query: str, params: Dict = None) -> Dict:
        """Analyze query execution plan"""
        explain_query = f"EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) {query}"

        result = self.db.execute(text(explain_query), params or {})
        plan = result.fetchone()[0]

        return self._parse_execution_plan(plan[0])

    def _parse_execution_plan(self, plan: Dict) -> Dict:
        """Parse EXPLAIN output for optimization insights"""
        execution_time = plan['Execution Time']
        planning_time = plan['Planning Time']

        issues = []

        # Check for sequential scans
        if self._has_seq_scan(plan['Plan']):
            issues.append("Sequential scan detected - consider adding index")

        # Check for high actual rows vs estimated
        if self._has_estimation_error(plan['Plan']):
            issues.append("Poor row estimation - run ANALYZE on tables")

        # Check for high buffer usage
        total_buffers = plan['Plan'].get('Shared Hit Blocks', 0) + \
                       plan['Plan'].get('Shared Read Blocks', 0)
        if total_buffers > 10000:
            issues.append(f"High buffer usage: {total_buffers} blocks")

        return {
            'execution_time_ms': execution_time,
            'planning_time_ms': planning_time,
            'total_time_ms': execution_time + planning_time,
            'issues': issues,
            'plan': plan
        }

    def _has_seq_scan(self, node: Dict) -> bool:
        """Check if plan contains sequential scan"""
        if node.get('Node Type') == 'Seq Scan':
            return True
        for child in node.get('Plans', []):
            if self._has_seq_scan(child):
                return True
        return False

    def _has_estimation_error(self, node: Dict, threshold: float = 10.0) -> bool:
        """Check for significant estimation errors"""
        actual = node.get('Actual Rows', 0)
        planned = node.get('Plan Rows', 0)

        if planned > 0 and actual / planned > threshold:
            return True

        for child in node.get('Plans', []):
            if self._has_estimation_error(child, threshold):
                return True

        return False

    def suggest_indexes(self, table: str) -> List[str]:
        """Suggest indexes based on query patterns"""
        # Analyze columns used in WHERE clauses
        where_query = text("""
            SELECT
                schemaname, tablename, attname, n_distinct
            FROM pg_stats
            WHERE tablename = :table
              AND null_frac < 0.1
              AND n_distinct > 100
        """)

        results = self.db.execute(where_query, {'table': table}).fetchall()

        suggestions = []
        for row in results:
            suggestions.append(
                f"CREATE INDEX CONCURRENTLY idx_{table}_{row.attname} "
                f"ON {table}({row.attname});"
            )

        return suggestions


# Usage example
def optimize_slow_queries(db_session):
    optimizer = QueryOptimizer(db_session)

    # Get slow queries from pg_stat_statements
    slow_queries = db_session.execute(text("""
        SELECT query, mean_exec_time
        FROM pg_stat_statements
        WHERE mean_exec_time > 100
        ORDER BY mean_exec_time DESC
        LIMIT 10
    """)).fetchall()

    for query_row in slow_queries:
        query = query_row.query
        logger.info(f"Analyzing query: {query[:100]}...")

        analysis = optimizer.analyze_query(query)
        logger.info(f"Execution time: {analysis['execution_time_ms']}ms")
        logger.info(f"Issues found: {analysis['issues']}")
```

### Automated Query Monitoring

```python
# monitoring/query_monitor.py
import psycopg2
from prometheus_client import Histogram, Counter, Gauge
import logging

logger = logging.getLogger(__name__)

# Metrics
query_duration = Histogram(
    'db_query_duration_seconds',
    'Query execution time',
    ['query_type', 'table']
)

slow_query_counter = Counter(
    'db_slow_queries_total',
    'Number of slow queries (>100ms)',
    ['query_type']
)

active_queries = Gauge(
    'db_active_queries',
    'Number of currently active queries'
)

class QueryMonitor:
    def __init__(self, dsn: str):
        self.dsn = dsn

    def monitor_active_queries(self):
        """Monitor currently running queries"""
        conn = psycopg2.connect(self.dsn)
        cur = conn.cursor()

        cur.execute("""
            SELECT
                pid,
                usename,
                application_name,
                client_addr,
                state,
                query,
                EXTRACT(EPOCH FROM (NOW() - query_start)) AS duration
            FROM pg_stat_activity
            WHERE state != 'idle'
              AND query NOT LIKE '%pg_stat_activity%'
            ORDER BY duration DESC
        """)

        active_count = 0
        for row in cur.fetchall():
            active_count += 1
            duration = row[6]

            if duration > 100:  # More than 100 seconds
                logger.warning(
                    f"Long-running query detected: "
                    f"PID={row[0]}, Duration={duration}s, Query={row[5][:100]}"
                )

        active_queries.set(active_count)

        cur.close()
        conn.close()

    def collect_slow_query_stats(self):
        """Collect statistics on slow queries"""
        conn = psycopg2.connect(self.dsn)
        cur = conn.cursor()

        cur.execute("""
            SELECT
                query,
                calls,
                mean_exec_time,
                total_exec_time
            FROM pg_stat_statements
            WHERE mean_exec_time > 100
            ORDER BY total_exec_time DESC
            LIMIT 50
        """)

        for row in cur.fetchall():
            query_type = self._get_query_type(row[0])
            slow_query_counter.labels(query_type=query_type).inc(row[1])

        cur.close()
        conn.close()

    def _get_query_type(self, query: str) -> str:
        """Extract query type (SELECT, INSERT, UPDATE, DELETE)"""
        query_upper = query.strip().upper()
        if query_upper.startswith('SELECT'):
            return 'SELECT'
        elif query_upper.startswith('INSERT'):
            return 'INSERT'
        elif query_upper.startswith('UPDATE'):
            return 'UPDATE'
        elif query_upper.startswith('DELETE'):
            return 'DELETE'
        else:
            return 'OTHER'
```

## Testing Strategy

### Performance Benchmarking

```python
# tests/performance/test_query_optimization.py
import pytest
import time
from sqlalchemy import text

def test_query_performance_improvement():
    """Test that optimized queries perform better"""
    # Original slow query
    slow_query = text("""
        SELECT s.*, f.*
        FROM stocks s
        LEFT JOIN financial_metrics f ON s.id = f.stock_id
        WHERE s.sector_id = 1
    """)

    # Optimized query
    optimized_query = text("""
        SELECT s.id, s.symbol, s.name, f.pe_ratio, f.market_cap
        FROM stocks s
        LEFT JOIN financial_metrics f ON s.id = f.stock_id
        WHERE s.sector_id = 1
          AND s.is_active = true
    """)

    # Benchmark slow query
    start = time.time()
    for _ in range(10):
        db.execute(slow_query).fetchall()
    slow_time = time.time() - start

    # Benchmark optimized query
    start = time.time()
    for _ in range(10):
        db.execute(optimized_query).fetchall()
    optimized_time = time.time() - start

    improvement = (slow_time - optimized_time) / slow_time * 100

    assert optimized_time < slow_time
    assert improvement > 20  # At least 20% improvement
```

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Index creation blocking production queries | Medium | High | Use CREATE INDEX CONCURRENTLY, schedule during low traffic |
| Over-indexing degrading write performance | Medium | Medium | Monitor write performance, remove unused indexes |
| Statistics outdated after optimization | Low | Medium | Run ANALYZE after index creation, schedule regular updates |
| Query refactoring introducing bugs | Medium | High | Comprehensive testing, gradual rollout, monitoring |
| False positives in slow query detection | Low | Low | Set appropriate thresholds, manual review |
| Performance regression after deployment | Low | High | Baseline metrics, rollback plan, canary deployment |

## Performance Requirements

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Queries executing > 100ms | < 5% of total | pg_stat_statements analysis |
| Average query execution time | < 50ms | Mean execution time from stats |
| Index hit ratio | > 95% | Cache hit percentage |
| Slow query reduction | > 70% improvement | Before/after comparison |
| Sequential scans on large tables | 0 occurrences | EXPLAIN ANALYZE review |
| Query plan generation time | < 5ms | Planning time from EXPLAIN |

## Security Considerations

### Query Access Control

```sql
-- Restrict access to pg_stat_statements
REVOKE ALL ON pg_stat_statements FROM PUBLIC;
GRANT SELECT ON pg_stat_statements TO monitoring_user;

-- Audit query modifications
CREATE TABLE query_optimization_audit (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    user_name TEXT,
    query_before TEXT,
    query_after TEXT,
    performance_improvement NUMERIC
);
```

## Error Handling

### Safe Index Creation

```sql
-- Create index with error handling
DO $$
BEGIN
    CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stocks_sector_price
    ON stocks(sector_id, current_price);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Index creation failed: %', SQLERRM;
END $$;
```

## Progress

**0% - Not started**

## Notes

### Dependencies
- PostgreSQL 12+ (for improved EXPLAIN features)
- pg_stat_statements extension
- auto_explain module (optional)
- pgBadger for log analysis (optional)

### Best Practices

1. **Query Analysis**
   - Run audit during normal business hours
   - Collect at least 24-48 hours of statistics
   - Focus on high-impact queries first
   - Document all findings

2. **Index Creation**
   - Always use CREATE INDEX CONCURRENTLY
   - Test indexes on staging first
   - Monitor disk space during creation
   - Validate improvements before production

3. **Query Refactoring**
   - Make incremental changes
   - Test thoroughly with realistic data volumes
   - Monitor for regressions
   - Keep original queries for rollback

4. **Ongoing Monitoring**
   - Schedule regular audits (quarterly)
   - Monitor query performance trends
   - Set up automated alerts
   - Keep optimization playbook updated

### Common Optimizations

1. **Replace Subqueries with JOINs**
2. **Use EXISTS instead of IN for large datasets**
3. **Add covering indexes for frequently accessed columns**
4. **Partition large tables**
5. **Use materialized views for complex aggregations**
6. **Implement query result caching**
7. **Optimize ORDER BY with appropriate indexes**
8. **Use LIMIT with pagination**

### Tools

- **pg_stat_statements**: Query performance statistics
- **EXPLAIN ANALYZE**: Execution plan analysis
- **pgBadger**: PostgreSQL log analyzer
- **pgHero**: Database insights and query optimization
- **pev2**: Visual explain plan analyzer
