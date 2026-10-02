CREATE DATABASE amazon_sales_db;
USE amazon_sales_db;

CREATE TABLE amazon_sales (
    order_id VARCHAR(255),
    product_name VARCHAR(255),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    order_date DATE,
    ship_date DATE,
    customer_id VARCHAR(255),
    customer_name VARCHAR(255),
    region VARCHAR(100),
    country VARCHAR(100),
    sales FLOAT,
    quantity INT,
    discount FLOAT,
    profit FLOAT,
    shipping_cost FLOAT,
    payment_method VARCHAR(100),
    review_score INT
);
DROP TABLE amazon_sales;

select* from amazon_sales;

-- Standardize Country Names
UPDATE amazon_sales 
SET country = 'United States' 
WHERE country IN ('USA', 'U.S.', 'US');


-- ** 1.Sales Performance Analysis **

-- i) Total Sales and Profit and Units Sold
SELECT 
    CONCAT('$', FORMAT(SUM(sales) / 1000, 0), 'K') AS total_sales,
    CONCAT('$', FORMAT(SUM(profit) / 1000, 0), 'K') AS total_profit,
    CONCAT('$', FORMAT(SUM(quantity) / 1000, 0), 'K') AS total_units_sold
FROM amazon_sales;
-- Shows total revenue, profit, and items sold.


-- ii) Monthly & Yearly Sales Trends 
SELECT 
    YEAR(order_date) AS year,
    CONCAT(FORMAT(SUM(sales) / 1000, 0), 'K') AS total_sales,
    CONCAT(FORMAT(SUM(profit) / 1000, 0), 'K') AS total_profit
FROM amazon_sales
GROUP BY year
ORDER BY year;
-- Tracks sales performance over time


-- iii) Top 10 Best-Selling Sub-Categories
SELECT 
    sub_category, 
    CONCAT('$', FORMAT(SUM(sales) / 1000, 0), 'K') AS total_sales
FROM amazon_sales
GROUP BY sub_category
ORDER BY SUM(sales) DESC
LIMIT 10;
-- Identifies best-performing product subcategories.


-- iv) Most Sold Product in Each Category
SELECT category, product_ID, total_units_sold
FROM (
    SELECT category, product_ID, SUM(quantity) AS total_units_sold,
           RANK() OVER (PARTITION BY category ORDER BY SUM(quantity) DESC) AS rnk
    FROM amazon_sales
    GROUP BY category, product_ID
) ranked
WHERE rnk = 1;
-- Finds the highest-selling product per category.


-- ** 2.Customer Behavior Analysis **

-- i) Customer Review Analysis (Positive, Neutral, Negative)
SELECT 
    CASE 
        WHEN review_score >= 4 THEN 'Positive'
        WHEN review_score = 3 THEN 'Neutral'
        ELSE 'Negative'
    END AS review_category,
    COUNT(*) AS total_reviews,
    CONCAT(ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()), 1), '%') AS percentage
FROM amazon_sales
GROUP BY review_category
ORDER BY total_reviews DESC;
-- Analyzes customer sentiment distribution.


-- ii) Customer Sales, Profit, and Total Units Analysis 
SELECT 
    customer_name,
    ROUND(SUM(sales)) AS total_sales,
    ROUND(SUM(profit)) AS total_profit,
    SUM(quantity) AS total_units
FROM amazon_sales
GROUP BY customer_name
ORDER BY total_sales;
-- Top customers drive sales, profit and units sold


-- ** 3.Profitability & Discount Impact **

-- i) Average Profit Per Category
SELECT category, CONCAT('$',ROUND(AVG(profit), 2)) AS avg_profit
FROM amazon_sales
GROUP BY category
ORDER BY avg_profit DESC;
-- Identifies which categories generate the most profit.


-- ii) Impact of Discounts on Profitability
SELECT discount, CONCAT('$',ROUND(AVG(profit),2)) AS avg_profit, COUNT(order_id) AS num_orders
FROM amazon_sales
GROUP BY discount
ORDER BY discount ASC;
-- Shows how discounts affect profitability.


-- iii) Orders with High Discounts but Low Profit
SELECT * FROM amazon_sales 
WHERE discount > 0.20 AND profit < 5
ORDER BY discount DESC;
-- Finds transactions where discounts led to low profitability.


-- ** 4.Inventory & Order Management **

-- i) Low-Selling Products
SELECT product_ID, SUM(quantity) AS total_units_sold
FROM amazon_sales
GROUP BY product_ID
HAVING total_units_sold < 10
ORDER BY total_units_sold ASC;
-- Finds slow-moving products.


