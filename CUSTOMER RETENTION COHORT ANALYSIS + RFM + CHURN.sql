-- CUSTOMER RETENTION COHORT ANALYSIS + RFM + CHURN
-- Dataset: Online Retail II 

--CREATE RAW TABLE
DROP TABLE IF EXISTS raw_transactions;

CREATE TABLE raw_transactions (
    invoice         VARCHAR(20),
    stock_code      VARCHAR(20),
    descr     NVARCHAR(MAX),
    quantity        INT,
    invoice_date    DATETIME,
    price           DECIMAL(10,2),
    customer_id     INT,
    country         VARCHAR(50)
);
Use MyDatabase
select * from raw_transactions 

-- LOAD DATA
BULK INSERT raw_transactions
FROM 'C:\Users\MEHAK\Downloads\online_retail_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

-- CLEAN THE DATA
-- Remove cancelled invoices (Invoice starting with 'C'), null customer_id,
-- non-positive quantity/price
DROP TABLE IF EXISTS clean_transactions;

SELECT
    invoice,
    stock_code,
    descr,
    quantity,
    invoice_date,
    price,
    customer_id,
    country,
    (quantity * price) AS line_total
INTO clean_transactions
FROM raw_transactions
WHERE customer_id IS NOT NULL
  AND quantity > 0
  AND price > 0
  AND invoice NOT LIKE 'C%';   

-- Quick sanity check 
SELECT
    COUNT(*)                       AS total_line_items,
    COUNT(DISTINCT invoice)        AS total_orders,
    COUNT(DISTINCT customer_id)    AS total_customers,
    MIN(invoice_date)              AS date_range_start,
    MAX(invoice_date)              AS date_range_end,
    ROUND(SUM(line_total), 2)      AS total_revenue
FROM clean_transactions;


-- COHORT ANALYSIS

-- Assign each customer to a cohort = month of their first purchase
DROP TABLE IF EXISTS customer_cohort;

SELECT
    customer_id,
    CAST(DATEFROMPARTS(YEAR(MIN(invoice_date)), MONTH(MIN(invoice_date)), 1) AS DATE) AS cohort_month
INTO customer_cohort
FROM clean_transactions
GROUP BY customer_id;

-- For every transaction, compute the "cohort index" (how many months after their first purchase this order happened)
DROP TABLE IF EXISTS cohort_activity;

SELECT
    t.customer_id,
    c.cohort_month,
    CAST(DATEFROMPARTS(YEAR(t.invoice_date), MONTH(t.invoice_date), 1) AS DATE) AS activity_month,
    (YEAR(t.invoice_date)  - YEAR(c.cohort_month))  * 12
  + (MONTH(t.invoice_date) - MONTH(c.cohort_month))   AS cohort_index
INTO cohort_activity
FROM clean_transactions t
JOIN customer_cohort c ON t.customer_id = c.customer_id;

-- Cohort size (how many customers started in each cohort)
DROP TABLE IF EXISTS cohort_size;

SELECT cohort_month, COUNT(DISTINCT customer_id) AS num_customers
INTO cohort_size
FROM customer_cohort
GROUP BY cohort_month;

--  Retention counts: distinct customers active per cohort per month-offset
DROP TABLE IF EXISTS cohort_retention_counts;

SELECT
    cohort_month,
    cohort_index,
    COUNT(DISTINCT customer_id) AS active_customers
INTO cohort_retention_counts
FROM cohort_activity
GROUP BY cohort_month, cohort_index;

--  FINAL cohort retention table (% retained)
SELECT
    r.cohort_month,
    r.cohort_index,
    r.active_customers,
    s.num_customers AS cohort_size,
    ROUND(100.0 * r.active_customers / s.num_customers, 1) AS retention_pct
FROM cohort_retention_counts r
JOIN cohort_size s ON r.cohort_month = s.cohort_month
ORDER BY r.cohort_month, r.cohort_index;



--RFM SEGMENTATION

DROP TABLE IF EXISTS rfm_base;

SELECT
    customer_id,
    DATEDIFF(DAY, MAX(invoice_date), (SELECT MAX(invoice_date) FROM clean_transactions)) AS recency_days,
    COUNT(DISTINCT invoice) AS frequency,
    ROUND(SUM(line_total), 2) AS monetary
INTO rfm_base
FROM clean_transactions
GROUP BY customer_id;

-- Score each dimension 1-5 using NTILE (5 = best)
DROP TABLE IF EXISTS rfm_scored;

SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    -- lower recency_days = better, so invert the ntile
    (6 - NTILE(5) OVER (ORDER BY recency_days))      AS r_score,
    NTILE(5) OVER (ORDER BY frequency)                AS f_score,
    NTILE(5) OVER (ORDER BY monetary)                 AS m_score
INTO rfm_scored
FROM rfm_base;

-- Combine into segments
DROP TABLE IF EXISTS rfm_segments;

SELECT
    *,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2                  THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2  THEN 'Lost'
        ELSE 'Needs Attention'
    END AS segment
INTO rfm_segments
FROM rfm_scored;

-- Segment summary: size and revenue share per segment
SELECT
    segment,
    COUNT(*) AS num_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers,
    ROUND(SUM(monetary), 2) AS segment_revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_of_revenue
FROM rfm_segments
GROUP BY segment
ORDER BY segment_revenue DESC;



-- CHURN FLAG (target label)

DROP TABLE IF EXISTS churn_flagged;

SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    CASE WHEN recency_days > 90 THEN 1 ELSE 0 END AS churned
INTO churn_flagged
FROM rfm_base;

-- Overall churn rate
SELECT
    SUM(CASE WHEN churned = 1 THEN 1 ELSE 0 END)                              AS churned_customers,
    COUNT(*)                                                                   AS total_customers,
    ROUND(100.0 * SUM(CASE WHEN churned = 1 THEN 1 ELSE 0 END) / COUNT(*), 1)  AS churn_rate_pct
FROM churn_flagged;