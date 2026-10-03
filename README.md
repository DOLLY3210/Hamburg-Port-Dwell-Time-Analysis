# Hamburg Port Dwell Time Analysis: Port Demurrage & KPI Dashboard

## Project Overview
This project features a data-driven **Power BI Dashboard** paired with business intelligence queries designed to track and optimize Hamburg Port performance. Built with a focus on port operations, the dashboard analyzes **1,500 containers** across five major global carriers to identify operational bottlenecks, track cost leakages, and optimize port dwell times. 

This project demonstrates business intelligence and data engineering skills tailored directly for modern container logistics, freight forwarding, and terminal operations—highly relevant for the fast-paced Hamburg logistics hub.

## 📊 Key Insights & Business Value Delivered
1. **Demurrage & Cost Control:** Tracked and aggregated **€43,875** (€43.88K) in total demurrage penalties, segmenting financial risk across distinct cargo categories.
2. **Bottleneck Identification:** Pinpointed that **Chemicals** account for the highest penalty fees (**€10,275**), signaling potential delays in hazardous material customs clearing.
3. **Carrier Performance Benchmarking:** Identified **CMA CGM** as the slowest carrier with an average port dwell time of **3.00 days**, compared to the fleet average of **2.42 days**, enabling data-backed carrier negotiations.
4. **Capacity Planning:** Conducted a peak traffic analysis revealing a maximum volume surge of **385 arrivals** in March, allowing logistics managers to scale workforce capacity ahead of peak intervals.

### Tech Stack & Skills Demonstrated
* **Database Querying:** PostgreSQL / SQL Data Extraction
* **BI Tool:** Power BI Desktop
* **Data Modeling:** Star schema architecture connecting dimensions (Carriers, Cargo Types, Time-series) to core logistics fact tables.
* **DAX & Metrics:** Created tailored measures for rolling container counts, average dwell times, and tiered penalty fee structures.
* **Data Transformation:** Cleaned null data points and handled incomplete edge-month reporting data (filtered partial periods for data integrity).

### Dashboard Structure
1. **High-Level KPIs:** Total Demurrage Penalties (€), Average Port Dwell Time (Days), Total Containers (Units), and Peak Monthly Volumes.
2. **Cargo Breakdown Chart:** Bar chart highlighting the exact financial penalty distribution across Chemicals, Electronics, Automotive, Retail, and Perishables.
3. **Carrier Grid Analysis:** Detailed cross-table tracking Carrier Names against Total Volume and Average Days at Port.
4. **Time Series Trend:** Line graph tracking container flow trajectories across business months.

---

## 🛠️ SQL Queries & Database Implementation

The business logic used to power the Power BI visuals was validated and extracted using the following **PostgreSQL** script:

### 1. Table Schema Setup
```sql
CREATE TABLE Hamburg_port (
    container_id VARCHAR(50),
    carrier VARCHAR(100),
    cargo_type VARCHAR(100),
    arrival_date DATE,
    pickup_date DATE,
    free_days_allowed INT,
    daily_demurrage_fee INT
);
```

### 2. Total Container Volume
```sql
SELECT COUNT(container_id) AS Total_containers 
FROM Hamburg_port;
```

### 3. Average Port Dwell Time (Overall)
```sql
SELECT ROUND(AVG(pickup_date::date - arrival_date::date), 2) AS average_days_at_port 
FROM Hamburg_port;
```

### 4. Carrier Performance Benchmarking
```sql
SELECT carrier,
       COUNT(container_id) AS Total_containers,
       ROUND(AVG(pickup_date::date - arrival_date::date), 1) AS average_days_at_port 
FROM Hamburg_port
GROUP BY carrier
ORDER BY average_days_at_port DESC;
```

### 5. Total Financial Penalty (Demurrage) by Cargo Type
*(Accounts for the 3-day port free-time tier threshold limit)*
```sql
SELECT cargo_type,
       SUM(CASE 
           WHEN (pickup_date::date - arrival_date::date) > 3
           THEN ((pickup_date::date - arrival_date::date) - 3) * 75 
           ELSE 0 
       END) AS Total_penalty_fees_in_euros 
FROM Hamburg_port
GROUP BY cargo_type
ORDER BY Total_penalty_fees_in_euros DESC;
```

### 6. Peak Traffic Analysis (Busiest Months)
```sql
SELECT DATE_TRUNC('month', arrival_date::date) AS arrival_month,
       COUNT(container_id) AS total_arrivals
FROM Hamburg_port
GROUP BY DATE_TRUNC('month', arrival_date::date)
ORDER BY arrival_month ASC;
```
