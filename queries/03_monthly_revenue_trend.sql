select date_format(t.transaction_date, '%Y - %m') as Year_months,
round(sum(t.gross_revenue),2) as Total_rev,
lag(round(sum(t.gross_revenue),2),1) over (order by  date_format(t.transaction_date, '%Y - %m')) as Prev_months_rev,
round((round(sum(t.gross_revenue),2) - lag(round(sum(t.gross_revenue),2),1) over (order by  date_format(t.transaction_date, '%Y - %m'))), 2) as Rev_difference
from transactions as t
group by Year_months;