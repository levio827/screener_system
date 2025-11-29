# PERF-004: Connection Pooling (PgBouncer)

## Metadata

| Field | Value |
|-------|-------|
| **ID** | PERF-004 |
| **Title** | Implement Connection Pooling |
| **Type** | Infrastructure |
| **Status** | BACKLOG |
| **Priority** | P1 (High) |
| **Estimate** | 4 hours |
| **Sprint** | Sprint 6 |
| **Epic** | Performance & Scalability |
| **Assignee** | TBD |
| **Created** | 2025-11-29 |
| **Tags** | `database`, `pgbouncer`, `connection-pooling`, `performance`, `postgresql` |
| **Blocks** | - |

## Description

Implement PgBouncer as a connection pooler between the application and PostgreSQL database to optimize database connection management. This includes configuring PgBouncer in transaction pooling mode, setting appropriate connection limits, implementing health checks, integrating with monitoring dashboards, and validating performance improvements through load testing.

## Acceptance Criteria

- [ ] **PgBouncer Installation and Setup**
  - [ ] Install PgBouncer on appropriate infrastructure
  - [ ] Configure PgBouncer.ini with optimal settings
  - [ ] Setup authentication (userlist.txt or auth_query)
  - [ ] Configure logging and monitoring
  - [ ] Test basic connectivity
- [ ] **Transaction Pooling Mode Configuration**
  - [ ] Configure pool_mode = transaction
  - [ ] Set appropriate default_pool_size
  - [ ] Configure max_client_conn
  - [ ] Setup reserve_pool_size
  - [ ] Test transaction isolation
- [ ] **Connection Count Optimization**
  - [ ] Analyze current connection usage patterns
  - [ ] Calculate optimal pool sizes
  - [ ] Configure per-database pool limits
  - [ ] Setup connection limits per user
  - [ ] Validate connection distribution
- [ ] **Health Checks and Monitoring**
  - [ ] Implement PgBouncer health check endpoint
  - [ ] Setup connection metrics collection
  - [ ] Configure Prometheus exporter
  - [ ] Create monitoring dashboard
  - [ ] Setup alerting for pool exhaustion
- [ ] **Integration and Testing**
  - [ ] Update application database connection strings
  - [ ] Test connection pooling behavior
  - [ ] Conduct load testing
  - [ ] Measure performance improvements
  - [ ] Document configuration and procedures

## Subtasks

### 1. PgBouncer Installation
- [ ] **Server Provisioning**
  - [ ] Provision server or container for PgBouncer
  - [ ] Ensure proximity to database servers
  - [ ] Configure network security groups
  - [ ] Setup firewall rules
- [ ] **Installation**
  - [ ] Install PgBouncer package
  - [ ] Create pgbouncer user and directories
  - [ ] Setup systemd service
  - [ ] Verify installation
- [ ] **Initial Configuration**
  - [ ] Create pgbouncer.ini configuration
  - [ ] Setup userlist.txt for authentication
  - [ ] Configure log directory
  - [ ] Test basic startup

### 2. PgBouncer Configuration
- [ ] **Connection Settings**
  - [ ] Configure database connections section
  - [ ] Set listen_addr and listen_port
  - [ ] Configure auth_type and auth_file
  - [ ] Setup admin users
- [ ] **Pool Settings**
  - [ ] Set pool_mode = transaction
  - [ ] Configure default_pool_size
  - [ ] Set min_pool_size and reserve_pool_size
  - [ ] Configure max_client_conn and max_db_connections
  - [ ] Set server_idle_timeout and server_lifetime
- [ ] **Performance Tuning**
  - [ ] Configure query_wait_timeout
  - [ ] Set server_connect_timeout
  - [ ] Configure max_prepared_statements
  - [ ] Optimize buffer sizes
- [ ] **Security Settings**
  - [ ] Enable SSL/TLS if needed
  - [ ] Configure client certificate validation
  - [ ] Setup IP whitelisting
  - [ ] Enable admin console authentication

