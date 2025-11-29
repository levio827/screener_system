# PERF-001a: GraphQL Schema Design

## Metadata

| Field | Value |
|-------|-------|
| **ID** | PERF-001a |
| **Title** | Design and Implement GraphQL Schema |
| **Type** | Feature |
| **Status** | BACKLOG |
| **Priority** | P2 (Medium) |
| **Estimate** | 8 hours |
| **Sprint** | Sprint 8 |
| **Epic** | Performance & Scalability |
| **Assignee** | TBD |
| **Created** | 2025-11-29 |
| **Tags** | `graphql`, `api`, `performance`, `n+1-problem`, `dataloader` |
| **Blocks** | PERF-001b |

## Description

Design and implement a comprehensive GraphQL schema for the screener system using Strawberry GraphQL. This implementation will replace REST endpoints with a more efficient GraphQL API that resolves N+1 query problems using DataLoader pattern, reduces over-fetching, and provides better frontend developer experience.

## Acceptance Criteria

- [ ] **GraphQL Schema Design**
  - [ ] Define core types (Stock, Sector, Industry, FinancialMetrics)
  - [ ] Design query operations (stocks, screening, filters)
  - [ ] Design mutation operations (watchlist, alerts)
  - [ ] Define input types and filters
  - [ ] Document schema with descriptions
- [ ] **Strawberry GraphQL Setup**
  - [ ] Install and configure Strawberry GraphQL
  - [ ] Setup FastAPI integration
  - [ ] Configure GraphQL Playground/GraphiQL
  - [ ] Implement authentication middleware
  - [ ] Setup CORS for GraphQL endpoint
- [ ] **Main Query Implementation**
  - [ ] Implement stock listing query with pagination
  - [ ] Implement stock detail query
  - [ ] Implement screening query with filters
  - [ ] Implement sector/industry aggregation queries
  - [ ] Add sorting and filtering capabilities
- [ ] **DataLoader for N+1 Problem Resolution**
  - [ ] Implement DataLoader for stock relationships
  - [ ] Implement DataLoader for financial metrics
  - [ ] Implement DataLoader for sector/industry data
  - [ ] Add batch loading for watchlist items
  - [ ] Configure DataLoader caching strategy

## Subtasks

### 1. Schema Design and Documentation
- [ ] **Type Definitions**
  - [ ] Create Stock type with all fields
  - [ ] Create FinancialMetrics type
  - [ ] Create Sector and Industry types
  - [ ] Create Watchlist and Alert types
  - [ ] Add field-level descriptions
- [ ] **Query Design**
  - [ ] Design stocks query with pagination
  - [ ] Design screening query with filters
  - [ ] Design aggregation queries
  - [ ] Add sorting options
- [ ] **Input Types**
  - [ ] Create StockFilterInput
  - [ ] Create ScreeningCriteriaInput
  - [ ] Create PaginationInput
  - [ ] Create SortInput

### 2. Strawberry GraphQL Setup
- [ ] **Installation and Configuration**
  - [ ] Install strawberry-graphql[fastapi]
  - [ ] Configure FastAPI app integration
  - [ ] Setup GraphQL endpoint (/graphql)
  - [ ] Enable GraphQL Playground in development
- [ ] **Middleware Setup**
  - [ ] Implement authentication middleware
  - [ ] Add request logging middleware
  - [ ] Configure error handling
  - [ ] Setup CORS configuration

### 3. Query Resolvers Implementation
- [ ] **Stock Queries**
  - [ ] Implement stocks resolver with pagination
  - [ ] Implement stock(id) resolver
  - [ ] Implement searchStocks resolver
  - [ ] Add field resolvers for relationships
- [ ] **Screening Queries**
  - [ ] Implement screening resolver
  - [ ] Add filter logic implementation
  - [ ] Implement aggregation logic
  - [ ] Add caching for common queries

### 4. DataLoader Implementation
- [ ] **Create DataLoaders**
  - [ ] StockLoader for batch stock fetching
  - [ ] FinancialMetricsLoader for metrics
  - [ ] SectorLoader and IndustryLoader
  - [ ] WatchlistLoader for user data
