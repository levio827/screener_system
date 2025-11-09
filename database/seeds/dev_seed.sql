-- ============================================================================
-- dev_seed.sql
-- Description: Development seed data for testing
-- Usage: psql -U screener_user -d screener_db -f seeds/dev_seed.sql
-- ============================================================================

-- ============================================================================
-- SAMPLE STOCKS
-- ============================================================================

INSERT INTO stocks (code, name, name_english, market, sector, industry, listing_date, shares_outstanding) VALUES
('005930', '삼성전자', 'Samsung Electronics', 'KOSPI', 'Technology', 'Semiconductors', '1975-06-11', 5969782550),
('000660', 'SK하이닉스', 'SK Hynix', 'KOSPI', 'Technology', 'Semiconductors', '1996-12-26', 728002365),
('035420', 'NAVER', 'NAVER', 'KOSPI', 'Technology', 'Internet Services', '2002-10-29', 164263395),
('005380', '현대차', 'Hyundai Motor', 'KOSPI', 'Consumer Cyclical', 'Auto Manufacturers', '1974-10-02', 213467164),
('035720', '카카오', 'Kakao', 'KOSPI', 'Technology', 'Internet Services', '2017-07-10', 444945058),
('105560', 'KB금융', 'KB Financial Group', 'KOSPI', 'Financial', 'Banking', '2008-09-22', 417016811),
('055550', '신한지주', 'Shinhan Financial Group', 'KOSPI', 'Financial', 'Banking', '2001-09-10', 456136893),
('051910', 'LG화학', 'LG Chem', 'KOSPI', 'Basic Materials', 'Chemicals', '2001-04-25', 70592343),
('006400', '삼성SDI', 'Samsung SDI', 'KOSPI', 'Technology', 'Batteries', '1979-06-08', 68770732),
('207940', '삼성바이오로직스', 'Samsung Biologics', 'KOSPI', 'Healthcare', 'Biotechnology', '2016-11-10', 68185860)
ON CONFLICT (code) DO NOTHING;

COMMENT ON TABLE stocks IS 'Sample data loaded for development';

-- ============================================================================
-- SAMPLE DAILY PRICES (Last 30 days for Samsung Electronics)
-- ============================================================================

-- Generate sample prices for Samsung Electronics (005930)
INSERT INTO daily_prices (stock_code, trade_date, open_price, high_price, low_price, close_price, volume, trading_value, market_cap)
SELECT
    '005930' AS stock_code,
    CURRENT_DATE - (30 - gs.day) AS trade_date,
    70000 + (RANDOM() * 5000 - 2500)::INTEGER AS open_price,
    72000 + (RANDOM() * 3000)::INTEGER AS high_price,
    68000 - (RANDOM() * 3000)::INTEGER AS low_price,
    70000 + (RANDOM() * 5000 - 2500)::INTEGER AS close_price,
    (10000000 + RANDOM() * 5000000)::BIGINT AS volume,
    (700000000000 + RANDOM() * 100000000000)::BIGINT AS trading_value,
    (420000000000000 + RANDOM() * 50000000000000)::BIGINT AS market_cap
FROM generate_series(1, 30) AS gs(day)
ON CONFLICT (stock_code, trade_date) DO NOTHING;

-- ============================================================================
-- SAMPLE FINANCIAL STATEMENTS (Samsung Electronics - Last 4 quarters)
-- ============================================================================

INSERT INTO financial_statements (
    stock_code, period_type, fiscal_year, fiscal_quarter, report_date,
    revenue, operating_profit, net_profit,
    total_assets, total_liabilities, equity,
    operating_cash_flow, free_cash_flow
) VALUES
('005930', 'quarterly', 2024, 3, '2024-10-31',
    79107000000000, 13519000000000, 10062000000000,
    465872000000000, 116404000000000, 349468000000000,
    23000000000000, 15000000000000),
('005930', 'quarterly', 2024, 2, '2024-07-31',
    74068000000000, 10446000000000, 7798000000000,
    460000000000000, 115000000000000, 345000000000000,
    21000000000000, 14000000000000),
('005930', 'quarterly', 2024, 1, '2024-04-30',
    71920000000000, 6636000000000, 5190000000000,
    455000000000000, 113000000000000, 342000000000000,
    19000000000000, 12000000000000),
('005930', 'quarterly', 2023, 4, '2024-01-31',
    67400000000000, 2820000000000, 2192000000000,
    450000000000000, 112000000000000, 338000000000000,
    18000000000000, 11000000000000)
