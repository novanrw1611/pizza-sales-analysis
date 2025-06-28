-- Dataset: https://www.kaggle.com/datasets/miniyadav/pizza-sales-case-study

-- -- ---------------------------------- DATA PREPARATION --------------------------------
-- Create database
create database pizzahut;
use pizzahut;

-- Create table
CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    ingredients TEXT NOT NULL
);

CREATE TABLE pizzas (
    pizza_id VARCHAR(50) PRIMARY KEY,
    pizza_type_id VARCHAR(50) NOT NULL,
    size VARCHAR(10) NOT NULL,
    price DECIMAL(10 , 2 ) NOT NULL,
    FOREIGN KEY (pizza_type_id)
        REFERENCES pizza_types (pizza_type_id)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    date DATE NOT NULL,
    time TIME NOT NULL
);

CREATE TABLE order_details (
    order_details_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    pizza_id VARCHAR(50) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (order_id)
        REFERENCES orders (order_id),
    FOREIGN KEY (pizza_id)
        REFERENCES pizzas (pizza_id),
    CONSTRAINT uc_order_pizza UNIQUE (order_id , pizza_id)
);

-- ------------------------------ DATA UNDERSTANDING ------------------------------
# A. Basic Data Profiling
-- Check table
SELECT *
FROM order_details;

SELECT *
FROM orders;

SELECT *
FROM pizza_types;

SELECT *
FROM pizzas;

-- Check structure & data type
DESCRIBE orders;
DESCRIBE order_details;
DESCRIBE pizzas;
DESCRIBE pizza_types;

-- Data time coverage
SELECT MIN(date), 
		MAX(date)
FROM orders;

-- Volume data
SELECT 
    FORMAT((SELECT 
                COUNT(*)
            FROM
                orders),
        0) AS total_orders,
    FORMAT((SELECT 
                COUNT(*)
            FROM
                order_details),
        0) AS total_items,
    FORMAT((SELECT 
                COUNT(DISTINCT pizza_id)
            FROM
                pizzas),
        0) AS unique_pizzas;

-- Product category distribution
SELECT 
    pt.category,
    FORMAT(SUM(od.quantity), 0) AS total_quantity_sold,
    ROUND(SUM(od.quantity) * 100.0 / (SELECT 
                    SUM(quantity)
                FROM
                    order_details),
            2) AS percentage
FROM
    order_details od
        JOIN
    pizzas p USING (pizza_id)
        JOIN
    pizza_types pt USING (pizza_type_id)
GROUP BY pt.category
ORDER BY total_quantity_sold DESC;

SELECT 
    pt.category,
    FORMAT(ROUND(SUM(od.quantity * p.price), 2),
        2) AS total_revenue,
    ROUND(SUM(od.quantity * p.price) * 100.0 / (SELECT 
                    SUM(od.quantity * p.price)
                FROM
                    order_details od
                        JOIN
                    pizzas p USING (pizza_id)),
            2) AS revenue_percentage
FROM
    order_details od
        JOIN
    pizzas p USING (pizza_id)
        JOIN
    pizza_types pt USING (pizza_type_id)
GROUP BY pt.category
ORDER BY total_revenue DESC;

SELECT 
    pt.category,
    p.size,
    FORMAT(SUM(od.quantity), 0) AS quantity_sold,
    FORMAT(ROUND(SUM(od.quantity * p.price), 2),
        0) AS revenue
FROM
    order_details od
        JOIN
    pizzas p USING (pizza_id)
        JOIN
    pizza_types pt USING (pizza_type_id)
GROUP BY pt.category , p.size
ORDER BY pt.category , CASE p.size
    WHEN 'S' THEN 1
    WHEN 'M' THEN 2
    WHEN 'L' THEN 3
    ELSE 4
END;

UPDATE orders 
SET 
    date = '2015-01-01'
WHERE
    date IS NULL;

-- B. Format standardization
-- Time format standardization
UPDATE orders 
SET 
    time = TIME(STR_TO_DATE(time, '%H:%i:%s'));

-- C. Duplicate check
-- Check duplicate order_details
SELECT 
    order_id, pizza_id, COUNT(*)
FROM
    order_details
GROUP BY order_id , pizza_id
HAVING COUNT(*) > 1;

-- D. Data validation
-- Check for unreasonable prices
SELECT *
FROM pizzas
WHERE price <= 0 OR price > 100;

-- Check for invalid quantity
SELECT *
FROM order_details
WHERE quantity <= 0 OR quantity > 20;