- [ ] **Configure Batching**
  - [ ] Set batch size limits
  - [ ] Configure cache TTL
  - [ ] Implement cache invalidation
  - [ ] Add monitoring for batch efficiency

## Implementation Details

### GraphQL Schema Example

```python
# schema/types.py
import strawberry
from typing import List, Optional
from datetime import datetime
from decimal import Decimal

@strawberry.type
class Sector:
    id: int
    name: str
    code: str
    stock_count: int

@strawberry.type
class Industry:
    id: int
    name: str
    code: str
    sector_id: int

    @strawberry.field
    async def sector(self, info) -> Sector:
        loader = info.context["sector_loader"]
        return await loader.load(self.sector_id)

@strawberry.type
class FinancialMetrics:
    stock_id: int
    market_cap: Optional[Decimal]
    pe_ratio: Optional[Decimal]
    pb_ratio: Optional[Decimal]
    roe: Optional[Decimal]
    debt_ratio: Optional[Decimal]
    dividend_yield: Optional[Decimal]
    updated_at: datetime

@strawberry.type
class Stock:
    id: int
    symbol: str
    name: str
    market: str
    sector_id: int
    industry_id: int
    current_price: Decimal
    change_percent: Decimal
    volume: int
    updated_at: datetime

    @strawberry.field
    async def sector(self, info) -> Sector:
        loader = info.context["sector_loader"]
        return await loader.load(self.sector_id)

    @strawberry.field
    async def industry(self, info) -> Industry:
        loader = info.context["industry_loader"]
        return await loader.load(self.industry_id)

    @strawberry.field
    async def financial_metrics(self, info) -> Optional[FinancialMetrics]:
        loader = info.context["financial_metrics_loader"]
        return await loader.load(self.id)

@strawberry.type
class StockConnection:
    items: List[Stock]
    total_count: int
    has_next_page: bool
    has_previous_page: bool

# Input Types
@strawberry.input
class StockFilterInput:
    symbols: Optional[List[str]] = None
    sectors: Optional[List[int]] = None
    industries: Optional[List[int]] = None
    min_price: Optional[Decimal] = None
    max_price: Optional[Decimal] = None
    min_market_cap: Optional[Decimal] = None
    max_market_cap: Optional[Decimal] = None

@strawberry.input
class PaginationInput:
    page: int = 1
    page_size: int = 20

@strawberry.enum
class SortOrder:
    ASC = "asc"
    DESC = "desc"

@strawberry.input
class SortInput:
    field: str
    order: SortOrder = SortOrder.ASC
```

### Query Implementation

```python
# schema/queries.py
import strawberry
from typing import List, Optional
from .types import Stock, StockConnection, Sector, Industry
from .inputs import StockFilterInput, PaginationInput, SortInput

@strawberry.type
class Query:
    @strawberry.field
    async def stocks(
        self,
        info,
        filters: Optional[StockFilterInput] = None,
        pagination: Optional[PaginationInput] = None,
        sort: Optional[SortInput] = None
    ) -> StockConnection:
        """
        Query stocks with filtering, pagination, and sorting.

        Example:
        ```graphql
        query {
          stocks(
            filters: { sectors: [1, 2], minPrice: 10000 }
            pagination: { page: 1, pageSize: 20 }
            sort: { field: "market_cap", order: DESC }
          ) {
            items {
              id
              symbol
              name
              currentPrice
              sector { name }
              financialMetrics { peRatio }
            }
            totalCount
            hasNextPage
          }
        }
        ```
        """
        db = info.context["db"]

        # Build query with filters
        query = db.query(StockModel)

        if filters:
            if filters.symbols:
                query = query.filter(StockModel.symbol.in_(filters.symbols))
            if filters.sectors:
                query = query.filter(StockModel.sector_id.in_(filters.sectors))
            if filters.min_price:
                query = query.filter(StockModel.current_price >= filters.min_price)
            if filters.max_price:
                query = query.filter(StockModel.current_price <= filters.max_price)

        # Apply sorting
        if sort:
            order = desc if sort.order == SortOrder.DESC else asc
            query = query.order_by(order(getattr(StockModel, sort.field)))

        # Get total count
        total_count = query.count()

        # Apply pagination
        pagination = pagination or PaginationInput()
        offset = (pagination.page - 1) * pagination.page_size
        query = query.offset(offset).limit(pagination.page_size)

        # Fetch results
        stocks = query.all()

        return StockConnection(
            items=[Stock.from_orm(s) for s in stocks],
            total_count=total_count,
            has_next_page=offset + len(stocks) < total_count,
            has_previous_page=pagination.page > 1
        )

    @strawberry.field
    async def stock(self, info, id: int) -> Optional[Stock]:
        """Get a single stock by ID"""
        loader = info.context["stock_loader"]
        return await loader.load(id)

    @strawberry.field
    async def sectors(self, info) -> List[Sector]:
        """Get all sectors"""
        db = info.context["db"]
        sectors = db.query(SectorModel).all()
        return [Sector.from_orm(s) for s in sectors]
```

