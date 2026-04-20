
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



-- LAG / LEAD

SELECT
    time_id,
    TO_CHAR(SUM(amount_sold), '9,999,999,999') AS sales$,
    TO_CHAR(LAG(SUM(amount_sold), 1) OVER (ORDER BY time_id), '9,999,999,999') AS LAG1,
    TO_CHAR(LEAD(SUM(amount_sold), 1) OVER (ORDER BY time_id), '9,999,999,999') AS LEAD1
FROM
    sh.sales s
WHERE
    time_id >= TO_DATE('10-OCT-2000', 'DD-MON-YYYY')
AND
    time_id <= TO_DATE('17-OCT-2000', 'DD-MON-YYYY')
GROUP BY
    time_id;




-- FIRST_VALUE

SELECT
    channel_desc,
    calendar_month_number,
    SUM(amount_sold) AS sales$,
    FIRST_VALUE(SUM(amount_sold)) OVER (PARTITION BY calendar_month_number ORDER BY SUM(amount_sold))
        AS min_sales_month
FROM
    sh.sales s
JOIN
    sh.times t ON t.time_id = s.time_id
JOIN
    sh.channels ch ON ch.channel_id = s.channel_id
WHERE
    calendar_month_number IN (1, 2, 3, 4)
GROUP BY
    channel_desc,
    calendar_month_number
ORDER BY
    2;




-- LAST_VALUE

SELECT    channel_desc,
          calendar_month_number,
          SUM(amount_sold) AS sales$,
          LAST_VALUE(SUM(amount_sold)) OVER (PARTITION BY calendar_month_number ORDER BY SUM(amount_sold))
          AS max_sales_month
FROM      sh.sales s
    JOIN  sh.times t ON t.time_id = s.time_id
    JOIN  sh.channels ch ON ch.channel_id = s.channel_id
WHERE     calendar_month_number IN (1, 2, 3, 4)
GROUP BY  channel_desc,
          calendar_month_number
ORDER BY  2;




-- LAST_VALUE: Unexpected results

SELECT x,
LAST_VALUE(x) OVER (ORDER BY x),
LAST_VALUE(x) OVER (ORDER BY x DESC)
FROM GENERATE_SERIES(1, 10) AS x;


SELECT x,
ARRAY_AGG(x) OVER (ORDER BY x),
ARRAY_AGG(x) OVER (ORDER BY x DESC)
FROM GENERATE_SERIES(1, 10) AS x;



/*
 * 
 * https://www.postgresqltutorial.com/postgresql-window-function/
 * 
 */















