select s.store_name as Store_Name,
s.region as Region,
s.store_size_sqft as Store_sqft,
round(sum(t.gross_revenue),2) as Total_rev,
round(sum(t.gross_revenue / s.store_size_sqft), 2) as Rev_by_sqft
from stores as s
join transactions as t
on s.store_id = t.store_id
group by s.store_name,s.region, s.store_size_sqft
order by Rev_by_sqft desc;