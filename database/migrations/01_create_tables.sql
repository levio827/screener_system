-- ============================================================================
-- Migration: 01_create_tables.sql
-- Description: Create core tables for stock screening platform
-- Author: Database Team
-- Created: 2025-11-09
-- ============================================================================

-- ============================================================================
-- STOCK MASTER DATA
-- ============================================================================

CREATE TABLE IF NOT EXISTS stocks (
    code VARCHAR(6) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    name_english VARCHAR(100),
    market VARCHAR(10) NOT NULL CHECK (market IN ('KOSPI', 'KOSDAQ')),
    sector VARCHAR(50),
    industry VARCHAR(100),
    listing_date DATE,
    delisting_date DATE,
    shares_outstanding BIGINT,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT valid_code_length CHECK (LENGTH(code) = 6),
    CONSTRAINT valid_shares CHECK (shares_outstanding IS NULL OR shares_outstanding > 0)
);

COMMENT ON TABLE stocks IS 'Master table for all listed stocks on KOSPI and KOSDAQ';
COMMENT ON COLUMN stocks.code IS '6-digit stock code (e.g., 005930 for Samsung Electronics)';
COMMENT ON COLUMN stocks.market IS 'Market classification: KOSPI or KOSDAQ';
COMMENT ON COLUMN stocks.sector IS 'Broad sector classification (e.g., Technology, Finance)';
COMMENT ON COLUMN stocks.industry IS 'Specific industry (e.g., Semiconductors, Banking)';
COMMENT ON COLUMN stocks.delisting_date IS 'NULL if currently listed, set upon delisting';

-- ============================================================================
-- DAILY PRICE DATA (Will be converted to TimescaleDB hypertable)
-- ============================================================================

CREATE TABLE IF NOT EXISTS daily_prices (
    stock_code VARCHAR(6) NOT NULL,
    trade_date DATE NOT NULL,

    open_price INTEGER,
    high_price INTEGER,
    low_price INTEGER,
    close_price INTEGER NOT NULL,
    adjusted_close INTEGER, -- Adjusted for splits and dividends

    volume BIGINT,
    trading_value BIGINT,
    market_cap BIGINT,

    PRIMARY KEY (stock_code, trade_date),
    FOREIGN KEY (stock_code) REFERENCES stocks(code) ON DELETE CASCADE,

    CONSTRAINT valid_prices CHECK (
        open_price > 0 AND
        high_price >= open_price AND
        low_price <= open_price AND
        close_price > 0 AND
        high_price >= low_price
    ),
    CONSTRAINT valid_volume CHECK (volume >= 0),
    CONSTRAINT valid_market_cap CHECK (market_cap IS NULL OR market_cap > 0)
);

COMMENT ON TABLE daily_prices IS 'Daily OHLCV data for all stocks (TimescaleDB hypertable)';
COMMENT ON COLUMN daily_prices.adjusted_close IS 'Close price adjusted for corporate actions';
COMMENT ON COLUMN daily_prices.trading_value IS 'Total trading value in KRW';

-- ============================================================================
-- FINANCIAL STATEMENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS financial_statements (
    id SERIAL PRIMARY KEY,
    stock_code VARCHAR(6) NOT NULL,
    period_type VARCHAR(10) NOT NULL CHECK (period_type IN ('quarterly', 'annual')),
    fiscal_year INTEGER NOT NULL,
    fiscal_quarter INTEGER CHECK (fiscal_quarter BETWEEN 1 AND 4),
    report_date DATE NOT NULL,

    -- Income Statement
    revenue BIGINT,
    cost_of_revenue BIGINT,
    gross_profit BIGINT,
    operating_expenses BIGINT,
    operating_profit BIGINT,
    non_operating_income BIGINT,
    non_operating_expenses BIGINT,
    ebt BIGINT, -- Earnings Before Tax
    tax_expense BIGINT,
    net_profit BIGINT,

    -- Per Share Metrics
    eps NUMERIC(10, 2), -- Earnings Per Share
    bps NUMERIC(10, 2), -- Book Value Per Share
    dps NUMERIC(10, 2), -- Dividend Per Share

    -- Balance Sheet
    current_assets BIGINT,
    non_current_assets BIGINT,
    total_assets BIGINT,
    current_liabilities BIGINT,
    non_current_liabilities BIGINT,
    total_liabilities BIGINT,
    equity BIGINT,

    -- Cash Flow Statement
    operating_cash_flow BIGINT,
    investing_cash_flow BIGINT,
    financing_cash_flow BIGINT,
    free_cash_flow BIGINT, -- Operating CF - CapEx
    capital_expenditure BIGINT,

    created_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (stock_code) REFERENCES stocks(code) ON DELETE CASCADE,
    UNIQUE (stock_code, period_type, fiscal_year, fiscal_quarter),

    CONSTRAINT valid_fiscal_year CHECK (fiscal_year BETWEEN 1900 AND 2100),
    CONSTRAINT quarterly_has_quarter CHECK (
        (period_type = 'annual' AND fiscal_quarter IS NULL) OR
        (period_type = 'quarterly' AND fiscal_quarter IS NOT NULL)
    )
);

