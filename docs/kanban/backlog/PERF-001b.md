# PERF-001b: GraphQL Frontend Integration

## Metadata

| Field | Value |
|-------|-------|
| **ID** | PERF-001b |
| **Title** | Integrate GraphQL with Frontend |
| **Type** | Feature |
| **Status** | BACKLOG |
| **Priority** | P2 (Medium) |
| **Estimate** | 8 hours |
| **Sprint** | Sprint 8 |
| **Epic** | Performance & Scalability |
| **Assignee** | TBD |
| **Depends On** | PERF-001a |
| **Created** | 2025-11-29 |
| **Tags** | `graphql`, `frontend`, `apollo-client`, `caching`, `react` |
| **Blocks** | - |

## Description

Integrate Apollo Client into the React frontend to consume the GraphQL API. This implementation will replace REST API calls with GraphQL queries and mutations, implement intelligent caching strategies, optimize bundle size, and establish performance benchmarking to validate improvements over the existing REST implementation.

## Acceptance Criteria

- [ ] **Apollo Client Setup**
  - [ ] Install and configure Apollo Client
  - [ ] Setup Apollo Provider in React app
  - [ ] Configure HTTP link with authentication
  - [ ] Setup error handling and retry logic
  - [ ] Configure development tools (Apollo DevTools)
- [ ] **Main Query Migration**
  - [ ] Migrate stock listing queries
  - [ ] Migrate stock detail queries
  - [ ] Migrate screening/filtering queries
  - [ ] Migrate watchlist operations
  - [ ] Update React components to use hooks
- [ ] **Performance Comparison Benchmark**
  - [ ] Measure initial load time (REST vs GraphQL)
  - [ ] Measure query response times
  - [ ] Measure payload sizes
  - [ ] Document performance improvements
  - [ ] Create before/after comparison report
- [ ] **Caching Strategy Implementation**
  - [ ] Configure InMemoryCache with type policies
  - [ ] Implement field-level caching policies
  - [ ] Setup cache persistence (optional)
  - [ ] Implement optimistic updates
  - [ ] Configure cache eviction policies

## Subtasks

### 1. Apollo Client Setup and Configuration
- [ ] **Installation**
  - [ ] Install @apollo/client package
  - [ ] Install graphql package
  - [ ] Update package.json dependencies
  - [ ] Run npm/yarn install
- [ ] **Client Configuration**
  - [ ] Create Apollo Client instance
  - [ ] Configure HTTP Link with backend URL
  - [ ] Setup authentication headers
  - [ ] Configure error link for global error handling
  - [ ] Setup retry link for failed requests
- [ ] **Provider Setup**
  - [ ] Wrap app with ApolloProvider
  - [ ] Configure cache policies
  - [ ] Enable Apollo DevTools in development
  - [ ] Setup type generation for TypeScript

### 2. Query Migration from REST to GraphQL
- [ ] **Stock Listing Page**
  - [ ] Create GraphQL query document
  - [ ] Replace fetch/axios with useQuery hook
  - [ ] Handle loading and error states
  - [ ] Implement pagination
  - [ ] Add filter controls
- [ ] **Stock Detail Page**
  - [ ] Create stock detail query
  - [ ] Implement with useQuery hook
  - [ ] Add related data queries
  - [ ] Handle cache updates
- [ ] **Screening/Filtering**
  - [ ] Create screening query with filters
  - [ ] Implement dynamic filter updates
  - [ ] Handle complex filter combinations
  - [ ] Optimize re-query behavior
- [ ] **Watchlist Management**
  - [ ] Create watchlist queries
  - [ ] Implement add/remove mutations
  - [ ] Update cache after mutations
  - [ ] Implement optimistic updates

### 3. Performance Benchmarking
- [ ] **Setup Benchmarking Tools**
  - [ ] Install performance measurement tools
  - [ ] Create test scenarios
  - [ ] Setup metrics collection
  - [ ] Create automated benchmark scripts
- [ ] **Measure REST API Performance**
  - [ ] Initial page load time
  - [ ] Query response times
  - [ ] Network payload sizes
  - [ ] Total data transfer