### 3. Application Integration
- [ ] **Connection String Updates**
  - [ ] Update database URLs to point to PgBouncer
  - [ ] Configure connection pool in application
  - [ ] Adjust application timeout settings
  - [ ] Test connection failover
- [ ] **Code Changes**
  - [ ] Review and update transaction management
  - [ ] Adjust prepared statement usage if needed
  - [ ] Update connection retry logic
  - [ ] Test database operations
- [ ] **Deployment**
  - [ ] Deploy changes to staging
  - [ ] Conduct integration testing
  - [ ] Deploy to production with monitoring
  - [ ] Validate performance

### 4. Monitoring and Alerting
- [ ] **Metrics Collection**
  - [ ] Install pgbouncer_exporter for Prometheus
  - [ ] Configure metric scraping
  - [ ] Setup custom metrics if needed
  - [ ] Verify metric collection
- [ ] **Dashboard Creation**
  - [ ] Create Grafana dashboard for PgBouncer
  - [ ] Add connection pool utilization graphs
  - [ ] Display query queue metrics
  - [ ] Show error rates and latency
- [ ] **Alert Configuration**
  - [ ] Setup pool exhaustion alerts
  - [ ] Configure high wait time alerts
  - [ ] Add error rate alerts
  - [ ] Setup PgBouncer down alerts

### 5. Testing and Validation
- [ ] **Functional Testing**
  - [ ] Test basic database operations
  - [ ] Verify transaction isolation
  - [ ] Test connection recycling
  - [ ] Validate error handling
- [ ] **Performance Testing**
  - [ ] Measure connection establishment time
  - [ ] Test under high concurrent load
  - [ ] Compare performance with direct connections
  - [ ] Validate connection pool efficiency
- [ ] **Failure Testing**
  - [ ] Test PgBouncer restart scenario
  - [ ] Test database failover
  - [ ] Simulate pool exhaustion
  - [ ] Verify graceful degradation

## Implementation Details

### PgBouncer Installation

```bash
#!/bin/bash
# scripts/install-pgbouncer.sh

set -e

echo "Installing PgBouncer..."

# Install PgBouncer
sudo apt-get update
sudo apt-get install -y pgbouncer

# Create directories
sudo mkdir -p /etc/pgbouncer
sudo mkdir -p /var/log/pgbouncer
sudo mkdir -p /var/run/pgbouncer

# Create pgbouncer user
sudo useradd -r -s /bin/false pgbouncer || true

# Set ownership
sudo chown -R pgbouncer:pgbouncer /etc/pgbouncer
sudo chown -R pgbouncer:pgbouncer /var/log/pgbouncer
sudo chown -R pgbouncer:pgbouncer /var/run/pgbouncer

echo "PgBouncer installed successfully"
```

### PgBouncer Configuration

```ini
;; /etc/pgbouncer/pgbouncer.ini

[databases]
; Database connection strings
screener_db = host=postgres-primary.internal port=5432 dbname=screener_db
screener_db_replica1 = host=postgres-replica1.internal port=5432 dbname=screener_db
screener_db_replica2 = host=postgres-replica2.internal port=5432 dbname=screener_db

; Fallback database for admin console
pgbouncer = host=postgres-primary.internal port=5432 dbname=pgbouncer

[pgbouncer]
;;;
;;; Administrative settings
;;;

logfile = /var/log/pgbouncer/pgbouncer.log
pidfile = /var/run/pgbouncer/pgbouncer.pid
listen_addr = 0.0.0.0
listen_port = 6432
unix_socket_dir = /var/run/pgbouncer

;;;
;;; Authentication settings
;;;

auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
auth_query = SELECT usename, passwd FROM pg_shadow WHERE usename=$1

;;;
;;; Connection pooling settings
;;;

pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
min_pool_size = 10
reserve_pool_size = 5
max_db_connections = 50
max_user_connections = 50

;;;
;;; Timing settings
;;;

server_lifetime = 3600
server_idle_timeout = 600
server_connect_timeout = 15
server_login_retry = 15
query_timeout = 0
query_wait_timeout = 120
client_idle_timeout = 0
idle_transaction_timeout = 0

;;;
;;; Performance settings
;;;

server_reset_query = DISCARD ALL
server_reset_query_always = 0
ignore_startup_parameters = extra_float_digits

;;;
;;; Logging
;;;

log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
stats_period = 60

;;;
;;; Console access control
;;;

admin_users = admin
stats_users = stats_user

;;;
;;; Connection sanity checks, timeouts
;;;

server_check_delay = 30
server_check_query = select 1

;;;
;;; TLS settings (if needed)
;;;

;client_tls_sslmode = disable
;client_tls_ca_file = /etc/ssl/certs/ca.crt
;client_tls_cert_file = /etc/ssl/certs/server.crt
;client_tls_key_file = /etc/ssl/private/server.key

;;;
;;; Dangerous settings
;;;

application_name_add_host = 1
max_prepared_statements = 0
```

