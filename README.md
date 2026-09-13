# 🛒 Quick-Commerce Dark-Store Inventory & Fulfillment Analytics

## 📌 Project Overview

Quick-commerce platforms compete heavily on **product availability, delivery speed, and customer experience**. When a customer finds a desired product unavailable on one platform, they may consider purchasing it from a competing platform.

This project analyzes **100,000 quick-commerce orders** across Blinkit, Swiggy Instamart, and JioMart to:

- Evaluate platform-level delivery performance
- Identify category-level peak demand hours
- Develop a demand-based inventory planning framework
- Calculate **Safety Stock** and **Reorder Point**
- Identify categories requiring inventory replenishment
- Build an interactive **Power BI dashboard** for operational decision-making

The project combines **MySQL, SQL, and Power BI** to transform transactional data into actionable business insights.

> **Note:** Customer switching is used as the business rationale for improving product availability. The dataset does not directly measure customer switching behavior.

---

## 🎯 Business Problem

Quick-commerce businesses need to maintain product availability while avoiding excessive inventory.

A stockout can create a poor customer experience and may encourage customers to look for the same product on competing platforms. At the same time, holding excessive inventory can increase working-capital and storage costs.

The key business questions addressed in this project are:

1. Which quick-commerce platform has the highest delivery delay rate?
2. When does demand peak for each product category?
3. How can historical order demand be used to estimate Safety Stock?
4. At what inventory level should a category be reordered?
5. Which categories currently require immediate replenishment under the simulated inventory scenario?

---

## 📊 Dataset

The project uses a **100,000-row quick-commerce order dataset** containing transactions from:

- Blinkit
- Swiggy Instamart
- JioMart

### Product Categories

- Fruits & Vegetables
- Dairy
- Beverages
- Snacks
- Grocery
- Personal Care

### Dataset Fields

The dataset contains order, customer, platform, delivery, revenue, feedback, and time-related attributes, including:

- `order_id`
- `customer_id`
- `platform_name`
- `product_category_name`
- `order_datetime`
- `delivery_time_min`
- `order_value_inr`
- `delivery_delay`
- `refund_requested`
- `service_rating`
- `customer_feedback`
- `sla_delay`
- `date`
- `order_hour`

> **Important:** The dataset does not contain physical product quantities or actual dark-store inventory levels. Therefore, demand is measured using **order count**, and current inventory values used in the inventory analysis are **simulated scenario inputs**.

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| **MySQL Workbench** | Data analysis, aggregation, CTEs, window functions, inventory calculations |
| **SQL** | Platform analysis, demand analysis, Safety Stock and Reorder Point calculations |
| **Power BI** | Interactive dashboard and data visualization |
| **DAX / Power BI Visuals** | KPI cards, charts, inventory status visualization |
| **Excel / CSV** | Data storage and analysis outputs |

---

## 🔄 Project Workflow

```text
                    QUICK-COMMERCE DATASET
                              |
                              ↓
                  DATA CLEANING & PREPARATION
                              |
                              ↓
                         MYSQL / SQL
                              |
             ┌────────────────┼────────────────┐
             ↓                ↓                ↓
      Platform SLA      Peak Demand      Inventory Analysis
        Analysis           Analysis              |
             |                |                 ↓
             |                |       Average / Maximum Demand
             |                |                 |
             |                |                 ↓
             |                |        Safety Stock Calculation
             |                |                 |
             |                |                 ↓
             |                |         Reorder Point
             |                |                 |
             |                |                 ↓
             |                |        Inventory Risk Status
             |                |                 |
             └────────────────┴─────────────────┘
                              |
                              ↓
                       POWER BI DASHBOARD
```

---

# 🔍 Analysis Methodology

## 1. Delivery SLA Analysis

Platform-level delivery performance was evaluated using:

- Total orders
- Total revenue
- Number of delayed orders
- Delivery delay percentage

The delivery delay rate was calculated as:

**Delay Rate = Delayed Orders / Total Orders × 100**

### Results

| Platform | Total Orders | Revenue (₹) | Delayed Orders | Delay Rate |
|---|---:|---:|---:|---:|
| JioMart | 25,856 | ₹11,663,443 | 11,226 | **43.42%** |
| Blinkit | 40,695 | ₹17,444,570 | 7,205 | **17.70%** |
| Swiggy Instamart | 33,449 | ₹13,887,523 | 5,367 | **16.05%** |

### Key Insight

