# PERF-003: Database Read Replicas

## Metadata

| Field | Value |
|-------|-------|
| **ID** | PERF-003 |
| **Title** | Setup PostgreSQL Read Replicas |
| **Type** | Infrastructure |
| **Status** | BACKLOG |
| **Priority** | P1 (High) |
| **Estimate** | 8 hours |
| **Sprint** | Sprint 7 |
| **Epic** | Performance & Scalability |
| **Assignee** | TBD |
| **Created** | 2025-11-29 |
| **Tags** | `database`, `postgresql`, `replication`, `read-replica`, `scalability` |
| **Blocks** | - |

## Description

Implement PostgreSQL streaming replication with read replicas to distribute read load across multiple database instances. This includes configuring primary-replica replication, implementing read/write split in the application layer using SQLAlchemy, monitoring replication lag, establishing failover procedures, and conducting comprehensive load testing to validate performance improvements.

## Acceptance Criteria

- [ ] **PostgreSQL Streaming Replication Setup**
  - [ ] Configure primary database for replication
  - [ ] Setup at least 2 read replica instances
  - [ ] Configure WAL (Write-Ahead Logging) streaming
  - [ ] Enable synchronous or asynchronous replication
  - [ ] Verify replication is working correctly
- [ ] **SQLAlchemy Read/Write Separation**
  - [ ] Configure multiple database engines
  - [ ] Implement routing middleware for read/write operations
  - [ ] Setup session management for replica selection
  - [ ] Add replica load balancing
  - [ ] Implement fallback to primary on replica failure
- [ ] **Replication Lag Monitoring**
  - [ ] Setup replication lag metrics collection
  - [ ] Configure lag threshold alerts
  - [ ] Create monitoring dashboard
  - [ ] Implement lag-aware routing
  - [ ] Document acceptable lag thresholds
- [ ] **Failover Testing**
  - [ ] Document failover procedures
  - [ ] Test automatic failover scenarios
  - [ ] Test manual failover process
  - [ ] Verify data consistency after failover
  - [ ] Create runbook for failover operations
- [ ] **Load Testing and Validation**
  - [ ] Conduct baseline performance tests
  - [ ] Test read load distribution
  - [ ] Measure query performance improvements
  - [ ] Validate connection pool behavior
  - [ ] Document performance gains

## Subtasks

### 1. Primary Database Configuration
- [ ] **Replication Settings**
  - [ ] Enable WAL archiving
  - [ ] Configure max_wal_senders
  - [ ] Set wal_level to replica
  - [ ] Configure max_replication_slots
  - [ ] Enable hot_standby
- [ ] **Networking Configuration**
  - [ ] Configure pg_hba.conf for replica access
  - [ ] Setup replication user with proper permissions
  - [ ] Test network connectivity
  - [ ] Configure SSL for replication traffic
- [ ] **Backup Configuration**
  - [ ] Setup base backup process
  - [ ] Configure WAL archiving to S3/storage
  - [ ] Test backup restoration
  - [ ] Document backup procedures

### 2. Read Replica Setup
- [ ] **Replica Instance Creation**
  - [ ] Provision replica server instances
  - [ ] Install PostgreSQL matching primary version
  - [ ] Configure system resources (CPU, RAM, Storage)
  - [ ] Setup monitoring agents
- [ ] **Replication Configuration**
  - [ ] Create base backup from primary
  - [ ] Configure recovery.conf/standby.signal
  - [ ] Setup primary_conninfo
  - [ ] Configure hot_standby parameters
  - [ ] Start replica and verify streaming
- [ ] **Multiple Replicas**
  - [ ] Setup second read replica
  - [ ] Configure cascading replication (if needed)
  - [ ] Test load distribution
  - [ ] Verify synchronization

### 3. Application Layer Implementation
- [ ] **SQLAlchemy Configuration**
  - [ ] Create engine for primary database
  - [ ] Create engine pool for read replicas
  - [ ] Configure connection pooling parameters
  - [ ] Setup engine disposal on failover
- [ ] **Routing Middleware**
  - [ ] Implement read/write routing logic
  - [ ] Add transaction context detection
  - [ ] Configure replica selection algorithm
  - [ ] Implement sticky sessions for consistency
- [ ] **Session Management**
  - [ ] Create session factory with routing
  - [ ] Implement context-aware session binding
  - [ ] Add explicit read/write hints
  - [ ] Test session behavior
