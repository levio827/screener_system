# Stock Screening Platform API Documentation

## Overview

This directory contains the OpenAPI 3.0 specification for the Stock Screening Platform REST API.

**Base URL**: `https://api.screener.kr/v1`

## Quick Start

### 1. View API Documentation

**Option A: Swagger UI (Recommended)**

```bash
# Install swagger-ui-watcher (Node.js required)
npm install -g swagger-ui-watcher

# Serve the API documentation
swagger-ui-watcher openapi.yaml
```

Then open http://localhost:8000 in your browser.

**Option B: Redoc**

```bash
# Install redoc-cli
npm install -g redoc-cli

# Generate static HTML
redoc-cli bundle openapi.yaml -o api-docs.html

# Open in browser
open api-docs.html
```

**Option C: Online Swagger Editor**

Visit [https://editor.swagger.io](https://editor.swagger.io) and paste the contents of `openapi.yaml`.

### 2. Test API Endpoints

**Using curl**:

```bash
# Register a new user
curl -X POST https://api.screener.kr/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'

# Login and get token
TOKEN=$(curl -X POST https://api.screener.kr/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}' \
  | jq -r '.access_token')

# Use token to access protected endpoints
curl -X GET https://api.screener.kr/v1/users/me \
  -H "Authorization: Bearer $TOKEN"
```

**Using httpie**:

```bash
# More readable than curl
http POST https://api.screener.kr/v1/auth/login \
  email=test@example.com \
  password=password123

# With token
http GET https://api.screener.kr/v1/portfolios \
  Authorization:"Bearer $TOKEN"
```

**Using Postman**:

1. Import `openapi.yaml` into Postman
2. All endpoints will be auto-configured
3. Set up environment variable for `access_token`

## API Structure

### Authentication Flow

```
1. Register: POST /auth/register
   → Returns access_token + refresh_token

2. Login: POST /auth/login
   → Returns access_token (15min) + refresh_token (30 days)

3. Use access_token in header:
   Authorization: Bearer <access_token>

4. When access_token expires:
   POST /auth/refresh with refresh_token
   → Get new access_token

5. Logout: POST /auth/logout
   → Revokes refresh_token
```

### Endpoint Categories

| Category | Description | Auth Required |
|----------|-------------|---------------|
| **Authentication** | Register, login, token refresh | No |
| **Stocks** | Stock information, prices, financials | No |
| **Screening** | Filter stocks with custom criteria | No |
| **Market** | Market overview, hot stocks, movers | No |
| **Portfolios** | Create and manage portfolios | Yes |
| **Alerts** | Price/volume alerts | Yes |
| **Users** | User profile management | Yes |
| **Watchlists** | Save stocks for monitoring | Yes |

### Rate Limiting

| Tier | Requests/Minute | Daily Limit |
|------|-----------------|-------------|
| **Free** | 100 | 10,000 |
| **Basic** | 500 | 50,000 |
| **Pro** | 2,000 | Unlimited |

Rate limit headers are included in all responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1699999999
```

## Example Workflows

### Workflow 1: Stock Screening

```bash
# 1. Screen for high-dividend stocks
curl -X POST https://api.screener.kr/v1/screen \
  -H "Content-Type: application/json" \
  -d '{
    "market": "KOSPI",
    "filters": {
      "dividend_yield": {"min": 3.0},
      "quality_score": {"min": 70},
      "debt_to_equity": {"max": 100}
    },
    "sort_by": "dividend_yield",
    "order": "desc",
    "per_page": 20
  }'

# 2. View stock details
curl -X GET https://api.screener.kr/v1/stocks/005930

# 3. Get historical prices
curl -X GET "https://api.screener.kr/v1/stocks/005930/prices?from_date=2024-01-01&to_date=2024-12-31"

# 4. View financial statements
curl -X GET "https://api.screener.kr/v1/stocks/005930/financials?period_type=quarterly&years=5"
```

### Workflow 2: Portfolio Management

```bash
# 1. Login and get token
TOKEN=$(curl -s -X POST https://api.screener.kr/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}' \
  | jq -r '.access_token')

# 2. Create portfolio
PORTFOLIO_ID=$(curl -s -X POST https://api.screener.kr/v1/portfolios \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Growth Portfolio","description":"High-growth tech stocks"}' \
  | jq -r '.id')

# 3. Add holdings
curl -X POST https://api.screener.kr/v1/portfolios/$PORTFOLIO_ID/holdings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "stock_code": "005930",
    "quantity": 10,
    "avg_price": 68000,
    "purchase_date": "2024-09-10"
  }'

# 4. View portfolio performance
curl -X GET https://api.screener.kr/v1/portfolios/$PORTFOLIO_ID \
  -H "Authorization: Bearer $TOKEN"
```

### Workflow 3: Alerts

```bash
# 1. Create price alert
curl -X POST https://api.screener.kr/v1/alerts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "stock_code": "005930",
    "alert_type": "price",
    "condition": "above",
    "threshold_value": 75000,
    "notify_via": ["email", "push"]
  }'