**JioMart recorded the highest delivery delay rate at 43.42%**, significantly higher than Blinkit and Swiggy Instamart.

This indicates that delivery SLA performance should be a priority area for operational investigation.

---

## 2. Peak Demand Analysis

Hourly order demand was analyzed separately for each product category.

A SQL `DENSE_RANK()` window function was used to identify the highest-demand hour for every category.

### Results

| Category | Peak Hour | Orders at Peak Hour |
|---|---:|---:|
| Beverages | 16:00 | 803 |
| Dairy | 13:00 | 818 |
| Fruits & Vegetables | 22:00 | 806 |
| Grocery | 12:00 | 814 |
| Personal Care | 19:00 | 794 |
| Snacks | 14:00 | 807 |

### Key Insight

Demand peaks vary considerably by category.

For example:

- **Fruits & Vegetables:** 22:00
- **Personal Care:** 19:00
- **Beverages:** 16:00
- **Snacks:** 14:00
- **Dairy:** 13:00
- **Grocery:** 12:00

These patterns can help dark-store operators align replenishment and inventory availability with category-specific demand periods.

---

# 📦 3. Inventory Analysis

The inventory analysis uses historical category-level order demand to create a **demand-based inventory planning framework**.

Because the dataset does not contain actual inventory levels, current stock values are simulated scenario inputs used to demonstrate how the inventory model can support replenishment decisions.

---

## 📐 Safety Stock Calculation

The project assumes:

- **Average Lead Time:** 2 days
- **Maximum Lead Time:** 4 days

Safety Stock is calculated as:

```text
Safety Stock =
(Max Daily Demand × Max Lead Time)
-
(Avg Daily Demand × Avg Lead Time)
```

This approach provides additional inventory coverage based on the difference between maximum and average demand during the assumed lead-time conditions.

---

## 🔁 Reorder Point Calculation

The Reorder Point is calculated as:

```text
Reorder Point =
(Avg Daily Demand × Avg Lead Time)
+
Safety Stock
```

This represents the inventory level at which replenishment should be triggered under the scenario assumptions.

---

## ⚠️ Inventory Risk Classification

The simulated current stock level is compared against calculated Safety Stock and Reorder Point.

| Condition | Inventory Status |
|---|---|
| Current Stock < 50% of Safety Stock | 🔴 Critical |
| Current Stock ≤ Safety Stock | 🟠 Warning |
| Current Stock ≤ Reorder Point | 🟡 Action Required |
| Current Stock > Reorder Point | 🟢 Healthy |

These thresholds are **scenario-based business rules** created for the project.

---

## 📋 Inventory Results

| Category | Current Stock | Safety Stock | Reorder Point | Status |
|---|---:|---:|---:|---|
| Fruits & Vegetables | 800 | 2,120 | 4,076 | 🔴 Critical |
| Dairy | 1,500 | 2,128 | 4,112 | 🟠 Warning |
| Snacks | 1,800 | 2,202 | 4,168 | 🟠 Warning |
| Beverages | 3,000 | 2,106 | 4,052 | 🟡 Action Required |
| Grocery | 5,000 | 2,278 | 4,248 | 🟢 Healthy |
| Personal Care | 5,000 | 2,090 | 4,036 | 🟢 Healthy |

---

# 💡 Key Business Insights

### 1. JioMart has the highest delivery delay rate

JioMart recorded a **43.42% delivery delay rate**, considerably higher than Blinkit and Swiggy Instamart.

This suggests that delivery operations and SLA performance require further investigation.

### 2. Demand varies by category and hour

Each category has a different peak demand period. This indicates that inventory availability and replenishment planning can benefit from **category-specific demand timing** rather than a single store-wide schedule.

### 3. Fruits & Vegetables represents the highest inventory risk

Under the simulated inventory scenario, Fruits & Vegetables has only **800 units of simulated stock** against a calculated Safety Stock of **2,120**, placing it in the Critical category.

### 4. Dairy and Snacks are below Safety Stock

Both categories fall below their calculated Safety Stock levels and are therefore classified as Warning.

### 5. Beverages has reached its Reorder Point range

Beverages has simulated stock of **3,000**, compared with a Reorder Point of **4,052**, indicating that replenishment should be considered.

---

# 📊 Power BI Dashboard

The Power BI dashboard provides a consolidated view of:

- Total Orders
- Total Revenue
- Delivery SLA Delay Rate by Platform
- Peak Demand Hour by Category
- Current Stock
- Safety Stock
- Reorder Point
- Inventory Risk Status
- Critical Inventory Alerts

The dashboard is designed to allow decision-makers to quickly identify:

- Delivery performance issues
- Category demand patterns
- Inventory risk
- Replenishment priorities

---

# 🎯 Business Recommendations

Based on the analysis:

### 1. Prioritize inventory replenishment for critical categories

Fruits & Vegetables should receive immediate replenishment attention under the simulated inventory scenario.

### 2. Monitor categories below Safety Stock

Dairy and Snacks should be monitored closely to reduce the likelihood of potential stockouts.

### 3. Use category-specific demand patterns

Replenishment planning can incorporate category-level peak hours to improve product availability during high-demand periods.

### 4. Investigate JioMart's delivery delays

The substantially higher delay rate observed for JioMart warrants further investigation into delivery capacity, operational processes, and SLA performance.

### 5. Use Safety Stock and Reorder Point as planning thresholds

The inventory model can provide a structured framework for identifying categories that may require replenishment based on historical demand and assumed lead times.

---

# 📁 Repository Structure

```text
Project/
│
├── Dataset of 100,000 orders/
├── MySQL/
├── Power BI/
│
├── category_peak_demand.csv
├── dark_store_inventory_calculated.csv
├── inventory_stockout_alerts.csv
├── platform_performance.csv
│
└── README.md
```

---

# ▶️ How to Reproduce the Analysis

## Step 1 — Obtain the Dataset

Download the quick-commerce orders dataset and place the CSV file in the project dataset folder.

## Step 2 — Load the Data into MySQL

Create a MySQL database and import the `quickcom_orders.csv` dataset.

## Step 3 — Run the SQL Analysis

Open:

```text
MySQL/dark_store_inventory_analysis.sql
```

Run the SQL sections in MySQL Workbench.

The SQL script performs:

1. Platform delivery performance analysis
2. Category-level peak demand analysis
3. Safety Stock calculation
4. Reorder Point calculation
5. Inventory risk classification

## Step 4 — Export the SQL Results

The analysis produces the required output datasets for the Power BI dashboard.

## Step 5 — Open the Power BI Dashboard

Open the `.pbix` file in Power BI Desktop and review the interactive dashboard.

---

# ⚠️ Assumptions & Limitations

This project is intended as an **analytics and inventory-planning case study**, rather than a production inventory management system.

### Inventory levels are simulated

The dataset does not contain actual dark-store inventory levels. Therefore, `current_stock_on_hand` values are simulated scenario inputs used to demonstrate the inventory model.

### Lead times are assumed

The analysis assumes:

- Average Lead Time = 2 days
- Maximum Lead Time = 4 days

These values are scenario assumptions and should be replaced with actual operational lead-time data in a production environment.

### Demand is measured using order count

The dataset does not contain a product quantity field. Therefore, demand is represented using **daily order count**, rather than physical units sold.

### Customer switching is not directly measured

The project uses potential customer switching after stockouts as the business motivation, but the dataset does not contain information that directly tracks customers switching between platforms.

### Inventory rules are scenario-based

The Critical, Warning, Action Required, and Healthy classifications are business rules created for this case study and are not observed labels from the original dataset.

### Not a live inventory system

The model demonstrates an analytical framework for inventory planning. A production system would require real-time inventory, supplier lead times, purchase orders, stock receipts, product-level quantities, and other operational data.

---

# 🚀 Project Outcome

This project demonstrates an end-to-end **retail and business analytics workflow**:

```text
Raw Transaction Data
        ↓
Data Preparation
        ↓
SQL-Based Analysis
        ↓
Demand Pattern Identification
        ↓
Inventory Model
        ↓
Safety Stock & Reorder Point
        ↓
Inventory Risk Classification
        ↓
Power BI Dashboard
        ↓
Business Recommendations
```

The project combines **SQL analysis, inventory planning concepts, data visualization, and business interpretation** to demonstrate how transactional data can be transformed into operational insights for quick-commerce businesses.

---

# 👨‍💻 Author

**Muthamizh Chelvan**

B.Sc. Retail Management & Information Technology

Central University of Andhra Pradesh

### Skills Demonstrated

- SQL
- MySQL
- Power BI
- Data Analysis
- Data Visualization
- Inventory Analysis
- Demand Analysis
- Business Intelligence
- Retail Analytics