- [ ] **Measure GraphQL Performance**
  - [ ] Initial page load time
  - [ ] Query response times
  - [ ] Network payload sizes
  - [ ] Cache hit rates
- [ ] **Generate Comparison Report**
  - [ ] Create performance comparison charts
  - [ ] Document improvements
  - [ ] Identify bottlenecks
  - [ ] Share results with team

### 4. Caching Strategy Implementation
- [ ] **Cache Configuration**
  - [ ] Configure type policies for entities
  - [ ] Setup normalized cache structure
  - [ ] Define merge functions for lists
  - [ ] Configure cache redirects
- [ ] **Field Policies**
  - [ ] Setup pagination field policies
  - [ ] Configure read functions
  - [ ] Implement custom merge logic
  - [ ] Add keyArgs configuration
- [ ] **Cache Updates**
  - [ ] Implement mutation cache updates
  - [ ] Setup refetch queries
  - [ ] Configure cache eviction
  - [ ] Add manual cache updates where needed
- [ ] **Optimistic Updates**
  - [ ] Implement optimistic responses
  - [ ] Handle rollback on errors
  - [ ] Add loading indicators
  - [ ] Test edge cases

## Implementation Details

### Apollo Client Setup

```typescript
// src/lib/apollo-client.ts
import { ApolloClient, InMemoryCache, HttpLink, ApolloLink, from } from '@apollo/client';
import { onError } from '@apollo/client/link/error';
import { RetryLink } from '@apollo/client/link/retry';

// HTTP Link configuration
const httpLink = new HttpLink({
  uri: process.env.REACT_APP_GRAPHQL_ENDPOINT || 'http://localhost:8000/graphql',
  credentials: 'include',
});

// Authentication link
const authLink = new ApolloLink((operation, forward) => {
  const token = localStorage.getItem('auth_token');

  operation.setContext({
    headers: {
      authorization: token ? `Bearer ${token}` : '',
      'x-client-version': process.env.REACT_APP_VERSION || '1.0.0',
    },
  });

  return forward(operation);
});

// Error handling link
const errorLink = onError(({ graphQLErrors, networkError, operation }) => {
  if (graphQLErrors) {
    graphQLErrors.forEach(({ message, locations, path, extensions }) => {
      console.error(
        `[GraphQL error]: Message: ${message}, Location: ${locations}, Path: ${path}`,
        extensions
      );

      // Handle authentication errors
      if (extensions?.code === 'UNAUTHENTICATED') {
        // Redirect to login or refresh token
        window.location.href = '/login';
      }
    });
  }

  if (networkError) {
    console.error(`[Network error]: ${networkError}`);
  }
});

// Retry link for transient failures
const retryLink = new RetryLink({
  delay: {
    initial: 300,
    max: 3000,
    jitter: true,
  },
  attempts: {
    max: 3,
    retryIf: (error, _operation) => {
      // Retry on network errors but not on GraphQL errors
      return !!error && !error.result;
    },
  },
});

// Cache configuration
const cache = new InMemoryCache({
  typePolicies: {
    Query: {
      fields: {
        stocks: {
          keyArgs: ['filters', 'sort'],
          merge(existing = { items: [] }, incoming, { args }) {
            const page = args?.pagination?.page || 1;

            // Handle pagination merge
            if (page === 1) {
              return incoming;
            }

            return {
              ...incoming,
              items: [...existing.items, ...incoming.items],
            };
          },
        },
      },
    },
    Stock: {
      fields: {
        financialMetrics: {
          merge: true,
        },
      },
    },
  },
});

// Create Apollo Client
export const apolloClient = new ApolloClient({
  link: from([errorLink, retryLink, authLink, httpLink]),
  cache,
  defaultOptions: {
    watchQuery: {
      fetchPolicy: 'cache-and-network',
      errorPolicy: 'all',
    },
    query: {
      fetchPolicy: 'cache-first',
      errorPolicy: 'all',
    },
    mutate: {
      errorPolicy: 'all',
    },
  },
  connectToDevTools: process.env.NODE_ENV === 'development',
});
```

