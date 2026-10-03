# Hamburg Port Dwell Time Analysis
Container dwell time, carrier performance and demurrage costs at the Port of Hamburg, analysed with PostgreSQL and Power BI.

---

## Project Overview

When a container stays at the port longer than its free time, the importer pays demurrage fees. These fees cost money, and long stays also block space at the terminal.

In this project I analysed **1,500 containers** from **5 carriers** to answer simple but important questions: How long do containers stay at the port? Which carrier is the slowest? How much money is lost to late fees? When is the port busiest?

I used **PostgreSQL** to calculate the numbers and **Power BI** to show them in an easy-to-read dashboard.

This project is built for container logistics, freight forwarding and terminal operations, which are key areas of the Hamburg port economy.

---

## Business Questions and Answers

| # | Business Question | Answer |
|---|---|---|
| 1 | How many containers are there in total? | **1,500** |
| 2 | How many days does a container stay at the port before pickup? | **2.42 days** on average |
| 3 | Which carrier has the highest average dwell time? | **CMA CGM** with **3.00 days** |
| 4 | How much is spent on late fees (3-day free limit)? | **€43,875** |
| 5 | How many containers arrive each month? | Peak in **March** with **385 arrivals** |

---

## Key Findings

- **Late fees add up.** Containers that stayed longer than 3 days created **€43,875** in demurrage fees.
- **Chemicals cost the most.** This cargo type had the highest fees (**€10,275**). One possible reason is slower customs clearance for dangerous goods, but the data alone cannot confirm this.
- **CMA CGM is the slowest carrier.** Its containers stay **3.00 days** on average, compared with **2.42 days** for all carriers together. This is useful information for carrier discussions.
- **March is the busiest month**, with **385 arrivals**. The port can plan staff and equipment ahead of busy periods like this.

---

## Tools Used

- **PostgreSQL:** data storage and KPI queries
- **Power BI Desktop:** dashboard and visuals
- **DAX measures:** `COUNT` for total containers, `AVERAGE` for dwell days at port, and `SUM` for total demurrage fees
- **Data cleaning:** removed empty values and excluded incomplete months so the monthly trend is fair

---

## Dashboard

The dashboard has four parts:

1. **KPI cards:** total demurrage fees (€), average dwell time (days), total containers and peak monthly volume
2. **Cargo chart:** demurrage fees for Chemicals, Electronics, Automotive, Retail and Perishables
3. **Carrier table:** each carrier with its container count and average days at port
4. **Monthly trend:** a line chart of container arrivals per month

---

## SQL Queries

All queries are also saved in [`sql/Hamburg_port_queries.sql`](sql/Hamburg_port_queries.sql).

**1. Create the table**
```sql
CREATE TABLE Hamburg_port (
    container_id        VARCHAR(50),
    carrier             VARCHAR(100),
    cargo_type          VARCHAR(100),
    arrival_date        DATE,
    pickup_date         DATE,
    free_days_allowed   INT,
    daily_demurrage_fee INT
);
```

**2. Total number of containers**
```sql
SELECT COUNT(container_id) AS total_containers
FROM Hamburg_port;
```

**3. Average dwell time (days at port)**
```sql
SELECT ROUND(AVG(pickup_date - arrival_date), 2) AS average_days_at_port
FROM Hamburg_port;
```

**4. Dwell time by carrier**
```sql
SELECT carrier,
       COUNT(container_id) AS total_containers,
       ROUND(AVG(pickup_date - arrival_date), 1) AS average_days_at_port
FROM Hamburg_port
GROUP BY carrier
ORDER BY average_days_at_port DESC;
```

**5. Demurrage fees by cargo type** (3 free days, then €75 per extra day)
```sql
SELECT cargo_type,
       SUM(CASE
             WHEN (pickup_date - arrival_date) > 3
             THEN ((pickup_date - arrival_date) - 3) * 75
             ELSE 0
           END) AS total_penalty_fees_in_euros
FROM Hamburg_port
GROUP BY cargo_type
ORDER BY total_penalty_fees_in_euros DESC;
```

**6. Arrivals per month (peak traffic)**
```sql
SELECT DATE_TRUNC('month', arrival_date) AS arrival_month,
       COUNT(container_id) AS total_arrivals
FROM Hamburg_port
GROUP BY DATE_TRUNC('month', arrival_date)
ORDER BY arrival_month ASC;
```

---

## Repository Structure

```
Hamburg-Port-Dwell-Time-Analysis/
├── data/          Dataset (CSV file)
├── docs/          Business questions document
├── powerbi/       Power BI dashboard file (.pbix)
├── screenshots/   Images of the dashboard and queries
├── sql/           PostgreSQL queries
└── README.md
```
---

## How to Use This Project

1. Download the CSV file from the `data` folder.
2. Create the table and import the CSV into PostgreSQL (see the SQL file).
3. Run the queries to get the KPIs.
4. Open the `.pbix` file in Power BI Desktop to explore the dashboard.

---

## About the Data

This is a practice dataset created for learning purposes. It is not real Port of Hamburg data.
The dataset has 1,500 containers with carrier, cargo type, arrival date, pickup date, free days and daily demurrage fee.

---

## About Me

I am **DOLLY**, a data analyst interested in logistics and supply chain analytics. I enjoy turning raw data into clear answers that help businesses make better decisions.

- GitHub: [DOLLY3210](https://github.com/DOLLY3210)
  
