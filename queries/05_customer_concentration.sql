with customer_spend as (
select t.customer_id,
c.first_name,
c.last_name,
c.annual_income,
round(sum(t.gross_revenue),2) as total_rev
from customers as c
join transactions as t
on c.customer_id = t.customer_id
group by t.customer_id, c.first_name, c.last_name, c.annual_income
order by total_rev desc),
pareto as (
select customer_id,
first_name,
last_name,
annual_income,
total_rev,
round(sum(total_rev) over (order by total_rev desc),2) as running_total,
round((sum(total_rev) over (order by total_rev desc) / sum(total_rev) over ()) * 100, 2) as cumulative_pct
from customer_spend
)
select *,
	case when cumulative_pct <= 10 then 'Top 10%' when cumulative_pct > 10 and cumulative_pct <= 50 then 'Next 40%' else 'Bottom 50%'end as pareto_flag
from pareto
order by total_rev desc