### DataLoader Implementation

```python
# loaders/stock_loader.py
from typing import List, Optional
from strawberry.dataloader import DataLoader
from sqlalchemy.orm import Session
from models import Stock as StockModel, FinancialMetrics as MetricsModel

class StockLoader(DataLoader):
    def __init__(self, db: Session):
        super().__init__(load_fn=self.load_stocks)
        self.db = db

    async def load_stocks(self, keys: List[int]) -> List[Optional[Stock]]:
        """Batch load stocks by IDs"""
        stocks = self.db.query(StockModel).filter(
            StockModel.id.in_(keys)
        ).all()

        stock_map = {stock.id: Stock.from_orm(stock) for stock in stocks}
        return [stock_map.get(key) for key in keys]

class FinancialMetricsLoader(DataLoader):
    def __init__(self, db: Session):
        super().__init__(load_fn=self.load_metrics)
        self.db = db

    async def load_metrics(self, stock_ids: List[int]) -> List[Optional[FinancialMetrics]]:
        """Batch load financial metrics for stocks"""
        metrics = self.db.query(MetricsModel).filter(
            MetricsModel.stock_id.in_(stock_ids)
        ).all()

        metrics_map = {m.stock_id: FinancialMetrics.from_orm(m) for m in metrics}
        return [metrics_map.get(stock_id) for stock_id in stock_ids]

class SectorLoader(DataLoader):
    def __init__(self, db: Session):
        super().__init__(load_fn=self.load_sectors)
        self.db = db

    async def load_sectors(self, sector_ids: List[int]) -> List[Optional[Sector]]:
        """Batch load sectors by IDs"""
        sectors = self.db.query(SectorModel).filter(
            SectorModel.id.in_(sector_ids)
        ).all()

        sector_map = {s.id: Sector.from_orm(s) for s in sectors}
        return [sector_map.get(sid) for sid in sector_ids]

# Context setup
def get_context(db: Session):
    return {
        "db": db,
        "stock_loader": StockLoader(db),
        "financial_metrics_loader": FinancialMetricsLoader(db),
        "sector_loader": SectorLoader(db),
        "industry_loader": IndustryLoader(db),
    }
```

### FastAPI Integration

```python
# main.py
from fastapi import FastAPI
from strawberry.fastapi import GraphQLRouter
from schema import schema
from database import get_db
from loaders import get_context

app = FastAPI()

async def get_graphql_context(request, response):
    db = next(get_db())
    try:
        return get_context(db)
    finally:
        db.close()

graphql_app = GraphQLRouter(
    schema,
    context_getter=get_graphql_context,
    graphiql=True  # Enable GraphiQL in development
)

app.include_router(graphql_app, prefix="/graphql")
```

## Testing Strategy

