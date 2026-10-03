select s.region,
round(sum(t.gross_revenue),2) as Sum_of_Rev
from stores as s 
join transactions as t
on s.store_id = t.store_id
group by s.region
order by Sum_of_Rev desc;
