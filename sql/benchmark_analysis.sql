-- ============================================================
-- Investment Portfolio Performance & Risk Analysis
-- S&P 500 Benchmark Analysis
-- Tool: MySQL
-- ============================================================

USE INVESTMENT;

-- ------------------------------------------------------------
-- 1. Validate benchmark data
-- ------------------------------------------------------------

SELECT *
FROM benchmark
LIMIT 10;


-- ------------------------------------------------------------
-- 2. Validate benchmark date coverage
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS trading_days,
    MIN(trade_date) AS first_trade_date,
    MAX(trade_date) AS last_trade_date
FROM benchmark;


-- ------------------------------------------------------------
-- 3. Create benchmark daily returns
-- ------------------------------------------------------------

CREATE TABLE benchmark_returns AS

WITH benchmark_prices AS (
    SELECT
        trade_date,
        close_price,
        LAG(close_price) OVER (
            ORDER BY trade_date
        ) AS previous_close
    FROM benchmark
)

SELECT
    trade_date,
    close_price,
    previous_close,
    (close_price - previous_close) / previous_close AS daily_return
FROM benchmark_prices;


-- ------------------------------------------------------------
-- 4. Validate benchmark daily returns
-- ------------------------------------------------------------

SELECT
    trade_date,
    close_price,
    previous_close,
    daily_return
FROM benchmark_returns
ORDER BY trade_date
LIMIT 15;


-- ------------------------------------------------------------
-- 5. Benchmark cumulative return
-- ------------------------------------------------------------

SELECT
    ROUND(
        (EXP(SUM(LN(1 + daily_return))) - 1) * 100,
        2
    ) AS sp500_cumulative_return_pct
FROM benchmark_returns
WHERE daily_return IS NOT NULL;


-- ------------------------------------------------------------
-- 6. Benchmark CAGR
-- ------------------------------------------------------------

SELECT
    ROUND(
        (
            POW(
                EXP(SUM(LN(1 + daily_return))),
                365.25 /
                DATEDIFF(
                    MAX(trade_date),
                    MIN(trade_date)
                )
            ) - 1
        ) * 100,
        2
    ) AS sp500_cagr_pct
FROM benchmark_returns
WHERE daily_return IS NOT NULL;


-- ------------------------------------------------------------
-- 7. Benchmark annualized volatility
-- ------------------------------------------------------------

SELECT
    ROUND(
        STDDEV_SAMP(daily_return) * SQRT(252) * 100,
        2
    ) AS sp500_annualized_volatility_pct
FROM benchmark_returns
WHERE daily_return IS NOT NULL;


-- ------------------------------------------------------------
-- 8. Benchmark maximum drawdown
-- ------------------------------------------------------------

WITH cumulative_values AS (
    SELECT
        trade_date,
        EXP(
            SUM(LN(1 + daily_return))
            OVER (ORDER BY trade_date)
        ) AS benchmark_value
    FROM benchmark_returns
    WHERE daily_return IS NOT NULL
),

running_peaks AS (
    SELECT
        trade_date,
        benchmark_value,
        MAX(benchmark_value)
        OVER (
            ORDER BY trade_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_peak
    FROM cumulative_values
)

SELECT
    ROUND(
        MIN(
            (benchmark_value - running_peak)
            / running_peak
        ) * 100,
        2
    ) AS sp500_maximum_drawdown_pct
FROM running_peaks;


-- ------------------------------------------------------------
-- 9. Portfolio vs. S&P 500 cumulative return
-- ------------------------------------------------------------

SELECT
    'Portfolio' AS investment,
    ROUND(
        (EXP(SUM(LN(1 + portfolio_daily_return))) - 1) * 100,
        2
    ) AS cumulative_return_pct
FROM portfolio_daily_returns

UNION ALL

SELECT
    'S&P 500' AS investment,
    ROUND(
        (EXP(SUM(LN(1 + daily_return))) - 1) * 100,
        2
    ) AS cumulative_return_pct
FROM benchmark_returns
WHERE daily_return IS NOT NULL;