### App Provider Setup

```tsx
// src/App.tsx
import React from 'react';
import { ApolloProvider } from '@apollo/client';
import { apolloClient } from './lib/apollo-client';
import { StockListPage } from './pages/StockListPage';

function App() {
  return (
    <ApolloProvider client={apolloClient}>
      <div className="App">
        <StockListPage />
      </div>
    </ApolloProvider>
  );
}

export default App;
```

### GraphQL Query Documents

```typescript
// src/graphql/queries.ts
import { gql } from '@apollo/client';

export const GET_STOCKS = gql`
  query GetStocks(
    $filters: StockFilterInput
    $pagination: PaginationInput
    $sort: SortInput
  ) {
    stocks(filters: $filters, pagination: $pagination, sort: $sort) {
      items {
        id
        symbol
        name
        market
        currentPrice
        changePercent
        volume
        sector {
          id
          name
        }
        industry {
          id
          name
        }
        financialMetrics {
          marketCap
          peRatio
          pbRatio
          roe
          dividendYield
        }
      }
      totalCount
      hasNextPage
      hasPreviousPage
    }
  }
`;

export const GET_STOCK_DETAIL = gql`
  query GetStockDetail($id: Int!) {
    stock(id: $id) {
      id
      symbol
      name
      market
      currentPrice
      changePercent
      volume
      updatedAt
      sector {
        id
        name
        code
      }
      industry {
        id
        name
        code
      }
      financialMetrics {
        marketCap
        peRatio
        pbRatio
        roe
        debtRatio
        dividendYield
        updatedAt
      }
    }
  }
`;

export const GET_SECTORS = gql`
  query GetSectors {
    sectors {
      id
      name
      code
      stockCount
    }
  }
`;
```

### React Component with GraphQL

```tsx
// src/pages/StockListPage.tsx
import React, { useState } from 'react';
import { useQuery } from '@apollo/client';
import { GET_STOCKS, GET_SECTORS } from '../graphql/queries';
import { StockFilterInput, PaginationInput, SortInput } from '../types/graphql';

interface StockListPageProps {}

export const StockListPage: React.FC<StockListPageProps> = () => {
  const [filters, setFilters] = useState<StockFilterInput>({});
  const [pagination, setPagination] = useState<PaginationInput>({ page: 1, pageSize: 20 });
  const [sort, setSort] = useState<SortInput>({ field: 'symbol', order: 'ASC' });

  // Stocks query
  const { data, loading, error, fetchMore } = useQuery(GET_STOCKS, {
    variables: { filters, pagination, sort },
    notifyOnNetworkStatusChange: true,
  });

  // Sectors query for filter dropdown
  const { data: sectorsData } = useQuery(GET_SECTORS);

  const handleLoadMore = () => {
    fetchMore({
      variables: {
        pagination: { ...pagination, page: pagination.page + 1 },
      },
    }).then(() => {
      setPagination(prev => ({ ...prev, page: prev.page + 1 }));
    });
  };

  const handleFilterChange = (newFilters: Partial<StockFilterInput>) => {
    setFilters(prev => ({ ...prev, ...newFilters }));
    setPagination({ page: 1, pageSize: 20 }); // Reset to page 1
  };

  if (loading && !data) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  const stocks = data?.stocks?.items || [];
  const hasMore = data?.stocks?.hasNextPage || false;

  return (
    <div className="stock-list-page">
      <h1>Stock Screener</h1>

      {/* Filters */}
      <div className="filters">
        <select
          onChange={(e) => handleFilterChange({
            sectors: e.target.value ? [parseInt(e.target.value)] : undefined
          })}
        >
          <option value="">All Sectors</option>
          {sectorsData?.sectors?.map(sector => (
            <option key={sector.id} value={sector.id}>
              {sector.name}
            </option>
          ))}
        </select>
      </div>

      {/* Stock List */}
      <div className="stock-list">
        {stocks.map(stock => (
          <div key={stock.id} className="stock-item">
            <h3>{stock.symbol} - {stock.name}</h3>
            <p>Price: ${stock.currentPrice.toFixed(2)}</p>
            <p>Change: {stock.changePercent.toFixed(2)}%</p>
            <p>Sector: {stock.sector.name}</p>
            <p>P/E Ratio: {stock.financialMetrics?.peRatio?.toFixed(2) || 'N/A'}</p>
          </div>
        ))}
      </div>

      {/* Load More */}
      {hasMore && (
        <button onClick={handleLoadMore} disabled={loading}>
          {loading ? 'Loading...' : 'Load More'}
        </button>
      )}
    </div>
  );
};
```