-- ii) Fastest & Slowest Shipping Products
SELECT product_ID, 
       ROUND(AVG(DATEDIFF(ship_date, order_date))) AS avg_shipping_days
FROM amazon_sales
GROUP BY product_ID
ORDER BY avg_shipping_days ASC;
-- Analyzes shipping performance by product.


-- iii) Peak Sales Days of the Week
SELECT DAYNAME(order_date) AS weekday, COUNT(order_id) AS total_orders
FROM amazon_sales
GROUP BY weekday
ORDER BY total_orders DESC;
-- Identifies the best days for sales


-- iv) Sales & Shipping Cost by Region
SELECT 
    region, 
    CONCAT(ROUND(SUM(sales)/1000, 1), 'K') AS total_sales, 
    CONCAT(ROUND(SUM(shipping_cost)/1000, 1), 'K') AS total_shipping_cost
FROM amazon_sales
GROUP BY region
ORDER BY SUM(sales) DESC;
-- Compares revenue and shipping expenses across regions.


-- ** 5.Customer Feedback & Payment Analysis **

-- i) Most Common Review Score
SELECT review_score, COUNT(*) AS num_reviews
FROM amazon_sales
GROUP BY review_score
ORDER BY num_reviews DESC;
-- Analyzes customer satisfaction trends.


-- ii) Total Transactions by Payment Method
SELECT 
    YEAR(order_date) AS year, 
    payment_method, 
    COUNT(*) AS total_transactions
FROM amazon_sales
GROUP BY YEAR(order_date), payment_method
ORDER BY year DESC, total_transactions DESC;
-- Shows preferred payment methods.


-- ** 6.Trend Analysis & Forecasting **

-- i) Sales Contribution by Category Over the Years
SELECT 
    YEAR(order_date) AS year, 
    category, 
    CONCAT(ROUND(SUM(sales) / 1000, 1), 'K') AS total_sales_k, 
    ROUND(SUM(sales) * 100.0 / SUM(SUM(sales)) OVER(PARTITION BY YEAR(order_date)), 2) AS sales_percentage
FROM amazon_sales
GROUP BY YEAR(order_date), category
ORDER BY year, SUM(sales) DESC;
-- Shows each category’s contribution to total sales.

-- ii) Year-over-Year Sales Growth
SELECT 
    YEAR(order_date) AS sales_year, 
    CONCAT('$', FORMAT(SUM(sales) / 1000000, 1), 'M') AS total_sales, 
    CONCAT('$', FORMAT(COALESCE(LAG(SUM(sales)) OVER (ORDER BY YEAR(order_date)), 0) / 1000000, 1), 'M') AS previous_year_sales, 
    CONCAT(ROUND(((SUM(sales) - LAG(SUM(sales)) OVER (ORDER BY YEAR(order_date))) 
                 / NULLIF(LAG(SUM(sales)) OVER (ORDER BY YEAR(order_date)), 0)) * 100, 2), '%') AS growth_rate 
FROM amazon_sales 
GROUP BY sales_year 
ORDER BY sales_year;
-- Shows annual growth trends.


-- iii) Top 3 Best-Selling Products Each Month
WITH MonthlyProductSales AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, product_ID, 
           SUM(sales) AS total_sales,
           RANK() OVER (PARTITION BY DATE_FORMAT(order_date, '%Y-%m') ORDER BY SUM(sales) DESC) rnk
    FROM amazon_sales
    GROUP BY 1, 2
)
SELECT month, product_ID, 
CONCAT('$', FORMAT(total_sales, 2)) AS total_sales
FROM MonthlyProductSales
WHERE rnk <= 3
ORDER BY 1, rnk;
-- Finds the most popular products each month.


-- iv) Most Profitable Day of the Week
SELECT DAYNAME(order_date) AS weekday, 
       CONCAT('$', FORMAT(SUM(profit) / 1000, 2), 'K') AS total_profit
FROM amazon_sales
GROUP BY 1
ORDER BY SUM(profit) DESC;
-- Finds the most profitable day for sales.


-- v) Predict Next Month’s Sales Using Moving Averages 
WITH MonthlySales AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, SUM(sales) AS total_sales
    FROM amazon_sales
    GROUP BY 1
)
SELECT month, 
       CONCAT('$', FORMAT(total_sales / 1000, 1), 'K') AS total_sales, 
       CONCAT('$', FORMAT(AVG(total_sales) 
              OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) / 1000, 1), 'K') 
              AS moving_avg_3months
FROM MonthlySales;
-- Uses a moving average to estimate future sales.
