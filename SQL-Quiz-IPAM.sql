-- Step 1: compute unit price per sale for year 2001
-- Step 2: rank products within each category by price (cheapest first)
-- Step 3: take the cheapest from each category and rank them across all categories
-- Step 4: pick the product at the 3rd overall position

WITH sales_2001 AS (
SELECT
	p.prod_id,
	p.prod_name,
	p.prod_category,
	s.amount_sold / NULLIF(s.quantity_sold, 0) AS unit_price
FROM
	sh.sales s
JOIN sh.times t ON
	s.time_id = t.time_id
JOIN sh.products p ON
	s.prod_id = p.prod_id
WHERE
	t.calendar_year = 2001
),
cheapest_per_category AS (
SELECT
	prod_name,
	prod_category,
	unit_price,
	ROW_NUMBER() OVER (
            PARTITION BY prod_category
ORDER BY
	unit_price ASC
        ) AS rn_in_category
FROM
	sales_2001
),
least_expensive_list AS (
SELECT
	prod_name,
	prod_category,
	unit_price,
	ROW_NUMBER() OVER (
	ORDER BY unit_price ASC) AS overall_position
FROM
	cheapest_per_category
WHERE
	rn_in_category = 1
)
SELECT
	overall_position,
	prod_category,
	prod_name,
	unit_price
FROM
	least_expensive_list
ORDER BY
	overall_position;



-- Percentage difference in Hardware sales: Q4 2000 vs Q1 2000
-- Channels: Partners and Internet

WITH quarterly_sales AS (
    SELECT
        t.calendar_quarter_number                   AS quarter_num,
        SUM(s.amount_sold)                          AS total_amount
    FROM sh.sales s
    JOIN sh.products p ON p.prod_id    = s.prod_id
    JOIN sh.channels c ON c.channel_id = s.channel_id
    JOIN sh.times    t ON t.time_id    = s.time_id
    WHERE t.calendar_year            = 2000
      AND t.calendar_quarter_number IN (1, 4)
      AND c.channel_desc            IN ('Partners', 'Internet')
      AND p.prod_category            = 'Hardware'
    GROUP BY t.calendar_quarter_number
)
SELECT
    ROUND(
        ( (MAX(total_amount) FILTER (WHERE quarter_num = 4))
        - (MAX(total_amount) FILTER (WHERE quarter_num = 1)) )
        / (MAX(total_amount) FILTER (WHERE quarter_num = 1))
        * 100,
        2
    ) AS pct_difference
FROM quarterly_sales;



-- Total cumulative sales for 2000 (all four quarters)
-- Categories: Electronics, Hardware, Software/Other
-- Channels:   Partners, Internet

SELECT
    ROUND(SUM(s.amount_sold)::numeric, 2) AS total_sales
FROM sh.sales s
JOIN sh.products p ON p.prod_id    = s.prod_id
JOIN sh.channels c ON c.channel_id = s.channel_id
JOIN sh.times    t ON t.time_id    = s.time_id
WHERE t.calendar_year = 2000
  AND c.channel_desc  IN ('Partners', 'Internet')
  AND p.prod_category IN ('Electronics', 'Hardware', 'Software/Other');




-- Breakdown by quarter and category for verification

SELECT
    t.calendar_quarter_number                       AS quarter_num,
    p.prod_category                                 AS category,
    ROUND(SUM(s.amount_sold)::numeric, 2)           AS sales
FROM sh.sales s
JOIN sh.products p ON p.prod_id    = s.prod_id
JOIN sh.channels c ON c.channel_id = s.channel_id
JOIN sh.times    t ON t.time_id    = s.time_id
WHERE t.calendar_year = 2000
  AND c.channel_desc  IN ('Partners', 'Internet')
  AND p.prod_category IN ('Electronics', 'Hardware', 'Software/Other')
GROUP BY ROLLUP (t.calendar_quarter_number, p.prod_category)
ORDER BY quarter_num NULLS LAST, category NULLS LAST;











