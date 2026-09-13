-- =======================================================
-- PROJECT: Quick-Commerce Dark Store Analytics
--          & Inventory Optimization
-- AUTHOR: Muthamizh Chelvan
-- DATABASE: quick_commerce_db
-- =======================================================

USE quick_commerce_db;


-- =======================================================
-- SECTION 1: PLATFORM DELAY & REVENUE ANALYSIS
-- =======================================================
-- Purpose:
-- Benchmark delivery performance and revenue across
-- quick-commerce platforms.
-- =======================================================

SELECT 
    TRIM(platform_name) AS platform_name,
    
    COUNT(order_id) AS total_orders,
    
    ROUND(SUM(order_value_inr), 2) AS total_revenue_inr,
    
    SUM(
        CASE 
            WHEN LOWER(TRIM(delivery_delay)) = 'yes'
            THEN 1
            ELSE 0
        END
    ) AS delayed_orders_count,
    
    ROUND(
        SUM(
            CASE 
                WHEN LOWER(TRIM(delivery_delay)) = 'yes'
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(order_id),
        2
    ) AS delayed_order_pct

FROM quickcom_orders

GROUP BY TRIM(platform_name)

ORDER BY delayed_order_pct DESC;


-- =======================================================
-- SECTION 2: PEAK DEMAND HOURS BY CATEGORY
-- =======================================================
-- Purpose:
-- Identify the hour with the highest order demand for
-- each product category.
--
-- Demand is measured as number of orders because the
-- source dataset does not provide product quantity/
-- units-sold information.
--
-- DENSE_RANK() retains tied peak hours if they occur.
-- =======================================================

WITH Hourly_Demand AS (

    SELECT 
        TRIM(product_category_name) AS product_category_name,
        order_hour,

        COUNT(order_id) AS total_orders,

        ROUND(SUM(order_value_inr), 2) AS hourly_revenue,

        DENSE_RANK() OVER (
            PARTITION BY TRIM(product_category_name)
            ORDER BY COUNT(order_id) DESC
        ) AS peak_rank

    FROM quickcom_orders

    GROUP BY 
        TRIM(product_category_name),
        order_hour
)

SELECT 
    product_category_name,
    order_hour AS peak_hour_24hr,
    total_orders,
    hourly_revenue

FROM Hourly_Demand

WHERE peak_rank = 1

ORDER BY 
    product_category_name,
    peak_hour_24hr;


-- =======================================================
-- SECTION 3: DEMAND-BASED SAFETY STOCK & REORDER POINT
-- =======================================================
-- Purpose:
-- Calculate inventory thresholds using historical
-- category-level daily order demand.
--
-- IMPORTANT:
-- The source dataset does NOT contain actual dark-store
-- inventory levels or supplier lead-time records.
--
-- Therefore:
--   1. Demand metrics are derived from the source data.
--   2. Lead times are analytical assumptions.
--   3. Current inventory is simulated separately.
--
-- Lead-Time Assumptions:
--   Average Lead Time = 2 days
--   Maximum Lead Time = 4 days
--
-- Safety Stock:
--   SS = (Max Daily Demand × Max Lead Time)
--        - (Avg Daily Demand × Avg Lead Time)
--
-- Reorder Point:
--   ROP = (Avg Daily Demand × Avg Lead Time)
--         + Safety Stock
-- =======================================================

DROP TABLE IF EXISTS dark_store_inventory_calculated;


CREATE TABLE dark_store_inventory_calculated AS

WITH Daily_Category_Demand AS (

    SELECT 
        date,

        TRIM(product_category_name) AS product_category_name,

        -- Each transaction represents one order.
        -- Therefore demand is measured as daily order count.
        COUNT(order_id) AS daily_orders

    FROM quickcom_orders

    GROUP BY 
        date,
        TRIM(product_category_name)
),

Category_Demand_Stats AS (

    SELECT 
        product_category_name,

        -- Average daily order demand
        ROUND(AVG(daily_orders), 0) AS avg_daily_orders,

        -- Maximum observed daily order demand
        MAX(daily_orders) AS max_daily_orders,

        -- Analytical lead-time assumptions
        2 AS avg_lead_time_days,
        4 AS max_lead_time_days

    FROM Daily_Category_Demand

    GROUP BY product_category_name
)

SELECT 

    product_category_name AS category_name,

    avg_daily_orders,

    max_daily_orders,

    avg_lead_time_days,

    max_lead_time_days,

    -- ---------------------------------------------------
    -- SAFETY STOCK
    -- ---------------------------------------------------
    (
        max_daily_orders * max_lead_time_days
    )
    -
    (
        avg_daily_orders * avg_lead_time_days
    ) AS calculated_safety_stock,

    -- ---------------------------------------------------
    -- REORDER POINT
    -- ---------------------------------------------------
    (
        avg_daily_orders * avg_lead_time_days
    )
    +
    (
        (
            max_daily_orders * max_lead_time_days
        )
        -
        (
            avg_daily_orders * avg_lead_time_days
        )
    ) AS reorder_point

FROM Category_Demand_Stats;


-- =======================================================
-- SECTION 4: SIMULATED DARK-STORE INVENTORY SCENARIO
-- =======================================================
-- Purpose:
-- Compare calculated inventory thresholds against
-- simulated current stock levels.
--
-- IMPORTANT:
-- Current stock values below are SIMULATED inputs.
-- They are NOT actual inventory values from the Kaggle
-- source dataset.
--
-- They are included to demonstrate how a dark-store
-- inventory monitoring framework could classify stock
-- availability and replenishment risk.
-- =======================================================

WITH Simulated_Inventory AS (

    SELECT 
        'Fruits & Vegetables' AS category_name,
        800 AS current_stock_on_hand

    UNION ALL

    SELECT 
        'Dairy',
        1500

    UNION ALL

    SELECT 
        'Beverages',
        3000

    UNION ALL

    SELECT 
        'Snacks',
        1800

    UNION ALL

    SELECT 
        'Grocery',
        5000

    UNION ALL

    SELECT 
        'Personal Care',
        5000
),

Inventory_Analysis AS (

    SELECT 

        i.category_name,

        i.current_stock_on_hand,

        d.avg_daily_orders,

        d.max_daily_orders,

        d.avg_lead_time_days,

        d.max_lead_time_days,

        d.calculated_safety_stock,

        d.reorder_point

    FROM Simulated_Inventory i

    INNER JOIN dark_store_inventory_calculated d

        ON TRIM(i.category_name) = TRIM(d.category_name)
)

SELECT 

    category_name,

    current_stock_on_hand,

    avg_daily_orders,

    max_daily_orders,

    avg_lead_time_days,

    max_lead_time_days,

    calculated_safety_stock,

    reorder_point,

    CASE

        -- ------------------------------------------------
        -- CRITICAL:
        -- Current stock is below 50% of Safety Stock.
        -- ------------------------------------------------
        WHEN current_stock_on_hand
             < (calculated_safety_stock / 2)

        THEN 'CRITICAL: IMMEDIATE REPLENISHMENT'


        -- ------------------------------------------------
        -- WARNING:
        -- Current stock is at or below Safety Stock.
        -- ------------------------------------------------
        WHEN current_stock_on_hand
             <= calculated_safety_stock

        THEN 'WARNING: BELOW SAFETY STOCK'


        -- ------------------------------------------------
        -- ACTION REQUIRED:
        -- Current stock has reached the Reorder Point.
        -- ------------------------------------------------
        WHEN current_stock_on_hand
             <= reorder_point

        THEN 'ACTION REQUIRED: REORDER POINT REACHED'


        -- ------------------------------------------------
        -- HEALTHY:
        -- Current stock remains above Reorder Point.
        -- ------------------------------------------------
        ELSE 'HEALTHY STOCK LEVEL'

    END AS stock_status

FROM Inventory_Analysis

ORDER BY

    CASE

        WHEN current_stock_on_hand
             < (calculated_safety_stock / 2)
        THEN 1

        WHEN current_stock_on_hand
             <= calculated_safety_stock
        THEN 2

        WHEN current_stock_on_hand
             <= reorder_point
        THEN 3

        ELSE 4

    END,

    category_name;