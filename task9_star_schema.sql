CREATE TABLE dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id TEXT,
    customer_name TEXT,
    segment TEXT
);

CREATE TABLE dim_product (
    product_key SERIAL PRIMARY KEY,
    product_id TEXT,
    product_name TEXT,
    category TEXT,
    sub_category TEXT
);

CREATE TABLE dim_region (
    region_key SERIAL PRIMARY KEY,
    region TEXT,
    country TEXT,
    state TEXT,
    city TEXT
);

CREATE TABLE dim_date (
    date_key SERIAL PRIMARY KEY,
    order_date DATE,
    year INT,
    month INT,
    weeknum INT
);

CREATE TABLE fact_sales (
    sales_key SERIAL PRIMARY KEY,
    customer_key INT REFERENCES dim_customer(customer_key),
    product_key INT REFERENCES dim_product(product_key),
    region_key INT REFERENCES dim_region(region_key),
    date_key INT REFERENCES dim_date(date_key),
    sales NUMERIC,
    profit NUMERIC,
    quantity INT,
    discount NUMERIC
);

INSERT INTO dim_customer (customer_id, customer_name, segment)
SELECT DISTINCT customer_id, customer_name, segment
FROM superstore;

INSERT INTO dim_product (product_id, product_name, category, sub_category)
SELECT DISTINCT product_id, product_name, category, sub_category
FROM superstore;

INSERT INTO dim_region (region, country, state, city)
SELECT DISTINCT region, country, state, city
FROM superstore;

INSERT INTO dim_date (order_date, year, month, weeknum)
SELECT DISTINCT
    order_date,
    year,
    EXTRACT(MONTH FROM order_date),
    weeknum
FROM superstore;

TRUNCATE fact_sales;

INSERT INTO fact_sales (
    customer_key,
    product_key,
    region_key,
    date_key,
    sales,
    profit,
    quantity,
    discount
)
SELECT
    dc.customer_key,
    dp.product_key,
    dr.region_key,
    dd.date_key,
    s.sales,
    s.profit,
    s.quantity,
    s.discount
FROM public.superstore s
JOIN dim_customer dc 
    ON s.customer_id = dc.customer_id
JOIN dim_product dp 
    ON s.product_id = dp.product_id
JOIN dim_region dr 
    ON s.region = dr.region
   AND s.country = dr.country
   AND s.state = dr.state
   AND s.city = dr.city
JOIN dim_date dd 
    ON s.order_date = dd.order_date;

CREATE INDEX idx_fact_customer ON fact_sales(customer_key);
CREATE INDEX idx_fact_product ON fact_sales(product_key);
CREATE INDEX idx_fact_region ON fact_sales(region_key);
CREATE INDEX idx_fact_date ON fact_sales(date_key);

SELECT COUNT(*) FROM superstore;
SELECT COUNT(*) FROM fact_sales;

SELECT COUNT(*) FROM fact_sales
WHERE customer_key IS NULL
OR product_key IS NULL
OR region_key IS NULL
OR date_key IS NULL;

SELECT
    dp.category,
    SUM(fs.sales) AS total_sales
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
GROUP BY dp.category
ORDER BY total_sales DESC;