COMMENT ON TABLE financial_statements IS 'Quarterly and annual financial statements';
COMMENT ON COLUMN financial_statements.period_type IS 'quarterly or annual reporting period';
COMMENT ON COLUMN financial_statements.fiscal_quarter IS 'NULL for annual reports, 1-4 for quarterly';

-- ============================================================================
-- CALCULATED INDICATORS
-- ============================================================================

CREATE TABLE IF NOT EXISTS calculated_indicators (
    stock_code VARCHAR(6) NOT NULL,
    calculation_date DATE NOT NULL,

    -- Valuation Metrics
    per NUMERIC(10, 2), -- Price-to-Earnings Ratio
    pbr NUMERIC(10, 2), -- Price-to-Book Ratio
    psr NUMERIC(10, 2), -- Price-to-Sales Ratio
    pcr NUMERIC(10, 2), -- Price-to-Cash Flow Ratio
    ev_ebitda NUMERIC(10, 2), -- Enterprise Value / EBITDA
    ev_sales NUMERIC(10, 2),
    ev_fcf NUMERIC(10, 2),
    dividend_yield NUMERIC(5, 2), -- Percentage
    payout_ratio NUMERIC(5, 2),
    peg_ratio NUMERIC(10, 2),

    -- Profitability Metrics
    roe NUMERIC(5, 2), -- Return on Equity (%)
    roa NUMERIC(5, 2), -- Return on Assets (%)
    roic NUMERIC(5, 2), -- Return on Invested Capital (%)
    gross_margin NUMERIC(5, 2), -- Percentage
    operating_margin NUMERIC(5, 2),
    net_margin NUMERIC(5, 2),
    ebitda_margin NUMERIC(5, 2),
    fcf_margin NUMERIC(5, 2),

    -- Growth Metrics (Year-over-Year %)
    revenue_growth_yoy NUMERIC(6, 2),
    profit_growth_yoy NUMERIC(6, 2),
    eps_growth_yoy NUMERIC(6, 2),
    revenue_growth_qoq NUMERIC(6, 2), -- Quarter-over-Quarter
    profit_growth_qoq NUMERIC(6, 2),
    revenue_cagr_3y NUMERIC(6, 2), -- 3-year CAGR
    revenue_cagr_5y NUMERIC(6, 2),
    eps_cagr_3y NUMERIC(6, 2),
    eps_cagr_5y NUMERIC(6, 2),

    -- Stability Metrics
    debt_to_equity NUMERIC(6, 2),
    debt_to_assets NUMERIC(6, 2),
    interest_coverage NUMERIC(6, 2),
    current_ratio NUMERIC(5, 2),
    quick_ratio NUMERIC(5, 2),
    cash_ratio NUMERIC(5, 2),
    altman_z_score NUMERIC(5, 2),
    piotroski_f_score INTEGER CHECK (piotroski_f_score BETWEEN 0 AND 9),

    -- Efficiency Metrics
    asset_turnover NUMERIC(5, 2),
    inventory_turnover NUMERIC(5, 2),
    receivables_turnover NUMERIC(5, 2),
    payables_turnover NUMERIC(5, 2),
    cash_conversion_cycle INTEGER, -- Days

    -- Technical Metrics
    price_change_1d NUMERIC(5, 2), -- Percentage
    price_change_1w NUMERIC(5, 2),
    price_change_1m NUMERIC(5, 2),
    price_change_3m NUMERIC(5, 2),
    price_change_6m NUMERIC(5, 2),
    price_change_1y NUMERIC(5, 2),
    price_change_3y NUMERIC(6, 2),
    price_change_5y NUMERIC(6, 2),
    volume_20d_avg BIGINT,
    volume_60d_avg BIGINT,
    volume_surge_pct NUMERIC(6, 2), -- Volume vs 20D avg

    -- Moving Averages
    ma_5d NUMERIC(10, 2),
    ma_20d NUMERIC(10, 2),
    ma_60d NUMERIC(10, 2),
    ma_120d NUMERIC(10, 2),
    ma_200d NUMERIC(10, 2),

    -- Technical Indicators
    rsi_14d NUMERIC(5, 2) CHECK (rsi_14d BETWEEN 0 AND 100),
    macd NUMERIC(10, 2),
    macd_signal NUMERIC(10, 2),
    bollinger_upper NUMERIC(10, 2),
    bollinger_lower NUMERIC(10, 2),

    -- Composite Scores (1-100)
    quality_score INTEGER CHECK (quality_score BETWEEN 1 AND 100),
    value_score INTEGER CHECK (value_score BETWEEN 1 AND 100),
    growth_score INTEGER CHECK (growth_score BETWEEN 1 AND 100),
    momentum_score INTEGER CHECK (momentum_score BETWEEN 1 AND 100),
    overall_score INTEGER CHECK (overall_score BETWEEN 1 AND 100),

    created_at TIMESTAMP DEFAULT NOW(),

    PRIMARY KEY (stock_code, calculation_date),
    FOREIGN KEY (stock_code) REFERENCES stocks(code) ON DELETE CASCADE
);