- [ ] **Error Handling**
  - [ ] Implement replica failure detection
  - [ ] Add automatic fallback to primary
  - [ ] Configure retry logic
  - [ ] Add circuit breaker pattern

### 4. Monitoring and Alerting
- [ ] **Metrics Collection**
  - [ ] Setup replication lag monitoring
  - [ ] Track replica health status
  - [ ] Monitor connection counts
  - [ ] Collect query performance metrics
- [ ] **Dashboard Creation**
  - [ ] Create replication status dashboard
  - [ ] Add lag visualization
  - [ ] Display replica health metrics
  - [ ] Show query distribution
- [ ] **Alert Configuration**
  - [ ] Setup lag threshold alerts (> 5s)
  - [ ] Configure replica down alerts
  - [ ] Add connection pool exhaustion alerts
  - [ ] Create on-call escalation rules

### 5. Testing and Validation
- [ ] **Functional Testing**
  - [ ] Test read query routing
  - [ ] Test write query routing
  - [ ] Verify transaction consistency
  - [ ] Test failover scenarios
- [ ] **Performance Testing**
  - [ ] Baseline performance measurement
  - [ ] Load test with replicas
  - [ ] Measure throughput improvements
  - [ ] Test under various load patterns
- [ ] **Chaos Testing**
  - [ ] Simulate replica failure
  - [ ] Test network partition scenarios
  - [ ] Verify automatic recovery
  - [ ] Test split-brain prevention

## Implementation Details

### Primary Database Configuration

```sql
-- postgresql.conf on primary
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
archive_mode = on
archive_command = 'aws s3 cp %p s3://db-wal-archive/%f'
wal_keep_size = 1GB

-- Connection settings
max_connections = 200
shared_buffers = 4GB
effective_cache_size = 12GB
work_mem = 16MB
maintenance_work_mem = 512MB

-- Create replication user
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'secure_password';

-- Grant necessary permissions
GRANT CONNECT ON DATABASE screener_db TO replicator;
```

```conf
# pg_hba.conf - Allow replication connections
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    replication     replicator      10.0.1.0/24             md5
hostssl replication     replicator      10.0.1.0/24             md5
```

### Read Replica Configuration

```bash
#!/bin/bash
# scripts/setup-replica.sh

# Stop PostgreSQL on replica
sudo systemctl stop postgresql

# Remove existing data
sudo rm -rf /var/lib/postgresql/14/main/*

# Create base backup from primary
pg_basebackup -h primary-db.internal \
  -D /var/lib/postgresql/14/main \
  -U replicator \
  -P \
  -v \
  -R \
  -X stream \
  -C -S replica_slot_1

# Set proper permissions
sudo chown -R postgres:postgres /var/lib/postgresql/14/main

# Start replica
sudo systemctl start postgresql

# Verify replication status
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"
```

```sql
-- postgresql.conf on replica
hot_standby = on
max_connections = 200
hot_standby_feedback = on
wal_receiver_status_interval = 10s

-- Connection pooling for read replicas
max_connections = 100
shared_buffers = 2GB
```

### SQLAlchemy Read/Write Routing

