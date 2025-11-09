#!/bin/bash

# ============================================================================
# run_migrations.sh
# Description: Execute all database migrations in sequence
# Usage: ./run_migrations.sh [database_name] [username]
# ============================================================================

set -e  # Exit on error

# Configuration
DB_NAME="${1:-screener_db}"
DB_USER="${2:-screener_user}"
DB_HOST="${3:-localhost}"
DB_PORT="${4:-5432}"
MIGRATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../migrations" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Database Migration Script"
echo "=========================================="
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Host: $DB_HOST:$DB_PORT"
echo "Migrations Directory: $MIGRATIONS_DIR"
echo "=========================================="
echo ""

# Check if psql is installed
if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: psql is not installed${NC}"
    echo "Please install PostgreSQL client tools"
    exit 1
fi

# Test database connection
echo -e "${YELLOW}Testing database connection...${NC}"
if ! PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c '\q' 2>/dev/null; then
    echo -e "${RED}Error: Cannot connect to database${NC}"
    echo "Please check your credentials and ensure PostgreSQL is running"
    echo ""
    echo "Set password with: export PGPASSWORD=your_password"
    exit 1
fi
echo -e "${GREEN}✓ Database connection successful${NC}"
echo ""

# Execute migrations in order
MIGRATION_FILES=(
    "00_extensions.sql"
    "01_create_tables.sql"
    "02_timescaledb_setup.sql"
    "03_indexes.sql"
    "04_functions_triggers.sql"
    "05_views.sql"
)

for migration in "${MIGRATION_FILES[@]}"; do
    MIGRATION_PATH="$MIGRATIONS_DIR/$migration"

    if [ ! -f "$MIGRATION_PATH" ]; then
        echo -e "${RED}Error: Migration file not found: $migration${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Running migration: $migration${NC}"

    if PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$MIGRATION_PATH"; then
        echo -e "${GREEN}✓ $migration completed successfully${NC}"
    else
        echo -e "${RED}✗ $migration failed${NC}"
        exit 1
    fi

    echo ""
done

echo "=========================================="
echo -e "${GREEN}All migrations completed successfully!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Load seed data: ./scripts/seed_dev.sh"
echo "  2. Verify schema: psql -U $DB_USER -d $DB_NAME -c '\dt'"
echo "  3. Refresh materialized views: psql -U $DB_USER -d $DB_NAME -c 'SELECT refresh_all_materialized_views();'"
echo ""
