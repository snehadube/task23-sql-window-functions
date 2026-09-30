-- =====================================================================
-- SQL Window Functions Intro  |  Dataset: AdventureWorks 2022 (denormalized)
-- Database: PostgreSQL  |  Table: sales   (one row = one order line item)
-- Functions covered: ROW_NUMBER, RANK, DENSE_RANK, LAG (+ SUM OVER bonus)
-- =====================================================================

-- ---------- TABLE SETUP (run once) ----------
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    sales_order_number     VARCHAR(20),
    order_date             DATE,
    quantity               INT,
    unit_price             NUMERIC(12,2),
    total_sales            NUMERIC(14,2),
    cost                   NUMERIC(14,2),
    product_name           VARCHAR(100),
    reseller_name          VARCHAR(150),
    reseller_country       VARCHAR(50),
    salesperson_fullname   VARCHAR(100),
    sales_territory_region VARCHAR(50),
    sales_territory_group  VARCHAR(50)
);
-- Import adventureworks_clean.csv via pgAdmin (Import/Export, Header = ON, Delimiter = ,)

-- ---------- Q1 ----------
-- ROW_NUMBER: har order ke andar line items ko sales value ke hisaab se number do.
SELECT sales_order_number, product_name, total_sales,
       ROW_NUMBER() OVER (PARTITION BY sales_order_number ORDER BY total_sales DESC) AS line_rank
FROM sales
WHERE sales_order_number IN ('SO43666','SO43667','SO43676')
ORDER BY sales_order_number, line_rank;

-- ---------- Q2 ----------
-- ROW_NUMBER: har reseller ka sabse RECENT order (top-1-per-group / dedup pattern).
WITH orders AS (
    SELECT sales_order_number, reseller_name, MAX(order_date) AS order_date,
           SUM(total_sales) AS order_value
    FROM sales
    GROUP BY sales_order_number, reseller_name
), numbered AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY reseller_name ORDER BY order_date DESC, sales_order_number DESC) AS rn
    FROM orders
)
SELECT reseller_name, sales_order_number, order_date, order_value
FROM numbered
WHERE rn = 1
ORDER BY order_value DESC
LIMIT 10;

-- ---------- Q3 ----------
-- ROW_NUMBER: har sales territory region ke top 3 products (total sales se).
WITH product_sales AS (
    SELECT sales_territory_region, product_name, SUM(total_sales) AS sales
    FROM sales
    GROUP BY sales_territory_region, product_name
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY sales_territory_region ORDER BY sales DESC) AS rn
    FROM product_sales
)
SELECT sales_territory_region, rn AS position, product_name, sales
FROM ranked
WHERE rn <= 3
ORDER BY sales_territory_region, rn;

-- ---------- Q4 ----------
-- RANK: salespeople ko total sales ke hisaab se rank karo.
SELECT salesperson_fullname,
       SUM(total_sales) AS total_sales,
       RANK() OVER (ORDER BY SUM(total_sales) DESC) AS sales_rank
FROM sales
GROUP BY salesperson_fullname
ORDER BY sales_rank;

-- ---------- Q5 ----------
-- RANK partitioned: har territory group ke andar top 3 salespeople.
WITH sp AS (
    SELECT sales_territory_group, salesperson_fullname, SUM(total_sales) AS total_sales
    FROM sales
    GROUP BY sales_territory_group, salesperson_fullname
), ranked AS (
    SELECT *, RANK() OVER (PARTITION BY sales_territory_group ORDER BY total_sales DESC) AS rnk
    FROM sp
)
SELECT sales_territory_group, rnk, salesperson_fullname, total_sales
FROM ranked
WHERE rnk <= 3
ORDER BY sales_territory_group, rnk;

-- ---------- Q6 ----------
-- ROW_NUMBER vs RANK vs DENSE_RANK side by side (ties wale products, units sold pe).
WITH units AS (
    SELECT product_name, SUM(quantity) AS units_sold
    FROM sales
    GROUP BY product_name
), ranked AS (
    SELECT product_name, units_sold,
           ROW_NUMBER() OVER (ORDER BY units_sold DESC) AS row_num,
           RANK()       OVER (ORDER BY units_sold DESC) AS rnk,
           DENSE_RANK() OVER (ORDER BY units_sold DESC) AS dense_rnk
    FROM units
)
SELECT *
FROM ranked
WHERE rnk BETWEEN 100 AND 112
ORDER BY row_num;

