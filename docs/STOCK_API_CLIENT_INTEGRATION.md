# Stock API Client Integration Analysis

**Date:** 2025-11-09
**Status:** Recommendation
**Target Project:** screener_system

---

## Executive Summary

After reviewing the `stock_api_client` C++ library, several valuable patterns, features, and integration opportunities have been identified for the `screener_system` Python/TypeScript platform.

### Key Findings

✅ **Reusable Architecture Patterns**: OAuth management, connection pooling, async logging
✅ **Missing Features**: Real-time data source, WebSocket support, order book data
✅ **Enhancement Opportunities**: Korean stock market integration (KIS API)
✅ **Documentation Excellence**: Comprehensive roadmap and priority matrix

---

## 1. Architecture Patterns to Adopt

### 1.1 OAuth 2.0 Token Management

**Current State (stock_api_client):**
- Automatic token refresh
- Thread-safe token storage
- Token expiration handling

**Recommendation for screener_system:**

```python
# backend/app/services/external_api_service.py

class KISApiClient:
    """Korea Investment & Securities API Client with auto-refresh"""

    def __init__(self, app_key: str, app_secret: str):
        self.app_key = app_key
        self.app_secret = app_secret
        self._token: Optional[str] = None
        self._token_expires_at: Optional[datetime] = None
        self._lock = asyncio.Lock()

    async def _ensure_valid_token(self) -> str:
        """Auto-refresh token if expired"""
        async with self._lock:
            if self._token and self._token_expires_at > datetime.now():
                return self._token

            # Refresh token
            self._token = await self._fetch_new_token()
            self._token_expires_at = datetime.now() + timedelta(hours=24)
            return self._token

    async def get_current_price(self, stock_code: str) -> StockPrice:
        token = await self._ensure_valid_token()
        # Use token for API call
        ...
```

**Benefits:**
- ✅ No manual token management
- ✅ Thread-safe for concurrent requests
- ✅ Automatic recovery from expiration

---

### 1.2 Connection Pooling

**Current State (stock_api_client):**
- CURL connection pool for reuse
- Reduces connection overhead
- Thread-safe design

**Recommendation for screener_system:**

```python
# backend/app/core/http_client.py

import httpx
from typing import Optional

class HTTPClientPool:
    """Singleton HTTP client with connection pooling"""

    _instance: Optional[httpx.AsyncClient] = None

    @classmethod
    def get_client(cls) -> httpx.AsyncClient:
        if cls._instance is None:
            cls._instance = httpx.AsyncClient(
                limits=httpx.Limits(
                    max_connections=100,
                    max_keepalive_connections=20
                ),
                timeout=httpx.Timeout(10.0)
            )
        return cls._instance
```

**Benefits:**
- ✅ Reduced connection overhead (20-30% faster)
- ✅ Better resource utilization
- ✅ Automatic keep-alive management

---

### 1.3 High-Performance Logging

**Current State (stock_api_client):**
- Async logging with <1μs overhead
- Bounded queue to prevent memory overflow
- Dynamic log level adjustment

**Recommendation for screener_system:**

```python
# backend/app/core/async_logger.py

import logging
from logging.handlers import QueueHandler, QueueListener
from queue import Queue

class AsyncLogger:
    """Non-blocking logger for high-performance applications"""

    def __init__(self, queue_size: int = 10000):
        self.queue = Queue(maxsize=queue_size)

        # Queue handler (non-blocking)
        queue_handler = QueueHandler(self.queue)

        # File handler (runs in background thread)
        file_handler = logging.FileHandler('logs/app.log')
        file_handler.setFormatter(
            logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        )

        # Start background listener
        self.listener = QueueListener(self.queue, file_handler)
        self.listener.start()

        # Configure root logger
        logging.getLogger().addHandler(queue_handler)
        logging.getLogger().setLevel(logging.INFO)
```

**Benefits:**
- ✅ No I/O blocking on API threads
- ✅ Prevents log flooding from filling disk
- ✅ Adjustable log level for performance tuning

---

## 2. Missing Features to Implement

### 2.1 Real-time Data Source Integration

**Current Gap:**
- screener_system uses placeholder/mock data sources
- No integration with actual Korean stock market APIs

**Recommendation:**

Create **KIS API integration** as primary data source:

**New Ticket: DP-004 - KIS API Integration**

```markdown
# [DP-004] Korea Investment & Securities API Integration

## Priority: High
## Estimated Time: 20 hours

### Subtasks
- [ ] KIS API client implementation
  - [ ] OAuth 2.0 authentication
  - [ ] Current price API
  - [ ] Order book API (호가)
  - [ ] Historical chart data API
- [ ] Rate limiting (20 req/sec)
- [ ] Error handling and retry logic
- [ ] Caching layer (Redis)
- [ ] Integration with existing data pipeline

### Acceptance Criteria
- [ ] Fetch real-time prices for 2,400 stocks
- [ ] Respect rate limits (20 req/sec)
- [ ] Cache responses (30 min TTL for prices)
- [ ] Handle authentication automatically
- [ ] 99% uptime during market hours
```