ON CONFLICT (stock_code, period_type, fiscal_year, fiscal_quarter) DO NOTHING;

-- ============================================================================
-- SAMPLE CALCULATED INDICATORS
-- ============================================================================

INSERT INTO calculated_indicators (
    stock_code, calculation_date,
    per, pbr, psr, dividend_yield,
    roe, roa, gross_margin, operating_margin, net_margin,
    revenue_growth_yoy, profit_growth_yoy,
    debt_to_equity, current_ratio,
    piotroski_f_score, quality_score, value_score, growth_score, overall_score
) VALUES
('005930', CURRENT_DATE,
    12.5, 1.2, 1.8, 2.5,
    15.2, 9.8, 38.5, 15.3, 12.7,
    8.5, 15.3,
    33.3, 2.1,
    8, 85, 75, 70, 80),
('000660', CURRENT_DATE,
    15.3, 1.5, 2.2, 1.8,
    12.5, 7.2, 35.2, 12.8, 10.5,
    12.3, 18.7,
    42.5, 1.8,
    7, 80, 72, 78, 78),
('035420', CURRENT_DATE,
    18.2, 2.8, 3.5, 0.5,
    18.3, 12.5, 42.8, 18.9, 15.2,
    15.8, 22.5,
    15.2, 2.8,
    8, 88, 65, 85, 82)
ON CONFLICT (stock_code, calculation_date) DO NOTHING;

-- ============================================================================
-- SAMPLE USERS
-- ============================================================================

-- Password: 'password123' (hashed with bcrypt cost 12)
-- In production, NEVER store plain passwords - this is for testing only
INSERT INTO users (email, password_hash, name, subscription_tier, email_verified) VALUES
('test@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqRjNihZ6e', 'Test User', 'free', TRUE),
('premium@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqRjNihZ6e', 'Premium User', 'pro', TRUE),
('basic@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqRjNihZ6e', 'Basic User', 'basic', TRUE)
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- SAMPLE PORTFOLIOS
-- ============================================================================

WITH user_ids AS (
    SELECT id FROM users WHERE email = 'premium@example.com' LIMIT 1
)
INSERT INTO portfolios (user_id, name, description, is_default)
SELECT
    id,
    'Growth Portfolio',
    'High-growth tech stocks',
    TRUE
FROM user_ids
ON CONFLICT DO NOTHING;

WITH user_ids AS (
    SELECT id FROM users WHERE email = 'premium@example.com' LIMIT 1
)
INSERT INTO portfolios (user_id, name, description)
SELECT
    id,
    'Dividend Portfolio',
    'Stable dividend-paying stocks'
FROM user_ids
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SAMPLE PORTFOLIO HOLDINGS
-- ============================================================================

WITH portfolio_ids AS (
    SELECT p.id
    FROM portfolios p
    JOIN users u ON p.user_id = u.id
    WHERE u.email = 'premium@example.com'
      AND p.name = 'Growth Portfolio'
    LIMIT 1
)
INSERT INTO portfolio_holdings (portfolio_id, stock_code, quantity, avg_price, purchase_date)
SELECT
    id,
    '005930',
    10,
    68000,
    CURRENT_DATE - INTERVAL '60 days'
FROM portfolio_ids
ON CONFLICT DO NOTHING;

WITH portfolio_ids AS (
    SELECT p.id
    FROM portfolios p
    JOIN users u ON p.user_id = u.id
    WHERE u.email = 'premium@example.com'
      AND p.name = 'Growth Portfolio'
    LIMIT 1
)
INSERT INTO portfolio_holdings (portfolio_id, stock_code, quantity, avg_price, purchase_date)
SELECT
    id,
    '035420',
    5,
    180000,
    CURRENT_DATE - INTERVAL '30 days'
FROM portfolio_ids
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SAMPLE SCREENING TEMPLATES
-- ============================================================================

INSERT INTO screening_templates (name, description, category, filter_config, is_public) VALUES
('High Dividend Stocks', 'Stocks with dividend yield > 3% and stable financials', 'dividend',
 '{"dividend_yield": {"min": 3.0}, "quality_score": {"min": 70}, "debt_to_equity": {"max": 100}}'::jsonb, TRUE),
('Value Stocks', 'Undervalued stocks with low PER and PBR', 'value',
 '{"per": {"max": 15}, "pbr": {"max": 1.5}, "roe": {"min": 10}}'::jsonb, TRUE),