### Unit Tests
```python
# tests/test_graphql_schema.py
import pytest
from strawberry.test import create_test_client
from schema import schema

def test_stocks_query():
    """Test stocks query returns correct structure"""
    client = create_test_client(schema)

    query = """
        query {
            stocks(pagination: { page: 1, pageSize: 10 }) {
                items {
                    id
                    symbol
                    name
                }
                totalCount
                hasNextPage
            }
        }
    """

    result = client.query(query)
    assert result.errors is None
    assert "stocks" in result.data
    assert "items" in result.data["stocks"]
    assert "totalCount" in result.data["stocks"]

def test_stock_with_relationships():
    """Test N+1 problem is resolved with DataLoader"""
    client = create_test_client(schema)

    query = """
        query {
            stocks(pagination: { page: 1, pageSize: 5 }) {
                items {
                    id
                    symbol
                    sector { name }
                    industry { name }
                    financialMetrics { peRatio }
                }
            }
        }
    """

    # Should execute only a few queries, not N+1
    result = client.query(query)
    assert result.errors is None

    # Verify all relationships are loaded
    for stock in result.data["stocks"]["items"]:
        assert stock["sector"] is not None
        assert stock["industry"] is not None
```

### Integration Tests
```python
# tests/integration/test_graphql_api.py
def test_graphql_endpoint(client):
    """Test GraphQL endpoint is accessible"""
    response = client.post("/graphql", json={
        "query": "{ __schema { queryType { name } } }"
    })
    assert response.status_code == 200

def test_filtering_and_sorting(client):
    """Test complex query with filtering and sorting"""
    query = """
        query {
            stocks(
                filters: { sectors: [1], minPrice: 10000 }
                sort: { field: "market_cap", order: DESC }
                pagination: { page: 1, pageSize: 20 }
            ) {
                items { id symbol currentPrice }
                totalCount
            }
        }
    """
    response = client.post("/graphql", json={"query": query})
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["stocks"]["totalCount"] >= 0
```

### Performance Tests
```python
# tests/performance/test_dataloader_efficiency.py
def test_dataloader_batch_loading(db_session, query_counter):
    """Verify DataLoader reduces query count"""
    with query_counter:
        # Query 10 stocks with their sectors
        result = execute_graphql("""
            query {
                stocks(pagination: { pageSize: 10 }) {
                    items {
                        id
                        symbol
                        sector { name }
                    }
                }
            }
        """)

    # Should be 2 queries: 1 for stocks, 1 batched for sectors
    # Without DataLoader: 11 queries (1 + 10)
    assert query_counter.count <= 3
```

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| N+1 query problems in complex nested queries | Medium | High | Implement comprehensive DataLoader for all relationships, add query monitoring |
| Schema breaking changes affecting existing clients | Medium | High | Use versioning, maintain backward compatibility, gradual migration |
| Performance degradation with large datasets | Low | High | Implement pagination limits, query complexity analysis, rate limiting |
| Authentication/authorization bypass | Low | Critical | Implement field-level permissions, validate JWT tokens, audit access logs |
| Circular reference causing infinite loops | Medium | Medium | Use depth limiting, complexity calculation, max query depth enforcement |
| Memory issues with DataLoader caching | Low | Medium | Set cache TTL, implement LRU eviction, monitor memory usage |

## Performance Requirements

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Query response time (simple) | < 50ms | GraphQL query execution time |
| Query response time (complex with joins) | < 200ms | End-to-end latency monitoring |
| DataLoader batch efficiency | > 90% | Ratio of batched vs individual queries |
| Concurrent requests support | 100 req/sec | Load testing with k6/Artillery |
| Schema introspection time | < 10ms | GraphiQL schema loading time |
| Memory usage per request | < 50MB | Process memory monitoring |
| Query complexity limit | < 1000 points | Complexity calculation algorithm |

## Security Considerations