-- E. Basic Descriptive Statistical 
-- Price 
SELECT 
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price,
    STDDEV(price) AS stddev_price
FROM pizzas;

-- Quantity 
SELECT 
    MIN(quantity) AS min_qty,
    MAX(quantity) AS max_qty,
    AVG(quantity) AS avg_qty,
    STDDEV(quantity) AS stddev_qty
FROM order_details;

-- ------------------------------ DATA WRAGLING ------------------------------
-- 1. Check Missing Values
-- Orders table
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS missing_date,
    SUM(CASE WHEN time IS NULL THEN 1 ELSE 0 END) AS missing_time
FROM orders;

-- Order_details table
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_details_id IS NULL THEN 1 ELSE 0 END) AS missing_order_details_id,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN pizza_id IS NULL THEN 1 ELSE 0 END) AS missing_pizza_id,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS missing_quantity
FROM order_details;

-- 2. Duplicate Check
-- Order_id
SELECT order_id, COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Order_details_id
SELECT order_details_id, COUNT(*) AS duplicate_count
FROM order_details
GROUP BY order_details_id
HAVING COUNT(*) > 1;

-- 3. Add Column Day, Month
ALTER TABLE orders
ADD COLUMN day VARCHAR(10),
ADD COLUMN month VARCHAR(10);

-- Update new column values
UPDATE orders
SET 
    day = DAYNAME(date),
    month = MONTHNAME(date);

-- Verify results
SELECT date, day, month FROM orders LIMIT 10;


-- ---------------------- DATA CLEANING ----------------------------------
-- EXPLORATORY DATA ANALYSIS (EDA) 

-- 1. Total Order
SELECT 
    FORMAT(COUNT(DISTINCT order_id), 0) AS total_order
FROM
    orders;

-- 2. Total revenue 
SELECT 
    FORMAT(ROUND(SUM(order_details.quantity * pizzas.price),
                0),
        0) AS total_sales
FROM
    order_details
        JOIN
    pizzas USING (pizza_id);

-- 3. Total pizza sold 
SELECT 
    FORMAT(SUM(quantity), 0) AS Total_pizza_sold
FROM
    order_details;

-- Total pizza sold (by Hour)
SELECT 
    HOUR(o.time) AS Hour,
    COUNT(od.quantity) AS Pizzas_Sold
FROM 
    orders o
JOIN 
    order_details od USING(order_id)
GROUP BY 
    Hour
ORDER BY 
    Hour;

    
-- 4. The highest-priced pizza 
SELECT 
    pt.name, p.price
FROM
    pizza_types pt
        JOIN
    pizzas p USING (pizza_type_id)
ORDER BY p.price DESC
LIMIT 5;

-- 5. The lowest-priced pizza
SELECT 
    pt.name, p.price
FROM
    pizza_types pt
        JOIN
    pizzas p USING (pizza_type_id)
ORDER BY p.price ASC
LIMIT 5;

-- 6. Total Price per Pizza Size
SELECT 
    p.size, FORMAT(SUM(od.quantity * p.price), 2) AS size_total
FROM
    order_details od
        JOIN
    pizzas p USING (pizza_id)
GROUP BY p.size
ORDER BY size_total DESC;

-- 7. Total Pizzas Sold by Pizza Category
SELECT 
    pt.category, FORMAT(SUM(od.quantity), 0) AS total_qty
FROM
    pizza_types pt
        JOIN
    pizzas p USING (pizza_type_id)
        JOIN
    order_details od USING (pizza_id)
GROUP BY pt.category
ORDER BY total_qty DESC;

-- 8. Total Price per Pizza Category
SELECT 
    pt.category,
    FORMAT(SUM(od.quantity * p.price), 2) AS category_total
FROM
    order_details od
        JOIN
    pizzas p USING (pizza_id)
        JOIN
    pizza_types pt USING (pizza_type_id)
GROUP BY pt.category
ORDER BY category_total DESC;

-- 9. Top 5 pizza ordered by size
SELECT 
    p.size, FORMAT(COUNT(od.order_details_id), 0) AS order_count
FROM
    pizzas p
        JOIN
    order_details od USING (pizza_id)
GROUP BY p.size
ORDER BY order_count ASC;

-- 10.  Average pizza order
SELECT 
    CAST(CAST(SUM(quantity) AS DECIMAL (10 , 2 )) / CAST(COUNT(DISTINCT order_id) AS DECIMAL (10 , 2 ))
        AS DECIMAL (10 , 2 )) AS Avg_Pizzas_per_order
