-- ============================================
-- 01_data_exploration.sql
-- Project: E-commerce Profitability and Growth Analysis
-- Purpose: Initial data exploration and sanity checks on RAW data
-- Notes:
-- - At this stage we DO NOT modify data.
-- - We only inspect schema, scale, date coverage and data quality issues.
-- ============================================

-- ----------------------------
-- 1) Schema / column names
-- ----------------------------
PRAGMA table_info(online_retail_raw);

-- ----------------------------
-- 2) Dataset size (scale)
-- ----------------------------
SELECT COUNT(*) AS total_rows
FROM online_retail_raw;

-- ----------------------------
-- 3) Quick sample preview
-- ----------------------------
SELECT *
FROM online_retail_raw
LIMIT 10;

-- ----------------------------
-- 4) Raw date range (as stored in RAW table)
-- NOTE: This is lexical MIN/MAX if InvoiceDate is text.
-- We'll parse dates properly in staging/cleaning step.
-- ----------------------------
SELECT
  MIN(InvoiceDate) AS min_invoice_date_raw,
  MAX(InvoiceDate) AS max_invoice_date_raw
FROM online_retail_raw;

-- Optional: confirm if 2010 exists (useful when MIN/MAX looks wrong)
SELECT COUNT(*) AS rows_with_2010
FROM online_retail_raw
WHERE InvoiceDate LIKE '%2010%';

-- ----------------------------
-- 5) Missing / suspicious values in key fields
-- ----------------------------
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
  SUM(CASE WHEN TRIM(COALESCE(Description, '')) = '' THEN 1 ELSE 0 END) AS missing_description
FROM online_retail_raw;

-- ----------------------------
-- 6) Cancelled invoices (InvoiceNo starting with 'C')
-- ----------------------------
SELECT COUNT(*) AS cancelled_rows
FROM online_retail_raw
WHERE InvoiceNo LIKE 'C%';

-- ----------------------------
-- 7) Invalid quantities / prices (non-positive)
-- ----------------------------
SELECT
  SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS invalid_quantity_rows,
  SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS invalid_price_rows
FROM online_retail_raw;

-- ----------------------------
-- 8) Country coverage
-- ----------------------------
SELECT COUNT(DISTINCT Country) AS country_count
FROM online_retail_raw;

-- Optional: top countries by row count (sanity check)
SELECT
  Country,
  COUNT(*) AS row_count
FROM online_retail_raw
GROUP BY Country
ORDER BY row_count DESC
LIMIT 10;

-- ----------------------------
-- 9) Data quality summary (counts + % of total)
-- Helpful for README/portfolio narrative
-- ----------------------------
WITH stats AS (
  SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END) AS cancelled_rows,
    SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS invalid_qty_rows,
    SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS invalid_price_rows,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS missing_customer_id_rows
  FROM online_retail_raw
)
SELECT
  total_rows,
  cancelled_rows,
  ROUND(1.0 * cancelled_rows / total_rows, 4) AS cancelled_pct,
  invalid_qty_rows,
  ROUND(1.0 * invalid_qty_rows / total_rows, 4) AS invalid_qty_pct,
  invalid_price_rows,
  ROUND(1.0 * invalid_price_rows / total_rows, 4) AS invalid_price_pct,
  missing_customer_id_rows,
  ROUND(1.0 * missing_customer_id_rows / total_rows, 4) AS missing_customer_id_pct
FROM stats;
