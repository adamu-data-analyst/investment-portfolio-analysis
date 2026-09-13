-- Portfolio performance, risk and return analysis
-- ============================================================
-- Investment Portfolio Performance & Risk Analysis
-- Portfolio Performance Analysis
-- Tool: MySQL
-- ============================================================

USE INVESTMENT;

-- ------------------------------------------------------------
-- 1. Individual stock cumulative returns
-- ------------------------------------------------------------

SELECT
    stock_name,
    ROUND(
        (EXP(SUM(LN(1 + daily_return))) - 1) * 100,
        2
    ) AS cumulative_return_pct
FROM stock_returns
WHERE daily_return IS NOT NULL
GROUP BY stock_name
ORDER BY cumulative_return_pct DESC;


-- ------------------------------------------------------------
-- 2. Individual stock CAGR
-- ------------------------------------------------------------

WITH stock_periods AS (
    SELECT
        stock_name,
        MIN(trade_date) AS first_date,
        MAX(trade_date) AS last_date,
        EXP(SUM(LN(1 + daily_return))) AS growth_factor
    FROM stock_returns
    WHERE daily_return IS NOT NULL
    GROUP BY stock_name
)

SELECT
    stock_name,
    ROUND(
        (POW(
            growth_factor,
            365.25 / DATEDIFF(last_date, first_date)
        ) - 1) * 100,
        2
    ) AS cagr_pct
FROM stock_periods
ORDER BY cagr_pct DESC;


-- ------------------------------------------------------------
-- 3. Portfolio daily return
-- Equal-weight portfolio: 1/9 weight per stock
-- ------------------------------------------------------------

CREATE TABLE portfolio_daily_returns AS
SELECT
    trade_date,
    AVG(daily_return) AS portfolio_daily_return
FROM stock_returns
WHERE daily_return IS NOT NULL
GROUP BY trade_date
ORDER BY trade_date;


-- ------------------------------------------------------------
-- 4. Portfolio cumulative return
-- ------------------------------------------------------------

SELECT
    ROUND(
        (EXP(SUM(LN(1 + portfolio_daily_return))) - 1) * 100,
        2
    ) AS portfolio_cumulative_return_pct
FROM portfolio_daily_returns;


-- ------------------------------------------------------------
-- 5. Portfolio CAGR
-- ------------------------------------------------------------

SELECT
    ROUND(
        (
            POW(
                EXP(SUM(LN(1 + portfolio_daily_return))),
                365.25 /
                DATEDIFF(
                    MAX(trade_date),
                    MIN(trade_date)
                )
            ) - 1
        ) * 100,
        2
    ) AS portfolio_cagr_pct
FROM portfolio_daily_returns;


-- ------------------------------------------------------------
-- 6. Portfolio annualized volatility
-- ------------------------------------------------------------

SELECT
    ROUND(
        STDDEV_SAMP(portfolio_daily_return) * SQRT(252) * 100,
        2
    ) AS portfolio_annualized_volatility_pct
FROM portfolio_daily_returns;


-- ------------------------------------------------------------
-- 7. Portfolio maximum drawdown
-- ------------------------------------------------------------

WITH cumulative_values AS (
    SELECT
        trade_date,
        EXP(
            SUM(LN(1 + portfolio_daily_return))
            OVER (ORDER BY trade_date)
        ) AS portfolio_value
    FROM portfolio_daily_returns
),

running_peaks AS (
    SELECT
        trade_date,
        portfolio_value,
        MAX(portfolio_value)
        OVER (
            ORDER BY trade_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_peak
    FROM cumulative_values
)

SELECT
    ROUND(
        MIN(
            (portfolio_value - running_peak)
            / running_peak
        ) * 100,
        2
    ) AS maximum_drawdown_pct
FROM running_peaks;


-- ------------------------------------------------------------
-- 8. Portfolio Sharpe ratio
-- Assumes a zero risk-free rate
-- ------------------------------------------------------------

SELECT
    ROUND(
        (
            AVG(portfolio_daily_return)
            / STDDEV_SAMP(portfolio_daily_return)
        ) * SQRT(252),
        2
    ) AS portfolio_sharpe_ratio
FROM portfolio_daily_returns;
