-- ============================================================================
-- Migration: 05_views.sql
-- Description: Create materialized views for performance optimization
-- Author: Database Team
-- Created: 2025-11-09
-- ============================================================================

-- ============================================================================
-- STOCK SCREENING VIEWS
-- ============================================================================

-- Combined view: Stock info + latest price + latest indicators
CREATE MATERIALIZED VIEW IF NOT EXISTS stock_screening_view AS
SELECT
    s.code,
    s.name,
    s.name_english,
    s.market,
    s.sector,
    s.industry,
    s.shares_outstanding,

    -- Latest price data
    lp.trade_date AS last_trade_date,
    lp.close_price AS current_price,
    lp.volume AS current_volume,
    lp.market_cap,

    -- Latest indicators
    li.calculation_date AS indicators_date,
    li.per,
    li.pbr,
    li.psr,
    li.pcr,
    li.dividend_yield,
    li.roe,
    li.roa,
    li.roic,
    li.gross_margin,
    li.operating_margin,
    li.net_margin,
    li.revenue_growth_yoy,
    li.profit_growth_yoy,
    li.eps_growth_yoy,
    li.debt_to_equity,
    li.current_ratio,
    li.altman_z_score,
    li.piotroski_f_score,
    li.price_change_1d,
    li.price_change_1w,
    li.price_change_1m,
    li.price_change_3m,
    li.price_change_6m,
    li.price_change_1y,
    li.volume_surge_pct,
    li.quality_score,
    li.value_score,
    li.growth_score,
    li.momentum_score,
    li.overall_score

FROM stocks s

-- Latest price (LATERAL join for efficiency)
LEFT JOIN LATERAL (
    SELECT
        trade_date,
        close_price,
        volume,
        market_cap
    FROM daily_prices
    WHERE stock_code = s.code
    ORDER BY trade_date DESC
    LIMIT 1
) lp ON TRUE

-- Latest indicators
LEFT JOIN LATERAL (
    SELECT *
    FROM calculated_indicators
    WHERE stock_code = s.code
    ORDER BY calculation_date DESC
    LIMIT 1
) li ON TRUE

WHERE s.delisting_date IS NULL; -- Only active stocks

-- Indexes on materialized view for fast filtering
CREATE INDEX IF NOT EXISTS idx_screening_market ON stock_screening_view(market);
CREATE INDEX IF NOT EXISTS idx_screening_sector ON stock_screening_view(sector);
CREATE INDEX IF NOT EXISTS idx_screening_per ON stock_screening_view(per) WHERE per > 0;
CREATE INDEX IF NOT EXISTS idx_screening_pbr ON stock_screening_view(pbr) WHERE pbr > 0;
CREATE INDEX IF NOT EXISTS idx_screening_roe ON stock_screening_view(roe) WHERE roe IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_screening_dividend_yield ON stock_screening_view(dividend_yield) WHERE dividend_yield > 0;
CREATE INDEX IF NOT EXISTS idx_screening_quality_score ON stock_screening_view(quality_score) WHERE quality_score IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_screening_market_cap ON stock_screening_view(market_cap) WHERE market_cap > 0;

COMMENT ON MATERIALIZED VIEW stock_screening_view IS 'Pre-joined view for fast stock screening (refresh daily)';

-- ============================================================================
-- SECTOR PERFORMANCE VIEW
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS sector_performance AS
WITH latest_data AS (
    SELECT
        s.sector,
        s.market,
        dp.close_price AS current_price,
        lag(dp.close_price, 1) OVER (PARTITION BY dp.stock_code ORDER BY dp.trade_date) AS prev_close_1d,
        lag(dp.close_price, 5) OVER (PARTITION BY dp.stock_code ORDER BY dp.trade_date) AS prev_close_1w,
        lag(dp.close_price, 20) OVER (PARTITION BY dp.stock_code ORDER BY dp.trade_date) AS prev_close_1m,
        dp.volume,
        dp.market_cap,
        ROW_NUMBER() OVER (PARTITION BY dp.stock_code ORDER BY dp.trade_date DESC) AS rn
    FROM daily_prices dp
    JOIN stocks s ON dp.stock_code = s.code
    WHERE s.delisting_date IS NULL
)
SELECT
    sector,
    market,
    COUNT(*) AS stock_count,
    SUM(market_cap) AS total_market_cap,
    SUM(volume) AS total_volume,
    ROUND(AVG(CASE
        WHEN prev_close_1d > 0 THEN ((current_price - prev_close_1d)::NUMERIC / prev_close_1d * 100)
    END), 2) AS avg_change_1d,
    ROUND(AVG(CASE
        WHEN prev_close_1w > 0 THEN ((current_price - prev_close_1w)::NUMERIC / prev_close_1w * 100)
    END), 2) AS avg_change_1w,
    ROUND(AVG(CASE
        WHEN prev_close_1m > 0 THEN ((current_price - prev_close_1m)::NUMERIC / prev_close_1m * 100)
    END), 2) AS avg_change_1m,
    COUNT(CASE WHEN current_price > prev_close_1d THEN 1 END) AS advancers,
    COUNT(CASE WHEN current_price < prev_close_1d THEN 1 END) AS decliners
