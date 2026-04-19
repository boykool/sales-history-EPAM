
-- SET

-- SET search_path TO sh, public;

SELECT * FROM sh.sales LIMIT 12;


-- AVG() + PARTITION BY

SELECT
    prod_id,
    prod_name,
    prod_subcategory,
    prod_list_price,
    ROUND(AVG(prod_list_price) OVER (PARTITION BY prod_subcategory), 2)
FROM
    sh.products
WHERE
    prod_subcategory IN ('Bulk Pack Diskettes', 'Camera Media', 'Printer Supplies');

-- BOO

SELECT
	p.prod_id ,
	p.prod_name,
	p.prod_subcategory,
	p.prod_list_price,
	AVG(p.prod_list_price) OVER (PARTITION BY p.prod_subcategory )
FROM
	products p
WHERE
	p.prod_subcategory IN ('Bulk Pack Diskettes', 'Camera Media', 'Printer Supplies' )
;



-- SUM() + PARTITION BY

SELECT
    cn.country_name,
    ch.channel_desc,
    SUM(amount_sold) AS sales$,
    SUM(SUM(amount_sold)) OVER (PARTITION BY cn.country_name) AS all_channels_sales$
FROM
    sh.sales s
JOIN
    sh.products p ON p.prod_id = s.prod_id
JOIN
    sh.customers cust ON cust.cust_id = s.cust_id
JOIN
    sh.times t ON t.time_id = s.time_id
JOIN
    sh.channels ch ON ch.channel_id = s.channel_id
JOIN
    sh.countries cn ON cn.country_id = cust.country_id
WHERE
    t.calendar_month_desc IN ('2000-09','2000-10')
AND
    cn.country_iso_code IN ('AU','BR','CA','DE')
GROUP BY
    cn.country_name,
    ch.channel_desc
ORDER BY
    country_name;















-- Aggregate Function: Reporting

-- For each product category, find the region in which it had maximum sales

SELECT
    prod_category,
    country_region,
    SUM(s.amount_sold) AS sales,
    MAX(SUM(amount_sold)) OVER (PARTITION BY p.prod_category) AS max_reg_sales
FROM
    sh.sales s
JOIN
    sh.products p ON p.prod_id = s.prod_id -- to get prod_category
JOIN
    sh.customers cust ON cust.cust_id = s.cust_id -- to get country_id of customer
--JOIN
    --sh.channels ch ON ch.channel_id = s.channel_id -- present but unused in SELECT
JOIN
    sh.countries cn ON cn.country_id = cust.country_id -- to get country_region
WHERE
    time_id = TO_DATE('11-OCT-2001', 'DD-MON-YYYY')
GROUP BY
    prod_category,
    country_region;


-- BOO

SELECT prod_category, country_region, sales
FROM (
    SELECT
        p.prod_category,
        cn.country_region,
        SUM(s.amount_sold) AS sales,
        MAX(SUM(s.amount_sold)) OVER (PARTITION BY p.prod_category) AS max_reg_sales
    FROM sh.sales s
    JOIN sh.products  p    ON p.prod_id     = s.prod_id
    JOIN sh.customers cust ON cust.cust_id  = s.cust_id
    JOIN sh.countries cn   ON cn.country_id = cust.country_id
    WHERE s.time_id = TO_DATE('11-OCT-2001', 'DD-MON-YYYY')
    GROUP BY p.prod_category, cn.country_region
) t
WHERE sales = max_reg_sales;


-- TRY


SELECT
    prod_category,
    country_region,
    sales
FROM (
    SELECT
        prod_category,
        country_region,
        SUM(s.amount_sold) AS sales,
        MAX(SUM(amount_sold)) OVER (PARTITION BY p.prod_category) AS max_reg_sales
    FROM
        sh.sales s
    JOIN
        sh.products p ON p.prod_id =s.prod_id
    JOIN
        sh.customers cust ON cust.cust_id = s.cust_id
    JOIN
        sh.channels ch ON ch.channel_id = s.channel_id
    JOIN
        sh.countries cn ON cn.country_id = cust.country_id
    WHERE
        time_id = TO_DATE('11-OCT-2001', 'DD-MON-YYYY')
    GROUP BY
        prod_category,
        country_region
) tab
WHERE
    sales = max_reg_sales;