FROM
    order_details;

-- 11. Average Order Value
SELECT 
    ROUND(SUM(od.quantity * p.price) / COUNT(DISTINCT o.order_id),
            2) AS Avg_Order_Value
FROM
    orders o
        JOIN
    order_details od ON o.order_id = od.order_id
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id;
    
-- 12. Contribution of each pizza type to total revenue by Pizza Category
SELECT 
    pt.category,
    CONCAT(FORMAT(SUM(od.quantity * p.price) / (SELECT 
                        SUM(od.quantity * p.price)
                    FROM
                        order_details od
                            JOIN
                        pizzas p ON od.pizza_id = p.pizza_id) * 100,
                1),
            '%') AS sales_percentage
FROM
    order_details od
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY sales_percentage DESC;

-- 13. Contribution of each pizza type to total revenue by Pizza Size
SELECT 
    p.size,
    CONCAT(FORMAT(SUM(od.quantity * p.price) / (SELECT 
                        SUM(od.quantity * p.price)
                    FROM
                        order_details od
                            JOIN
                        pizzas p ON od.pizza_id = p.pizza_id) * 100,
                1),
            '%') AS sales_percentage
FROM
    order_details od
        JOIN
    pizzas p USING (pizza_id)
GROUP BY p.size
ORDER BY sales_percentage DESC;
    
-- 14. Percentage contribution of each pizza type to total revenue -- BELUM DITAMBAHI %
SELECT 
    pt.category,
    ROUND(SUM(od.quantity * p.price) / (SELECT 
                    ROUND(SUM(od.quantity * p.Price), 2) AS total_sales
                FROM
                    order_details od
                        JOIN
                    pizzas p USING (pizza_id)) * 100,
            2) AS revenue
FROM
    pizza_types pt
        JOIN
    pizzas p USING (pizza_type_id)
        JOIN
    order_details od USING (pizza_id)
GROUP BY pt.category
ORDER BY revenue;

-- 15. Top 5 Pizzas by Total Orders
SELECT 
    pt.name AS Pizza_Name,
    COUNT(od.order_details_id) AS Total_Orders
FROM
    order_details od
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY Pizza_Name
ORDER BY Total_Orders DESC
LIMIT 5;

-- 16. Bottom 5 Pizza  by Total Orders
SELECT 
    pt.name AS Pizza_Name,
    COUNT(od.order_details_id) AS Total_Orders
FROM
    order_details od
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY Pizza_Name
ORDER BY Total_Orders ASC
LIMIT 5;

-- 17. Top 5 Pizza by Revenue
SELECT 
    pt.name, FORMAT(SUM(od.quantity * p.price), 2) AS revenue
FROM
    order_details od
        JOIN
    pizzas p USING (pizza_id)
        JOIN
    pizza_types pt USING (pizza_type_id)
GROUP BY pt.name
ORDER BY SUM(od.quantity * p.price) DESC
LIMIT 5;

-- 18. Bottom 5 Pizza by Revenue
SELECT 
    pt.name, FORMAT(SUM(od.quantity * p.price), 2) AS revenue
FROM
    order_details od
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY SUM(od.quantity * p.price) ASC
LIMIT 5;

-- 19. Top 5 pizza by quantity
SELECT 
    pt.name, FORMAT(SUM(od.quantity), 0) AS total_quantity
FROM
    pizza_types pt
        JOIN
    pizzas p USING (pizza_type_id)
        JOIN
    order_details od USING (pizza_id)
GROUP BY pt.name
ORDER BY SUM(od.quantity) DESC
LIMIT 5;

-- 20. Bottom 5 Pizza by Quantity
SELECT 
    pt.name, SUM(od.quantity) AS total_quantity
FROM
    order_details od
        JOIN
    pizzas p USING (pizza_id)
        JOIN
    pizza_types pt USING (pizza_type_id)
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;

-- 21. Revenue by month and day
-- Month
WITH sales_data AS (
    SELECT 
        o.order_id,
        o.month,
        o.day,
        od.quantity,
        p.price,
        (od.quantity * p.price) AS revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas p ON od.pizza_id = p.pizza_id
)
SELECT 
    month,
    SUM(revenue) AS total_revenue,
    ROUND(SUM(revenue), 2) AS rounded_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2) AS avg_revenue_per_order
FROM sales_data
GROUP BY month
ORDER BY 
    FIELD(month, 'January', 'February', 'March', 'April', 'May', 'June', 
          'July', 'August', 'September', 'October', 'November', 'December'),
    total_revenue DESC;

