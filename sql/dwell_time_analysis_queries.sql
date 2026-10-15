-- =============================================================
-- Hamburg Port Dwell Time Analysis
-- SQL queries (PostgreSQL)
--
-- Dataset: 1,490 containers | 5 carriers | 5 cargo types
--          January - April 2026 | Synthetic AI-generated dataset.
--
-- The output of every query is shown underneath it.
-- =============================================================


-- -------------------------------------------------------------
-- Table setup
-- -------------------------------------------------------------
-- The CSV holds dates as DD/MM/YYYY, so set the date order before loading.
SET datestyle = 'ISO, DMY';

CREATE TABLE hamburg_port (
    container_id          VARCHAR(20),
    carrier               VARCHAR(30),
    cargo_type            VARCHAR(30),
    arrival_date          DATE,
    pickup_date           DATE,
    actual_delivery_days  INT,
    free_days_allowed     INT,
    daily_demurrage_fee   INT,
    actual_demurrage_fee  INT
);


-- -------------------------------------------------------------
-- 1. Total containers and demurrage exposure
-- -------------------------------------------------------------

select count(*) as total_containers,
       sum(actual_demurrage_fee) as total_demurrage_fee
from hamburg_port;

-- Result:
--  total_containers | total_demurrage_fee
-- ------------------+--------------------
--              1490 |               53860


-- -------------------------------------------------------------
-- 2. Average dwell time at the port
-- -------------------------------------------------------------

select round(avg(actual_delivery_days ), 2) as average_days_at_port
from hamburg_port;

-- Result:
--  average_days_at_port
-- ----------------------
--                  2.43
--
-- The free period is 3 days, so the average container is collected in time.


-- -------------------------------------------------------------
-- 3. Average dwell time by carrier
-- -------------------------------------------------------------

select carrier,
       count(container_id) as total_containers,
       round(avg(actual_delivery_days ), 2) as average_days_at_port
from hamburg_port
group by carrier
order by average_days_at_port desc;

-- Result:
--    carrier    | total_containers | average_days_at_port
-- --------------+-----------------+---------------------
--  CMA CGM      |              301 |                  2.98
--  ONE          |              311 |                  2.35
--  Maersk       |              294 |                  2.30
--  Hapag-Lloyd  |              279 |                  2.27
--  MSC          |              305 |                  2.24


-- -------------------------------------------------------------
-- 4. Fee validation: stored against calculated
-- -------------------------------------------------------------
-- Recalculates the fee from the daily rate and the days past the free
-- period, then compares it with the stored value.

select sum(actual_demurrage_fee) as stored_fee,
       sum(case when actual_delivery_days > free_days_allowed then (actual_delivery_days - free_days_allowed) * daily_demurrage_fee else 0 end ) as calculated_fee
from hamburg_port;

-- Result:
--  stored_fee | calculated_fee
-- ------------+----------------
--       53860 |          53860
--
-- The two figures agree, so the stored fees are consistent with the rates.


-- -------------------------------------------------------------
-- 5. Monthly arrivals, dwell time and delays
-- -------------------------------------------------------------

select to_char(arrival_date, 'yyyy-mm') as arrival_month,
       count(*) as arrivals,
       round(avg(actual_delivery_days), 2) as avg_dwell_days,
       round(sum(case when actual_delivery_days > free_days_allowed
                      then 1 else 0 end) * 100.0 / count(*), 1) as late_pct,
       sum(actual_demurrage_fee) as total_demurrage_fee
from hamburg_port
group by to_char(arrival_date, 'yyyy-mm')
order by arrival_month;

-- Result:
--  arrival_month | arrivals | avg_dwell_days | late_pct | total_demurrage_fee
-- ---------------+----------+----------------+----------+---------------------
--  2026-01       |      379 |           2.47 |     20.6 |               14825
--  2026-02       |      354 |           2.44 |     19.2 |               11005
--  2026-03       |      385 |           2.32 |     17.1 |               12760
--  2026-04       |      372 |           2.47 |     23.4 |               15270
--
-- March has the most arrivals but the shortest dwell time and the lowest
-- late share, so higher volume did not cause more delay. April is the
-- weakest month at 23.4% late.
-- Note: arrivals range only from 354 to 385, a spread of about 4%.


-- -------------------------------------------------------------
-- 6. Fee scenarios for different free periods
-- -------------------------------------------------------------

select sum(case when actual_delivery_days > 2
                then (actual_delivery_days - 2) * daily_demurrage_fee
                else 0 end) as fee_at_2_days,
       sum(case when actual_delivery_days > 3
                then (actual_delivery_days - 3) * daily_demurrage_fee
                else 0 end) as fee_at_3_days,
       sum(case when actual_delivery_days > 4
                then (actual_delivery_days - 4) * daily_demurrage_fee
                else 0 end) as fee_at_4_days,
       sum(case when actual_delivery_days > 5
                then (actual_delivery_days - 5) * daily_demurrage_fee
                else 0 end) as fee_at_5_days
from hamburg_port;

-- Result:
--  fee_at_2_days | fee_at_3_days | fee_at_4_days | fee_at_5_days
-- ---------------+--------------+--------------+--------------
--         105105 |         53860 |         26250 |         12660
--
-- The 3-day column reproduces the total from query 1, which confirms the
-- scenario logic. A 2-day free period would roughly double the fee income.


-- -------------------------------------------------------------
-- 7. Cost drivers by cargo type: tariff or delay
-- -------------------------------------------------------------

select cargo_type,
       max(daily_demurrage_fee) as daily_demurrage_rate,
       count(*) as containers,
       round(100.0 * sum(case when actual_delivery_days > free_days_allowed
                              then 1 else 0 end) / count(*), 1) as late_pct,
       sum(case when actual_delivery_days > free_days_allowed
                then actual_delivery_days - free_days_allowed
                else 0 end) as total_over_days,
       sum(actual_demurrage_fee) as total_demurrage_fee,
       round(100.0 * sum(actual_demurrage_fee)
             / (select sum(actual_demurrage_fee) from hamburg_port), 1) as fee_share_pct
from hamburg_port
group by cargo_type
order by total_demurrage_fee desc;

-- Result:
--  cargo_type  | daily_demurrage_rate | containers | late_pct | total_over_days | total_demurrage_fee | fee_share_pct
-- -------------+----------------------+------------+----------+-----------------+---------------------+---------------
--  Chemicals   |                  110 |        296 |     23.0 |             137 |               15070 |          28.0
--  Perishables |                  125 |        313 |     16.0 |              92 |               11500 |          21.4
--  Automotive  |                   85 |        296 |     21.3 |             120 |               10200 |          18.9
--  Electronics |                   80 |        282 |     20.2 |             121 |                9680 |          18.0
--  Retail      |                   65 |        303 |     20.1 |             114 |                7410 |          13.8
--
-- Chemicals cost the most on both counts: the second-highest daily rate and
-- the highest late share. Perishables carry the highest rate of all but the
-- best pickup discipline, so their cost comes from the tariff, not from delay.