### User Authentication File

```txt
# /etc/pgbouncer/userlist.txt
# Format: "username" "md5hashofpassword"

"app_user" "md5a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p"
"read_only_user" "md5x1y2z3a4b5c6d7e8f9g0h1i2j3k4l5"
"admin" "md5admin_hash_here"
"stats_user" "md5stats_hash_here"
```

```python
# scripts/generate-userlist.py
import hashlib

def generate_md5_hash(username, password):
    """Generate MD5 hash for PgBouncer userlist.txt"""
    hash_string = password + username
    md5_hash = hashlib.md5(hash_string.encode()).hexdigest()
    return f'"md5{md5_hash}"'

# Example usage
username = "app_user"
password = "secure_password"
hash_result = generate_md5_hash(username, password)
print(f'"{username}" {hash_result}')
```

### Systemd Service Configuration

```ini
# /etc/systemd/system/pgbouncer.service
[Unit]
Description=PgBouncer PostgreSQL connection pooler
After=network.target

[Service]
Type=forking
User=pgbouncer
Group=pgbouncer
ExecStart=/usr/sbin/pgbouncer -d /etc/pgbouncer/pgbouncer.ini
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/var/run/pgbouncer/pgbouncer.pid

# Restart configuration
Restart=on-failure
RestartSec=5s

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/pgbouncer /var/run/pgbouncer

[Install]
WantedBy=multi-user.target
```

### Application Configuration

```python
# config/database.py
import os
from sqlalchemy import create_engine
from sqlalchemy.pool import NullPool

# Database configuration with PgBouncer
DATABASE_CONFIG = {
    # Use PgBouncer for connection pooling
    'url': os.getenv(
        'DATABASE_URL',
        'postgresql://app_user:password@pgbouncer-host:6432/screener_db'
    ),

    # Disable application-level pooling since PgBouncer handles it
    'poolclass': NullPool,

    # Or use minimal pooling
    'pool_size': 5,
    'max_overflow': 0,

    # Connection settings
    'pool_pre_ping': True,
    'pool_recycle': 3600,
    'echo': False,

    # Timeout settings (should align with PgBouncer settings)
    'connect_args': {
        'connect_timeout': 10,
        'options': '-c statement_timeout=30000',  # 30 seconds
    }
}

# Create engine
engine = create_engine(**DATABASE_CONFIG)
```

```python
# For FastAPI dependency injection
from sqlalchemy.orm import sessionmaker, Session
from fastapi import Depends

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    """Database dependency for FastAPI"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### PgBouncer Admin Console Usage

```bash
# Connect to PgBouncer admin console
psql -h localhost -p 6432 -U admin pgbouncer

# View all databases
SHOW DATABASES;

# View pool statistics
SHOW POOLS;

# View server connections
SHOW SERVERS;

# View client connections
SHOW CLIENTS;

# View detailed statistics
SHOW STATS;

# View configuration
SHOW CONFIG;

# Reload configuration without restart
RELOAD;

# Pause all database connections
PAUSE;

# Resume database connections
RESUME;

# Kill specific client connection
KILL client_id;

