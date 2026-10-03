# Walmart Appliance & Electronics Sales Analysis — SQL

End-to-end SQL analysis of two years of Walmart appliance and electronics sales.
Four raw tables were modeled as a **star schema** in **MySQL** and queried to answer
five business questions spanning regional performance, store productivity, revenue
seasonality, and product and customer concentration.

This is the SQL companion to a Power BI version of the same dataset: there the data
was cleaned in Power Query and visualized in a dashboard; here the same figures are
derived directly in SQL with joins, window functions, CTEs, and `CASE` logic.

---

## Objective

Turn a raw transactional dataset into decisions. Specifically, use SQL to answer:

- Where does revenue come from by **region**, and which **stores** use their space most efficiently?
- How does revenue move **month to month**, and is there seasonality to plan around?
- How concentrated is revenue across the **product catalog** and the **customer base**?

The aim was to practice intermediate/advanced SQL (window functions, CTEs, derived
metrics) on realistic business questions an analyst would actually be handed.

## Overview

The dataset covers **5,000 transactions** across **50 stores**, **50 products**, and
**1,200 customers** over **Jan 2023 – Dec 2024**. Each of the five questions is
answered by a single, self-contained query in [`queries/`](queries/), progressing
from basic aggregation to window-function and CTE-based analysis.

| Metric | Value |
|---|--:|
| Gross revenue | **$6.29M** |
| Gross profit | **$1.80M** |
| Overall margin | **28.6%** |
| Transactions | 5,000 |
| Average order value | $1,258 |
| Period | Jan 1, 2023 – Dec 31, 2024 |

## Tools & Technology

| Tool | Use |
|---|---|
| **MySQL 8.0** | Database engine; all analysis written in SQL |
| **MySQL Workbench** | Query development and execution |
| **Window functions** | `LAG`, running totals, grand totals (`SUM() OVER`) |
| **CTEs** | Staging multi-step logic (`WITH`) |
| **Star-schema modeling** | One fact table joined to three dimensions |

> The window functions require MySQL **8.0+**; they will not run on 5.7 or earlier.

## Dataset

`transactions` is the fact table; the other three are dimensions joined to it by
their IDs. CSV copies are in [`data/`](data/).

| Table | Rows | Role | Key columns |
|---|--:|---|---|
| `transactions` | 5,000 | Fact — one row per sale | `transaction_id`, `transaction_date`, `customer_id`, `store_id`, `product_id`, `quantity`, `gross_revenue`, `gross_profit`, `unit_cost`, `channel` |
| `stores` | 50 | Dimension — store attributes | `store_id`, `store_name`, `city`, `state`, `region`, `store_type`, `store_size_sqft`, `employee_count` |
| `products` | 50 | Dimension — product catalog | `product_id`, `product_name`, `category`, `subcategory`, `brand`, `unit_cost`, `list_price` |
| `customers` | 1,200 | Dimension — customer profiles | `customer_id`, `first_name`, `last_name`, `annual_income`, `loyalty_level`, `customer_segment`, `region` |

**Relationships (star schema):**

```
transactions.store_id     →  stores.store_id
transactions.product_id   →  products.product_id
transactions.customer_id  →  customers.customer_id
```

## Key Insights

- **The South dominates geographically** — $2.40M in revenue, more than the Midwest
  and Northeast combined. West is a strong second at $1.98M.
