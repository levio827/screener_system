-- ============================================================================
-- Migration: 00_extensions.sql
-- Description: Install required PostgreSQL extensions
-- Author: Database Team
-- Created: 2025-11-09
-- ============================================================================

-- Enable TimescaleDB for time-series data optimization
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- Enable pg_trgm for fuzzy text search (stock names)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Enable UUID generation (for session tokens, API keys)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable cryptographic functions (password hashing fallback)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Verify extensions are installed
SELECT
    extname AS "Extension",
    extversion AS "Version"
FROM pg_extension
WHERE extname IN ('timescaledb', 'pg_trgm', 'uuid-ossp', 'pgcrypto')
ORDER BY extname;

-- ============================================================================
-- Notes:
-- - TimescaleDB must be added to postgresql.conf: shared_preload_libraries = 'timescaledb'
-- - After installing TimescaleDB, restart PostgreSQL
-- - These extensions are immutable and safe to run multiple times
-- ============================================================================