# Shut down PgBouncer gracefully
SHUTDOWN;
```

### Monitoring with Prometheus

```yaml
# docker-compose.yml for pgbouncer_exporter
version: '3.8'

services:
  pgbouncer_exporter:
    image: prometheuscommunity/pgbouncer-exporter:latest
    container_name: pgbouncer_exporter
    environment:
      - PGBOUNCER_EXPORTER_HOST=pgbouncer-host
      - PGBOUNCER_EXPORTER_PORT=6432
      - PGBOUNCER_EXPORTER_DATABASE=pgbouncer
      - PGBOUNCER_EXPORTER_USER=stats_user
      - PGBOUNCER_EXPORTER_PASSWORD=stats_password
    ports:
      - "9127:9127"
    restart: unless-stopped
```

```yaml
# prometheus/prometheus.yml
scrape_configs:
  - job_name: 'pgbouncer'
    static_configs:
      - targets: ['pgbouncer-exporter:9127']
    scrape_interval: 15s
```

### Prometheus Alerts

```yaml
# prometheus/alerts/pgbouncer.yml
groups:
  - name: pgbouncer_alerts
    interval: 30s
    rules:
      - alert: PgBouncerPoolExhaustion
        expr: pgbouncer_pools_client_active_connections / pgbouncer_pools_cl_max_conn > 0.9
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "PgBouncer pool near exhaustion"
          description: "Database {{ $labels.database }} connection pool is {{ $value | humanizePercentage }} full"

      - alert: PgBouncerHighWaitTime
        expr: rate(pgbouncer_stats_total_wait_time[5m]) > 1000
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High client wait time in PgBouncer"
          description: "Clients are experiencing high wait times: {{ $value }}ms"

      - alert: PgBouncerDown
        expr: up{job="pgbouncer"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PgBouncer is down"
          description: "PgBouncer instance {{ $labels.instance }} is not responding"

      - alert: PgBouncerMaxServerConnections
        expr: pgbouncer_pools_sv_active_connections >= pgbouncer_pools_sv_max_conn
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PgBouncer max server connections reached"
          description: "Database {{ $labels.database }} has reached max server connections"

      - alert: PgBouncerErrorRate
        expr: rate(pgbouncer_errors_count[5m]) > 10
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High error rate in PgBouncer"
          description: "PgBouncer is experiencing {{ $value }} errors/sec"
```

### Grafana Dashboard

```json
// grafana/dashboards/pgbouncer.json (simplified)
{
  "dashboard": {
    "title": "PgBouncer Monitoring",
    "panels": [
      {
        "title": "Active Client Connections",
        "targets": [{
          "expr": "pgbouncer_pools_client_active_connections"
        }]
      },
      {
        "title": "Active Server Connections",
        "targets": [{
          "expr": "pgbouncer_pools_server_active_connections"
        }]
      },
      {
        "title": "Connection Pool Utilization %",
        "targets": [{
          "expr": "(pgbouncer_pools_client_active_connections / pgbouncer_pools_cl_max_conn) * 100"
        }]
      },
      {
        "title": "Client Wait Time",
        "targets": [{
          "expr": "rate(pgbouncer_stats_total_wait_time[5m])"
        }]
      },
      {
        "title": "Queries per Second",
        "targets": [{
          "expr": "rate(pgbouncer_stats_total_query_count[1m])"
        }]
      },
      {
        "title": "Average Query Duration",
        "targets": [{
          "expr": "rate(pgbouncer_stats_total_query_time[5m]) / rate(pgbouncer_stats_total_query_count[5m])"
        }]
      }
    ]
  }
}
```

### Health Check Script

```python
# monitoring/pgbouncer_healthcheck.py
import psycopg2
from prometheus_client import Gauge, start_http_server
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Prometheus metrics
pgbouncer_health = Gauge('pgbouncer_health', 'PgBouncer health status (1=healthy, 0=unhealthy)')
pool_available_connections = Gauge(
    'pgbouncer_pool_available_connections',
    'Number of available connections in pool',
    ['database']
)

def check_pgbouncer_health(host, port, database, user, password):
    """Check if PgBouncer is healthy and responsive"""
    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            database=database,
            user=user,
            password=password,
            connect_timeout=5
        )
        cur = conn.cursor()

        # Simple query to verify functionality
        cur.execute("SELECT 1")
        result = cur.fetchone()

        cur.close()
        conn.close()

        if result and result[0] == 1:
            pgbouncer_health.set(1)
            logger.info("PgBouncer health check: PASS")
            return True
        else:
            pgbouncer_health.set(0)
            logger.error("PgBouncer health check: FAIL")
            return False

    except Exception as e:
        pgbouncer_health.set(0)
        logger.error(f"PgBouncer health check failed: {e}")
        return False


