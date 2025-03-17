--What is the average order value by year? 
-- extract year from purchase_ts and calculate the average of the usd_price as AOV to make sure the price is consistent, rounding it to 2 decimals
select extract(year from purchase_ts) as year, round(avg(usd_price),2) as aov
from core.orders
group by 1
order by 1;

--What is the refund rate per year?
-- extract year from purchase_ts and calculate the average of the refund rate, rounding it to 2 decimals
select extract(year from purchase_ts), round(avg(case when refund_ts is not null then 1 else 0 end) * 100, 2) as refund_rate 
from core.order_status
group by 1
order by 1;

--What is the total number of orders per year for each product?
-- see distinct names of products
select distinct product_name from core.orders;
--clean names, extract year from purchase_ts and count the order_id to find the total number of orders
select extract(year from purchase_ts) as year, 
  case when product_name = '27in\"\" 4k gaming monitor' then '27in 4k Gaming Monitor' else initcap(product_name) end as product_name_cleaned,
  count(distinct id) as order_count
from core.orders
group by 1,2
order by 1,2;

--How many days does it take to ship an order in 2020?
select date_trunc(os.purchase_ts, month) as purchase_month,
  date_trunc(os.ship_ts, month) as shipping_month,
  date_diff(os.ship_ts, os.purchase_ts, day) as time_to_ship,
  o.product_name
from core.order_status os
left join core.orders o on os.order_id = o.id
where extract(year from os.purchase_ts) = 2020;

--What is the average time-to-purchase, grouped by loyalty customers vs. non-loyalty customers?
select c.loyalty_program, 
  avg(date_diff(o.purchase_ts, c.created_on, day)) as avg_time_to_purchase
from core.customers c
left join core.orders o on c.id = o.customer_id
left join core.order_status os on o.id = os.order_id
group by 1;

--What was the refund rate and refund count for each product per year?
select extract(year from os.purchase_ts) as year, 
  case when product_name = '27in"" 4k gaming monitor' then '27in 4k Gaming Monitor' else initcap(product_name) end as product_clean,
  sum(case when refund_ts is not null then 1 else 0 end) as refund_count,
  round(avg(case when refund_ts is not null then 1 else 0 end),3) as refund_rate
from core.order_status os
left join core.orders o
  on os.order_id = o.id
group by 1,2
order by 3 desc;

--For each purchase platform, what are the top 3 customers by the number of purchases?
with order_count_cte as (
  select purchase_platform, 
    id, 
    count(distinct id) as order_count
  from core.orders
  group by 1, 2
)

select *, 
  row_number() over (partition by purchase_platform order by order_count desc) as order_ranked
from order_count_cte
qualify row_number() over (partition by purchase_platform order by order_count desc) <= 3;