COMMENT ON TABLE calculated_indicators IS 'Pre-calculated 200+ indicators for fast screening';
COMMENT ON COLUMN calculated_indicators.calculation_date IS 'Date when indicators were calculated';
COMMENT ON COLUMN calculated_indicators.piotroski_f_score IS 'Financial strength score (0-9), higher is better';

-- ============================================================================
-- USER MANAGEMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100),

    subscription_tier VARCHAR(20) NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'basic', 'pro')),
    subscription_starts_at TIMESTAMP,
    subscription_expires_at TIMESTAMP,

    email_verified BOOLEAN DEFAULT FALSE,
    email_verification_token VARCHAR(255),

    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP,

    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

COMMENT ON TABLE users IS 'User account information';
COMMENT ON COLUMN users.subscription_tier IS 'free, basic, or pro subscription level';
COMMENT ON COLUMN users.email_verified IS 'TRUE after email verification link clicked';

-- ============================================================================
-- PORTFOLIO MANAGEMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS portfolios (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_default BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (user_id, name)
);

COMMENT ON TABLE portfolios IS 'User-created portfolio containers';
COMMENT ON COLUMN portfolios.is_default IS 'Default portfolio shown on dashboard';

CREATE TABLE IF NOT EXISTS portfolio_holdings (
    id SERIAL PRIMARY KEY,
    portfolio_id INTEGER NOT NULL,
    stock_code VARCHAR(6) NOT NULL,

    quantity INTEGER NOT NULL CHECK (quantity > 0),
    avg_price NUMERIC(10, 2) NOT NULL CHECK (avg_price > 0),
    purchase_date DATE,
    notes TEXT,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (portfolio_id) REFERENCES portfolios(id) ON DELETE CASCADE,
    FOREIGN KEY (stock_code) REFERENCES stocks(code),
    UNIQUE (portfolio_id, stock_code)
);

COMMENT ON TABLE portfolio_holdings IS 'Individual stock holdings within portfolios';
COMMENT ON COLUMN portfolio_holdings.avg_price IS 'Average purchase price per share';

