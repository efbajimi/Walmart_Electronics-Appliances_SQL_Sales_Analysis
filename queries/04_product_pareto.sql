with product_revenue as (
select p.product_name,
round(sum(t.gross_revenue),2) as Total_rev_per_product
from products p
join transactions t
on p.product_id = t.product_id
group by p.product_name 
order by Total_rev_per_product desc ),
pareto as (
select product_name,
Total_rev_per_product,
sum(Total_rev_per_product) over (order by Total_rev_per_product desc) as running_total,
round((sum(Total_rev_per_product) over (order by Total_rev_per_product desc) / sum(Total_rev_per_product) over ()) * 100, 2) as cumulative_pct
from product_revenue
)
select *,
	case when cumulative_pct <= 80 then 'Top 80%' else 'Tail' end as pareto_flag
from pareto
order by Total_rev_per_product desc;