def get_pool_stats(admin_host, admin_port, admin_user, admin_password):
    """Get pool statistics from PgBouncer admin console"""
    try:
        conn = psycopg2.connect(
            host=admin_host,
            port=admin_port,
            database='pgbouncer',
            user=admin_user,
            password=admin_password
        )
        cur = conn.cursor()

        # Get pool statistics
        cur.execute("SHOW POOLS")
        pools = cur.fetchall()

        for pool in pools:
            database = pool[0]
            cl_active = pool[2]
            cl_waiting = pool[3]
            sv_active = pool[4]
            sv_idle = pool[5]
            sv_used = pool[6]
            maxwait = pool[7]

            available = sv_idle
            pool_available_connections.labels(database=database).set(available)

            logger.info(
                f"Pool {database}: "
                f"clients_active={cl_active}, "
                f"clients_waiting={cl_waiting}, "
                f"servers_active={sv_active}, "
                f"servers_idle={sv_idle}"
            )

        cur.close()
        conn.close()

    except Exception as e:
        logger.error(f"Failed to get pool stats: {e}")


if __name__ == '__main__':
    # Start Prometheus metrics server
    start_http_server(8000)

    while True:
        check_pgbouncer_health(
            host='pgbouncer-host',
            port=6432,
            database='screener_db',
            user='app_user',
            password='password'
        )

        get_pool_stats(
            admin_host='pgbouncer-host',
            admin_port=6432,
            admin_user='admin',
            admin_password='admin_password'
        )

        time.sleep(30)
```

## Testing Strategy

### Connection Pool Testing

```python
# tests/test_connection_pool.py
import pytest
from sqlalchemy import create_engine, text
import concurrent.futures
import time

def test_connection_pooling_efficiency():
    """Test that connection pooling reduces connection overhead"""
    # Direct connection (baseline)
    direct_engine = create_engine(
        'postgresql://user:password@postgres-host:5432/db',
        poolclass=NullPool
    )

    # PgBouncer connection
    pooled_engine = create_engine(
        'postgresql://user:password@pgbouncer-host:6432/db',
        poolclass=NullPool
    )

    # Measure connection time for direct connections
    direct_times = []
    for _ in range(100):
        start = time.time()
        with direct_engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        direct_times.append(time.time() - start)

    # Measure connection time with PgBouncer
    pooled_times = []
    for _ in range(100):
        start = time.time()
        with pooled_engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        pooled_times.append(time.time() - start)

    avg_direct = sum(direct_times) / len(direct_times)
    avg_pooled = sum(pooled_times) / len(pooled_times)

    print(f"Average direct connection time: {avg_direct:.4f}s")
    print(f"Average pooled connection time: {avg_pooled:.4f}s")
    print(f"Improvement: {((avg_direct - avg_pooled) / avg_direct * 100):.2f}%")

    # PgBouncer should be faster
    assert avg_pooled < avg_direct


def test_concurrent_connections(pooled_engine):
    """Test handling many concurrent connections"""
    def execute_query(i):
        with pooled_engine.connect() as conn:
            result = conn.execute(text("SELECT :num as num"), {"num": i})
            return result.fetchone()[0]

    with concurrent.futures.ThreadPoolExecutor(max_workers=100) as executor:
        futures = [executor.submit(execute_query, i) for i in range(1000)]
        results = [f.result() for f in concurrent.futures.as_completed(futures)]

    assert len(results) == 1000
    assert all(r in range(1000) for r in results)