# 2. List active alerts
curl -X GET "https://api.screener.kr/v1/alerts?is_active=true" \
  -H "Authorization: Bearer $TOKEN"
```

## Response Format

### Success Response

```json
{
  "stocks": [...],
  "meta": {
    "page": 1,
    "per_page": 50,
    "total": 1234,
    "pages": 25
  },
  "query_time_ms": 234
}
```

### Error Response

```json
{
  "error": "VALIDATION_ERROR",
  "message": "Invalid request parameters",
  "details": {
    "per": ["must be greater than 0"]
  }
}
```

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 204 | No Content | Request successful, no body returned (e.g., DELETE) |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Authentication required or token expired |
| 403 | Forbidden | Insufficient permissions (e.g., feature not in tier) |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource already exists (e.g., email taken) |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

## Client Libraries

### Python (using httpx)

```python
import httpx
from typing import Optional

class ScreenerAPI:
    def __init__(self, base_url: str = "https://api.screener.kr/v1"):
        self.base_url = base_url
        self.client = httpx.Client()
        self.access_token: Optional[str] = None

    def login(self, email: str, password: str):
        response = self.client.post(
            f"{self.base_url}/auth/login",
            json={"email": email, "password": password}
        )
        response.raise_for_status()
        data = response.json()
        self.access_token = data["access_token"]
        return data

    def screen_stocks(self, filters: dict, sort_by: str = "market_cap"):
        response = self.client.post(
            f"{self.base_url}/screen",
            json={
                "filters": filters,
                "sort_by": sort_by,
                "order": "desc"
            }
        )
        response.raise_for_status()
        return response.json()

    def get_stock(self, stock_code: str):
        response = self.client.get(f"{self.base_url}/stocks/{stock_code}")
        response.raise_for_status()
        return response.json()

    def create_portfolio(self, name: str, description: str = None):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        response = self.client.post(
            f"{self.base_url}/portfolios",
            headers=headers,
            json={"name": name, "description": description}
        )
        response.raise_for_status()
        return response.json()

# Usage
api = ScreenerAPI()
api.login("user@example.com", "password123")

# Screen for value stocks
results = api.screen_stocks({
    "per": {"max": 15},
    "pbr": {"max": 1.5},
    "roe": {"min": 10}
})

print(f"Found {results['meta']['total']} stocks")
for stock in results['stocks']:
    print(f"{stock['name']}: PER={stock['indicators']['per']}")
```

### JavaScript/TypeScript (using axios)

```typescript
import axios, { AxiosInstance } from 'axios';

class ScreenerAPI {
  private client: AxiosInstance;
  private accessToken: string | null = null;

  constructor(baseURL: string = 'https://api.screener.kr/v1') {
    this.client = axios.create({ baseURL });
  }

  async login(email: string, password: string) {
    const response = await this.client.post('/auth/login', { email, password });
    this.accessToken = response.data.access_token;
    return response.data;
  }

  async screenStocks(filters: any, sortBy: string = 'market_cap') {
    const response = await this.client.post('/screen', {
      filters,
      sort_by: sortBy,
      order: 'desc'
    });
    return response.data;
  }

  async getStock(stockCode: string) {
    const response = await this.client.get(`/stocks/${stockCode}`);
    return response.data;
  }

  async getPortfolios() {
    const response = await this.client.get('/portfolios', {
      headers: { Authorization: `Bearer ${this.accessToken}` }
    });
    return response.data;
  }
}

// Usage
const api = new ScreenerAPI();
await api.login('user@example.com', 'password123');

const results = await api.screenStocks({
  dividend_yield: { min: 3.0 },
  quality_score: { min: 70 }
}, 'dividend_yield');

console.log(`Found ${results.meta.total} stocks`);
```

## Testing

### Unit Tests

```bash
# Install pytest and httpx
pip install pytest httpx

# Run API tests
pytest tests/api/
```

### Integration Tests

```bash
# Run full integration test suite
pytest tests/integration/ --base-url=https://api-staging.screener.kr/v1
```

### Load Testing

```bash
# Install k6 (https://k6.io)
brew install k6

# Run load test
k6 run tests/load/screening_load_test.js
```

Example k6 script:
```javascript
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  vus: 100, // 100 virtual users
  duration: '30s'
};

export default function() {
  let response = http.post('https://api.screener.kr/v1/screen', JSON.stringify({
    market: 'KOSPI',
    filters: { per: { max: 15 } }
  }), {
    headers: { 'Content-Type': 'application/json' }
  });

  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500
  });
}
```

## Changelog

### Version 1.0.0 (2024-11-09)

- Initial API release
- Stock screening with 200+ indicators
- Portfolio management
- Alerts system
- Market overview endpoints

---

## Support

- **API Issues**: https://github.com/screener/api/issues
- **Email**: api-support@screener.kr
- **Documentation**: https://docs.screener.kr/api
- **Status Page**: https://status.screener.kr

## License

Proprietary - All rights reserved. See [Terms of Service](https://screener.kr/terms).
