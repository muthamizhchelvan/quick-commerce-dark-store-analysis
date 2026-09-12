-- =======================================================
-- PROJECT: Quick-Commerce Dark Store Analytics & Inventory Optimization
-- AUTHOR: [Your Name]
-- DATABASE: quick_commerce_db
-- =======================================================

USE quick_commerce_db;

-- -------------------------------------------------------
-- SECTION 1: Platform Delay & Revenue Analysis
-- -------------------------------------------------------
SELECT 
    platform_name,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(order_value_inr), 2) AS total_revenue_inr,
    SUM(CASE WHEN LOWER(TRIM(delivery_delay)) = 'yes' THEN 1 ELSE 0 END) AS delayed_orders_count,
    ROUND(
        SUM(CASE WHEN LOWER(TRIM(delivery_delay)) = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(order_id), 
        2
    ) AS delayed_order_pct
FROM quickcom_orders
GROUP BY platform_name;


-- -------------------------------------------------------
-- SECTION 2: Peak Demand Hours per Category (Window Functions)
-- -------------------------------------------------------
WITH Hourly_Demand AS (
    SELECT 
        product_category_name,
        order_hour,
        COUNT(order_id) AS total_orders,
        SUM(order_value_inr) AS hourly_revenue,
        DENSE_RANK() OVER (
            PARTITION BY product_category_name 
            ORDER BY COUNT(order_id) DESC
        ) AS peak_rank
    FROM quickcom_orders
    GROUP BY product_category_name, order_hour
)
SELECT 
    product_category_name,
    order_hour AS peak_hour_24hr,
    total_orders,
    hourly_revenue
FROM Hourly_Demand
WHERE peak_rank = 1;


-- -------------------------------------------------------
-- SECTION 3: Dynamic Safety Stock & Reorder Point Calculation
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS dark_store_inventory_calculated AS
WITH Daily_Category_Demand AS (
    SELECT 
        date,
        product_category_name,
        COUNT(order_id) AS daily_units_sold
    FROM quickcom_orders
    GROUP BY date, product_category_name
),
Category_Demand_Stats AS (
    SELECT 
        product_category_name,
        ROUND(AVG(daily_units_sold), 0) AS avg_daily_demand,
        MAX(daily_units_sold) AS max_daily_demand,
        2 AS avg_lead_time_days,
        4 AS max_lead_time_days
    FROM Daily_Category_Demand
    GROUP BY product_category_name
)
SELECT 
    product_category_name AS category_name,
    ROUND(avg_daily_demand * 0.8, 0) AS current_stock_on_hand,
    (max_daily_demand * 4) - (avg_daily_demand * 2) AS calculated_safety_stock,
    (avg_daily_demand * 2) + ((max_daily_demand * 4) - (avg_daily_demand * 2)) AS reorder_point
FROM Category_Demand_Stats;


-- -------------------------------------------------------
-- SECTION 4: Stockout Risk Alerts
-- -------------------------------------------------------
SELECT 
    category_name,
    CASE 
        WHEN category_name LIKE '%Fruits%' THEN 800
        WHEN category_name LIKE '%Dairy%' THEN 1500
        WHEN category_name LIKE '%Beverages%' THEN 3000
        WHEN category_name LIKE '%Personal%' THEN 5000
        WHEN category_name LIKE '%Grocery%' THEN 5000
        WHEN category_name LIKE '%Snacks%' THEN 1800
    END AS current_stock_on_hand,
    calculated_safety_stock,
    reorder_point,
    CASE 
        WHEN (CASE 
                WHEN category_name LIKE '%Fruits%' THEN 800
                WHEN category_name LIKE '%Dairy%' THEN 1500
                WHEN category_name LIKE '%Beverages%' THEN 3000
                WHEN category_name LIKE '%Personal%' THEN 5000
                WHEN category_name LIKE '%Grocery%' THEN 5000
                WHEN category_name LIKE '%Snacks%' THEN 1800
              END) < (calculated_safety_stock / 2) THEN 'CRITICAL: IMMEDIATE REPLENISHMENT'
        WHEN (CASE 
                WHEN category_name LIKE '%Fruits%' THEN 800
                WHEN category_name LIKE '%Dairy%' THEN 1500
                WHEN category_name LIKE '%Beverages%' THEN 3000
                WHEN category_name LIKE '%Personal%' THEN 5000
                WHEN category_name LIKE '%Grocery%' THEN 5000
                WHEN category_name LIKE '%Snacks%' THEN 1800
              END) <= calculated_safety_stock THEN 'WARNING: BELOW SAFETY STOCK'
        WHEN (CASE 
                WHEN category_name LIKE '%Fruits%' THEN 800
                WHEN category_name LIKE '%Dairy%' THEN 1500
                WHEN category_name LIKE '%Beverages%' THEN 3000
                WHEN category_name LIKE '%Personal%' THEN 5000
                WHEN category_name LIKE '%Grocery%' THEN 5000
                WHEN category_name LIKE '%Snacks%' THEN 1800
              END) <= reorder_point THEN 'ACTION REQUIRED: REORDER POINT REACHED'
        ELSE 'HEALTHY STOCK LEVEL'
    END AS stock_status
FROM dark_store_inventory_calculated;