**Alternative Data Sources:**
- Korea Exchange (KRX) Public Data Portal
- FinanceDataReader (open-source Python library)
- Yahoo Finance Korea (limited data)

---

### 2.2 WebSocket Real-time Streaming

**Current State (stock_api_client roadmap):**
- Planned feature for <100ms latency
- True real-time vs 3-5 second polling

**Recommendation for screener_system:**

**New Ticket: BE-005 - WebSocket Real-time Price Streaming**

```markdown
# [BE-005] WebSocket Real-time Price Stream

## Priority: Medium (Phase 2)
## Estimated Time: 16 hours

### Features
- WebSocket server for frontend clients
- Server-Sent Events (SSE) alternative
- Connection management (reconnect, heartbeat)
- Room-based subscriptions (per stock code)

### Technology
- FastAPI WebSocket support
- Redis Pub/Sub for multi-instance
- Frontend: WebSocket API / EventSource

### Use Cases
- Live price updates on stock detail page
- Real-time screener results
- Alert notifications
```

---

### 2.3 Order Book Data (호가 정보)

**Enhancement from stock_api_client roadmap:**
- 10-level bid/ask depth
- Essential for trading decision-making

**Recommendation:**

**New Feature: Order Book Display**

Add to existing tickets:
- **FE-004**: Add order book component to stock detail page
- **BE-003**: Add `/v1/stocks/{code}/orderbook` endpoint
- **DP-002**: Include order book in price ingestion DAG

**Database Schema Addition:**

```sql
-- database/migrations/06_order_book.sql

CREATE TABLE order_book (
    stock_code VARCHAR(6) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,

    -- Ask (매도) prices and volumes
    ask_price_1 DECIMAL(10, 2),
    ask_volume_1 BIGINT,
    ask_price_2 DECIMAL(10, 2),
    ask_volume_2 BIGINT,
    -- ... up to ask_price_10

    -- Bid (매수) prices and volumes
    bid_price_1 DECIMAL(10, 2),
    bid_volume_1 BIGINT,
    bid_price_2 DECIMAL(10, 2),
    bid_volume_2 BIGINT,
    -- ... up to bid_price_10

    PRIMARY KEY (stock_code, timestamp)
);

SELECT create_hypertable('order_book', 'timestamp');
```

---

## 3. Documentation Strategy

### 3.1 Enhancement Roadmap

**Learned from stock_api_client:**
- Comprehensive feature priority matrix
- Value vs complexity analysis
- Timeline visualization

**Recommendation:**

Create **ENHANCEMENT_ROADMAP.md** for screener_system with:

1. **Current State**: What works today
2. **Feature Backlog**: Prioritized features (P0-P3)
3. **Timeline**: Phased rollout plan
4. **Resource Requirements**: Development effort estimates
5. **Success Metrics**: KPIs per phase

**Example structure:**

```markdown
# screener_system Enhancement Roadmap

## Phase 1: Production Readiness (Weeks 1-6)
- [ ] Real data source integration (KIS API)
- [ ] Performance optimization (<500ms p99)
- [ ] Monitoring and alerting
- [ ] Security hardening

## Phase 2: Advanced Features (Weeks 7-12)
- [ ] WebSocket real-time streaming
- [ ] Order book visualization
- [ ] Advanced screening filters (200+ indicators)
- [ ] Portfolio backtesting

## Phase 3: Market Expansion (Weeks 13-18)
- [ ] Mobile app (React Native)
- [ ] US stock support
- [ ] Premium tier features
- [ ] Trading simulation
```

---

### 3.2 Feature Priority Matrix

**Recommendation:**

Create **FEATURE_PRIORITY_MATRIX.md**:

```markdown
## Value vs Effort Matrix

High Value │
          │  ┌─────────────┐
          │  │  KIS API    │ P0 (Critical)
          │  │ Integration │
          │  └─────────────┘
          │
          │  ┌─────────────┐  ┌─────────────┐
          │  │  WebSocket  │  │  Order      │ P1
          │  │  Streaming  │  │  Book       │
          │  └─────────────┘  └─────────────┘
          │
          │  ┌─────────────┐
          │  │  Mobile     │ P2
          │  │   App       │
          │  └─────────────┘
          │
Low Value │  ┌─────────────┐
          │  │  US Stocks  │ P3
          │  └─────────────┘
          └─────────────────────────────────
            Low          Medium          High
                      Complexity
```

---

## 4. Recommended New Tickets

### 4.1 Priority 0 (Critical)