-- Day
WITH sales_data AS (
    SELECT 
        o.order_id,
        o.month,
        o.day,
        od.quantity,
        p.price,
        (od.quantity * p.price) AS revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas p ON od.pizza_id = p.pizza_id
)
SELECT 
    day,
    SUM(revenue) AS total_revenue,
    ROUND(SUM(revenue), 2) AS rounded_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2) AS avg_revenue_per_order
FROM sales_data
GROUP BY day
ORDER BY 
    FIELD(day, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
    total_revenue DESC;


-- ----------------------------- ANALYSIS METHOD --------------------------------
-- A. Profitability Analysis
SELECT 
    pt.name AS Pizza_Name,
    SUM(od.quantity) AS Total_Quantity_Sold,
    SUM(od.quantity * p.price) AS Total_Revenue,
    SUM(od.quantity * p.price * 0.3) AS Estimated_Profit,
    ROUND(SUM(od.quantity * p.price * 0.3) * 100 / (SELECT 
                    SUM(od.quantity * p.price * 0.3)
                FROM
                    order_details od
                        JOIN
                    pizzas p ON od.pizza_id = p.pizza_id),
            2) AS Profit_Percentage
FROM
    order_details od
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY Pizza_Name
ORDER BY Estimated_Profit DESC;
    
-- B. RFM Analysis (Recency, Frequency, Monetary)
WITH rfm_data AS (
    SELECT 
        o.order_id,
        MAX(o.date) AS last_order_date,
        COUNT(o.order_id) AS frequency,
        SUM(od.quantity * p.price) AS monetary_value,
        DATEDIFF((SELECT MAX(date) FROM orders), MAX(o.date)) AS recency
    FROM 
        orders o
    JOIN 
        order_details od ON o.order_id = od.order_id
    JOIN 
        pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY 
        o.order_id
)
SELECT 
    order_id,
    recency,
    frequency,
    monetary_value,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    NTILE(5) OVER (ORDER BY monetary_value) AS m_score,
    CONCAT(
        CAST(NTILE(5) OVER (ORDER BY recency DESC) AS CHAR),
        CAST(NTILE(5) OVER (ORDER BY frequency) AS CHAR),
        CAST(NTILE(5) OVER (ORDER BY monetary_value) AS CHAR)
    ) AS rfm_cell
FROM 
    rfm_data;

-- C. Market Basket Analysis
WITH order_pizzas AS (
    SELECT 
        o.order_id,
        GROUP_CONCAT(pt.name ORDER BY pt.name SEPARATOR ', ') AS pizza_combination
    FROM 
        orders o
    JOIN 
        order_details od ON o.order_id = od.order_id
    JOIN 
        pizzas p ON od.pizza_id = p.pizza_id
    JOIN 
        pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY 
        o.order_id
    HAVING 
        COUNT(DISTINCT od.pizza_id) > 1
)
SELECT 
    pizza_combination,
    COUNT(*) AS combination_count,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM order_pizzas), 2) AS percentage_of_orders
FROM 
    order_pizzas
GROUP BY 
    pizza_combination
ORDER BY 
    combination_count DESC
LIMIT 10;

-- D. Temporal Analysis
-- Hour of Day Analysis
SELECT 
    HOUR(o.time) AS hour_of_day,
    FORMAT(COUNT(DISTINCT o.order_id), 0) AS order_count,
    ROUND(COUNT(DISTINCT o.order_id) * 100 / (SELECT 
                    COUNT(*)
                FROM
                    orders),
            2) AS percentage
FROM
    orders o
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Day of Week Analysis
SELECT 
    DAYNAME(o.date) AS day_of_week,
    FORMAT(COUNT(DISTINCT o.order_id), 0) AS order_count,
    ROUND(COUNT(DISTINCT o.order_id) * 100 / (SELECT 
                    COUNT(*)
                FROM
                    orders),
            2) AS percentage
FROM
    orders o
GROUP BY day_of_week
ORDER BY FIELD(day_of_week,
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday');

-- Monthly Seasonality
SELECT 
    MONTHNAME(o.date) AS month,
    FORMAT(COUNT(DISTINCT o.order_id), 0) AS order_count,
    ROUND(COUNT(DISTINCT o.order_id) * 100 / (SELECT 
                    COUNT(*)
                FROM
                    orders),
            2) AS percentage
FROM
    orders o
GROUP BY month , MONTH(o.date)
ORDER BY MONTH(o.date);
    