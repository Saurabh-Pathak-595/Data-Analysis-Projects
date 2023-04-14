-- Added database/schema "swiggy_analysis" then imported tables, orders and items using table data import wizard from the CSV files
-- Database_name "swiggy_analysis"
use swiggy_analysis;
show tables;
Select * from items;
Select * from orders;

-- Distinct Food Items Ordered
Select distinct name as `Distinct Food Items` from items;
Select count(distinct name) as `count of distinct food items` from items;

-- Distribution of items 
select distinct is_veg from items;
Select name from items where is_veg=2;
SELECT 
    CASE
        WHEN is_veg = 1 THEN 'veg'
        WHEN is_veg = 0 THEN 'non_veg'
        ELSE "others"
    END AS `distribution of items`,
    COUNT(*) AS count_of_items
FROM
    items
GROUP BY `distribution of items`;

-- Count unique orders
Select count(distinct order_id) as `unique orders` from orders;

-- Show items containing chicken in their name
Select name from items where name like "%chicken%";

-- items ordered by their popularity
select name, count(*) as `no. of times ordered` from items group by name order by `no. of times ordered` desc;

-- item ordered most number of times
select name, count(*) from items group by name order by count(*) desc limit 1;

--  Distinct rain mode 
Select distinct rain_mode from orders;  

--  Distinct on_time mode 
select distinct on_time from orders;

-- Orders during rain time
Select * from orders where rain_mode!=0;

-- Distinct restaurants
Select distinct restaurant_name from orders;
select count(distinct restaurant_name) from orders;

-- Restaurants ordered by their popularity
Select restaurant_name, count(*) as `no. of orders` from orders group by restaurant_name order by 2 desc;

-- Restaurant with most orders
Select restaurant_name, count(*) as `no. of orders` from orders group by restaurant_name order by 2 desc limit 1;

-- orders placed per month and year in descending order
Select date_format(order_time, "%Y - %M") as `year-month`, count(*) as `no. of orders` from orders group by 1 order by 2 desc;

-- Most recent order and items in most recent order (using CTE)
Select max(order_time) from orders;

with summary (order_id, order_total, restaurant_name, order_time, name) as 
(
Select o.order_id, order_total, restaurant_name, order_time, name 
from orders o join items i on o.order_id=i.order_id order by 4 desc
)
Select name, order_time from summary where order_time = (select max(order_time) from summary);

-- Revenue made per month
Select date_format(order_time, "%Y - %M") as `year-month`, sum(order_total) as revenue from orders group by `year-month` order by revenue desc;

-- Average order value
Select round((sum(order_total)/count(distinct order_id)),2) as `AOV` from orders;

-- Year wise revenue 
Select year(order_time) as `year`, sum(order_total) as revenue from orders group by 1 order by 1 asc;

-- Year on year change in revenue (using subquery)
Select *, concat(round((((o.revenue-lag(o.revenue) over())*100)/lag(o.revenue) over()),2),"%") as `% age change in revenue` 
 from 
  (Select distinct year(order_time) as `year`, sum(order_total) over(partition by year(order_time)) as revenue from orders order by 1 asc)o;

-- Restaurant with highest revenue ranking
Select *, rank() over (order by s.revenue desc) `revenue wise ranking` 
 from
  (Select distinct restaurant_name, sum(order_total) over (partition by restaurant_name) as revenue from orders)s;
 
 -- how much money was made during rain-mode
 Select sum(order_total) as `money made during rain mode` from orders where rain_mode!=0;