### Mutations with Optimistic Updates

```tsx
// src/graphql/mutations.ts
import { gql } from '@apollo/client';

export const ADD_TO_WATCHLIST = gql`
  mutation AddToWatchlist($stockId: Int!) {
    addToWatchlist(stockId: $stockId) {
      id
      stockId
      addedAt
    }
  }
`;

// Component using mutation
import { useMutation } from '@apollo/client';

function WatchlistButton({ stockId }: { stockId: number }) {
  const [addToWatchlist, { loading }] = useMutation(ADD_TO_WATCHLIST, {
    variables: { stockId },
    optimisticResponse: {
      addToWatchlist: {
        __typename: 'WatchlistItem',
        id: -1, // Temporary ID
        stockId,
        addedAt: new Date().toISOString(),
      },
    },
    update(cache, { data }) {
      // Update cache after mutation
      cache.modify({
        fields: {
          watchlist(existingItems = []) {
            const newItemRef = cache.writeFragment({
              data: data.addToWatchlist,
              fragment: gql`
                fragment NewWatchlistItem on WatchlistItem {
                  id
                  stockId
                  addedAt
                }
              `,
            });
            return [...existingItems, newItemRef];
          },
        },
      });
    },
  });

  return (
    <button onClick={() => addToWatchlist()} disabled={loading}>
      {loading ? 'Adding...' : 'Add to Watchlist'}
    </button>
  );
}
```

### TypeScript Type Generation

```json
// codegen.yml
overwrite: true
schema: "http://localhost:8000/graphql"
documents: "src/**/*.{ts,tsx}"
generates:
  src/types/graphql.ts:
    plugins:
      - "typescript"
      - "typescript-operations"
      - "typescript-react-apollo"
    config:
      withHooks: true
      withComponent: false
      withHOC: false
```

## Testing Strategy

### Unit Tests

```typescript
// src/__tests__/StockListPage.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import { MockedProvider } from '@apollo/client/testing';
import { StockListPage } from '../pages/StockListPage';
import { GET_STOCKS, GET_SECTORS } from '../graphql/queries';

const mocks = [
  {
    request: {
      query: GET_STOCKS,
      variables: {
        filters: {},
        pagination: { page: 1, pageSize: 20 },
        sort: { field: 'symbol', order: 'ASC' },
      },
    },
    result: {
      data: {
        stocks: {
          items: [
            {
              id: 1,
              symbol: 'AAPL',
              name: 'Apple Inc.',
              currentPrice: 150.0,
              changePercent: 2.5,
              sector: { id: 1, name: 'Technology' },
              industry: { id: 1, name: 'Consumer Electronics' },
              financialMetrics: { peRatio: 28.5 },
            },
          ],
          totalCount: 100,
          hasNextPage: true,
          hasPreviousPage: false,
        },
      },
    },
  },
];

test('renders stock list', async () => {
  render(
    <MockedProvider mocks={mocks} addTypename={false}>
      <StockListPage />
    </MockedProvider>
  );

  await waitFor(() => {
    expect(screen.getByText('AAPL - Apple Inc.')).toBeInTheDocument();
  });
});
```

### Integration Tests