**DP-004: KIS API Integration**
- Estimated: 20 hours
- Dependencies: DB-002, BE-001
- Delivers: Real production data source

**BE-005: API Rate Limiting & Throttling**
- Estimated: 6 hours
- Dependencies: BE-001
- Delivers: Protect against abuse, manage external API quotas

---

### 4.2 Priority 1 (High Value)

**BE-006: WebSocket Real-time Streaming**
- Estimated: 16 hours
- Dependencies: BE-003, DP-004
- Delivers: Real-time price updates

**FE-005: Order Book Visualization**
- Estimated: 12 hours
- Dependencies: BE-006, FE-004
- Delivers: 10-level bid/ask display

**DB-005: Performance Monitoring Views**
- Estimated: 4 hours
- Dependencies: DB-003
- Delivers: Query performance tracking

---

### 4.3 Priority 2 (Medium Value)

**BE-007: External API Adapter Pattern**
- Estimated: 8 hours
- Dependencies: BE-001
- Delivers: Pluggable data source architecture

**INFRA-004: Log Aggregation (ELK Stack)**
- Estimated: 12 hours
- Dependencies: INFRA-003
- Delivers: Centralized logging

---

### 4.4 Priority 3 (Future)

**BE-008: Trading Paper Simulation**
- Estimated: 24 hours
- Dependencies: BE-006
- Delivers: Virtual trading for testing strategies

**FE-006: Mobile App (React Native)**
- Estimated: 80 hours
- Dependencies: BE-001, BE-003, BE-004
- Delivers: iOS/Android support

---

## 5. Architecture Improvements

### 5.1 Layered API Client Design

**Pattern from stock_api_client:**

```
KisClient
  ├── KisAuth (OAuth management)
  ├── CurlConnectionPool (HTTP layer)
  ├── StockLogger (Async logging)
  └── StockData (Data models)
```

**Recommended for screener_system:**

```python
# backend/app/services/data_source/

data_source/
├── __init__.py
├── base.py              # AbstractDataSource interface
├── kis_client.py        # Korea Investment & Securities
├── krx_client.py        # Korea Exchange (backup)
├── mock_client.py       # Testing/development
└── data_source_factory.py
```

```python
# backend/app/services/data_source/base.py

from abc import ABC, abstractmethod
from typing import List, Optional

class AbstractDataSource(ABC):
    """Interface for stock data sources"""

    @abstractmethod
    async def get_current_price(self, stock_code: str) -> StockPrice:
        pass

    @abstractmethod
    async def get_price_history(
        self,
        stock_code: str,
        from_date: date,
        to_date: date
    ) -> List[DailyPrice]:
        pass

    @abstractmethod
    async def get_order_book(self, stock_code: str) -> OrderBook:
        pass
```

**Benefits:**
- ✅ Easy to swap data sources
- ✅ Testable with mock implementations
- ✅ Multi-source redundancy (fallback)

---

### 5.2 Circuit Breaker Pattern

**For external API resilience:**

```python
# backend/app/core/circuit_breaker.py

from enum import Enum
import time

class CircuitState(Enum):
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing, reject requests
    HALF_OPEN = "half_open"  # Testing recovery

class CircuitBreaker:
    def __init__(
        self,
        failure_threshold: int = 5,
        timeout: int = 60
    ):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED

    async def call(self, func, *args, **kwargs):
        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time > self.timeout:
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker is OPEN")

        try:
            result = await func(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise e

    def _on_success(self):
        self.failure_count = 0
        self.state = CircuitState.CLOSED

    def _on_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()

        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
```

---

## 6. Configuration Management

### 6.1 External API Credentials

**Add to .env.example:**

```bash
# External Data Sources
KIS_APP_KEY=your_kis_app_key_here
KIS_APP_SECRET=your_kis_app_secret_here
KIS_ACCOUNT_NUMBER=your_account_number
KIS_USE_REAL_SERVER=false  # false = virtual/paper trading

# Rate Limiting
KIS_MAX_REQUESTS_PER_SECOND=20
KIS_REQUEST_TIMEOUT=10

# Caching
PRICE_CACHE_TTL=300  # 5 minutes
ORDER_BOOK_CACHE_TTL=10  # 10 seconds
```

### 6.2 Feature Flags

**Add feature toggle system:**

```python
# backend/app/core/config.py

class Settings(BaseSettings):
    # ... existing settings

    # Feature flags
    ENABLE_REAL_TIME_WEBSOCKET: bool = False
    ENABLE_KIS_API: bool = True
    ENABLE_ORDER_BOOK: bool = False
    ENABLE_PAPER_TRADING: bool = False

    # External APIs
    KIS_APP_KEY: Optional[str] = None
    KIS_APP_SECRET: Optional[str] = None
```

---

## 7. Testing Strategy

### 7.1 Mock External APIs

