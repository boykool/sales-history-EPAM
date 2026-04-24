
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
 * https://youtu.be/Wvg4PjbMTO8
 * 
 */





/*
 * 
 * https://claude.ai/share/9240bb42-e70d-4210-ba12-e140113d6f45
 * 
 */




-- Cumulative sales amount per customer by quarter for year 2000
-- Outer SUM aggregates within each (cust_id, quarter);
-- window SUM accumulates those quarterly totals across quarters within each customer

SELECT c.cust_id,
       t.calendar_quarter_desc,
       SUM(s.amount_sold) AS q_sales,
       SUM(SUM(s.amount_sold)) OVER (
           PARTITION BY c.cust_id
           ORDER BY t.calendar_quarter_desc
           RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cum_sales
FROM sh.sales s
JOIN sh.customers c ON c.cust_id = s.cust_id
JOIN sh.times     t ON t.time_id = s.time_id
WHERE c.cust_id IN (2595, 9646, 11111)
  AND t.calendar_year = 2000
GROUP BY c.cust_id, t.calendar_quarter_desc
ORDER BY c.cust_id, t.calendar_quarter_desc;


-- Cumulative amount_sold

SELECT     c.cust_id, t.calendar_quarter_desc,
           SUM(amount_sold) AS q_sales,
           SUM(SUM(amount_sold)) OVER (PARTITION BY c.cust_id ORDER BY t.calendar_quarter_desc
                                      RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales
FROM       sh.sales s
  JOIN     sh.customers c ON c.cust_id = s.cust_id
  JOIN     sh.times t ON t.time_id = s.time_id
WHERE      c.cust_id IN (2595, 9646, 11111)
AND        t.calendar_year = 2000
GROUP BY   c.cust_id,
           t.calendar_quarter_desc
ORDER BY   c.cust_id,
           t.calendar_quarter_desc;


-- Same cumulative sum, but window definition is extracted into a named WINDOW clause;
-- ARRAY_AGG shows which values are included in the frame at each step (frame debugging)

SELECT c.cust_id,
       t.calendar_quarter_desc,
       SUM(s.amount_sold)                  AS q_sales,
       SUM(SUM(s.amount_sold))   OVER w    AS cum_sales,
       ARRAY_AGG(SUM(s.amount_sold)) OVER w AS array_agg
FROM sh.sales s
JOIN sh.customers c ON c.cust_id = s.cust_id
JOIN sh.times     t ON t.time_id = s.time_id
WHERE c.cust_id IN (2595, 9646, 11111)
  AND t.calendar_year = 2000
GROUP BY c.cust_id, t.calendar_quarter_desc
WINDOW w AS (
    PARTITION BY c.cust_id
    ORDER BY t.calendar_quarter_desc
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
ORDER BY c.cust_id, t.calendar_quarter_desc;



-- Cumulative amount_sold + ARRAY_AGG

SELECT
    c.cust_id,
    t.calendar_quarter_desc,
    SUM(amount_sold) AS q_sales,
    SUM(SUM(amount_sold)) OVER w AS cum_sales,
    ARRAY_AGG(SUM(amount_sold)) OVER w AS array_agg
FROM sh.sales s
JOIN sh.customers c ON c.cust_id = s.cust_id
JOIN sh.times t ON t.time_id = s.time_id
WHERE c.cust_id IN (2595, 9646, 11111)
  AND t.calendar_year = 2000
GROUP BY
    c.cust_id,
    t.calendar_quarter_desc
WINDOW w AS (
    PARTITION BY c.cust_id
    ORDER BY t.calendar_quarter_desc
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
ORDER BY
    c.cust_id,
    t.calendar_quarter_desc;


-- Same cumulative calculation but with EXCLUDE CURRENT ROW:
-- the current row is dropped from the frame before aggregation is applied.
-- For the first row in each partition the frame becomes empty -> SUM and ARRAY_AGG return NULL

SELECT c.cust_id,
       t.calendar_quarter_desc,
       SUM(s.amount_sold)                   AS q_sales,
       SUM(SUM(s.amount_sold))    OVER w    AS cum_sales,
       ARRAY_AGG(SUM(s.amount_sold)) OVER w AS array_agg
FROM sh.sales s
JOIN sh.customers c ON c.cust_id = s.cust_id
JOIN sh.times     t ON t.time_id = s.time_id
WHERE c.cust_id IN (2595, 9646, 11111)
  AND t.calendar_year = 2000
GROUP BY c.cust_id, t.calendar_quarter_desc
WINDOW w AS (
    PARTITION BY c.cust_id
    ORDER BY t.calendar_quarter_desc
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    EXCLUDE CURRENT ROW
)
ORDER BY c.cust_id, t.calendar_quarter_desc;


-- Cumulative amount_sold + ARRAY_AGG + frame_exclusion

SELECT    c.cust_id, t.calendar_quarter_desc,
          SUM(amount_sold) AS q_sales,
          SUM(SUM(amount_sold)) OVER w AS cum_sales,
          ARRAY_AGG(SUM(amount_sold)) OVER w AS array_agg
FROM      sh.sales s
JOIN      sh.customers c ON c.cust_id = s.cust_id
JOIN      sh.times t ON t.time_id = s.time_id
WHERE     c.cust_id IN (2595, 9646, 11111)
AND       t.calendar_year = 2000
GROUP BY  c.cust_id,
          t.calendar_quarter_desc
WINDOW    w AS (PARTITION BY c.cust_id ORDER BY t.calendar_quarter_desc
            RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE CURRENT ROW)
ORDER BY  c.cust_id,
          t.calendar_quarter_desc;




-- Centered 3-day moving average of daily sales.
-- The frame uses an INTERVAL offset because t.time_id is of type date:
-- take all rows whose time_id lies within [current - 1 day, current + 1 day]


SELECT t.time_id,
       TO_CHAR(SUM(s.amount_sold), '9,999,999,999') AS sales,
       TO_CHAR(
           AVG(SUM(s.amount_sold)) OVER (
               ORDER BY t.time_id
               RANGE BETWEEN INTERVAL '1 day' PRECEDING
                         AND INTERVAL '1 day' FOLLOWING
           ),
           '9,999,999,999'
       ) AS cent_3_day_avg
FROM sh.sales s
JOIN sh.times t ON t.time_id = s.time_id
WHERE t.calendar_week_number IN (51)
  AND t.calendar_year = 1999
GROUP BY t.time_id
ORDER BY t.time_id;



-- Centered moving average

SELECT   t.time_id,
         TO_CHAR(SUM(amount_sold),'9,999,999,999') AS sales,
         TO_CHAR(AVG(SUM(amount_sold)) OVER (ORDER BY t.time_id RANGE BETWEEN
                                           INTERVAL '1' DAY PRECEDING AND
                                           INTERVAL '1' DAY FOLLOWING), '9,999,999,999') AS cent_3_day_avg
FROM     sh.sales s
 JOIN    sh.times t ON t.time_id = s.time_id
WHERE    t.calendar_week_number IN (51)
AND      calendar_year = 1999
GROUP BY t.time_id
ORDER BY t.time_id;



-- Quarterly sales report: previous quarter, absolute delta, percent delta
-- Inner query: FIRST_VALUE over a 2-row frame returns the previous quarter's sales
-- Outer query: CASE substitutes 'N/A' for Q1 (where no previous quarter exists)

SELECT calendar_quarter_desc,
       q_sales,
       CASE WHEN RIGHT(calendar_quarter_desc, 1) = '1' THEN 'N/A'
            ELSE TO_CHAR(prev_q, '9,999,999,990.99')
       END AS prev_q,
       CASE WHEN RIGHT(calendar_quarter_desc, 1) = '1' THEN 'N/A'
            ELSE TO_CHAR(q_sales - prev_q, '9,999,999,990.99')
       END AS delta_q,
       CASE WHEN RIGHT(calendar_quarter_desc, 1) = '1' THEN 'N/A'
            ELSE TO_CHAR((q_sales - prev_q) / prev_q * 100, '9,999,999,990.99') || '%'
       END AS delta_q_prc
FROM (
    SELECT t.calendar_quarter_desc,
           SUM(s.amount_sold) AS q_sales,
           FIRST_VALUE(SUM(s.amount_sold)) OVER (
               ORDER BY t.calendar_quarter_desc
               ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
           ) AS prev_q
    FROM sh.sales s
    JOIN sh.products  p ON p.prod_id = s.prod_id
    JOIN sh.customers c ON c.cust_id = s.cust_id
    JOIN sh.times     t ON t.time_id = s.time_id
    WHERE t.calendar_year = 2000
      AND c.cust_id IN (2595, 9646, 11111)
    GROUP BY t.calendar_quarter_desc
) tab
ORDER BY 1;


-- Centered moving average

SELECT    t.time_id,
          TO_CHAR(SUM(amount_sold),'9,999,999,999') AS sales,
          TO_CHAR(AVG(SUM(amount_sold)) OVER (ORDER BY t.time_id RANGE BETWEEN
                                              INTERVAL '1' DAY PRECEDING AND
                                              INTERVAL '1' DAY FOLLOWING), '9,999,999,999') AS cent_3_day_avg
FROM      sh.sales s
  JOIN    sh.times t ON t.time_id = s.time_id
WHERE     t.calendar_week_number IN (51)
AND       calendar_year = 1999
GROUP BY  t.time_id
ORDER BY  t.time_id;



-- Cleaner version using LAG instead of FIRST_VALUE with a frame
-- LAG returns NULL for the first row - no need for RIGHT(..., 1) = '1' trick;
-- we just check prev_q IS NULL

SELECT calendar_quarter_desc,
       q_sales,
       CASE WHEN prev_q IS NULL THEN 'N/A'
            ELSE TO_CHAR(prev_q, '9,999,999,990.99')
       END AS prev_q,
       CASE WHEN prev_q IS NULL THEN 'N/A'
            ELSE TO_CHAR(q_sales - prev_q, '9,999,999,990.99')
       END AS delta_q,
       CASE WHEN prev_q IS NULL THEN 'N/A'
            ELSE TO_CHAR((q_sales - prev_q) / prev_q * 100, '9,999,999,990.99') || '%'
       END AS delta_q_prc
FROM (
    SELECT t.calendar_quarter_desc,
           SUM(s.amount_sold) AS q_sales,
           LAG(SUM(s.amount_sold)) OVER (ORDER BY t.calendar_quarter_desc) AS prev_q
    FROM sh.sales s
    JOIN sh.products  p ON p.prod_id = s.prod_id
    JOIN sh.customers c ON c.cust_id = s.cust_id
    JOIN sh.times     t ON t.time_id = s.time_id
    WHERE t.calendar_year = 2000
      AND c.cust_id IN (2595, 9646, 11111)
    GROUP BY t.calendar_quarter_desc
) tab
ORDER BY 1;


-- Reporting

SELECT      calendar_quarter_desc, q_sales,
            CASE WHEN RIGHT(calendar_quarter_desc, 1)= '1' THEN 'N/A'
                 ELSE TO_CHAR(prev_q, '9,999,999,990.99')
            END AS prev_q,
            CASE WHEN RIGHT(calendar_quarter_desc, 1)= '1' THEN 'N/A'
                 ELSE TO_CHAR(q_sales - prev_q, '9,999,999,990.99')
            END AS delta_q,
            CASE WHEN RIGHT(calendar_quarter_desc, 1)= '1' THEN 'N/A'
                 ELSE TO_CHAR((q_sales - prev_q) / prev_q * 100, '9,999,999,990.99') || '%'
            END AS delta_q_prc
FROM (
      SELECT   t.calendar_quarter_desc, SUM(amount_sold) AS q_sales,
               FIRST_VALUE(SUM(amount_sold)) OVER (ORDER BY t.calendar_quarter_desc
                                                   ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS prev_q
      FROM     sh.sales s
      JOIN     sh.products p ON p.prod_id = s.prod_id
      JOIN     sh.customers c ON c.cust_id = s.cust_id
      JOIN     sh.times t ON t.time_id = s.time_id
      WHERE    t.calendar_year = 2000
      AND      c.cust_id IN (2595,9646, 11111)
      GROUP BY t.calendar_quarter_desc
) tab
ORDER BY 1;


-- FIRST_VALUE with two different frame modes on the same ordering key.
-- The data has a gap: months 3,4,5 then 10,11,12 (no sales in 6-9 via Tele Sales in 1998).
-- RANGE  looks at VALUES: "1 PRECEDING" means month_number >= current - 1, so 9 is missing -> frame has only the current row
-- GROUPS looks at PEER GROUPS: "1 PRECEDING" means one peer group back in physical order, so month 5 is the previous group before month 10

SELECT t.calendar_month_number,
       SUM(s.amount_sold) AS m_sales,
       FIRST_VALUE(SUM(s.amount_sold)) OVER (
           ORDER BY t.calendar_month_number
           RANGE BETWEEN 1 PRECEDING AND CURRENT ROW
       ) AS range_first_value,
       FIRST_VALUE(SUM(s.amount_sold)) OVER (
           ORDER BY t.calendar_month_number
           GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
       ) AS groups_first_value
FROM sh.sales    s
JOIN sh.customers c  ON c.cust_id    = s.cust_id
JOIN sh.times     t  ON t.time_id    = s.time_id
JOIN sh.channels  ch ON ch.channel_id = s.channel_id
WHERE t.calendar_year = 1998
  AND ch.channel_desc = 'Tele Sales'
GROUP BY t.calendar_month_number
ORDER BY t.calendar_month_number;


-- RANGE vs GROUPS

SELECT    t.calendar_month_number,
          SUM(amount_sold) AS m_sales,
          FIRST_VALUE(SUM(amount_sold)) OVER (ORDER BY t.calendar_month_number
                                             RANGE BETWEEN 1 PRECEDING AND CURRENT ROW) AS range_first_value,
          FIRST_VALUE(SUM(amount_sold)) OVER (ORDER BY t.calendar_month_number
                                             GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW) AS groups_first_value
FROM      sh.sales s
  JOIN    sh.customers c ON c.cust_id = s.cust_id
  JOIN    sh.times t ON t.time_id = s.time_id
  JOIN    sh.channels ch ON ch.channel_id = s.channel_id
WHERE     t.calendar_year = 1998
AND       ch.channel_desc = 'Tele Sales'
GROUP BY  t.calendar_month_number
ORDER BY  t.calendar_month_number;



/*
 * 
 * https://claude.ai/share/9240bb42-e70d-4210-ba12-e140113d6f45
 *  
 */


/*
 * 
 * https://www.postgresqltutorial.com/postgresql-window-function/
 * 
 * https://youtu.be/Wvg4PjbMTO8
 * 
 */