```python
# database/routing.py
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import NullPool
from contextlib import contextmanager
import random
from typing import Optional, List
import logging

logger = logging.getLogger(__name__)

class DatabaseRouter:
    def __init__(self, primary_url: str, replica_urls: List[str]):
        self.primary_url = primary_url
        self.replica_urls = replica_urls

        # Create engine for primary
        self.primary_engine = create_engine(
            primary_url,
            pool_size=20,
            max_overflow=10,
            pool_pre_ping=True,
            pool_recycle=3600,
            echo=False
        )

        # Create engines for replicas
        self.replica_engines = [
            create_engine(
                url,
                pool_size=20,
                max_overflow=10,
                pool_pre_ping=True,
                pool_recycle=3600,
                echo=False
            )
            for url in replica_urls
        ]

        self.replica_health = [True] * len(self.replica_engines)

        # Session factories
        self.PrimarySession = sessionmaker(bind=self.primary_engine)
        self.ReplicaSessions = [
            sessionmaker(bind=engine) for engine in self.replica_engines
        ]

    def get_read_engine(self):
        """Get a healthy read replica engine using round-robin"""
        healthy_replicas = [
            (i, engine) for i, engine in enumerate(self.replica_engines)
            if self.replica_health[i]
        ]

        if not healthy_replicas:
            logger.warning("No healthy replicas available, falling back to primary")
            return self.primary_engine

        # Random selection for load balancing
        idx, engine = random.choice(healthy_replicas)
        return engine

    def get_write_engine(self):
        """Always return primary engine for writes"""
        return self.primary_engine

    def mark_replica_unhealthy(self, engine):
        """Mark a replica as unhealthy"""
        try:
            idx = self.replica_engines.index(engine)
            self.replica_health[idx] = False
            logger.error(f"Marked replica {idx} as unhealthy")
        except ValueError:
            pass

    def mark_replica_healthy(self, engine):
        """Mark a replica as healthy"""
        try:
            idx = self.replica_engines.index(engine)
            self.replica_health[idx] = True
            logger.info(f"Marked replica {idx} as healthy")
        except ValueError:
            pass

    @contextmanager
    def get_session(self, read_only: bool = False):
        """Context manager for database sessions with routing"""
        if read_only:
            engine = self.get_read_engine()
        else:
            engine = self.primary_engine

        session = Session(bind=engine)

        try:
            yield session
            session.commit()
        except Exception as e:
            session.rollback()
            # Mark replica as unhealthy if it failed
            if read_only and engine != self.primary_engine:
                self.mark_replica_unhealthy(engine)
            raise
        finally:
            session.close()


# Singleton instance
_router: Optional[DatabaseRouter] = None


def init_database_router(primary_url: str, replica_urls: List[str]):
    """Initialize the database router"""
    global _router
    _router = DatabaseRouter(primary_url, replica_urls)
    return _router


def get_db_router() -> DatabaseRouter:
    """Get the global database router"""
    if _router is None:
        raise RuntimeError("Database router not initialized")
    return _router


def get_db_session(read_only: bool = False):
    """Dependency injection for FastAPI"""
    router = get_db_router()
    with router.get_session(read_only=read_only) as session:
        yield session
```

### FastAPI Integration

```python
# main.py
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from database.routing import init_database_router, get_db_session
import os

app = FastAPI()

# Initialize router on startup
@app.on_event("startup")
async def startup_event():
    primary_url = os.getenv("DATABASE_PRIMARY_URL")
    replica_urls = [
        os.getenv("DATABASE_REPLICA_1_URL"),
        os.getenv("DATABASE_REPLICA_2_URL"),
    ]

    init_database_router(primary_url, replica_urls)


# Read-only endpoint using replica
@app.get("/stocks")
async def get_stocks(
    db: Session = Depends(lambda: get_db_session(read_only=True))
):
    stocks = db.query(Stock).limit(100).all()
    return stocks


# Write endpoint using primary
@app.post("/stocks")
async def create_stock(
    stock_data: StockCreate,
    db: Session = Depends(lambda: get_db_session(read_only=False))
):
    stock = Stock(**stock_data.dict())
    db.add(stock)
    db.commit()
    db.refresh(stock)
    return stock
```

### Explicit Routing with Decorators

```python
# database/decorators.py
from functools import wraps
from database.routing import get_db_router

def use_replica(func):
    """Decorator to explicitly use read replica"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        router = get_db_router()
        with router.get_session(read_only=True) as session:
            return func(session, *args, **kwargs)
    return wrapper


def use_primary(func):
    """Decorator to explicitly use primary database"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        router = get_db_router()
        with router.get_session(read_only=False) as session:
            return func(session, *args, **kwargs)
    return wrapper


# Usage
@use_replica
def get_stock_by_id(session, stock_id: int):
    return session.query(Stock).filter(Stock.id == stock_id).first()


@use_primary
def create_stock(session, stock_data: dict):
    stock = Stock(**stock_data)
    session.add(stock)
    session.commit()
    return stock
```

### Replication Lag Monitoring