-- ---------- Q7 ----------
-- DENSE_RANK: har reseller country me resellers ko sales se rank karo, sirf top 2 dikhao.
WITH rs AS (
    SELECT reseller_country, reseller_name, SUM(total_sales) AS total_sales
    FROM sales
    GROUP BY reseller_country, reseller_name
), ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY reseller_country ORDER BY total_sales DESC) AS drnk
    FROM rs
)
SELECT reseller_country, drnk, reseller_name, total_sales
FROM ranked
WHERE drnk <= 2
ORDER BY reseller_country, drnk;

-- ---------- Q8 ----------
-- LAG: monthly sales aur pichhle mahine ki sales.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::DATE AS month, SUM(total_sales) AS sales
    FROM sales
    GROUP BY 1
)
SELECT month, sales,
       LAG(sales) OVER (ORDER BY month) AS prev_month_sales
FROM monthly
ORDER BY month;

-- ---------- Q9 ----------
-- LAG: month-over-month growth % (trend).
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::DATE AS month, SUM(total_sales) AS sales
    FROM sales
    GROUP BY 1
)
SELECT month, sales,
       sales - LAG(sales) OVER (ORDER BY month) AS change_amt,
       ROUND(100.0 * (sales - LAG(sales) OVER (ORDER BY month))
             / LAG(sales) OVER (ORDER BY month), 2) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- ---------- Q10 ----------
-- LAG with PARTITION BY: territory group ke hisaab se year-over-year growth.
-- Note: 2017 (Jul-Dec) aur 2020 (Jan-May) adhoore saal hain.
WITH yearly AS (
    SELECT sales_territory_group, EXTRACT(YEAR FROM order_date)::INT AS yr, SUM(total_sales) AS sales
    FROM sales
    GROUP BY 1, 2
)
SELECT sales_territory_group, yr, sales,
       LAG(sales) OVER (PARTITION BY sales_territory_group ORDER BY yr) AS prev_year_sales,
       ROUND(100.0 * (sales - LAG(sales) OVER (PARTITION BY sales_territory_group ORDER BY yr))
             / LAG(sales) OVER (PARTITION BY sales_territory_group ORDER BY yr), 2) AS yoy_growth_pct
FROM yearly
ORDER BY sales_territory_group, yr;

-- ---------- Q11 ----------
-- LAG: ek reseller ke do orders ke beech kitne din (repeat purchase gap).
WITH orders AS (
    SELECT sales_order_number, reseller_name, MAX(order_date) AS order_date, SUM(total_sales) AS order_value
    FROM sales
    GROUP BY sales_order_number, reseller_name
), gaps AS (
    SELECT reseller_name, sales_order_number, order_date, order_value,
           order_date - LAG(order_date) OVER (PARTITION BY reseller_name ORDER BY order_date, sales_order_number) AS days_since_prev_order
    FROM orders
)
SELECT reseller_name, COUNT(days_since_prev_order) AS repeat_orders,
       ROUND(AVG(days_since_prev_order), 1) AS avg_gap_days
FROM gaps
GROUP BY reseller_name
HAVING COUNT(days_since_prev_order) >= 8
ORDER BY avg_gap_days
LIMIT 10;

-- ---------- Q12 ----------
-- BONUS: SUM() OVER = running total, plus LAG se pichhle mahine se compare.
WITH monthly AS (
    SELECT EXTRACT(YEAR FROM order_date)::INT AS yr,
           DATE_TRUNC('month', order_date)::DATE AS month,
           SUM(total_sales) AS sales
    FROM sales
    GROUP BY 1, 2
)
SELECT yr, month, sales,
       SUM(sales) OVER (PARTITION BY yr ORDER BY month) AS ytd_sales,
       CASE WHEN sales > LAG(sales) OVER (PARTITION BY yr ORDER BY month) THEN 'Up'
            WHEN sales < LAG(sales) OVER (PARTITION BY yr ORDER BY month) THEN 'Down'
            ELSE '-' END AS vs_prev_month
FROM monthly
ORDER BY month;