FROM latest_data
WHERE rn = 1 AND sector IS NOT NULL
GROUP BY sector, market;

CREATE INDEX IF NOT EXISTS idx_sector_performance_sector ON sector_performance(sector);
CREATE INDEX IF NOT EXISTS idx_sector_performance_market ON sector_performance(market);

COMMENT ON MATERIALIZED VIEW sector_performance IS 'Sector-level performance metrics (refresh every 5 minutes during market hours)';

-- ============================================================================
-- POPULAR STOCKS VIEW (Most Viewed)
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS popular_stocks AS
SELECT
    resource_id AS stock_code,
    s.name AS stock_name,
    s.market,
    COUNT(*) AS view_count,
    COUNT(DISTINCT user_id) AS unique_viewers,
    MAX(created_at) AS last_viewed
FROM user_activity_log
JOIN stocks s ON resource_id = s.code
WHERE action_type = 'view_stock'
  AND resource_type = 'stock'
  AND created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY resource_id, s.name, s.market
ORDER BY view_count DESC
LIMIT 100;

COMMENT ON MATERIALIZED VIEW popular_stocks IS 'Most viewed stocks in last 7 days (refresh hourly)';

-- ============================================================================
-- DIVIDEND STOCKS VIEW
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS dividend_stocks AS
SELECT
    s.code,
    s.name,
    s.market,
    ci.dividend_yield,
    ci.payout_ratio,
    ci.per,
    ci.pbr,
    ci.roe,
    ci.debt_to_equity,
    ci.quality_score,
    dp.close_price AS current_price,
    dp.market_cap
FROM stocks s
JOIN calculated_indicators ci ON s.code = ci.stock_code
JOIN daily_prices dp ON s.code = dp.stock_code
WHERE s.delisting_date IS NULL
  AND ci.dividend_yield > 0
  AND ci.calculation_date = (
      SELECT MAX(calculation_date)
      FROM calculated_indicators
      WHERE stock_code = s.code
  )
  AND dp.trade_date = (
      SELECT MAX(trade_date)
      FROM daily_prices
      WHERE stock_code = s.code
  )
ORDER BY ci.dividend_yield DESC;

CREATE INDEX IF NOT EXISTS idx_dividend_stocks_yield ON dividend_stocks(dividend_yield DESC);

COMMENT ON MATERIALIZED VIEW dividend_stocks IS 'Stocks with dividend yields (pre-filtered for dividend screens)';

-- ============================================================================
-- VALUE STOCKS VIEW (Low PER, PBR)
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS value_stocks AS
SELECT
    s.code,
    s.name,
    s.market,
    s.sector,
    ci.per,
    ci.pbr,
    ci.psr,
    ci.ev_ebitda,
    ci.roe,
    ci.roa,
    ci.revenue_growth_yoy,
    ci.quality_score,
    ci.value_score,
    dp.close_price AS current_price,
    dp.market_cap
FROM stocks s
JOIN calculated_indicators ci ON s.code = ci.stock_code
JOIN daily_prices dp ON s.code = dp.stock_code
WHERE s.delisting_date IS NULL
  AND ci.per > 0 AND ci.per < 20
  AND ci.pbr > 0 AND ci.pbr < 2
  AND ci.roe > 5
  AND ci.calculation_date = (SELECT MAX(calculation_date) FROM calculated_indicators WHERE stock_code = s.code)
  AND dp.trade_date = (SELECT MAX(trade_date) FROM daily_prices WHERE stock_code = s.code)