```python
# monitoring/replication_lag.py
import psycopg2
from prometheus_client import Gauge
import time
import logging

logger = logging.getLogger(__name__)

# Prometheus metrics
replication_lag_gauge = Gauge(
    'postgresql_replication_lag_seconds',
    'Replication lag in seconds',
    ['replica_name']
)

replica_status_gauge = Gauge(
    'postgresql_replica_status',
    'Replica status (1=healthy, 0=unhealthy)',
    ['replica_name']
)


def check_replication_lag(primary_dsn: str, replica_dsn: str, replica_name: str):
    """Check replication lag between primary and replica"""
    try:
        # Connect to primary
        primary_conn = psycopg2.connect(primary_dsn)
        primary_cur = primary_conn.cursor()

        # Get current WAL LSN on primary
        primary_cur.execute("SELECT pg_current_wal_lsn();")
        primary_lsn = primary_cur.fetchone()[0]

        # Connect to replica
        replica_conn = psycopg2.connect(replica_dsn)
        replica_cur = replica_conn.cursor()

        # Get replay LSN on replica
        replica_cur.execute("SELECT pg_last_wal_replay_lsn();")
        replica_lsn = replica_cur.fetchone()[0]

        # Calculate lag in bytes
        replica_cur.execute(
            f"SELECT pg_wal_lsn_diff('{primary_lsn}', '{replica_lsn}');"
        )
        lag_bytes = replica_cur.fetchone()[0]

        # Get replay lag in seconds
        replica_cur.execute(
            "SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()));"
        )
        lag_seconds = replica_cur.fetchone()[0] or 0

        # Update Prometheus metrics
        replication_lag_gauge.labels(replica_name=replica_name).set(lag_seconds)
        replica_status_gauge.labels(replica_name=replica_name).set(1)

        logger.info(
            f"Replica {replica_name} lag: {lag_seconds:.2f}s, {lag_bytes} bytes"
        )

        # Close connections
        primary_cur.close()
        primary_conn.close()
        replica_cur.close()
        replica_conn.close()

        return lag_seconds

    except Exception as e:
        logger.error(f"Failed to check replication lag for {replica_name}: {e}")
        replica_status_gauge.labels(replica_name=replica_name).set(0)
        return None


def monitor_replication_lag_continuously(
    primary_dsn: str,
    replica_configs: list,
    interval: int = 10
):
    """Continuously monitor replication lag"""
    while True:
        for config in replica_configs:
            check_replication_lag(
                primary_dsn,
                config['dsn'],
                config['name']
            )
        time.sleep(interval)
```

### Prometheus Alerts Configuration

```yaml
# prometheus/alerts/replication.yml
groups:
  - name: postgresql_replication
    interval: 30s
    rules:
      - alert: HighReplicationLag
        expr: postgresql_replication_lag_seconds > 5
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High replication lag detected"
          description: "Replica {{ $labels.replica_name }} has replication lag of {{ $value }}s"

      - alert: CriticalReplicationLag
        expr: postgresql_replication_lag_seconds > 30
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Critical replication lag detected"
          description: "Replica {{ $labels.replica_name }} has critical replication lag of {{ $value }}s"

      - alert: ReplicaDown
        expr: postgresql_replica_status == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL replica is down"
          description: "Replica {{ $labels.replica_name }} is unhealthy or unreachable"

      - alert: ReplicationStopped
        expr: rate(postgresql_replication_lag_seconds[5m]) == 0 and postgresql_replication_lag_seconds > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Replication has stopped"
          description: "Replica {{ $labels.replica_name }} replication appears to be stopped"
```

### Failover Script

```bash
#!/bin/bash
# scripts/failover-replica.sh

set -e

REPLICA_HOST=$1
REPLICA_PORT=${2:-5432}

if [ -z "$REPLICA_HOST" ]; then
    echo "Usage: $0 <replica_host> [port]"
    exit 1
fi

echo "=== PostgreSQL Failover Script ==="
echo "Target replica: $REPLICA_HOST:$REPLICA_PORT"

# Step 1: Stop application traffic to primary
echo "Step 1: Stopping application traffic..."
# kubectl scale deployment screener-api --replicas=0

# Step 2: Promote replica to primary
echo "Step 2: Promoting replica to primary..."
ssh postgres@$REPLICA_HOST "pg_ctl promote -D /var/lib/postgresql/14/main"

# Step 3: Wait for promotion to complete
echo "Step 3: Waiting for promotion..."
sleep 5

# Step 4: Verify replica is accepting writes
echo "Step 4: Verifying write capability..."
PGPASSWORD=password psql -h $REPLICA_HOST -U postgres -c "SELECT pg_is_in_recovery();" | grep -q "f"

if [ $? -eq 0 ]; then
    echo "✓ Replica promoted successfully"
else
    echo "✗ Replica promotion failed"
    exit 1
fi

# Step 5: Update application database URL
echo "Step 5: Updating application configuration..."
# kubectl set env deployment/screener-api DATABASE_PRIMARY_URL=postgresql://...

# Step 6: Restart application
echo "Step 6: Restarting application..."
# kubectl scale deployment screener-api --replicas=3

echo "=== Failover completed successfully ==="
```