-- ============================================================================
-- ALERTS & NOTIFICATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    stock_code VARCHAR(6) NOT NULL,

    alert_type VARCHAR(20) NOT NULL CHECK (alert_type IN ('price', 'volume', 'indicator')),
    condition VARCHAR(20) NOT NULL CHECK (condition IN ('above', 'below', 'equals', 'crosses_above', 'crosses_below')),
    threshold_value NUMERIC(15, 4) NOT NULL,
    indicator_name VARCHAR(50), -- For indicator-based alerts (e.g., 'rsi_14d')

    notify_via TEXT[] DEFAULT ARRAY['email'], -- Array: email, push, sms

    is_active BOOLEAN DEFAULT TRUE,
    triggered_at TIMESTAMP,
    trigger_count INTEGER DEFAULT 0,
    last_checked_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (stock_code) REFERENCES stocks(code),

    CONSTRAINT valid_notify_via CHECK (
        notify_via <@ ARRAY['email', 'push', 'sms']::TEXT[]
    )
);

COMMENT ON TABLE alerts IS 'User-configured price/volume/indicator alerts';
COMMENT ON COLUMN alerts.condition IS 'Trigger condition: above, below, equals, crosses_above, crosses_below';
COMMENT ON COLUMN alerts.trigger_count IS 'Number of times this alert has been triggered';

-- ============================================================================
-- AUDIT & ANALYTICS
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_activity_log (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER,

    action_type VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(100),

    metadata JSONB,

    ip_address INET,
    user_agent TEXT,

    created_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

COMMENT ON TABLE user_activity_log IS 'Audit log of user actions for analytics and security';
COMMENT ON COLUMN user_activity_log.action_type IS 'e.g., login, screen, view_stock, create_portfolio';
COMMENT ON COLUMN user_activity_log.metadata IS 'Additional context as JSON (e.g., filters used)';

CREATE TABLE IF NOT EXISTS data_ingestion_log (
    id SERIAL PRIMARY KEY,

    source VARCHAR(50) NOT NULL, -- krx, fguide, news, etc.
    data_type VARCHAR(50) NOT NULL, -- prices, financials, indicators, etc.

    records_processed INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,

    status VARCHAR(20) NOT NULL CHECK (status IN ('running', 'success', 'partial', 'failed')),
    error_message TEXT,

    started_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE data_ingestion_log IS 'Data pipeline execution tracking and monitoring';
COMMENT ON COLUMN data_ingestion_log.status IS 'running, success, partial (some failures), or failed';

-- ============================================================================
-- SAVED SCREENS & TEMPLATES
-- ============================================================================

CREATE TABLE IF NOT EXISTS screening_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    category VARCHAR(50), -- value, growth, dividend, momentum, etc.

    filter_config JSONB NOT NULL, -- Stored filter criteria

    is_public BOOLEAN DEFAULT TRUE, -- Public templates visible to all users
    created_by INTEGER, -- NULL for system templates

    usage_count INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

COMMENT ON TABLE screening_templates IS 'Pre-built and user-created screening templates';
COMMENT ON COLUMN screening_templates.filter_config IS 'JSON object containing filter criteria';
COMMENT ON COLUMN screening_templates.is_public IS 'TRUE for templates visible to all users';

CREATE TABLE IF NOT EXISTS saved_screens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,

    filter_config JSONB NOT NULL,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (user_id, name)
);

COMMENT ON TABLE saved_screens IS 'User-saved custom screening criteria';

-- ============================================================================
-- WATCHLISTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS watchlists (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL DEFAULT 'My Watchlist',

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (user_id, name)
);

CREATE TABLE IF NOT EXISTS watchlist_items (
    id SERIAL PRIMARY KEY,
    watchlist_id INTEGER NOT NULL,
    stock_code VARCHAR(6) NOT NULL,

    notes TEXT,
    added_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (watchlist_id) REFERENCES watchlists(id) ON DELETE CASCADE,
    FOREIGN KEY (stock_code) REFERENCES stocks(code),
    UNIQUE (watchlist_id, stock_code)
);

COMMENT ON TABLE watchlists IS 'User watchlist containers';
COMMENT ON TABLE watchlist_items IS 'Stocks within user watchlists';

-- ============================================================================
-- SESSIONS (Alternative to JWT-only auth)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER NOT NULL,

    refresh_token VARCHAR(255) UNIQUE NOT NULL,

    ip_address INET,
    user_agent TEXT,

    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT NOW(),
    last_accessed_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

COMMENT ON TABLE user_sessions IS 'Active user sessions with refresh tokens';
COMMENT ON COLUMN user_sessions.revoked IS 'TRUE when user logs out or token is invalidated';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Verify all tables created
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
