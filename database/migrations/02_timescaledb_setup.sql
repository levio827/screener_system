-- ============================================================================
-- Migration: 02_timescaledb_setup.sql
-- Description: Convert daily_prices to TimescaleDB hypertable and configure
--              time-series optimizations
-- Author: Database Team
-- Created: 2025-11-09
-- ============================================================================

-- ============================================================================
-- CONVERT TO HYPERTABLE
-- ============================================================================

-- Convert daily_prices to TimescaleDB hypertable
-- Partitioning: 1-month chunks by trade_date
SELECT create_hypertable(
    'daily_prices',
    'trade_date',
    chunk_time_interval => INTERVAL '1 month',
    if_not_exists => TRUE
);

COMMENT ON TABLE daily_prices IS 'TimescaleDB hypertable for daily stock prices (partitioned by trade_date)';

-- ============================================================================
-- CONTINUOUS AGGREGATES (Materialized Views for Fast Queries)
-- ============================================================================

-- Monthly aggregated prices (OHLC)
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_prices_monthly
WITH (timescaledb.continuous) AS
SELECT
    stock_code,
    time_bucket('1 month', trade_date) AS month,
    first(open_price, trade_date) AS open,
    max(high_price) AS high,
    min(low_price) AS low,
    last(close_price, trade_date) AS close,
    sum(volume) AS total_volume,
    avg(volume) AS avg_volume,
    count(*) AS trading_days
FROM daily_prices
GROUP BY stock_code, month
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW daily_prices_monthly IS 'Monthly OHLC aggregates (continuous aggregate)';

-- Weekly aggregated prices
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_prices_weekly
WITH (timescaledb.continuous) AS
SELECT
    stock_code,
    time_bucket('1 week', trade_date) AS week,
    first(open_price, trade_date) AS open,
    max(high_price) AS high,
    min(low_price) AS low,
    last(close_price, trade_date) AS close,
    sum(volume) AS total_volume,
    avg(volume) AS avg_volume,
    count(*) AS trading_days
FROM daily_prices
GROUP BY stock_code, week
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW daily_prices_weekly IS 'Weekly OHLC aggregates (continuous aggregate)';

-- ============================================================================
-- REFRESH POLICIES (Automatic Updates)
-- ============================================================================

-- Refresh monthly view every week (keeps recent data fresh)
SELECT add_continuous_aggregate_policy(
    'daily_prices_monthly',
    start_offset => INTERVAL '2 months',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 week',
    if_not_exists => TRUE
);

-- Refresh weekly view every day
SELECT add_continuous_aggregate_policy(
    'daily_prices_weekly',
    start_offset => INTERVAL '2 months',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- ============================================================================
-- COMPRESSION POLICIES
-- ============================================================================

-- Enable compression on daily_prices for data older than 365 days
-- This can reduce storage by 90%+ for historical data
ALTER TABLE daily_prices SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'stock_code',
    timescaledb.compress_orderby = 'trade_date DESC'
);

-- Automatically compress chunks older than 1 year
SELECT add_compression_policy(
    'daily_prices',
    INTERVAL '365 days',
    if_not_exists => TRUE
);

COMMENT ON TABLE daily_prices IS 'TimescaleDB hypertable with automatic compression for data > 1 year old';

-- ============================================================================
-- RETENTION POLICIES (Optional - Uncomment if needed)
-- ============================================================================

-- Automatically drop data older than 10 years (optional)
-- Uncomment the following line if you want to limit historical data retention
-- SELECT add_retention_policy('daily_prices', INTERVAL '10 years', if_not_exists => TRUE);

-- ============================================================================
-- PERFORMANCE VERIFICATION
-- ============================================================================

-- View hypertable information
SELECT * FROM timescaledb_information.hypertables
WHERE hypertable_name = 'daily_prices';

-- View compression settings
SELECT * FROM timescaledb_information.compression_settings
WHERE hypertable_name = 'daily_prices';

-- View continuous aggregates
SELECT * FROM timescaledb_information.continuous_aggregates;

-- View chunk information (partitions)
SELECT
    chunk_name,
    range_start,
    range_end,
    pg_size_pretty(total_bytes) AS chunk_size,
    pg_size_pretty(compressed_total_bytes) AS compressed_size,
    compression_status
FROM timescaledb_information.chunks
WHERE hypertable_name = 'daily_prices'
ORDER BY range_start DESC
LIMIT 10;

-- ============================================================================
-- HELPER VIEWS FOR ANALYSIS
-- ============================================================================

-- Latest price for each stock (commonly used query)
CREATE OR REPLACE VIEW latest_prices AS
SELECT DISTINCT ON (stock_code)
    stock_code,
    trade_date,
    close_price,
    volume,
    market_cap
FROM daily_prices
ORDER BY stock_code, trade_date DESC;

COMMENT ON VIEW latest_prices IS 'Most recent price for each stock';

-- 52-week high/low for each stock
CREATE OR REPLACE VIEW stock_52w_highs_lows AS
SELECT
    dp.stock_code,
    s.name,
    s.market,
    MAX(dp.high_price) AS high_52w,
    MIN(dp.low_price) AS low_52w,
    (SELECT close_price FROM daily_prices WHERE stock_code = dp.stock_code ORDER BY trade_date DESC LIMIT 1) AS current_price,
    ROUND(
        ((SELECT close_price FROM daily_prices WHERE stock_code = dp.stock_code ORDER BY trade_date DESC LIMIT 1) - MIN(dp.low_price))::NUMERIC /
        (MAX(dp.high_price) - MIN(dp.low_price))::NUMERIC * 100,
        2
    ) AS pct_from_low_to_high
FROM daily_prices dp
JOIN stocks s ON dp.stock_code = s.code
WHERE dp.trade_date >= CURRENT_DATE - INTERVAL '52 weeks'
GROUP BY dp.stock_code, s.name, s.market;

COMMENT ON VIEW stock_52w_highs_lows IS '52-week high/low prices and position within range';

-- ============================================================================
-- SAMPLE QUERIES FOR VERIFICATION
-- ============================================================================

-- Check if hypertable is working (should show chunks)
-- SELECT show_chunks('daily_prices');

-- Example: Get last 30 days of prices for Samsung (005930)
-- SELECT * FROM daily_prices
-- WHERE stock_code = '005930'
--   AND trade_date >= CURRENT_DATE - INTERVAL '30 days'
-- ORDER BY trade_date DESC;

-- Example: Get monthly aggregates for Samsung
-- SELECT * FROM daily_prices_monthly
-- WHERE stock_code = '005930'
-- ORDER BY month DESC
-- LIMIT 12;

-- ============================================================================
-- TIMESCALEDB SETUP COMPLETE
-- ============================================================================

\echo 'TimescaleDB setup completed successfully!'
\echo 'Hypertable created: daily_prices'
\echo 'Continuous aggregates: daily_prices_monthly, daily_prices_weekly'
\echo 'Compression enabled: Data older than 1 year will be compressed'
\echo ''
\echo 'Next steps:'
\echo '  1. Run 03_indexes.sql to create performance indexes'
\echo '  2. Load initial data using data pipeline'
\echo '  3. Monitor compression with: SELECT * FROM timescaledb_information.chunks;'