## Testing Strategy

### Unit Tests

```python
# tests/test_database_routing.py
import pytest
from database.routing import DatabaseRouter
from sqlalchemy import create_engine
from unittest.mock import Mock, patch

def test_write_uses_primary():
    """Test that write operations use primary database"""
    router = DatabaseRouter(
        primary_url="postgresql://primary/db",
        replica_urls=["postgresql://replica1/db"]
    )

    engine = router.get_write_engine()
    assert engine == router.primary_engine


def test_read_uses_replica():
    """Test that read operations use replica"""
    router = DatabaseRouter(
        primary_url="postgresql://primary/db",
        replica_urls=["postgresql://replica1/db"]
    )

    engine = router.get_read_engine()
    assert engine in router.replica_engines


def test_fallback_to_primary_when_replica_unhealthy():
    """Test fallback to primary when all replicas are unhealthy"""
    router = DatabaseRouter(
        primary_url="postgresql://primary/db",
        replica_urls=["postgresql://replica1/db"]
    )

    # Mark all replicas as unhealthy
    router.replica_health = [False]

    engine = router.get_read_engine()
    assert engine == router.primary_engine
```

### Integration Tests

```python
# tests/integration/test_replication.py
import pytest
from sqlalchemy import create_engine, text
import time

def test_replication_working(primary_engine, replica_engine):
    """Test that data replicates from primary to replica"""
    # Insert data on primary
    with primary_engine.connect() as conn:
        conn.execute(
            text("INSERT INTO test_table (name) VALUES ('test_value')")
        )
        conn.commit()

    # Wait for replication
    time.sleep(2)

    # Verify data on replica
    with replica_engine.connect() as conn:
        result = conn.execute(
            text("SELECT name FROM test_table WHERE name = 'test_value'")
        )
        assert result.fetchone() is not None


def test_replication_lag_acceptable(primary_dsn, replica_dsn):
    """Test that replication lag is within acceptable limits"""
    from monitoring.replication_lag import check_replication_lag

    lag = check_replication_lag(primary_dsn, replica_dsn, "replica1")

    assert lag is not None
    assert lag < 5.0  # Less than 5 seconds
```

### Load Tests

```python
# tests/load/test_replica_load.py
import asyncio
import aiohttp
from locust import HttpUser, task, between

class StockScreenerUser(HttpUser):
    wait_time = between(1, 3)

    @task(10)
    def get_stocks(self):
        """Read operation - should use replica"""
        self.client.get("/stocks?page=1&page_size=20")

    @task(1)
    def create_watchlist(self):
        """Write operation - should use primary"""
        self.client.post("/watchlist", json={"stock_id": 1})

    @task(5)
    def get_stock_detail(self):
        """Read operation - should use replica"""
        self.client.get("/stocks/1")


# Run: locust -f test_replica_load.py --host=http://localhost:8000
```

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Replication lag causing stale reads | Medium | High | Monitor lag closely, implement lag-aware routing, use synchronous replication for critical data |
| Replica failure affecting read availability | Medium | Medium | Multiple replicas, automatic fallback to primary, health checks |
| Split-brain scenario during failover | Low | Critical | Use proper failover procedures, implement fencing, verify single primary |
| Network partition between primary and replica | Low | High | Monitor replication status, implement connection timeouts, use VPC networking |
| Application routing bugs causing wrong DB usage | Medium | High | Comprehensive testing, explicit routing decorators, code reviews |
| Increased infrastructure costs | High | Low | Monitor resource usage, optimize replica count, use appropriate instance sizes |

## Performance Requirements

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Replication lag | < 2s average, < 5s max | pg_stat_replication monitoring |
| Read query performance improvement | > 30% reduction in latency | Load testing before/after |
| Primary write throughput | No degradation | Benchmark primary database |
| Replica query throughput | > 2x primary capacity | Load testing with multiple replicas |
| Failover time (RPO) | < 5 minutes | Failover testing |
| Data loss on failover (RTO) | < 5 seconds of data | Synchronous replication validation |
| Connection pool utilization | < 80% | Database connection monitoring |

## Security Considerations

### Replication User Security

