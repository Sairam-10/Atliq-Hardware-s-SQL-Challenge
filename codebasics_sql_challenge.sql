# Codebasics SQL Challenge

#1 Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT 
market
FROM dim_customer
WHERE region="APAC" AND customer="Atliq Exclusive";

#2 What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

WITH CTE1 AS(
SELECT 
count(distinct(product_code)) AS unique_products_2020
FROM fact_sales_monthly 
WHERE fiscal_year=2020),
CTE2 AS(
SELECT 
count(distinct(product_code)) AS unique_products_2021
FROM fact_sales_monthly 
WHERE fiscal_year=2021)
SELECT 
    CTE1.unique_products_2020,
    CTE2.unique_products_2021,
    ROUND((CTE2.unique_products_2021 - CTE1.unique_products_2020) * 100.0 / CTE1.unique_products_2020, 2) AS pct_change
FROM CTE1, CTE2;

#3 Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields, 
-- segment 
-- product_count

SELECT 
    segment,
    COUNT(DISTINCT product) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count desc;

#4 Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields, 
-- segment 
-- product_count_2020 
-- product_count_2021 
-- difference

WITH CTE1 AS(
SELECT 
    p.segment,
    COUNT(DISTINCT product) AS product_count_2020
FROM dim_product p
JOIN fact_sales_monthly s ON s.product_code=p.product_code
WHERE s.fiscal_year=2020
GROUP BY p.segment),
CTE2 AS(
SELECT 
    p.segment,
    COUNT(DISTINCT product) AS product_count_2021
FROM dim_product p
JOIN fact_sales_monthly s ON s.product_code=p.product_code
WHERE s.fiscal_year=2021
GROUP BY p.segment)
SELECT
CTE1.segment,
CTE1.product_count_2020,
CTE2.product_count_2021,
(CTE2.product_count_2021-CTE1.product_count_2020) as difference
FROM CTE1, CTE2
ORDER BY difference desc
LIMIT 1;

#5 Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, 
-- product_code 
-- product 
-- manufacturing_cost

WITH CTE1 AS(SELECT
p.product_code,
p.product,
ROUND(m.manufacturing_cost,2) AS manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m ON m.product_code=p.product_code
WHERE m.cost_year=2021
ORDER BY manufacturing_cost desc
LIMIT 1),
CTE2 AS(
SELECT
p.product_code,
p.product,
ROUND(m.manufacturing_cost,2) AS manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m ON m.product_code=p.product_code
WHERE m.cost_year=2021
ORDER BY manufacturing_cost
LIMIT 1)
SELECT
*
FROM CTE1
UNION
SELECT
*
FROM CTE2;

#6 Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
-- The final output contains these fields, 
-- customer_code 
-- customer 
-- average_discount_percentage

WITH CTE1 AS(
SELECT 
c.customer_code,
c.customer,
ROUND(avg(p.pre_invoice_discount_pct),4) as avg_discount_pct
FROM fact_pre_invoice_deductions p
JOIN dim_customer c ON p.customer_code=c.customer_code
WHERE p.fiscal_year=2021 AND c.market="INDIA"
GROUP BY c.customer_code, c.customer)
SELECT 
customer_code,
customer,
avg_discount_pct*100 as avg_discount_pct
FROM CTE1
ORDER BY avg_discount_pct desc
LIMIT 5;

#7 Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
-- The final report contains these columns: 
-- Month 
-- Year 
-- Gross sales Amount

CREATE temporary table gross_sales AS
SELECT
s.date,
s.fiscal_year,
s.customer_code,
s.product_code,
g.gross_price,
s.sold_quantity,
(g.gross_price*s.sold_quantity) AS gross_sales_amount
FROM fact_sales_monthly s
JOIN fact_gross_price g ON g.product_code=s.product_code AND g.fiscal_year=s.fiscal_year;

SELECT
year(date) as year,
month(s.date) as month,
ROUND(SUM(s.gross_sales_amount/1000000),2) as gross_sales_mln
FROM gross_sales s
JOIN dim_customer c ON s.customer_code=c.customer_code
WHERE customer="Atliq Exclusive"
GROUP BY month(s.date),year(date)
ORDER BY year, month;

#8 Which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity,
-- fiscal_year
-- Quarter 
-- total_sold_quantity


SELECT
fiscal_year,
get_fiscal_year_quarter(date) as Quarter,
sum(sold_quantity) as total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year="2020"
GROUP BY fiscal_year, Quarter;

#9 Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
-- The final output contains these fields, 
-- fiscal_year
-- channel 
-- gross_sales_mln 
-- percentage


WITH CTE1 AS (
SELECT
s.fiscal_year,
c.channel,
ROUND(SUM(s.gross_sales_amount/1000000),2) as gross_sales_mln
FROM gross_sales s
JOIN dim_customer c ON s.customer_code=c.customer_code
WHERE s.fiscal_year=2021
GROUP BY s.fiscal_year, c.channel)
SELECT
*,
(ROUND(gross_sales_mln/SUM(gross_sales_mln) OVER(),2))*100 as prct_contribution
FROM CTE1
ORDER BY prct_contribution desc;

#10 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields, 
-- division 
-- product_code
-- product
-- total_sold_quantity


WITH CTE1 AS(
SELECT
p.division,
p.product_code,
p.product,
SUM(s.sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly s
JOIN dim_product p ON s.product_code=p.product_code
WHERE fiscal_year="2021"
GROUP BY p.division, p.product_code, p.product),
CTE2 AS(
SELECT
division, 
product_code,
product,
total_sold_quantity,
dense_rank() OVER(partition by division ORDER BY total_sold_quantity desc) AS division_rank
FROM CTE1)
SELECT
*
FROM CTE2
WHERE division_rank<=3;