ORDER BY ci.value_score DESC NULLS LAST;

CREATE INDEX IF NOT EXISTS idx_value_stocks_score ON value_stocks(value_score DESC);

COMMENT ON MATERIALIZED VIEW value_stocks IS 'Value stocks (low PER/PBR, positive ROE)';

-- ============================================================================
-- GROWTH STOCKS VIEW (High Growth Rates)
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS growth_stocks AS
SELECT
    s.code,
    s.name,
    s.market,
    s.sector,
    ci.revenue_growth_yoy,
    ci.profit_growth_yoy,
    ci.eps_growth_yoy,
    ci.revenue_cagr_3y,
    ci.eps_cagr_3y,
    ci.roe,
    ci.net_margin,
    ci.growth_score,
    ci.quality_score,
    dp.close_price AS current_price,
    dp.market_cap
FROM stocks s
JOIN calculated_indicators ci ON s.code = ci.stock_code
JOIN daily_prices dp ON s.code = dp.stock_code
WHERE s.delisting_date IS NULL
  AND ci.revenue_growth_yoy > 10
  AND ci.profit_growth_yoy > 10
  AND ci.calculation_date = (SELECT MAX(calculation_date) FROM calculated_indicators WHERE stock_code = s.code)
  AND dp.trade_date = (SELECT MAX(trade_date) FROM daily_prices WHERE stock_code = s.code)
ORDER BY ci.growth_score DESC NULLS LAST;

CREATE INDEX IF NOT EXISTS idx_growth_stocks_score ON growth_stocks(growth_score DESC);

COMMENT ON MATERIALIZED VIEW growth_stocks IS 'Growth stocks (revenue/profit growth > 10%)';

-- ============================================================================
-- QUALITY STOCKS VIEW (High Piotroski F-Score)
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS quality_stocks AS
SELECT
    s.code,
    s.name,
    s.market,
    s.sector,
    ci.piotroski_f_score,
    ci.altman_z_score,
    ci.roe,
    ci.roa,
    ci.roic,
    ci.gross_margin,
    ci.operating_margin,
    ci.net_margin,
    ci.debt_to_equity,
    ci.current_ratio,
    ci.quality_score,
    dp.close_price AS current_price,
    dp.market_cap
FROM stocks s
JOIN calculated_indicators ci ON s.code = ci.stock_code
JOIN daily_prices dp ON s.code = dp.stock_code
WHERE s.delisting_date IS NULL
  AND ci.piotroski_f_score >= 7 -- High quality (7-9)
  AND ci.calculation_date = (SELECT MAX(calculation_date) FROM calculated_indicators WHERE stock_code = s.code)
  AND dp.trade_date = (SELECT MAX(trade_date) FROM daily_prices WHERE stock_code = s.code)
ORDER BY ci.piotroski_f_score DESC, ci.quality_score DESC NULLS LAST;

CREATE INDEX IF NOT EXISTS idx_quality_stocks_fscore ON quality_stocks(piotroski_f_score DESC);

COMMENT ON MATERIALIZED VIEW quality_stocks IS 'Quality stocks (Piotroski F-Score >= 7)';

-- ============================================================================
-- FINANCIAL HEALTH VIEW
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS financial_health_summary AS
SELECT
    s.code,
    s.name,
    s.market,

    -- Latest financials
    fs.fiscal_year,
    fs.fiscal_quarter,
    fs.revenue,
    fs.operating_profit,
    fs.net_profit,
    fs.total_assets,
    fs.total_liabilities,
    fs.equity,
    fs.operating_cash_flow,
    fs.free_cash_flow,

    -- Health ratios
    CASE WHEN fs.equity > 0 THEN ROUND((fs.total_liabilities::NUMERIC / fs.equity * 100), 2) END AS debt_to_equity_ratio,
    CASE WHEN fs.current_liabilities > 0 THEN ROUND((fs.current_assets::NUMERIC / fs.current_liabilities), 2) END AS current_ratio,
    CASE WHEN fs.revenue > 0 THEN ROUND((fs.net_profit::NUMERIC / fs.revenue * 100), 2) END AS net_margin,
    CASE WHEN fs.equity > 0 THEN ROUND((fs.net_profit::NUMERIC / fs.equity * 100), 2) END AS roe,
    CASE WHEN fs.revenue > 0 THEN ROUND((fs.operating_cash_flow::NUMERIC / fs.revenue * 100), 2) END AS ocf_margin