```sql
-- Create dedicated replication user with minimal permissions
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'strong_random_password';

-- Revoke all other permissions
REVOKE ALL PRIVILEGES ON DATABASE screener_db FROM replicator;

-- Only allow specific IP ranges
-- In pg_hba.conf:
-- hostssl replication replicator 10.0.1.0/24 md5
```

### SSL/TLS for Replication

```conf
# postgresql.conf
ssl = on
ssl_cert_file = '/etc/postgresql/ssl/server.crt'
ssl_key_file = '/etc/postgresql/ssl/server.key'
ssl_ca_file = '/etc/postgresql/ssl/ca.crt'

# Require SSL for replication
ssl_prefer_server_ciphers = on
ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL'
```

### Network Isolation

```bash
# Use VPC peering or private networking
# Replicas should not be accessible from public internet
# Use security groups to restrict access

# AWS Security Group example
aws ec2 authorize-security-group-ingress \
  --group-id sg-replica \
  --protocol tcp \
  --port 5432 \
  --source-group sg-primary
```

## Error Handling

### Replica Failure Handling

```python
# database/error_handling.py
from sqlalchemy.exc import OperationalError, DisconnectionError
from functools import wraps
import logging

logger = logging.getLogger(__name__)

def handle_replica_failure(max_retries=3):
    """Decorator to handle replica failures with fallback"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            retries = 0
            last_error = None

            while retries < max_retries:
                try:
                    return func(*args, **kwargs)
                except (OperationalError, DisconnectionError) as e:
                    retries += 1
                    last_error = e
                    logger.warning(
                        f"Replica operation failed (attempt {retries}/{max_retries}): {e}"
                    )

                    if retries < max_retries:
                        # Try with different replica or fallback to primary
                        continue
                    else:
                        logger.error(f"All retries exhausted: {e}")
                        raise

            raise last_error

        return wrapper
    return decorator
```

### Circuit Breaker Pattern

```python
# database/circuit_breaker.py
from datetime import datetime, timedelta
from enum import Enum

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"


class CircuitBreaker:
    def __init__(self, failure_threshold=5, timeout=60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED

    def call(self, func, *args, **kwargs):
        if self.state == CircuitState.OPEN:
            if datetime.now() - self.last_failure_time > timedelta(seconds=self.timeout):
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker is OPEN")

        try:
            result = func(*args, **kwargs)
            self.on_success()
            return result
        except Exception as e:
            self.on_failure()
            raise

    def on_success(self):
        self.failure_count = 0
        self.state = CircuitState.CLOSED

    def on_failure(self):
        self.failure_count += 1
        self.last_failure_time = datetime.now()

        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
```

## Progress

**0% - Not started**

## Notes

### Dependencies
- PostgreSQL 14+ (for improved replication features)
- psycopg2-binary >= 2.9.0
- SQLAlchemy >= 2.0.0
- prometheus-client (for monitoring)

### Best Practices

1. **Replication Configuration**
   - Use streaming replication for lower lag
   - Consider synchronous replication for critical data
   - Monitor replication slots to prevent WAL bloat
   - Regular backup verification

2. **Application Design**
   - Use read replicas for reporting queries
   - Use read replicas for search/filter operations
   - Always use primary for writes
   - Consider eventual consistency implications

3. **Monitoring**
   - Track replication lag continuously
   - Monitor replica health
   - Set up alerting for lag thresholds
   - Monitor connection pool usage

4. **Failover Planning**
   - Document failover procedures
   - Test failover regularly
   - Have rollback plan ready
   - Automate where possible

### Common Issues and Solutions

1. **High Replication Lag**
   - Increase wal_sender/receiver buffers
   - Optimize long-running queries on primary
   - Consider more powerful replica hardware
   - Check network bandwidth

2. **Replication Slot Bloat**
   - Monitor `pg_replication_slots`
   - Remove unused slots
   - Set `max_slot_wal_keep_size`

3. **Connection Pool Exhaustion**
   - Tune pool sizes appropriately
   - Implement connection timeouts
   - Monitor pool usage

### Operational Procedures

1. **Adding New Replica**
   - Create base backup
   - Configure replication
   - Verify replication working
   - Add to application pool
   - Monitor for 24 hours

2. **Removing Replica**
   - Remove from application pool
   - Monitor traffic shift
   - Stop replication
   - Drop replication slot

3. **Promoting Replica**
   - Follow failover script
   - Verify application connectivity
   - Update monitoring
   - Reconfigure old primary as replica