def test_pool_exhaustion_handling():
    """Test behavior when connection pool is exhausted"""
    # Configure with very small pool
    engine = create_engine(
        'postgresql://user:password@pgbouncer-host:6432/db',
        pool_size=2,
        max_overflow=0
    )

    def long_running_query():
        with engine.connect() as conn:
            conn.execute(text("SELECT pg_sleep(5)"))

    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        futures = [executor.submit(long_running_query) for _ in range(5)]

        # Some should succeed, some should timeout or queue
        results = []
        for future in concurrent.futures.as_completed(futures, timeout=10):
            try:
                future.result()
                results.append('success')
            except Exception as e:
                results.append('error')

    # At least some connections should succeed
    assert 'success' in results
```

### Load Testing

```python
# tests/load/test_pgbouncer_load.py
from locust import HttpUser, task, between
import random

class DatabaseLoadUser(HttpUser):
    wait_time = between(0.1, 0.5)

    @task(10)
    def read_query(self):
        """Simulate read query"""
        stock_id = random.randint(1, 10000)
        self.client.get(f"/stocks/{stock_id}")

    @task(3)
    def list_query(self):
        """Simulate list query"""
        page = random.randint(1, 100)
        self.client.get(f"/stocks?page={page}&page_size=20")

    @task(1)
    def write_query(self):
        """Simulate write query"""
        self.client.post("/watchlist", json={"stock_id": random.randint(1, 10000)})

# Run: locust -f test_pgbouncer_load.py --host=http://localhost:8000 -u 500 -r 50
```

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| PgBouncer single point of failure | Medium | High | Deploy PgBouncer in HA configuration, implement failover |
| Transaction mode incompatibility with prepared statements | Medium | Medium | Disable prepared statements or use session pooling for specific queries |
| Pool exhaustion under high load | Medium | High | Monitor pool utilization, configure appropriate limits, setup alerts |
| Configuration errors causing connection issues | Low | High | Thorough testing in staging, gradual rollout, rollback plan |
| Performance degradation from misconfiguration | Low | Medium | Load testing before production, monitoring, tuning |
| Authentication issues | Low | Medium | Test all user accounts, proper userlist.txt generation |

## Performance Requirements

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Connection establishment time | < 5ms | Benchmark direct vs pooled connections |
| Pool utilization | < 80% under normal load | PgBouncer SHOW POOLS monitoring |
| Query wait time | < 100ms | pgbouncer_stats_total_wait_time metric |
| Connection reuse rate | > 95% | Calculate from pgbouncer stats |
| Max concurrent connections support | 1000+ clients | Load testing |
| Database connection reduction | > 90% | Compare before/after connection counts |
| Latency overhead | < 1ms | Measure with and without PgBouncer |

## Security Considerations

### Authentication Security

```ini
# Use auth_query for dynamic authentication
auth_type = md5
auth_query = SELECT usename, passwd FROM pg_shadow WHERE usename=$1

# Or use scram-sha-256 for better security
auth_type = scram-sha-256
```

### Network Security

```bash
# Restrict access to PgBouncer
# /etc/pgbouncer/pgbouncer.ini
listen_addr = 10.0.1.10  # Internal IP only, not 0.0.0.0

# Use firewall rules
sudo ufw allow from 10.0.1.0/24 to any port 6432
sudo ufw deny 6432
```

### SSL/TLS Configuration

```ini
# Enable SSL for client connections
client_tls_sslmode = require
client_tls_ca_file = /etc/ssl/certs/ca.crt
client_tls_cert_file = /etc/ssl/certs/server.crt
client_tls_key_file = /etc/ssl/private/server.key
client_tls_protocols = TLSv1.2,TLSv1.3
client_tls_ciphers = HIGH:!aNULL:!MD5

# Enable SSL for server connections
server_tls_sslmode = require
server_tls_ca_file = /etc/ssl/certs/ca.crt
```

## Error Handling

### Connection Timeout Handling

```python
# app/database/errors.py
from sqlalchemy.exc import OperationalError, TimeoutError
from functools import wraps
import logging