('Growth Stocks', 'High-growth companies', 'growth',
 '{"revenue_growth_yoy": {"min": 15}, "profit_growth_yoy": {"min": 15}, "growth_score": {"min": 75}}'::jsonb, TRUE),
('Quality Stocks', 'High-quality companies with strong fundamentals', 'quality',
 '{"piotroski_f_score": {"min": 7}, "roe": {"min": 15}, "debt_to_equity": {"max": 50}}'::jsonb, TRUE)
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- SAMPLE WATCHLISTS
-- ============================================================================

WITH user_ids AS (
    SELECT id FROM users WHERE email = 'test@example.com' LIMIT 1
)
INSERT INTO watchlists (user_id, name)
SELECT id, 'My Watchlist'
FROM user_ids
ON CONFLICT DO NOTHING;

WITH watchlist_ids AS (
    SELECT w.id
    FROM watchlists w
    JOIN users u ON w.user_id = u.id
    WHERE u.email = 'test@example.com'
      AND w.name = 'My Watchlist'
    LIMIT 1
)
INSERT INTO watchlist_items (watchlist_id, stock_code, notes)
SELECT
    id,
    '005930',
    'Watching for price dip below 65,000'
FROM watchlist_ids
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SAMPLE ALERTS
-- ============================================================================

WITH user_ids AS (
    SELECT id FROM users WHERE email = 'premium@example.com' LIMIT 1
)
INSERT INTO alerts (user_id, stock_code, alert_type, condition, threshold_value, notify_via, is_active)
SELECT
    id,
    '005930',
    'price',
    'above',
    75000,
    ARRAY['email'],
    TRUE
FROM user_ids
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SAMPLE ACTIVITY LOG
-- ============================================================================

WITH user_ids AS (
    SELECT id FROM users WHERE email = 'test@example.com' LIMIT 1
)
INSERT INTO user_activity_log (user_id, action_type, resource_type, resource_id, metadata, ip_address)
SELECT
    id,
    'view_stock',
    'stock',
    '005930',
    '{"referrer": "screening"}'::jsonb,
    '192.168.1.100'::inet
FROM user_ids;

WITH user_ids AS (
    SELECT id FROM users WHERE email = 'test@example.com' LIMIT 1
)
INSERT INTO user_activity_log (user_id, action_type, resource_type, resource_id, metadata)
SELECT
    id,
    'screen',
    'screening_template',
    '1',
    '{"filters": {"per": {"max": 15}}}'::jsonb
FROM user_ids;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT
    'stocks' AS table_name,
    COUNT(*) AS row_count
FROM stocks
UNION ALL
SELECT 'daily_prices', COUNT(*) FROM daily_prices
UNION ALL
SELECT 'financial_statements', COUNT(*) FROM financial_statements
UNION ALL
SELECT 'calculated_indicators', COUNT(*) FROM calculated_indicators
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'portfolios', COUNT(*) FROM portfolios
UNION ALL
SELECT 'portfolio_holdings', COUNT(*) FROM portfolio_holdings
UNION ALL
SELECT 'screening_templates', COUNT(*) FROM screening_templates
UNION ALL
SELECT 'watchlists', COUNT(*) FROM watchlists
UNION ALL
SELECT 'watchlist_items', COUNT(*) FROM watchlist_items
UNION ALL
SELECT 'alerts', COUNT(*) FROM alerts
UNION ALL
SELECT 'user_activity_log', COUNT(*) FROM user_activity_log
ORDER BY table_name;

-- ============================================================================
-- DEV SEED DATA LOADED
-- ============================================================================

\echo ''
\echo 'Development seed data loaded successfully!'
\echo ''
\echo 'Test Users:'
\echo '  - test@example.com (free tier) - password: password123'
\echo '  - basic@example.com (basic tier) - password: password123'
\echo '  - premium@example.com (pro tier) - password: password123'
\echo ''
\echo 'Sample stocks: 10 major Korean companies'
\echo 'Sample prices: 30 days for Samsung Electronics'
\echo ''
\echo 'Next steps:'
\echo '  1. Refresh materialized views: SELECT refresh_all_materialized_views();'
\echo '  2. Test screening: SELECT * FROM stock_screening_view LIMIT 10;'
\echo '  3. Test portfolio: SELECT * FROM calculate_portfolio_value(1);'