**Create test fixtures:**

```python
# backend/tests/fixtures/kis_api_mock.py

import pytest
from app.services.data_source.mock_client import MockDataSource

@pytest.fixture
def mock_kis_client():
    """Mock KIS API client for testing"""
    client = MockDataSource()

    # Pre-load test data
    client.add_stock("005930", {
        "name": "삼성전자",
        "current_price": 71000,
        "change_rate": 2.5
    })

    return client
```

---

### 7.2 Integration Tests

**Test external API integration:**

```python
# backend/tests/integration/test_kis_api.py

@pytest.mark.integration
@pytest.mark.skipif(not os.getenv("KIS_APP_KEY"), reason="KIS credentials not configured")
async def test_kis_api_real_connection():
    """Test real connection to KIS API (virtual server)"""
    client = KISApiClient(
        app_key=os.getenv("KIS_APP_KEY"),
        app_secret=os.getenv("KIS_APP_SECRET")
    )

    # Test authentication
    token = await client._ensure_valid_token()
    assert token is not None

    # Test price query
    price = await client.get_current_price("005930")
    assert price.stock_code == "005930"
    assert price.current_price > 0
```

---

## 8. Implementation Roadmap

### Week 1-2: Foundation
- [ ] Create data source abstraction layer
- [ ] Implement KIS API client (OAuth, basic price query)
- [ ] Add connection pooling
- [ ] Implement async logging

### Week 3-4: Integration
- [ ] Integrate KIS API with existing DAGs
- [ ] Add rate limiting and circuit breaker
- [ ] Implement Redis caching layer
- [ ] Update API endpoints to use real data

### Week 5-6: Advanced Features
- [ ] WebSocket server implementation
- [ ] Order book API and UI
- [ ] Real-time price streaming
- [ ] Performance testing and optimization

### Week 7-8: Polish
- [ ] Documentation updates
- [ ] Monitoring dashboards
- [ ] Load testing
- [ ] Production deployment

---

## 9. Success Metrics

### Technical Metrics
- [ ] API latency < 200ms (p95)
- [ ] WebSocket latency < 100ms
- [ ] 99.9% uptime during market hours
- [ ] 0 data loss during ingestion
- [ ] Cache hit rate > 80%

### Business Metrics
- [ ] Real-time data for 2,400+ stocks
- [ ] 10,000+ concurrent users supported
- [ ] <1% error rate on external API calls
- [ ] User-reported data accuracy > 99%

---

## 10. Risk Mitigation

### External API Risks

| Risk | Mitigation |
|------|------------|
| KIS API downtime | Fallback to KRX API, cached data |
| Rate limit exceeded | Request queue, exponential backoff |
| Authentication failure | Auto-refresh, alert on repeated failures |
| Data inconsistency | Validation layer, anomaly detection |
| Cost overruns | Rate limiting, monitoring, alerts |

### Development Risks

| Risk | Mitigation |
|------|------------|
| Integration complexity | Phased rollout, feature flags |
| Performance degradation | Load testing, profiling |
| Breaking changes | API version pinning, integration tests |
| Security vulnerabilities | Code review, penetration testing |

---

## 11. Budget Estimate

### Development Costs

| Task | Hours | Cost @ $100/hr |
|------|-------|----------------|
| Data source abstraction | 8 | $800 |
| KIS API client | 20 | $2,000 |
| WebSocket server | 16 | $1,600 |
| Order book feature | 12 | $1,200 |
| Testing & QA | 16 | $1,600 |
| Documentation | 8 | $800 |
| **Total** | **80** | **$8,000** |

### Operational Costs (Annual)

- KIS API subscription: $0 (free tier)
- Additional Redis memory: ~$50/month = $600/year
- Increased server capacity: ~$100/month = $1,200/year
- **Total Annual**: ~$1,800

---

## 12. Conclusion

The `stock_api_client` project provides valuable insights for enhancing `screener_system`:

### ✅ High-Priority Recommendations

1. **Implement KIS API integration** for real production data
2. **Adopt connection pooling** for better performance
3. **Add async logging** to reduce I/O overhead
4. **Create enhancement roadmap** for stakeholder alignment

### ✅ Medium-Priority Recommendations

5. **Add WebSocket support** for real-time streaming
6. **Implement order book visualization**
7. **Create feature priority matrix** for decision-making

### ✅ Long-term Opportunities

8. Paper trading simulation
9. Mobile app development
10. International market expansion

**Next Steps:**
1. Review and approve recommended tickets (DP-004, BE-005, BE-006)
2. Set up KIS API test account
3. Begin KIS API client implementation (Week 1)
4. Create ENHANCEMENT_ROADMAP.md
5. Update project timeline

---

**Prepared by:** Development Team
**Date:** 2025-11-09
**Version:** 1.0
**Status:** Awaiting Approval