logger = logging.getLogger(__name__)

def handle_connection_errors(max_retries=3):
    """Handle connection pool exhaustion and timeouts"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except (OperationalError, TimeoutError) as e:
                    logger.warning(
                        f"Database connection error (attempt {attempt + 1}/{max_retries}): {e}"
                    )
                    if attempt == max_retries - 1:
                        logger.error("Max retries exceeded for database operation")
                        raise
                    time.sleep(0.1 * (attempt + 1))  # Exponential backoff
            return None
        return wrapper
    return decorator
```

### Circuit Breaker for PgBouncer

```python
# app/database/circuit_breaker.py
from datetime import datetime, timedelta

class PgBouncerCircuitBreaker:
    def __init__(self, failure_threshold=5, timeout=60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failures = 0
        self.last_failure = None
        self.state = 'CLOSED'  # CLOSED, OPEN, HALF_OPEN

    def call(self, func, *args, **kwargs):
        if self.state == 'OPEN':
            if datetime.now() - self.last_failure > timedelta(seconds=self.timeout):
                self.state = 'HALF_OPEN'
            else:
                raise Exception("Circuit breaker is OPEN - PgBouncer may be down")

        try:
            result = func(*args, **kwargs)
            if self.state == 'HALF_OPEN':
                self.state = 'CLOSED'
                self.failures = 0
            return result
        except Exception as e:
            self.failures += 1
            self.last_failure = datetime.now()
            if self.failures >= self.failure_threshold:
                self.state = 'OPEN'
            raise
```

## Progress

**0% - Not started**

## Notes

### Dependencies
- PgBouncer >= 1.17.0
- PostgreSQL client libraries
- pgbouncer-exporter (for Prometheus monitoring)
- prometheus-client (for custom metrics)

### Best Practices

1. **Pool Sizing**
   - Start with default_pool_size = (total_db_connections / number_of_pgbouncers) * 0.8
   - Monitor and adjust based on actual usage
   - Reserve some connections for admin tasks
   - Consider separate pools for different application tiers

2. **Pool Mode Selection**
   - Use transaction mode for stateless applications (recommended)
   - Use session mode if application uses temp tables or session-specific features
   - Avoid statement mode unless absolutely necessary

3. **Monitoring**
   - Track pool utilization continuously
   - Monitor client wait times
   - Set up alerts for pool exhaustion
   - Review statistics regularly

4. **Maintenance**
   - Reload configuration without downtime: RELOAD;
   - Use PAUSE/RESUME for safe maintenance
   - Monitor logs for errors and warnings
   - Keep PgBouncer version updated

### Common Issues and Solutions

1. **"No more connections allowed" Error**
   - Increase max_client_conn
   - Increase default_pool_size
   - Check for connection leaks in application
   - Review query_wait_timeout setting

2. **High Client Wait Time**
   - Increase pool size
   - Optimize slow queries
   - Check database performance
   - Consider adding more database resources

3. **Prepared Statement Issues**
   - Set max_prepared_statements = 0 in transaction mode
   - Or use session mode for specific users/databases
   - Update application to use simple queries

4. **Authentication Failures**
   - Verify userlist.txt MD5 hashes
   - Check auth_type setting
   - Ensure database user exists
   - Review pg_hba.conf on database server

### Configuration Tuning Guide

**For high-throughput applications:**
```ini
default_pool_size = 50
max_client_conn = 2000
query_wait_timeout = 30
```

**For low-latency applications:**
```ini
default_pool_size = 20
max_client_conn = 500
query_wait_timeout = 5
server_idle_timeout = 300
```

**For mixed workload:**
```ini
default_pool_size = 30
reserve_pool_size = 10
max_client_conn = 1000
query_wait_timeout = 60
```

### High Availability Setup

```bash
# Use multiple PgBouncer instances with HAProxy/Keepalived
# Load balance across PgBouncer instances
# Configure health checks
# Automatic failover
```
