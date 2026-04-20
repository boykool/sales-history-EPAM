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