- **Small-format stores are the most efficient.** Normalized by floor space,
  Neighborhood Markets lead on revenue per square foot (Raleigh #141 at $6.49/sqft),
  while the much larger Supercenters sit at the bottom (San Antonio #107 at $0.46/sqft).
  Raw revenue hides this completely.
- **Revenue is strongly seasonal.** It spikes every **November** (+$243K in 2023,
  +$291K in 2024 — a Black Friday effect) and drops back sharply each January.
- **The product mix is broad, not top-heavy.** It takes **30 of 50 products (60% of
  the catalog)** to reach 80% of revenue — there's no small set of hero products
  carrying the business.
- **Customers are more concentrated than products.** The top-spending **47 customers
  (4% of the base) generate the first 10% of revenue**, and ~29% of customers account
  for half of all revenue.
- **Electronics outsells Appliances** — $3.49M vs. $2.80M in revenue.

## Business Impact

- **Stocking & shelf space:** the revenue-per-sqft finding argues for protecting and
  possibly expanding the small-format Neighborhood Market model, and for scrutinizing
  whether the largest Supercenters justify their footprint.
- **Inventory & staffing:** the November spike is predictable, so inventory builds and
  seasonal staffing should be timed to it rather than spread evenly across the year.
- **Assortment strategy:** because revenue is spread across many products rather than a
  few, breadth of catalog matters — pruning the long tail carries more risk here than
  in a business with a sharp 80/20 split.
- **Customer strategy:** with a meaningful share of revenue concentrated in a small
  group of high-spenders, retention and loyalty efforts aimed at that top tier protect
  an outsized portion of revenue.
- **Regional focus:** the South and West are the growth engines; the Northeast
  ($0.66M) is the clearest expansion or turnaround opportunity.

## SQL Analysis (query by query)

### 1. Revenue by region
**Question:** How does revenue split across the four regions?
**Approach:** join the fact table to `stores`, sum `gross_revenue`, group by region.
**Techniques:** `JOIN`, `GROUP BY`, `SUM`.
**Result:** South **$2.40M** > West $1.98M > Midwest $1.25M > Northeast $0.66M.
→ [`queries/01_revenue_by_region.sql`](queries/01_revenue_by_region.sql)

### 2. Store productivity — revenue per square foot
**Question:** Which stores get the most revenue out of their floor space?
**Approach:** sum revenue per store and divide by `store_size_sqft` to normalize for
size, so productivity is measured rather than raw scale.
**Techniques:** `JOIN`, `GROUP BY`, `SUM`, derived ratio metric.
**Result:** Neighborhood Markets lead (Raleigh #141, **$6.49/sqft**); Supercenters
trail (San Antonio #107, $0.46/sqft).
→ [`queries/02_revenue_per_sqft.sql`](queries/02_revenue_per_sqft.sql)

### 3. Monthly revenue trend & month-over-month change
**Question:** How does revenue move month to month across the two years?
**Approach:** bucket transactions by year-month with `DATE_FORMAT`, sum revenue, and
use `LAG` to pull the prior month's total for a dollar-change column.
**Techniques:** `DATE_FORMAT`, `GROUP BY`, `LAG()` window function.
**Result:** strong seasonality — revenue spikes each November (+$243K in 2023, +$291K
in 2024) and falls back each January.
→ [`queries/03_monthly_revenue_trend.sql`](queries/03_monthly_revenue_trend.sql)

### 4. Product Pareto (80/20) analysis
**Question:** How concentrated is revenue across the product catalog?
**Approach:** rank products by revenue in a CTE, then accumulate a running total down
the ranking and express it as a cumulative share of the grand total, flagging each
product **Top 80%** or **Tail**.
**Techniques:** chained **CTEs**, running total `SUM() OVER (ORDER BY … DESC)`, grand
total `SUM() OVER ()`, cumulative %, `CASE`.
**Result:** revenue is broad — **30 of 50 products (60% of the catalog)** make up the
first 80%, so no small group of products carries sales.
→ [`queries/04_product_pareto.sql`](queries/04_product_pareto.sql)

### 5. Customer revenue concentration
**Question:** How concentrated is revenue among customers?
**Approach:** rank customers by total spend in a CTE, compute a cumulative share of
total revenue, and bucket them into **revenue-share bands** (shares of revenue, not
customer counts).
**Techniques:** chained **CTEs**, running & grand total window sums, cumulative %,
multi-branch `CASE`.
**Result:**

| Band (share of revenue) | Customers | % of customers |
|---|--:|--:|
| Top 10% of revenue | 47 | 4.0% |
| Next 40% of revenue | 295 | 24.9% |
| Bottom 50% of revenue | 843 | 71.1% |

→ [`queries/05_customer_concentration.sql`](queries/05_customer_concentration.sql)

## Techniques demonstrated

Star-schema `JOIN`s · `GROUP BY` aggregation · window functions (`LAG`, running &
cumulative `SUM() OVER`) · common table expressions (CTEs) · multi-branch `CASE`
logic · date bucketing with `DATE_FORMAT` · derived/normalized metrics

## Repository structure

```
walmart-sql-sales-analysis/
├── README.md
├── queries/
│   ├── 01_revenue_by_region.sql
│   ├── 02_revenue_per_sqft.sql
│   ├── 03_monthly_revenue_trend.sql
│   ├── 04_product_pareto.sql
│   └── 05_customer_concentration.sql
└── data/
    ├── transactions.csv
    ├── stores.csv
    ├── products.csv
    └── customers.csv
```

## How to run

1. Create a database and load the four CSVs in [`data/`](data/) as tables
   (`transactions`, `stores`, `products`, `customers`).
2. Open any file in [`queries/`](queries/) and run it.
3. Built and tested on **MySQL 8.0** — the window functions require 8.0+.