```typescript
// src/__tests__/integration/graphql-integration.test.ts
import { apolloClient } from '../../lib/apollo-client';
import { GET_STOCKS } from '../../graphql/queries';

describe('GraphQL Integration', () => {
  it('should fetch stocks successfully', async () => {
    const result = await apolloClient.query({
      query: GET_STOCKS,
      variables: {
        pagination: { page: 1, pageSize: 10 },
      },
    });

    expect(result.data.stocks).toBeDefined();
    expect(result.data.stocks.items).toBeInstanceOf(Array);
    expect(result.data.stocks.totalCount).toBeGreaterThan(0);
  });

  it('should cache query results', async () => {
    // First query
    const result1 = await apolloClient.query({
      query: GET_STOCKS,
      variables: { pagination: { page: 1, pageSize: 10 } },
    });

    // Second query should come from cache
    const result2 = await apolloClient.query({
      query: GET_STOCKS,
      variables: { pagination: { page: 1, pageSize: 10 } },
      fetchPolicy: 'cache-first',
    });

    expect(result1.data).toEqual(result2.data);
    expect(result2.loading).toBe(false);
  });
});
```

### Performance Tests

```typescript
// src/__tests__/performance/benchmark.test.ts
import { performance } from 'perf_hooks';

describe('Performance Benchmarks', () => {
  it('should load stocks faster than REST API', async () => {
    // GraphQL query
    const graphqlStart = performance.now();
    await apolloClient.query({
      query: GET_STOCKS,
      variables: { pagination: { page: 1, pageSize: 20 } },
    });
    const graphqlEnd = performance.now();
    const graphqlTime = graphqlEnd - graphqlStart;

    console.log(`GraphQL query time: ${graphqlTime}ms`);

    // Should be faster than REST baseline (e.g., 200ms)
    expect(graphqlTime).toBeLessThan(200);
  });

  it('should have smaller payload size', async () => {
    const result = await apolloClient.query({
      query: GET_STOCKS,
      variables: { pagination: { page: 1, pageSize: 20 } },
    });

    const payloadSize = JSON.stringify(result.data).length;
    console.log(`Payload size: ${payloadSize} bytes`);

    // Should be smaller than REST equivalent
    expect(payloadSize).toBeLessThan(50000); // 50KB
  });
});
```

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking changes during migration | Medium | High | Gradual migration, feature flags, maintain REST fallback |
| Cache inconsistency issues | Medium | Medium | Implement proper cache invalidation, use normalized cache |
| Performance regression in some scenarios | Low | High | Comprehensive benchmarking, rollback plan, A/B testing |
| Bundle size increase with Apollo Client | Medium | Medium | Code splitting, lazy loading, optimize imports |
| Learning curve for team | High | Low | Provide training, documentation, pair programming sessions |
| Authentication token refresh handling | Low | High | Implement token refresh logic, proper error handling |

## Performance Requirements

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Initial page load time | < 2s | Lighthouse performance audit |
| Time to interactive | < 3s | Chrome DevTools Performance tab |
| Query response time | < 200ms | Apollo DevTools network timing |
| Cache hit rate | > 70% | Apollo Client cache monitoring |
| Bundle size increase | < 50KB | Webpack bundle analyzer |
| Memory usage | < 100MB | Chrome DevTools Memory profiler |
| Payload size reduction | > 30% | Network tab comparison with REST |

## Security Considerations

### Authentication Token Handling

```typescript
// src/lib/auth.ts
import { apolloClient } from './apollo-client';

export const refreshAuthToken = async () => {
  try {
    const response = await fetch('/auth/refresh', {
      method: 'POST',
      credentials: 'include',
    });

    const { token } = await response.json();
    localStorage.setItem('auth_token', token);

    // Reset Apollo Client to use new token
    await apolloClient.resetStore();

    return token;
  } catch (error) {
    console.error('Token refresh failed:', error);
    // Redirect to login
    window.location.href = '/login';
  }
};
```

### Secure Storage

```typescript
// Use secure storage for sensitive data
const STORAGE_KEY = 'apollo_cache_persist';

// Don't persist sensitive data
const cache = new InMemoryCache({
  typePolicies: {
    // ... type policies
  },
});

// Optional: Persist cache with encryption
import { persistCache } from 'apollo3-cache-persist';

const setupCachePersistence = async () => {
  await persistCache({
    cache,
    storage: window.localStorage,
    key: STORAGE_KEY,
    maxSize: 1048576, // 1MB
    // Filter out sensitive data
    serialize: (data) => {
      // Remove auth tokens and user PII
      const sanitized = { ...data };
      delete sanitized.user?.email;
      return JSON.stringify(sanitized);
    },
  });
};
```