### Authentication & Authorization
```python
# middleware/auth.py
from strawberry.permission import BasePermission
from strawberry.types import Info

class IsAuthenticated(BasePermission):
    message = "User is not authenticated"

    async def has_permission(self, source, info: Info, **kwargs) -> bool:
        request = info.context["request"]
        return request.user is not None

class HasRole(BasePermission):
    def __init__(self, role: str):
        self.role = role

    async def has_permission(self, source, info: Info, **kwargs) -> bool:
        request = info.context["request"]
        return request.user and self.role in request.user.roles

# Usage in schema
@strawberry.type
class Query:
    @strawberry.field(permission_classes=[IsAuthenticated])
    async def watchlist(self, info) -> List[Stock]:
        user = info.context["request"].user
        # Return user's watchlist
        pass
```

### Query Complexity Limiting
```python
# middleware/complexity.py
from strawberry.extensions import Extension

class QueryComplexityExtension(Extension):
    MAX_COMPLEXITY = 1000

    def on_request_start(self):
        complexity = self.calculate_complexity(self.execution_context.query)
        if complexity > self.MAX_COMPLEXITY:
            raise ValueError(f"Query complexity {complexity} exceeds limit {self.MAX_COMPLEXITY}")

    def calculate_complexity(self, query):
        # Calculate based on depth, field count, list sizes
        complexity = 0
        # Implementation...
        return complexity
```

### Input Validation
```python
# Validate pagination inputs
@strawberry.input
class PaginationInput:
    page: int = 1
    page_size: int = 20

    def __post_init__(self):
        if self.page < 1:
            raise ValueError("Page must be >= 1")
        if self.page_size < 1 or self.page_size > 100:
            raise ValueError("Page size must be between 1 and 100")
```

## Error Handling

### Custom Error Types
```python
# errors.py
from strawberry import type as strawberry_type

@strawberry_type
class StockNotFoundError:
    message: str = "Stock not found"
    stock_id: int

@strawberry_type
class ValidationError:
    message: str
    field: str

# Usage in resolvers
@strawberry.field
async def stock(self, info, id: int) -> Union[Stock, StockNotFoundError]:
    stock = await info.context["stock_loader"].load(id)
    if stock is None:
        return StockNotFoundError(stock_id=id)
    return stock
```

### Global Error Handler
```python
# middleware/error_handler.py
from strawberry.extensions import Extension
import logging

logger = logging.getLogger(__name__)

class ErrorLoggingExtension(Extension):
    def on_request_end(self):
        if self.execution_context.errors:
            for error in self.execution_context.errors:
                logger.error(
                    f"GraphQL Error: {error.message}",
                    extra={
                        "path": error.path,
                        "locations": error.locations,
                        "user": getattr(self.execution_context.context.get("request"), "user", None)
                    }
                )
```

## Progress

**0% - Not started**

## Notes

### Dependencies
- strawberry-graphql[fastapi] >= 0.200.0
- fastapi >= 0.100.0
- sqlalchemy >= 2.0.0
- pydantic >= 2.0.0

### Best Practices
1. **Schema Design**
   - Use nullable fields judiciously
   - Provide comprehensive field descriptions
   - Follow naming conventions (camelCase for fields)
   - Group related fields into separate types

2. **DataLoader Pattern**
   - Always use DataLoader for 1:N and N:1 relationships
   - Set appropriate cache TTL based on data freshness requirements
   - Monitor batch efficiency metrics
   - Implement cache invalidation strategy

3. **Performance**
   - Implement pagination for all list queries
   - Set maximum page size limits
   - Use connection pattern for cursor-based pagination
   - Add query complexity analysis

4. **Documentation**
   - Document all types and fields with descriptions
   - Provide query examples in field descriptions
   - Maintain schema changelog
   - Generate schema documentation automatically

### Migration Strategy
1. Implement GraphQL schema alongside existing REST API
2. Start with read-only queries
3. Migrate frontend components gradually
4. Monitor performance and error rates
5. Deprecate REST endpoints after full migration
6. Keep REST API for backward compatibility during transition period

### Monitoring
- Track query execution times by operation name
- Monitor DataLoader hit rates
- Log slow queries (> 200ms)
- Track query complexity distribution
- Monitor error rates by query type
- Set up alerts for performance degradation
