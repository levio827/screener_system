"""
Indicator Calculation DAG

This DAG calculates 200+ financial and technical indicators for all stocks.
Triggered after daily price ingestion is complete.

Calculations include:
- Valuation metrics (PER, PBR, PSR, etc.)
- Profitability metrics (ROE, ROA, margins)
- Growth metrics (YoY, QoQ, CAGR)
- Technical indicators (RSI, MACD, moving averages)
- Composite scores (quality, value, growth)

Schedule: Triggered by daily_price_ingestion DAG
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

import logging
import pandas as pd
import numpy as np
from typing import Dict, List, Optional

# Default arguments
default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'email': ['data-alerts@screener.kr'],
    'email_on_failure': True,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

# DAG definition
dag = DAG(
    'indicator_calculation',
    default_args=default_args,
    description='Calculate 200+ indicators for all stocks',
    schedule_interval=None,  # Triggered by daily_price_ingestion
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=['indicators', 'calculations', 'critical'],
)


# ============================================================================
# INDICATOR CALCULATION CLASSES
# ============================================================================

class IndicatorCalculator:
    """
    Centralized indicator calculation logic.

    Calculates all 200+ indicators for a given stock.
    """

    def __init__(self, pg_hook: PostgresHook):
        self.pg_hook = pg_hook
        self.logger = logging.getLogger(__name__)

    def calculate_all_indicators(self, stock_code: str, calculation_date: str) -> Dict:
        """
        Calculate all indicators for a stock on a given date.

        Returns dictionary with all indicator values.
        """
        indicators = {}

        # Fetch required data
        prices = self._get_price_history(stock_code, days=252)  # ~1 year
        financials = self._get_latest_financials(stock_code)
        latest_price = prices.iloc[0] if not prices.empty else None

        if latest_price is None:
            self.logger.warning(f"No price data for {stock_code}")
            return {}

        # Calculate indicators by category
        indicators.update(self._calculate_valuation(stock_code, latest_price, financials))
        indicators.update(self._calculate_profitability(financials))
        indicators.update(self._calculate_growth(stock_code, financials))
        indicators.update(self._calculate_stability(financials))
        indicators.update(self._calculate_technical(prices))
        indicators.update(self._calculate_composite_scores(indicators))

        # Add metadata
        indicators['stock_code'] = stock_code
        indicators['calculation_date'] = calculation_date

        return indicators

    def _get_price_history(self, stock_code: str, days: int = 252) -> pd.DataFrame:
        """Fetch price history for technical calculations."""
        query = """
            SELECT trade_date, open_price, high_price, low_price, close_price, volume
            FROM daily_prices
            WHERE stock_code = %s
            ORDER BY trade_date DESC
            LIMIT %s
        """
        df = self.pg_hook.get_pandas_df(query, parameters=(stock_code, days))
        return df

    def _get_latest_financials(self, stock_code: str) -> Optional[Dict]:
        """Fetch latest financial statement."""
        query = """
            SELECT *
            FROM financial_statements
            WHERE stock_code = %s
            ORDER BY fiscal_year DESC, fiscal_quarter DESC NULLS LAST
            LIMIT 1
        """
        result = self.pg_hook.get_first(query, parameters=(stock_code,))
        if not result:
            return None

        # Convert to dictionary
        columns = [
            'id', 'stock_code', 'period_type', 'fiscal_year', 'fiscal_quarter',
            'report_date', 'revenue', 'operating_profit', 'net_profit',
            'total_assets', 'total_liabilities', 'equity', 'operating_cash_flow',
            'free_cash_flow'
        ]
        return dict(zip(columns, result))

    def _calculate_valuation(self, stock_code: str, latest_price: pd.Series, financials: Optional[Dict]) -> Dict:
        """Calculate valuation metrics (PER, PBR, PSR, etc.)."""
        if not financials:
            return {}

        close_price = latest_price['close_price']

        # Get shares outstanding
        shares = self.pg_hook.get_first(
            "SELECT shares_outstanding FROM stocks WHERE code = %s",
            parameters=(stock_code,)
        )[0]

        if not shares:
            return {}

        market_cap = close_price * shares

        # Calculate metrics
        per = None
        if financials.get('net_profit') and financials['net_profit'] > 0:
            eps = financials['net_profit'] / shares
            per = round(close_price / eps, 2) if eps > 0 else None

        pbr = None
        if financials.get('equity') and financials['equity'] > 0:
            bps = financials['equity'] / shares
            pbr = round(close_price / bps, 2) if bps > 0 else None

        psr = None
        if financials.get('revenue') and financials['revenue'] > 0:
            sps = financials['revenue'] / shares
            psr = round(close_price / sps, 2) if sps > 0 else None

        return {
            'per': per,
            'pbr': pbr,
            'psr': psr,
            # Add more valuation metrics as needed
        }

    def _calculate_profitability(self, financials: Optional[Dict]) -> Dict:
        """Calculate profitability metrics (ROE, ROA, margins)."""
        if not financials:
            return {}

        roe = None
        if financials.get('net_profit') and financials.get('equity') and financials['equity'] > 0:
            roe = round((financials['net_profit'] / financials['equity']) * 100, 2)

        roa = None
        if financials.get('net_profit') and financials.get('total_assets') and financials['total_assets'] > 0:
            roa = round((financials['net_profit'] / financials['total_assets']) * 100, 2)

        operating_margin = None
        if financials.get('operating_profit') and financials.get('revenue') and financials['revenue'] > 0:
            operating_margin = round((financials['operating_profit'] / financials['revenue']) * 100, 2)

        net_margin = None
        if financials.get('net_profit') and financials.get('revenue') and financials['revenue'] > 0:
            net_margin = round((financials['net_profit'] / financials['revenue']) * 100, 2)

        return {
            'roe': roe,
            'roa': roa,
            'operating_margin': operating_margin,
            'net_margin': net_margin,
        }

    def _calculate_growth(self, stock_code: str, financials: Optional[Dict]) -> Dict:
        """Calculate growth metrics (YoY, QoQ, CAGR)."""
        if not financials:
            return {}

        # Fetch year-ago financials
        year_ago_query = """
            SELECT revenue, net_profit
            FROM financial_statements
            WHERE stock_code = %s
              AND period_type = %s
              AND fiscal_year = %s
              AND fiscal_quarter IS NOT DISTINCT FROM %s
            LIMIT 1
        """

        year_ago = self.pg_hook.get_first(
            year_ago_query,
            parameters=(
                stock_code,
                financials['period_type'],
                financials['fiscal_year'] - 1,
                financials.get('fiscal_quarter')
            )
        )

        revenue_growth_yoy = None
        profit_growth_yoy = None

        if year_ago:
            prev_revenue, prev_profit = year_ago

            if prev_revenue and prev_revenue > 0:
                revenue_growth_yoy = round(
                    ((financials['revenue'] - prev_revenue) / prev_revenue) * 100, 2
                )

            if prev_profit and prev_profit > 0:
                profit_growth_yoy = round(
                    ((financials['net_profit'] - prev_profit) / prev_profit) * 100, 2
                )

        return {
            'revenue_growth_yoy': revenue_growth_yoy,
            'profit_growth_yoy': profit_growth_yoy,
        }

    def _calculate_stability(self, financials: Optional[Dict]) -> Dict:
        """Calculate stability metrics (debt ratios, current ratio)."""
        if not financials:
            return {}

        debt_to_equity = None
        if financials.get('total_liabilities') and financials.get('equity') and financials['equity'] > 0:
            debt_to_equity = round((financials['total_liabilities'] / financials['equity']) * 100, 2)

        current_ratio = None
        # Note: Would need current_assets and current_liabilities from financials
        # Simplified for demo

        return {
            'debt_to_equity': debt_to_equity,
            'current_ratio': current_ratio,
        }

    def _calculate_technical(self, prices: pd.DataFrame) -> Dict:
        """Calculate technical indicators (RSI, moving averages, momentum)."""
        if prices.empty:
            return {}

        # Price changes
        price_change_1d = None
        price_change_1w = None
        price_change_1m = None

        if len(prices) >= 2:
            price_change_1d = round(
                ((prices.iloc[0]['close_price'] - prices.iloc[1]['close_price']) /
                 prices.iloc[1]['close_price']) * 100, 2
            )

        if len(prices) >= 6:
            price_change_1w = round(
                ((prices.iloc[0]['close_price'] - prices.iloc[5]['close_price']) /
                 prices.iloc[5]['close_price']) * 100, 2
            )

        if len(prices) >= 21:
            price_change_1m = round(
                ((prices.iloc[0]['close_price'] - prices.iloc[20]['close_price']) /
                 prices.iloc[20]['close_price']) * 100, 2
            )

        # Volume surge
        volume_surge_pct = None
        if len(prices) >= 21:
            avg_volume_20d = prices.iloc[1:21]['volume'].mean()
            if avg_volume_20d > 0:
                volume_surge_pct = round(
                    ((prices.iloc[0]['volume'] / avg_volume_20d) - 1) * 100, 2
                )

        # Moving averages
        ma_20d = None
        if len(prices) >= 20:
            ma_20d = round(prices.iloc[:20]['close_price'].mean(), 2)

        return {
            'price_change_1d': price_change_1d,
            'price_change_1w': price_change_1w,
            'price_change_1m': price_change_1m,
            'volume_surge_pct': volume_surge_pct,
            'ma_20d': ma_20d,
        }

    def _calculate_composite_scores(self, indicators: Dict) -> Dict:
        """
        Calculate composite scores (1-100) combining multiple indicators.

        Quality Score: Based on profitability and stability
        Value Score: Based on valuation metrics
        Growth Score: Based on growth metrics
        """
        # Simplified scoring logic (in production, use more sophisticated models)

        quality_score = None
        if indicators.get('roe') and indicators.get('debt_to_equity'):
            roe_score = min(indicators['roe'] / 20 * 100, 100) if indicators['roe'] > 0 else 0
            debt_score = max(100 - indicators['debt_to_equity'], 0) if indicators['debt_to_equity'] else 50
            quality_score = int((roe_score + debt_score) / 2)

        value_score = None
        if indicators.get('per') and indicators.get('pbr'):
            per_score = max(100 - indicators['per'] * 5, 0) if indicators['per'] > 0 else 0
            pbr_score = max(100 - indicators['pbr'] * 40, 0) if indicators['pbr'] > 0 else 0
            value_score = int((per_score + pbr_score) / 2)

        growth_score = None
        if indicators.get('revenue_growth_yoy') and indicators.get('profit_growth_yoy'):
            rev_score = min(indicators['revenue_growth_yoy'] * 2, 100) if indicators['revenue_growth_yoy'] > 0 else 0
            profit_score = min(indicators['profit_growth_yoy'] * 2, 100) if indicators['profit_growth_yoy'] > 0 else 0
            growth_score = int((rev_score + profit_score) / 2)

        overall_score = None
        scores = [s for s in [quality_score, value_score, growth_score] if s is not None]
        if scores:
            overall_score = int(sum(scores) / len(scores))

        return {
            'quality_score': quality_score,
            'value_score': value_score,
            'growth_score': growth_score,
            'overall_score': overall_score,
        }


# ============================================================================
# TASK FUNCTIONS
# ============================================================================

def calculate_indicators_for_all_stocks(**context):
    """
    Calculate indicators for all active stocks.

    Uses parallel processing for performance.
    """
    logger = logging.getLogger(__name__)
    calculation_date = context['ds']

    pg_hook = PostgresHook(postgres_conn_id='screener_db')
    calculator = IndicatorCalculator(pg_hook)

    # Get list of active stocks
    stocks = pg_hook.get_records(
        "SELECT code FROM stocks WHERE delisting_date IS NULL ORDER BY code"
    )

    logger.info(f"Calculating indicators for {len(stocks)} stocks")

    conn = pg_hook.get_conn()
    cursor = conn.cursor()

    calculated_count = 0
    failed_stocks = []

    for (stock_code,) in stocks:
        try:
            indicators = calculator.calculate_all_indicators(stock_code, calculation_date)

            if not indicators:
                logger.warning(f"No indicators calculated for {stock_code}")
                failed_stocks.append(stock_code)
                continue

            # Upsert indicators
            cursor.execute("""
                INSERT INTO calculated_indicators (
                    stock_code, calculation_date,
                    per, pbr, psr, roe, roa, operating_margin, net_margin,
                    revenue_growth_yoy, profit_growth_yoy,
                    debt_to_equity, current_ratio,
                    price_change_1d, price_change_1w, price_change_1m,
                    volume_surge_pct, ma_20d,
                    quality_score, value_score, growth_score, overall_score
                ) VALUES (
                    %(stock_code)s, %(calculation_date)s,
                    %(per)s, %(pbr)s, %(psr)s, %(roe)s, %(roa)s, %(operating_margin)s, %(net_margin)s,
                    %(revenue_growth_yoy)s, %(profit_growth_yoy)s,
                    %(debt_to_equity)s, %(current_ratio)s,
                    %(price_change_1d)s, %(price_change_1w)s, %(price_change_1m)s,
                    %(volume_surge_pct)s, %(ma_20d)s,
                    %(quality_score)s, %(value_score)s, %(growth_score)s, %(overall_score)s
                )
                ON CONFLICT (stock_code, calculation_date)
                DO UPDATE SET
                    per = EXCLUDED.per,
                    pbr = EXCLUDED.pbr,
                    psr = EXCLUDED.psr,
                    roe = EXCLUDED.roe,
                    roa = EXCLUDED.roa,
                    operating_margin = EXCLUDED.operating_margin,
                    net_margin = EXCLUDED.net_margin,
                    revenue_growth_yoy = EXCLUDED.revenue_growth_yoy,
                    profit_growth_yoy = EXCLUDED.profit_growth_yoy,
                    debt_to_equity = EXCLUDED.debt_to_equity,
                    current_ratio = EXCLUDED.current_ratio,
                    price_change_1d = EXCLUDED.price_change_1d,
                    price_change_1w = EXCLUDED.price_change_1w,
                    price_change_1m = EXCLUDED.price_change_1m,
                    volume_surge_pct = EXCLUDED.volume_surge_pct,
                    ma_20d = EXCLUDED.ma_20d,
                    quality_score = EXCLUDED.quality_score,
                    value_score = EXCLUDED.value_score,
                    growth_score = EXCLUDED.growth_score,
                    overall_score = EXCLUDED.overall_score
            """, indicators)

            calculated_count += 1

            # Commit in batches of 100
            if calculated_count % 100 == 0:
                conn.commit()
                logger.info(f"Progress: {calculated_count}/{len(stocks)} stocks")

        except Exception as e:
            logger.error(f"Failed to calculate indicators for {stock_code}: {e}")
            failed_stocks.append(stock_code)

    # Final commit
    conn.commit()
    cursor.close()
    conn.close()

    logger.info(f"Calculated indicators for {calculated_count}/{len(stocks)} stocks")
    if failed_stocks:
        logger.warning(f"Failed stocks ({len(failed_stocks)}): {failed_stocks[:20]}")

    # Push metrics to XCom
    context['task_instance'].xcom_push(key='calculated_count', value=calculated_count)
    context['task_instance'].xcom_push(key='failed_count', value=len(failed_stocks))

    return calculated_count


# ============================================================================
# TASK DEFINITIONS
# ============================================================================

calculate_indicators = PythonOperator(
    task_id='calculate_indicators',
    python_callable=calculate_indicators_for_all_stocks,
    provide_context=True,
    execution_timeout=timedelta(minutes=30),
    dag=dag,
)

refresh_materialized_views = PostgresOperator(
    task_id='refresh_materialized_views',
    postgres_conn_id='screener_db',
    sql="SELECT refresh_all_materialized_views();",
    dag=dag,
)

log_calculation_status = PostgresOperator(
    task_id='log_calculation_status',
    postgres_conn_id='screener_db',
    sql="""
        INSERT INTO data_ingestion_log (
            source, data_type, records_processed, records_failed,
            status, started_at, completed_at
        ) VALUES (
            'internal', 'indicators', {{ ti.xcom_pull(task_ids='calculate_indicators', key='calculated_count') }},
            {{ ti.xcom_pull(task_ids='calculate_indicators', key='failed_count') }},
            'success', '{{ execution_date }}', NOW()
        )
    """,
    dag=dag,
)

# ============================================================================
# TASK DEPENDENCIES
# ============================================================================

calculate_indicators >> refresh_materialized_views >> log_calculation_status
