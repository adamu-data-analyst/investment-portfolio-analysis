-- ============================================================
-- Investment Portfolio Performance & Risk Analysis
-- Data Preparation & Daily Stock Returns
-- Tool: MySQL
-- ============================================================

CREATE DATABASE INVESTMENT;
USE INVESTMENT;

-- ------------------------------------------------------------
-- 1. Create raw stock table
-- ------------------------------------------------------------

CREATE TABLE stocks (
    open_price DECIMAL(15,4),
    high_price DECIMAL(15,4),
    low_price DECIMAL(15,4),
    close_price DECIMAL(15,4),
    volume BIGINT,
    stock_name VARCHAR(20),
    trade_date VARCHAR(20)
);

-- ------------------------------------------------------------
-- 2. Convert trade_date from text to DATE
-- ------------------------------------------------------------

ALTER TABLE stocks
ADD COLUMN traded_date DATE;

SET SQL_SAFE_UPDATES = 0;

UPDATE stocks
SET traded_date = STR_TO_DATE(trade_date, '%Y-%m-%d');

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE stocks
DROP COLUMN trade_date;

ALTER TABLE stocks
CHANGE traded_date trade_date DATE;

-- ------------------------------------------------------------
-- 3. Validate the dataset
-- ------------------------------------------------------------

SELECT *
FROM stocks
LIMIT 10;

SELECT
    stock_name,
    COUNT(*) AS trading_days,
    MIN(trade_date) AS first_trade_date,
    MAX(trade_date) AS last_trade_date
FROM stocks
GROUP BY stock_name
ORDER BY stock_name;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT stock_name) AS number_of_stocks,
    COUNT(DISTINCT trade_date) AS trading_dates
FROM stocks;

-- ------------------------------------------------------------
-- 4. Validate previous closing price using LAG()
-- ------------------------------------------------------------

SELECT
    stock_name,
    trade_date,
    close_price,
    LAG(close_price) OVER (
        PARTITION BY stock_name
        ORDER BY trade_date
    ) AS previous_close
FROM stocks
ORDER BY stock_name, trade_date
LIMIT 15;

-- ------------------------------------------------------------
-- 5. Preview daily return calculation
-- ------------------------------------------------------------

WITH stock_prices AS (
    SELECT
        stock_name,
        trade_date,
        close_price,
        LAG(close_price) OVER (
            PARTITION BY stock_name
            ORDER BY trade_date
        ) AS previous_close
    FROM stocks
)
SELECT
    stock_name,
    trade_date,
    close_price,
    previous_close,
    ROUND(
        (close_price - previous_close) / previous_close * 100,
        2
    ) AS daily_return_pct
FROM stock_prices
ORDER BY stock_name, trade_date
LIMIT 15;

-- ------------------------------------------------------------
-- 6. Create stock_returns table
-- ------------------------------------------------------------

CREATE TABLE stock_returns AS

WITH price_data AS (
    SELECT
        stock_name,
        trade_date,
        close_price,
        LAG(close_price) OVER (
            PARTITION BY stock_name
            ORDER BY trade_date
        ) AS previous_close
    FROM stocks
)

SELECT
    stock_name,
    trade_date,
    close_price,
    previous_close,
    (close_price - previous_close) / previous_close AS daily_return
FROM price_data;

-- ------------------------------------------------------------
-- 7. Validate the final return table
-- ------------------------------------------------------------

SELECT *
FROM stock_returns
ORDER BY stock_name, trade_date
LIMIT 15;