FROM stocks s
JOIN LATERAL (
    SELECT *
    FROM financial_statements
    WHERE stock_code = s.code
    ORDER BY fiscal_year DESC, fiscal_quarter DESC NULLS LAST
    LIMIT 1
) fs ON TRUE
WHERE s.delisting_date IS NULL;

CREATE INDEX IF NOT EXISTS idx_financial_health_code ON financial_health_summary(code);

COMMENT ON MATERIALIZED VIEW financial_health_summary IS 'Latest financial statements with calculated ratios';

-- ============================================================================
-- REFRESH FUNCTIONS
-- ============================================================================

-- Refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_all_materialized_views()
RETURNS TEXT AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY stock_screening_view;
    REFRESH MATERIALIZED VIEW CONCURRENTLY sector_performance;
    REFRESH MATERIALIZED VIEW CONCURRENTLY popular_stocks;
    REFRESH MATERIALIZED VIEW CONCURRENTLY dividend_stocks;
    REFRESH MATERIALIZED VIEW CONCURRENTLY value_stocks;
    REFRESH MATERIALIZED VIEW CONCURRENTLY growth_stocks;
    REFRESH MATERIALIZED VIEW CONCURRENTLY quality_stocks;
    REFRESH MATERIALIZED VIEW CONCURRENTLY financial_health_summary;

    RETURN 'All materialized views refreshed successfully at ' || NOW();
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_all_materialized_views IS 'Refresh all materialized views (run after daily data load)';

-- Example usage:
-- SELECT refresh_all_materialized_views();

-- ============================================================================
-- VIEW MAINTENANCE SCHEDULE
-- ============================================================================

/*
Recommended refresh schedule (use pg_cron or external scheduler):

1. stock_screening_view: Daily after data pipeline (18:00 KST)
2. sector_performance: Every 5 minutes during market hours (09:00-15:30 KST)
3. popular_stocks: Hourly
4. dividend_stocks: Daily
5. value_stocks: Daily
6. growth_stocks: Daily
7. quality_stocks: Daily
8. financial_health_summary: Daily after financials update (18:00 KST)

Example pg_cron jobs:
SELECT cron.schedule('refresh-screening-view', '0 18 * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY stock_screening_view');
SELECT cron.schedule('refresh-sector-perf', '*/5 9-15 * * 1-5', 'REFRESH MATERIALIZED VIEW CONCURRENTLY sector_performance');
*/

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- List all materialized views with sizes
SELECT
    schemaname,
    matviewname,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||matviewname)) AS size,
    ispopulated
FROM pg_matviews
WHERE schemaname = 'public'
ORDER BY matviewname;

-- List all regular views
SELECT
    schemaname,
    viewname
FROM pg_views
WHERE schemaname = 'public'
ORDER BY viewname;

-- ============================================================================
-- VIEWS CREATED SUCCESSFULLY
-- ============================================================================

\echo 'All materialized views and regular views created successfully!'
\echo ''
\echo 'Materialized Views (pre-computed for performance):'
\echo '  - stock_screening_view: All-in-one view for screening'
\echo '  - sector_performance: Sector-level metrics'
\echo '  - popular_stocks: Most viewed stocks'
\echo '  - dividend_stocks: Dividend-paying stocks'
\echo '  - value_stocks: Value investment candidates'
\echo '  - growth_stocks: Growth investment candidates'
\echo '  - quality_stocks: High-quality companies (F-Score >= 7)'
\echo '  - financial_health_summary: Latest financials with ratios'
\echo ''
\echo 'Regular Views (from 02_timescaledb_setup.sql):'
\echo '  - latest_prices: Most recent price for each stock'
\echo '  - stock_52w_highs_lows: 52-week high/low analysis'
\echo ''
\echo 'Next steps:'
\echo '  1. Populate materialized views: SELECT refresh_all_materialized_views();'
\echo '  2. Set up scheduled refresh (pg_cron or external scheduler)'
\echo '  3. Monitor view sizes and refresh times'
\echo ''
\echo 'Database schema setup is now complete!'
\echo 'Proceed with loading seed data or connecting to application.'
