# Software Requirements Specification (SRS)
# Stock Screening Platform

## Document Control

| Item | Details |
|------|---------|
| **Project Name** | Stock Screening Platform |
| **Document Version** | 1.0 |
| **Status** | Draft |
| **Created Date** | 2025-11-09 |
| **Last Updated** | 2025-11-09 |
| **Authors** | Engineering Team |
| **Reviewers** | Product Team, QA Team |
| **Classification** | Internal - Confidential |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [Specific Requirements](#3-specific-requirements)
4. [External Interface Requirements](#4-external-interface-requirements)
5. [System Features](#5-system-features)
6. [Non-Functional Requirements](#6-non-functional-requirements)
7. [Other Requirements](#7-other-requirements)
8. [Appendices](#8-appendices)

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification (SRS) document provides a complete description of all functions and requirements of the Stock Screening Platform. It is intended for:

- **Development Team**: To understand implementation requirements
- **QA Team**: To develop test plans and cases
- **Project Management**: To track progress against requirements
- **Stakeholders**: To verify system meets business needs

### 1.2 Scope

**Product Name**: Stock Screening Platform ("The Screener")

**Product Scope**: A web-based stock analysis and screening platform for Korean equity markets (KOSPI/KOSDAQ) providing:

- Advanced stock filtering using 200+ financial and technical indicators
- Real-time market data and analytics
- Portfolio tracking and performance monitoring
- Price and volume alert notifications
- Comprehensive financial statement analysis

**Benefits**:
- Reduce stock research time from hours to minutes
- Enable data-driven investment decisions
- Democratize access to institutional-quality analytics
- Improve investment returns through better stock selection

**Goals**:
- Achieve < 500ms screening query response time
- Support 10,000+ concurrent users
- Provide 99.9% system uptime
- Process 2,400+ stocks with 200+ indicators daily

### 1.3 Definitions, Acronyms, and Abbreviations

| Term | Definition |
|------|------------|
| **KOSPI** | Korea Composite Stock Price Index (main market) |
| **KOSDAQ** | Korean Securities Dealers Automated Quotations (tech-focused market) |
| **OHLCV** | Open, High, Low, Close, Volume (price data format) |
| **PER** | Price-to-Earnings Ratio |
| **PBR** | Price-to-Book Ratio |
| **ROE** | Return on Equity |
| **JWT** | JSON Web Token (authentication method) |
| **API** | Application Programming Interface |
| **SPA** | Single Page Application |
| **CRUD** | Create, Read, Update, Delete operations |
| **TTL** | Time To Live (cache expiration) |
| **DAG** | Directed Acyclic Graph (Airflow workflow) |
| **MVP** | Minimum Viable Product |
| **KRX** | Korea Exchange |

### 1.4 References

- [Product Requirements Document (PRD)](PRD.md)
- [OpenAPI Specification](../api/openapi.yaml)
- [Database Schema Documentation](../database/README.md)
- [Data Pipeline Documentation](../data_pipeline/README.md)
- IEEE Std 830-1998: IEEE Recommended Practice for Software Requirements Specifications

### 1.5 Overview

This document is organized as follows:
- **Section 2**: Overall system description and context
- **Section 3**: Specific functional requirements
- **Section 4**: External interface requirements
- **Section 5**: Detailed system features
- **Section 6**: Non-functional requirements (performance, security, etc.)
- **Section 7**: Other requirements (legal, regulatory, etc.)

---

## 2. Overall Description

### 2.1 Product Perspective

The Stock Screening Platform is a new, self-contained web application that integrates with external data sources:

```
┌─────────────────────────────────────────────────────────────┐
│                        End Users                             │
│              (Web Browser - Desktop/Mobile)                  │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS
                         ▼
┌─────────────────────────────────────────────────────────────┐
│               Stock Screening Platform                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Frontend    │  │   Backend    │  │   Database   │      │
│  │  (React)     │──│   (FastAPI)  │──│ (PostgreSQL) │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                           │                                  │
│                    ┌──────┴──────┐                          │
│                    ▼             ▼                           │
│           ┌──────────────┐  ┌──────────────┐               │
│           │  Data        │  │  Cache       │               │
│           │  Pipeline    │  │  (Redis)     │               │
│           │  (Airflow)   │  └──────────────┘               │
│           └──────────────┘                                  │
└────────────────┬────────────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        ▼                 ▼
┌──────────────┐   ┌──────────────┐
│  KRX API     │   │  F&Guide API │
│  (Prices)    │   │  (Financials)│
└──────────────┘   └──────────────┘
```

**System Interfaces**:
- **Web Browser**: Primary user interface (Chrome, Safari, Firefox, Edge)
- **KRX API**: Real-time/delayed stock price data
- **F&Guide API**: Financial statement and earnings data
- **SMTP Server**: Email notifications for alerts
- **Payment Gateway**: Subscription payment processing (Stripe/Toss)

**Hardware Interfaces**:
- **Server**: Cloud-based infrastructure (AWS/GCP/Naver Cloud)
- **Database**: PostgreSQL with TimescaleDB extension
- **Cache**: Redis cluster for high-performance caching

**Software Interfaces**:
- **Operating System**: Linux (Ubuntu 22.04 LTS or later)
- **Web Server**: NGINX (reverse proxy)
- **Container Runtime**: Docker 24+
- **Orchestration**: Kubernetes 1.29+

### 2.2 Product Functions

**Major Functions**:

1. **Stock Screening**
   - Filter stocks using multiple criteria across 200+ indicators
   - Save and reuse custom screening configurations
   - Use pre-built templates (dividend, value, growth, quality)
   - Export screening results to CSV/Excel

2. **Stock Analysis**
   - View detailed stock information (price, financials, indicators)
   - Display interactive price charts with multiple timeframes
   - Show 5-year financial statement history
   - Compare stock with industry peers

3. **Market Insights**
   - Display real-time market overview (KOSPI/KOSDAQ indices)
   - Identify hot stocks (volume surge detection)
   - Show top gainers/losers by timeframe
   - Track sector performance

4. **Portfolio Management**
   - Create and manage multiple portfolios
   - Track holdings with purchase price and quantity
   - Calculate unrealized gains/losses
   - Compare portfolio performance vs KOSPI benchmark

5. **Alerts & Notifications**
   - Set price alerts (above/below threshold)
   - Configure volume surge alerts
   - Receive notifications via email/push
   - Manage active alerts

6. **User Management**
   - Register with email/password or OAuth (Kakao, Naver, Google)
   - Manage user profile and preferences
   - Subscribe to paid tiers (Basic, Pro)
   - View subscription and billing history

### 2.3 User Classes and Characteristics

**User Class 1: Novice Investor**
- **Characteristics**: Limited investment experience (< 1 year), needs guidance
- **Technical Expertise**: Low (basic web browsing)
- **Frequency of Use**: Weekly
- **Priority**: High (target demographic)
- **Functions Used**: Pre-built templates, stock details, watchlists

**User Class 2: Active Trader**
- **Characteristics**: Frequent trading, seeks short-term opportunities
- **Technical Expertise**: Medium
- **Frequency of Use**: Daily (multiple times)
- **Priority**: High (high engagement)
- **Functions Used**: Hot stocks, custom screening, alerts

**User Class 3: Value Investor**
- **Characteristics**: Long-term focus, fundamental analysis
- **Technical Expertise**: High (understands financial metrics)
- **Frequency of Use**: Weekly
- **Priority**: Medium
- **Functions Used**: Advanced screening, financial statements, peer comparison

**User Class 4: Administrator**
- **Characteristics**: System operator, data quality monitor
- **Technical Expertise**: Very High
- **Frequency of Use**: Daily
- **Priority**: Critical (system maintenance)
- **Functions Used**: Data pipeline monitoring, user management, system health

### 2.4 Operating Environment

**Client-Side**:
- **Web Browsers**: Chrome 100+, Safari 15+, Firefox 100+, Edge 100+
- **Screen Resolutions**: 360px width minimum (mobile) to 4K displays
- **JavaScript**: ES2020+ support required
- **Storage**: 50MB minimum for cached data

**Server-Side**:
- **Operating System**: Ubuntu 22.04 LTS or compatible Linux distribution
- **Python**: 3.11 or later
- **Node.js**: 18 LTS or later (for frontend build)
- **Database**: PostgreSQL 16+ with TimescaleDB 2.14+
- **Cache**: Redis 7+
- **Container Runtime**: Docker 24+ / Kubernetes 1.29+

**Network**:
- **Bandwidth**: 100 Mbps minimum (server-side)
- **Latency**: < 50ms to database (same region deployment)
- **Firewall**: Ports 80 (HTTP), 443 (HTTPS), 5432 (PostgreSQL), 6379 (Redis)

### 2.5 Design and Implementation Constraints

**Regulatory Constraints**:
- **Data Licensing**: Must comply with KRX and F&Guide data usage terms
- **Investment Disclaimer**: Display disclaimer on all pages with financial data
- **Privacy Compliance**: GDPR and PIPA (Personal Information Protection Act) compliance
- **Financial Regulations**: Cannot provide personalized investment advice

**Technical Constraints**:
- **Database**: Must use PostgreSQL for ACID compliance and TimescaleDB for time-series optimization
- **Authentication**: Must use JWT for stateless authentication
- **Data Freshness**: Price data must be updated within 30 minutes of market close
- **Browser Support**: Must support last 2 major versions of mainstream browsers

**Business Constraints**:
- **Budget**: Limited to $50K development budget (MVP phase)
- **Timeline**: MVP must launch within 12 weeks
- **Team Size**: Maximum 5 developers (2 frontend, 2 backend, 1 DevOps)
- **Third-Party Costs**: API costs must not exceed $2K/month

**Performance Constraints**:
- **Response Time**: API calls must complete in < 200ms (p95)
- **Screening Query**: Must return results in < 500ms (p99)
- **Concurrent Users**: Must support 10,000 concurrent users without degradation
- **Database Size**: Must efficiently handle 10+ years of historical data

### 2.6 Assumptions and Dependencies

**Assumptions**:
1. Users have stable internet connection (minimum 1 Mbps)
2. Users have modern web browsers with JavaScript enabled
3. KRX and F&Guide APIs remain available and pricing stable
4. Korean market structure (KOSPI/KOSDAQ) remains consistent
5. PostgreSQL and TimescaleDB continue to be actively maintained

**Dependencies**:
1. **External APIs**:
   - KRX API for stock price data (critical dependency)
   - F&Guide API for financial statements (critical dependency)
   - OAuth providers (Kakao, Naver, Google) for social login

2. **Third-Party Services**:
   - Stripe/Toss for payment processing
   - SMTP service (Gmail, SendGrid) for email notifications
   - Cloud provider (AWS/GCP/Naver Cloud) for infrastructure

3. **Open Source Libraries**:
   - React, FastAPI, PostgreSQL, Redis, Airflow (see package.json, requirements.txt)
   - Security updates must be applied promptly

4. **Data Availability**:
   - Daily price data available by 18:00 KST
   - Quarterly financial statements within 45 days of quarter end
   - Annual reports within 90 days of fiscal year end

---

## 3. Specific Requirements

### 3.1 Functional Requirements

#### 3.1.1 User Authentication & Authorization

**REQ-AUTH-001: User Registration**
- **Description**: System shall allow users to register with email and password
- **Priority**: Critical
- **Inputs**: Email address, password (min 8 characters), name
- **Processing**:
  - Validate email format and uniqueness
  - Hash password using bcrypt (cost factor 12)
  - Send email verification link
  - Create user record in database
- **Outputs**: User account created, verification email sent
- **Error Handling**: Return error if email already exists or password too weak
- **Performance**: Registration must complete in < 2 seconds

**REQ-AUTH-002: Email Verification**
- **Description**: System shall verify user email addresses
- **Priority**: Critical
- **Inputs**: Verification token from email link
- **Processing**: Validate token, mark email as verified
- **Outputs**: Account activated, user can login
- **Error Handling**: Return error if token expired (24 hours) or invalid

**REQ-AUTH-003: User Login**
- **Description**: System shall authenticate users with email/password
- **Priority**: Critical
- **Inputs**: Email, password
- **Processing**:
  - Verify credentials against database
  - Generate JWT access token (15-minute expiry)
  - Generate refresh token (30-day expiry)
  - Log login event
- **Outputs**: Access token, refresh token, user profile
- **Error Handling**: Return 401 Unauthorized if credentials invalid, implement rate limiting (5 attempts/15 minutes)

**REQ-AUTH-004: OAuth Login**
- **Description**: System shall support OAuth login (Kakao, Naver, Google)
- **Priority**: High
- **Inputs**: OAuth provider, authorization code
- **Processing**: Exchange code for access token, fetch user profile, create/update user
- **Outputs**: JWT tokens, user profile
- **Error Handling**: Handle OAuth errors gracefully with user-friendly messages

**REQ-AUTH-005: Token Refresh**
- **Description**: System shall refresh expired access tokens
- **Priority**: Critical
- **Inputs**: Valid refresh token
- **Processing**: Validate refresh token, issue new access token
- **Outputs**: New access token
- **Error Handling**: Return 401 if refresh token invalid/revoked

**REQ-AUTH-006: Logout**
- **Description**: System shall revoke refresh tokens on logout
- **Priority**: Medium
- **Inputs**: Refresh token
- **Processing**: Revoke token in database
- **Outputs**: Success confirmation
- **Error Handling**: None (logout always succeeds)

**REQ-AUTH-007: Password Reset**
- **Description**: System shall allow password reset via email
- **Priority**: High
- **Inputs**: Email address
- **Processing**: Generate reset token, send email with reset link
- **Outputs**: Email sent confirmation
- **Error Handling**: Don't reveal if email exists (security)

**REQ-AUTH-008: Role-Based Access Control**
- **Description**: System shall enforce subscription tier permissions
- **Priority**: Critical
- **Inputs**: User subscription tier (free, basic, pro)
- **Processing**: Check permissions before allowing access to features
- **Outputs**: Access granted or 403 Forbidden
- **Error Handling**: Return clear message about required tier

#### 3.1.2 Stock Data Management

**REQ-STOCK-001: Stock Listing**
- **Description**: System shall provide paginated list of all stocks
- **Priority**: Critical
- **Inputs**: Market filter (KOSPI/KOSDAQ/ALL), sector filter, page, per_page
- **Processing**: Query stocks table with filters, apply pagination
- **Outputs**: Array of stocks with basic info, pagination metadata
- **Performance**: < 100ms response time
- **Error Handling**: Return empty array if no matches

**REQ-STOCK-002: Stock Detail**
- **Description**: System shall provide detailed information for individual stocks
- **Priority**: Critical
- **Inputs**: Stock code (6 digits)
- **Processing**:
  - Fetch stock from database
  - Retrieve latest price from daily_prices
  - Retrieve latest indicators from calculated_indicators
  - Aggregate data into response
- **Outputs**: Stock details with current price and indicators
- **Performance**: < 150ms response time
- **Error Handling**: Return 404 if stock code not found

**REQ-STOCK-003: Historical Prices**
- **Description**: System shall provide historical OHLCV data
- **Priority**: High
- **Inputs**: Stock code, from_date, to_date, interval (daily/weekly/monthly)
- **Processing**:
  - Validate date range (max 10 years)
  - Query daily_prices or aggregated views
  - Format data for charting
- **Outputs**: Array of price data points
- **Performance**: < 300ms for 1 year daily data
- **Error Handling**: Return error if date range invalid

**REQ-STOCK-004: Financial Statements**
- **Description**: System shall provide financial statement history
- **Priority**: High
- **Inputs**: Stock code, period_type (quarterly/annual), years (default 5)
- **Processing**: Query financial_statements table, order by fiscal_year DESC
- **Outputs**: Array of financial statements
- **Performance**: < 200ms
- **Error Handling**: Return empty array if no data available

**REQ-STOCK-005: Stock Search**
- **Description**: System shall support fuzzy search by stock name or code
- **Priority**: High
- **Inputs**: Search query string
- **Processing**: Use trigram similarity search (pg_trgm), return top 10 matches
- **Outputs**: Array of matching stocks
- **Performance**: < 100ms autocomplete response
- **Error Handling**: Return empty array if no matches

#### 3.1.3 Stock Screening

**REQ-SCREEN-001: Basic Screening**
- **Description**: System shall filter stocks using custom criteria
- **Priority**: Critical
- **Inputs**:
  - Market (KOSPI/KOSDAQ/ALL)
  - Filters object (key-value pairs with min/max)
  - Sort field and order
  - Pagination parameters
- **Processing**:
  - Query stock_screening_view (materialized view)
  - Apply filters dynamically
  - Sort results
  - Paginate
- **Outputs**: Filtered stock list with metadata
- **Performance**: < 500ms (p99) for complex queries
- **Error Handling**: Return error if invalid filter field

**REQ-SCREEN-002: Template-Based Screening**
- **Description**: System shall provide pre-built screening templates
- **Priority**: High
- **Inputs**: Template ID or category
- **Processing**: Load template filter configuration, execute screening
- **Outputs**: Template info and screening results
- **Performance**: Same as REQ-SCREEN-001
- **Error Handling**: Return 404 if template not found

**REQ-SCREEN-003: Custom Screen Saving**
- **Description**: Authenticated users shall save custom screening criteria
- **Priority**: Medium
- **Inputs**: Screen name, filter configuration
- **Processing**: Store in saved_screens table
- **Outputs**: Saved screen confirmation
- **Error Handling**: Prevent duplicate names for same user

**REQ-SCREEN-004: Screening Results Export**
- **Description**: Premium users shall export results to CSV/Excel
- **Priority**: Medium
- **Inputs**: Screening results
- **Processing**: Convert to CSV/XLSX format
- **Outputs**: Downloadable file
- **Performance**: < 2 seconds for 1000 rows
- **Error Handling**: Limit to 5000 rows to prevent abuse

#### 3.1.4 Market Insights

**REQ-MARKET-001: Market Overview**
- **Description**: System shall display current market statistics
- **Priority**: High
- **Inputs**: None (current date implied)
- **Processing**: Execute get_market_overview() database function
- **Outputs**: KOSPI and KOSDAQ statistics (advancers, decliners, volume, etc.)
- **Performance**: < 100ms (cached for 5 minutes)
- **Error Handling**: Return last known good data if calculation fails

**REQ-MARKET-002: Hot Stocks Detection**
- **Description**: System shall identify stocks with significant volume surge
- **Priority**: High
- **Inputs**: Minimum surge percentage (default 150%), limit (default 20)
- **Processing**: Execute get_hot_stocks() database function
- **Outputs**: Array of hot stocks with volume metrics
- **Performance**: < 200ms (cached for 5 minutes during market hours)
- **Error Handling**: Return empty array if market closed

**REQ-MARKET-003: Top Movers**
- **Description**: System shall show top gainers/losers by timeframe
- **Priority**: High
- **Inputs**: Type (gainers/losers), period (1d/1w/1m/etc.), limit
- **Processing**: Execute get_top_movers() database function
- **Outputs**: Ranked list of stocks by price change
- **Performance**: < 150ms (cached for 5 minutes)
- **Error Handling**: Return error if invalid period

**REQ-MARKET-004: Sector Performance**
- **Description**: System shall display sector-level performance
- **Priority**: Medium
- **Inputs**: None
- **Processing**: Query sector_performance materialized view
- **Outputs**: Sector statistics with price changes
- **Performance**: < 100ms
- **Error Handling**: None

#### 3.1.5 Portfolio Management

**REQ-PORT-001: Create Portfolio**
- **Description**: Authenticated users shall create portfolios
- **Priority**: High
- **Inputs**: Portfolio name, description (optional)
- **Processing**: Insert into portfolios table
- **Outputs**: Created portfolio object
- **Error Handling**: Prevent duplicate names for same user, enforce tier limits (Free: 1, Basic: 3, Pro: unlimited)

**REQ-PORT-002: List Portfolios**
- **Description**: Users shall view their portfolios
- **Priority**: High
- **Inputs**: User authentication
- **Processing**: Query portfolios for current user
- **Outputs**: Array of user's portfolios
- **Performance**: < 100ms
- **Error Handling**: Return empty array if no portfolios

**REQ-PORT-003: Portfolio Detail**
- **Description**: System shall show portfolio with holdings and performance
- **Priority**: High
- **Inputs**: Portfolio ID
- **Processing**:
  - Execute calculate_portfolio_value() function
  - Fetch holdings with current prices
  - Calculate gains/losses
- **Outputs**: Portfolio details with performance metrics
- **Performance**: < 200ms
- **Error Handling**: Return 404 if portfolio not found or unauthorized

**REQ-PORT-004: Add Holding**
- **Description**: Users shall add stocks to portfolio
- **Priority**: High
- **Inputs**: Portfolio ID, stock code, quantity, average price, purchase date
- **Processing**: Insert into portfolio_holdings
- **Outputs**: Created holding object
- **Error Handling**: Prevent duplicate stocks in same portfolio (update quantity instead)

**REQ-PORT-005: Update Holding**
- **Description**: Users shall modify holding details
- **Priority**: Medium
- **Inputs**: Holding ID, updated fields
- **Processing**: Update portfolio_holdings record
- **Outputs**: Updated holding object
- **Error Handling**: Return 404 if holding not found

**REQ-PORT-006: Delete Holding**
- **Description**: Users shall remove stocks from portfolio
- **Priority**: Medium
- **Inputs**: Holding ID
- **Processing**: Delete from portfolio_holdings
- **Outputs**: Success confirmation
- **Error Handling**: Return 404 if not found

**REQ-PORT-007: Portfolio Performance**
- **Description**: System shall calculate portfolio vs benchmark performance
- **Priority**: Medium
- **Inputs**: Portfolio ID, comparison index (KOSPI/KOSDAQ)
- **Processing**: Calculate portfolio returns, fetch index returns, compute relative performance
- **Outputs**: Performance comparison data
- **Performance**: < 300ms
- **Error Handling**: Handle missing index data gracefully

#### 3.1.6 Alerts & Notifications

**REQ-ALERT-001: Create Price Alert**
- **Description**: Users shall create price alerts
- **Priority**: High
- **Inputs**: Stock code, condition (above/below), threshold value, notification channels
- **Processing**: Insert into alerts table
- **Outputs**: Created alert object
- **Error Handling**: Enforce tier limits (Free: 3, Basic: 10, Pro: unlimited)

**REQ-ALERT-002: Create Volume Alert**
- **Description**: Users shall create volume surge alerts
- **Priority**: Medium
- **Inputs**: Stock code, surge percentage threshold
- **Processing**: Insert into alerts table
- **Outputs**: Created alert object
- **Error Handling**: Same as REQ-ALERT-001

**REQ-ALERT-003: List Alerts**
- **Description**: Users shall view their active alerts
- **Priority**: High
- **Inputs**: User authentication, filter (active/triggered/all)
- **Processing**: Query alerts table
- **Outputs**: Array of user's alerts
- **Performance**: < 100ms
- **Error Handling**: None

**REQ-ALERT-004: Delete Alert**
- **Description**: Users shall delete alerts
- **Priority**: High
- **Inputs**: Alert ID
- **Processing**: Delete from alerts table
- **Outputs**: Success confirmation
- **Error Handling**: Return 404 if not found or unauthorized

**REQ-ALERT-005: Alert Checking**
- **Description**: System shall check alerts every 5 minutes during market hours
- **Priority**: Critical
- **Inputs**: None (automated process)
- **Processing**: Execute check_price_alerts() function, trigger notifications
- **Outputs**: Triggered alerts logged
- **Performance**: Must complete within 5 minutes for all alerts
- **Error Handling**: Retry failed notifications up to 3 times

**REQ-ALERT-006: Email Notifications**
- **Description**: System shall send email notifications for triggered alerts
- **Priority**: High
- **Inputs**: Alert data, user email
- **Processing**: Format email template, send via SMTP
- **Outputs**: Email delivered
- **Performance**: < 10 seconds delivery
- **Error Handling**: Log failed deliveries, retry up to 3 times

**REQ-ALERT-007: Push Notifications**
- **Description**: System shall send browser push notifications
- **Priority**: Low
- **Inputs**: Alert data, user subscription
- **Processing**: Send via Web Push API
- **Outputs**: Notification displayed
- **Error Handling**: Gracefully handle denied permissions

#### 3.1.7 Watchlists

**REQ-WATCH-001: Create Watchlist**
- **Description**: Users shall create named watchlists
- **Priority**: Medium
- **Inputs**: Watchlist name
- **Processing**: Insert into watchlists table
- **Outputs**: Created watchlist object
- **Error Handling**: Prevent duplicate names for same user

**REQ-WATCH-002: Add to Watchlist**
- **Description**: Users shall add stocks to watchlist
- **Priority**: Medium
- **Inputs**: Watchlist ID, stock code, notes (optional)
- **Processing**: Insert into watchlist_items
- **Outputs**: Added item confirmation
- **Error Handling**: Prevent duplicate stocks in same watchlist

**REQ-WATCH-003: Remove from Watchlist**
- **Description**: Users shall remove stocks from watchlist
- **Priority**: Medium
- **Inputs**: Watchlist item ID
- **Processing**: Delete from watchlist_items
- **Outputs**: Success confirmation
- **Error Handling**: Return 404 if not found

**REQ-WATCH-004: View Watchlist**
- **Description**: Users shall view watchlist with current prices
- **Priority**: Medium
- **Inputs**: Watchlist ID
- **Processing**: Query watchlist_items with latest prices
- **Outputs**: Watchlist details with stock data
- **Performance**: < 200ms
- **Error Handling**: Return 404 if not found

#### 3.1.8 Subscription & Billing

**REQ-SUB-001: Subscription Tiers**
- **Description**: System shall enforce three subscription tiers
- **Priority**: Critical
- **Tiers**:
  - **Free**: 10 filters, 1 portfolio, 3 alerts, 20-min delayed data
  - **Basic** (₩9,900/mo): Unlimited filters, 3 portfolios, 10 alerts, real-time data
  - **Pro** (₩29,900/mo): All Basic features + unlimited portfolios/alerts, API access, export
- **Processing**: Check user subscription tier before feature access
- **Outputs**: Access granted or 403 Forbidden
- **Error Handling**: Return clear upgrade message

**REQ-SUB-002: Subscription Upgrade**
- **Description**: Users shall upgrade subscription
- **Priority**: High
- **Inputs**: Target tier, payment method
- **Processing**: Process payment, update user subscription tier
- **Outputs**: Subscription confirmation
- **Error Handling**: Handle payment failures gracefully

**REQ-SUB-003: Subscription Cancellation**
- **Description**: Users shall cancel subscription (no refund)
- **Priority**: High
- **Inputs**: User confirmation
- **Processing**: Mark subscription for cancellation at period end
- **Outputs**: Cancellation confirmation
- **Error Handling**: None

**REQ-SUB-004: Billing History**
- **Description**: Users shall view payment history
- **Priority**: Medium
- **Inputs**: User authentication
- **Processing**: Query payment records
- **Outputs**: Array of invoices
- **Performance**: < 150ms
- **Error Handling**: None

#### 3.1.9 Data Pipeline

**REQ-DATA-001: Daily Price Ingestion**
- **Description**: System shall ingest daily prices for all stocks after market close
- **Priority**: Critical
- **Schedule**: Mon-Fri at 18:00 KST
- **Processing**:
  - Fetch data from KRX API
  - Validate data quality (price relationships, non-negative values)
  - Upsert to daily_prices table
  - Verify ≥95% completeness
- **Outputs**: Daily prices loaded, data quality report
- **Performance**: Complete within 5 minutes
- **Error Handling**: Retry failed API calls 3 times, email alert if <95% complete

**REQ-DATA-002: Indicator Calculation**
- **Description**: System shall calculate 200+ indicators for all stocks daily
- **Priority**: Critical
- **Trigger**: After REQ-DATA-001 completes
- **Processing**:
  - Calculate indicators for each stock
  - Upsert to calculated_indicators table
  - Refresh materialized views
- **Outputs**: Indicators updated
- **Performance**: Complete within 20 minutes for 2,400 stocks
- **Error Handling**: Log failed stocks, continue processing others

**REQ-DATA-003: Financial Statement Updates**
- **Description**: System shall ingest quarterly/annual financials
- **Priority**: High
- **Schedule**: Weekly check for new reports
- **Processing**: Fetch from F&Guide API, validate, upsert to financial_statements
- **Outputs**: New financials loaded
- **Performance**: < 10 minutes
- **Error Handling**: Retry failures, alert on persistent errors

**REQ-DATA-004: Data Quality Monitoring**
- **Description**: System shall monitor data completeness and accuracy
- **Priority**: High
- **Schedule**: Daily after data pipelines
- **Processing**: Execute check_data_completeness() function, log results
- **Outputs**: Data quality report
- **Error Handling**: Alert if quality below threshold

---

## 4. External Interface Requirements

### 4.1 User Interfaces

**UI-001: Responsive Design**
- **Description**: All user interfaces shall be responsive across devices
- **Requirements**:
  - Support screen widths from 360px (mobile) to 3840px (4K desktop)
  - Touch-friendly tap targets (minimum 44x44px)
  - Readable text (minimum 16px base font size)
  - Consistent navigation across breakpoints

**UI-002: Accessibility**
- **Description**: Interfaces shall meet WCAG 2.1 Level AA standards
- **Requirements**:
  - Keyboard navigation support (Tab, Enter, Esc)
  - Screen reader compatibility (semantic HTML, ARIA labels)
  - Color contrast ratios: 4.5:1 for text, 3:1 for UI components
  - Focus indicators visible on all interactive elements

**UI-003: Screener Interface**
- **Layout**: Two-panel layout (filters left, results right)
- **Components**:
  - Filter panel with collapsible sections
  - Results table with sortable columns
  - Pagination controls
  - Template selector dropdown
- **Interactions**:
  - Real-time result updates as filters change (debounced 500ms)
  - Click stock row to navigate to detail page
  - Export button (for Premium users)

**UI-004: Stock Detail Interface**
- **Layout**: Tab-based layout (Overview, Financials, Valuation, Technical)
- **Components**:
  - Stock header (name, code, current price, change %)
  - Interactive price chart (TradingView Lightweight Charts)
  - Metric cards (PER, PBR, ROE, etc.)
  - Financial statement tables
  - Add to watchlist/portfolio buttons
- **Interactions**:
  - Chart timeframe selection (1D, 1W, 1M, 3M, 6M, 1Y, 5Y)
  - Hover tooltips on metrics with explanations
  - Tab switching without page reload

**UI-005: Portfolio Interface**
- **Layout**: Portfolio selector with detail view
- **Components**:
  - Portfolio cards with summary metrics
  - Holdings table (stock, quantity, avg price, current value, gain/loss)
  - Performance chart (portfolio vs benchmark)
  - Asset allocation pie chart
  - Add holding modal
- **Interactions**:
  - Switch between portfolios
  - Inline editing of holdings
  - Drag-and-drop reordering (optional)

**UI-006: Color Scheme**
- **Primary Colors**:
  - Brand: #2563eb (Blue)
  - Success/Gains: #10b981 (Green)
  - Danger/Losses: #ef4444 (Red)
  - Warning: #f59e0b (Yellow)
  - Neutral: #6b7280 (Gray)
- **Dark Mode**: Optional (Phase 2+)

### 4.2 Hardware Interfaces

Not applicable (web-based application, no direct hardware interfaces)

### 4.3 Software Interfaces

**SI-001: KRX API Interface**
- **Interface Type**: RESTful HTTP API
- **Protocol**: HTTPS
- **Authentication**: API Key in Authorization header
- **Data Format**: JSON
- **Operations**:
  - `GET /market/stocks/prices?date={YYYY-MM-DD}`: Fetch daily prices
  - `GET /market/stocks/{code}/info`: Fetch stock info
- **Error Handling**: Retry up to 3 times with exponential backoff
- **Rate Limit**: 100 requests/minute (to be confirmed with KRX)

**SI-002: F&Guide API Interface**
- **Interface Type**: RESTful HTTP API
- **Protocol**: HTTPS
- **Authentication**: OAuth 2.0
- **Data Format**: JSON or XML (to be confirmed)
- **Operations**:
  - `GET /financials/{stock_code}?period={quarterly|annual}`: Fetch financial statements
  - `GET /consensus/{stock_code}`: Fetch analyst consensus (Phase 2)
- **Error Handling**: Retry failed requests, alert on persistent failures
- **Rate Limit**: 500 requests/minute (to be confirmed)

**SI-003: Payment Gateway Interface (Stripe)**
- **Interface Type**: RESTful HTTP API + Webhooks
- **Protocol**: HTTPS
- **Authentication**: API Key (secret)
- **Data Format**: JSON
- **Operations**:
  - `POST /v1/checkout/sessions`: Create payment session
  - `POST /v1/subscriptions`: Create subscription
  - Webhook: `invoice.paid`, `subscription.deleted`
- **Error Handling**: Handle payment failures, retry webhooks
- **Compliance**: PCI DSS Level 1 (handled by Stripe)

**SI-004: Email Service Interface (SMTP)**
- **Interface Type**: SMTP protocol
- **Server**: Gmail SMTP (smtp.gmail.com:587) or SendGrid
- **Authentication**: Username/password or API key
- **Operations**:
  - Send email notifications (alerts, verification, password reset)
- **Error Handling**: Retry failed sends up to 3 times
- **Rate Limit**: 500 emails/day (Gmail), higher with SendGrid

**SI-005: OAuth Providers**
- **Providers**: Kakao, Naver, Google
- **Protocol**: OAuth 2.0
- **Operations**:
  - Authorization code flow
  - Exchange code for access token
  - Fetch user profile
- **Error Handling**: Display user-friendly error messages

### 4.4 Communications Interfaces

**CI-001: HTTP/HTTPS Protocol**
- **Client-Server**: HTTPS (TLS 1.3) for all API requests
- **Ports**: 80 (HTTP, redirect to HTTPS), 443 (HTTPS)
- **Compression**: gzip or brotli for API responses

**CI-002: WebSocket Protocol (Optional Phase 2)**
- **Purpose**: Real-time price updates during market hours
- **Protocol**: WSS (WebSocket Secure)
- **Port**: 443
- **Message Format**: JSON
- **Heartbeat**: Ping/pong every 30 seconds

**CI-003: Database Protocol**
- **Protocol**: PostgreSQL wire protocol
- **Port**: 5432 (internal network only, not exposed publicly)
- **Connection Pooling**: Max 20 connections per application instance
- **SSL**: Enabled for production

**CI-004: Cache Protocol**
- **Protocol**: Redis RESP (REdis Serialization Protocol)
- **Port**: 6379 (internal network only)
- **Authentication**: Password-protected
- **Persistence**: AOF (Append-Only File) enabled

---

## 5. System Features

### 5.1 Stock Screening Feature

**5.1.1 Description and Priority**
- **Priority**: Critical (Highest)
- **Description**: Core feature allowing users to filter stocks using multiple criteria

**5.1.2 Stimulus/Response Sequences**
1. User selects filters (market, PER < 15, ROE > 10%)
2. System queries database with filters
3. System returns matching stocks sorted by market cap
4. User clicks "Export to CSV"
5. System generates CSV file
6. User downloads file

**5.1.3 Functional Requirements**
- See REQ-SCREEN-001 through REQ-SCREEN-004

### 5.2 Real-Time Market Insights Feature

**5.2.1 Description and Priority**
- **Priority**: High
- **Description**: Provides users with current market trends and opportunities

**5.2.2 Stimulus/Response Sequences**
1. User navigates to homepage
2. System displays market overview (cached data)
3. System shows hot stocks (volume surge > 150%)
4. User clicks on hot stock
5. System navigates to stock detail page

**5.2.3 Functional Requirements**
- See REQ-MARKET-001 through REQ-MARKET-004

### 5.3 Portfolio Tracking Feature

**5.3.1 Description and Priority**
- **Priority**: High
- **Description**: Enables users to track holdings and performance

**5.3.2 Stimulus/Response Sequences**
1. User creates portfolio "Growth Portfolio"
2. User adds Samsung Electronics: 10 shares @ ₩68,000
3. System calculates current value using latest price (₩70,500)
4. System shows unrealized gain: ₩25,000 (+3.68%)
5. User compares portfolio vs KOSPI index
6. System displays relative performance chart

**5.3.3 Functional Requirements**
- See REQ-PORT-001 through REQ-PORT-007

### 5.4 Price Alert Feature

**5.4.1 Description and Priority**
- **Priority**: High
- **Description**: Notifies users when stocks meet specified conditions

**5.4.2 Stimulus/Response Sequences**
1. User creates alert: Samsung > ₩75,000
2. System stores alert in database
3. Automated job checks alerts every 5 minutes
4. Samsung price reaches ₩75,500
5. System triggers alert
6. System sends email notification
7. User receives email: "Alert triggered for Samsung Electronics"

**5.4.3 Functional Requirements**
- See REQ-ALERT-001 through REQ-ALERT-007

---

## 6. Non-Functional Requirements

### 6.1 Performance Requirements

**PERF-001: API Response Time**
- **Requirement**: 95th percentile API response time < 200ms
- **Measurement**: Application Performance Monitoring (Sentry APM)
- **Rationale**: Ensure responsive user experience

**PERF-002: Screening Query Time**
- **Requirement**: 99th percentile screening query < 500ms
- **Measurement**: Database query logging + APM
- **Rationale**: Core feature must feel instant

**PERF-003: Page Load Time**
- **Requirement**: 95th percentile page load (First Contentful Paint) < 1.5s
- **Measurement**: Real User Monitoring (RUM), Lighthouse CI
- **Rationale**: Industry standard for good user experience

**PERF-004: Chart Rendering**
- **Requirement**: Render 1 year of daily data (252 points) in < 1 second
- **Measurement**: Frontend performance profiling
- **Rationale**: Charts are frequently used, must be fast

**PERF-005: Concurrent Users**
- **Requirement**: Support 10,000 concurrent users without degradation
- **Measurement**: Load testing (k6), production monitoring
- **Rationale**: Ensure scalability for user growth

**PERF-006: Database Query Optimization**
- **Requirement**: No database query exceeds 1 second execution time
- **Measurement**: Slow query log, pg_stat_statements
- **Rationale**: Prevent database from becoming bottleneck

**PERF-007: Cache Hit Rate**
- **Requirement**: Redis cache hit rate > 80%
- **Measurement**: Redis INFO stats
- **Rationale**: Reduce database load and improve response time

### 6.2 Safety Requirements

**SAFE-001: Data Backup**
- **Requirement**: Daily automated backups with 30-day retention
- **Verification**: Restore test monthly
- **Rationale**: Protect against data loss

**SAFE-002: Disaster Recovery**
- **Requirement**: Recovery Time Objective (RTO) < 4 hours, Recovery Point Objective (RPO) < 1 hour
- **Implementation**: Database replication, automated failover
- **Rationale**: Minimize downtime and data loss

**SAFE-003: Graceful Degradation**
- **Requirement**: System remains operational with degraded functionality if non-critical services fail
- **Example**: Screening works even if alerts service is down
- **Rationale**: Maximize availability of core features

### 6.3 Security Requirements

**SEC-001: Authentication**
- **Requirement**: Use JWT with 15-minute access token expiry, 30-day refresh token
- **Implementation**: bcrypt password hashing (cost 12), secure token storage
- **Rationale**: Industry best practice for web authentication

**SEC-002: Authorization**
- **Requirement**: Enforce role-based access control (RBAC) on all protected resources
- **Implementation**: Middleware checks subscription tier before feature access
- **Rationale**: Prevent unauthorized access to premium features

**SEC-003: Data Encryption**
- **Requirement**:
  - Encrypt all data in transit (TLS 1.3)
  - Encrypt PII at rest (AES-256)
- **Implementation**: HTTPS only, database column encryption for sensitive fields
- **Rationale**: Comply with GDPR/PIPA, protect user data

**SEC-004: SQL Injection Prevention**
- **Requirement**: Use parameterized queries or ORM for all database operations
- **Implementation**: SQLAlchemy ORM, never concatenate user input into SQL
- **Rationale**: Prevent SQL injection attacks

**SEC-005: XSS Prevention**
- **Requirement**: Sanitize all user inputs, escape outputs, use Content Security Policy (CSP)
- **Implementation**: React auto-escaping, CSP headers
- **Rationale**: Prevent cross-site scripting attacks

**SEC-006: CSRF Protection**
- **Requirement**: Use SameSite cookies, CSRF tokens for state-changing operations
- **Implementation**: SameSite=Strict for session cookies
- **Rationale**: Prevent cross-site request forgery

**SEC-007: Rate Limiting**
- **Requirement**: Enforce rate limits per user and per IP
  - Free: 100 req/min
  - Basic: 500 req/min
  - Pro: 2000 req/min
- **Implementation**: Redis-based rate limiter
- **Rationale**: Prevent API abuse and DDoS attacks

**SEC-008: Dependency Scanning**
- **Requirement**: Scan dependencies weekly for vulnerabilities, apply patches within 7 days
- **Implementation**: Dependabot, npm audit, safety (Python)
- **Rationale**: Prevent exploitation of known vulnerabilities

**SEC-009: Audit Logging**
- **Requirement**: Log all security-relevant events (logins, permission changes, data access)
- **Implementation**: Write to user_activity_log table
- **Rationale**: Enable forensic analysis and compliance audits

### 6.4 Software Quality Attributes

**QUAL-001: Reliability (Availability)**
- **Target**: 99.9% uptime (< 8.76 hours downtime per year)
- **Measurement**: Uptime monitoring (UptimeRobot), incident tracking
- **Strategies**: Redundant servers, automated failover, health checks

**QUAL-002: Reliability (Error Rate)**
- **Target**: < 0.1% error rate for all API requests
- **Measurement**: Error tracking (Sentry)
- **Strategies**: Comprehensive error handling, retry logic, circuit breakers

**QUAL-003: Maintainability (Code Quality)**
- **Target**: SonarQube quality gate pass (A rating)
- **Metrics**: Code smells < 50, duplicated lines < 5%, cognitive complexity < 15
- **Strategies**: Code reviews, linting, static analysis

**QUAL-004: Maintainability (Documentation)**
- **Target**: All public APIs documented with OpenAPI, all functions have docstrings
- **Verification**: Documentation coverage > 90%
- **Strategies**: Automated doc generation, documentation as code

**QUAL-005: Maintainability (Test Coverage)**
- **Target**: > 80% unit test coverage for backend, > 70% for frontend
- **Measurement**: Coverage reports (pytest-cov, vitest)
- **Strategies**: Test-driven development (TDD), CI/CD pipeline enforcement

**QUAL-006: Usability (Learnability)**
- **Target**: New users can complete first screening within 2 minutes
- **Measurement**: User testing, onboarding analytics
- **Strategies**: Guided tutorial, pre-built templates, tooltips

**QUAL-007: Usability (Error Handling)**
- **Target**: All errors have clear, actionable messages
- **Example**: "Invalid email format" instead of "400 Bad Request"
- **Verification**: Manual review of all error messages

**QUAL-008: Portability**
- **Target**: Run on any Linux distribution with Docker support
- **Implementation**: Container-based architecture
- **Rationale**: Avoid vendor lock-in

**QUAL-009: Scalability (Horizontal)**
- **Target**: Support horizontal scaling of API servers, workers
- **Implementation**: Stateless architecture, load balancer
- **Rationale**: Handle traffic growth without code changes

**QUAL-010: Scalability (Vertical)**
- **Target**: Optimize for efficient resource usage (CPU, memory)
- **Metrics**: < 500MB memory per API instance, < 50% CPU under normal load
- **Strategies**: Profiling, query optimization, caching

---

## 7. Other Requirements

### 7.1 Legal Requirements

**LEGAL-001: Data Licensing Compliance**
- **Requirement**: Display KRX and F&Guide data attribution as required by license agreements
- **Implementation**: Footer with "Data provided by KRX and F&Guide" on all pages
- **Penalty**: License termination if violated

**LEGAL-002: Investment Disclaimer**
- **Requirement**: Display investment disclaimer on all pages with financial data
- **Text**: "The information provided is for reference only and does not constitute investment advice. Screener Platform is not responsible for investment losses resulting from use of this service."
- **Placement**: Footer or prominent notice

**LEGAL-003: Privacy Policy**
- **Requirement**: Comply with GDPR (if serving EU users) and PIPA (Korea)
- **Implementation**:
  - Obtain consent for data collection
  - Allow users to export/delete their data
  - Encrypt PII
  - Privacy policy page linked in footer

**LEGAL-004: Terms of Service**
- **Requirement**: Users must agree to ToS before registration
- **Contents**: Service scope, user obligations, limitation of liability, dispute resolution
- **Implementation**: Checkbox during registration

**LEGAL-005: Cookie Consent**
- **Requirement**: Obtain consent for non-essential cookies (if applicable)
- **Implementation**: Cookie banner on first visit
- **Rationale**: EU Cookie Law compliance

### 7.2 Regulatory Requirements

**REG-001: Financial Data Restrictions**
- **Requirement**: Cannot redistribute financial data to third parties
- **Implementation**: Terms of Service prohibit data scraping/resale
- **Rationale**: Comply with data provider agreements

**REG-002: No Investment Advice**
- **Requirement**: System must not provide personalized investment recommendations
- **Implementation**: Generic screening results only, no "buy/sell" signals
- **Rationale**: Avoid financial advisor licensing requirements

**REG-003: Age Restriction**
- **Requirement**: Users must be 18+ to register
- **Implementation**: Age verification during registration
- **Rationale**: Investment-related service

### 7.3 Localization Requirements

**LOC-001: Language**
- **Requirement**: User interface in Korean, code and documentation in English
- **Implementation**: i18n framework (react-i18next), Korean translations
- **Rationale**: Primary market is Korea

**LOC-002: Currency**
- **Requirement**: Display prices in Korean Won (₩), formatted with commas
- **Implementation**: Number formatting utilities
- **Example**: 70000 → ₩70,000

**LOC-003: Date/Time**
- **Requirement**: Display dates in YYYY-MM-DD format, times in KST timezone
- **Implementation**: date-fns with Korea locale
- **Rationale**: Korean market hours (09:00-15:30 KST)

**LOC-004: Number Formatting**
- **Requirement**: Use Korean number formatting (10,000 → 만)
- **Implementation**: Custom formatting function for large numbers
- **Example**: 10억 (1 billion), 조 (trillion)

---

## 8. Appendices

### Appendix A: Requirement Traceability Matrix

| Requirement ID | PRD Section | Priority | Verification Method |
|----------------|-------------|----------|---------------------|
| REQ-AUTH-001 | 5.2.5 | Critical | Unit test, E2E test |
| REQ-STOCK-001 | 5.2.1 | Critical | Integration test |
| REQ-SCREEN-001 | 5.2.2 | Critical | Performance test, E2E test |
| REQ-MARKET-001 | 5.2.3 | High | Integration test |
| REQ-PORT-001 | 5.2.4 | High | E2E test |
| REQ-ALERT-001 | 5.2.7 | High | Integration test |
| PERF-001 | 6.3 | Critical | Load test, APM monitoring |
| SEC-001 | 6.4 | Critical | Security audit, penetration test |

### Appendix B: Glossary

See Section 1.3

### Appendix C: Analysis Models

**C.1 Use Case Diagram**

```
                  Stock Screening Platform

    ┌──────────┐                           ┌──────────┐
    │  Novice  │                           │  Active  │
    │ Investor │                           │  Trader  │
    └────┬─────┘                           └────┬─────┘
         │                                      │
         │  ┌─────────────────────────────┐    │
         ├──│ Browse Stock List           │────┤
         ├──│ View Stock Details          │────┤
         ├──│ Screen Stocks (Templates)   │────┤
         │  └─────────────────────────────┘    │
         │                                      │
         │  ┌─────────────────────────────┐    │
         │  │ Custom Screening            │────┤
         │  │ Create Alerts               │────┤
         │  │ Manage Portfolio            │────┤
         │  │ Export Data (Premium)       │────┤
         │  └─────────────────────────────┘    │
         │                                      │
    ┌────┴─────┐                           ┌────┴─────┐
    │   User   │                           │  System  │
    │  (Base)  │                           │   Admin  │
    └──────────┘                           └──────────┘
                                                 │
                                  ┌──────────────┴──────────────┐
                                  │ Monitor Data Pipeline       │
                                  │ Manage Users                │
                                  │ View System Health          │
                                  └─────────────────────────────┘
```

**C.2 Entity-Relationship Diagram**

See `database/migrations/01_create_tables.sql` for full schema

**C.3 State Transition Diagram (User Subscription)**

```
           ┌──────┐
    ┌─────→│ Free │
    │      └──┬───┘
    │         │ upgrade
    │         ▼
    │      ┌──────┐
    │  ┌──→│Basic │──┐
    │  │   └──────┘  │ upgrade
    │  │             ▼
    │  │          ┌─────┐
    │  │          │ Pro │
    │  │          └──┬──┘
    │  │             │
    │  │  downgrade  │ cancel
    │  └─────────────┘
    │                │
    └────────────────┘
         (grace period ends)
```

### Appendix D: Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-09 | Engineering Team | Initial SRS creation |

---

**END OF DOCUMENT**