### XSS Protection

```typescript
// Sanitize user inputs in GraphQL variables
import DOMPurify from 'dompurify';

const sanitizeInput = (input: string): string => {
  return DOMPurify.sanitize(input);
};

// Use in components
const [searchTerm, setSearchTerm] = useState('');

const handleSearch = (value: string) => {
  const sanitized = sanitizeInput(value);
  setSearchTerm(sanitized);
};
```

## Error Handling

### Component-Level Error Boundaries

```tsx
// src/components/GraphQLErrorBoundary.tsx
import React, { Component, ReactNode } from 'react';
import { ApolloError } from '@apollo/client';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error?: ApolloError;
}

export class GraphQLErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error: error as ApolloError };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('GraphQL Error caught by boundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-container">
          <h2>Something went wrong</h2>
          <p>{this.state.error?.message || 'Unknown error occurred'}</p>
          <button onClick={() => this.setState({ hasError: false })}>
            Try again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

### Query Error Handling

```tsx
// src/hooks/useStocksQuery.ts
import { useQuery } from '@apollo/client';
import { GET_STOCKS } from '../graphql/queries';
import { toast } from 'react-toastify';

export const useStocksQuery = (variables: any) => {
  return useQuery(GET_STOCKS, {
    variables,
    onError: (error) => {
      // User-friendly error messages
      if (error.networkError) {
        toast.error('Network error. Please check your connection.');
      } else if (error.graphQLErrors.length > 0) {
        const message = error.graphQLErrors[0].message;
        toast.error(`Error: ${message}`);
      } else {
        toast.error('An unexpected error occurred.');
      }
    },
  });
};
```

## Progress

**0% - Not started**

## Notes

### Dependencies
- @apollo/client >= 3.8.0
- graphql >= 16.0.0
- @graphql-codegen/cli >= 5.0.0
- @graphql-codegen/typescript >= 4.0.0
- @graphql-codegen/typescript-operations >= 4.0.0
- @graphql-codegen/typescript-react-apollo >= 4.0.0

### Best Practices

1. **Query Organization**
   - Keep query documents in separate files
   - Use fragments for reusable fields
   - Organize by feature/domain
   - Generate TypeScript types automatically

2. **Caching Strategy**
   - Use normalized cache for entities
   - Implement field policies for lists
   - Configure proper cache invalidation
   - Use optimistic updates for better UX

3. **Performance Optimization**
   - Implement code splitting for Apollo Client
   - Use lazy queries where appropriate
   - Minimize query overfetching
   - Monitor bundle size impact

4. **Error Handling**
   - Implement global error link
   - Show user-friendly error messages
   - Log errors for debugging
   - Handle authentication errors gracefully

### Migration Checklist

- [ ] Setup Apollo Client infrastructure
- [ ] Generate TypeScript types from schema
- [ ] Migrate one page as proof of concept
- [ ] Run performance benchmarks
- [ ] Train team on Apollo Client usage
- [ ] Migrate remaining pages incrementally
- [ ] Update documentation
- [ ] Remove REST API calls
- [ ] Monitor production metrics

### Performance Benchmarking Plan

1. **Baseline Measurements (REST API)**
   - Initial load time
   - Time to interactive
   - Network waterfall
   - Total payload size
   - Number of requests

2. **GraphQL Measurements**
   - Same metrics as baseline
   - Cache hit/miss rates
   - Query execution times
   - Bundle size impact

3. **Comparison Report**
   - Side-by-side metrics
   - Percentage improvements
   - Identified bottlenecks
   - Recommendations

### Monitoring and Observability

- Use Apollo Studio for production monitoring
- Track query performance metrics
- Monitor cache hit rates
- Set up error rate alerts
- Track client-side performance
- Monitor bundle size over time
