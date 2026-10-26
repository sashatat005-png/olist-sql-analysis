/* =====================================================================
   Lumetta x Olist - Market, sellers and customer satisfaction
   Database : olist

   Business questions
     Q1. Is Olist's tech segment a fit for Lumetta's products?       (Part 1)
     Q2. Who sells tech on Olist, and how concentrated is it?        (Part 2)
     Q3. Where are Olist's customers and tech buyers?                (Part 3)
     Q4. What drives customer satisfaction?                          (Part 4)

   Definitions (stated once, used everywhere)
     - Tech      = categories in v_tech_products below
     - Revenue   = SUM(order_items.price) -> product price only, freight excluded
     - Scope     = Parts 1-3 use all orders (demand on the marketplace);
                   Part 4 uses delivered orders only
     - USD       = BRL converted with the yearly average rate in v_fx_rates
                   (one rule everywhere - cite the source of the rates)
     - Late      = delivered on a later calendar day than the estimated date

   ===================================================================== */

USE olist;



CREATE OR REPLACE VIEW v_tech_products AS
SELECT product_id, product_category_name
FROM products
WHERE product_category_name IN (
    'eletronicos',
    'informatica_acessorios',
    'pcs',
    'tablets_impressao_imagem',
    'telefonia',
    'telefonia_fixa',
    'audio',
    'consoles_games',
    'cine_foto'
);

-- One review score per order (some orders have several reviews)
CREATE OR REPLACE VIEW v_order_ratings AS
SELECT
    order_id,
    AVG(review_score) AS review_score
FROM order_reviews
WHERE review_score IS NOT NULL
GROUP BY order_id;

-- Yearly average BRL per USD (the student's own rates - add the source)
CREATE OR REPLACE VIEW v_fx_rates AS
SELECT 2016 AS yr, 3.4839 AS brl_per_usd
UNION ALL SELECT 2017, 3.1910
UNION ALL SELECT 2018, 3.6513;


/* =====================================================================
   PART 1 - MARKET FIT: how does tech compare to the rest of Olist?
   ===================================================================== */

-- 1.1 Tech vs. other: average price, revenue share

SELECT
    CASE WHEN tp.product_id IS NOT NULL THEN 'Tech' ELSE 'Other' END AS segment,
    COUNT(*)                                                    AS items_sold,
    COUNT(DISTINCT oi.order_id)                                 AS orders,
    ROUND(SUM(oi.price), 2)                                     AS revenue_brl,
    ROUND(100 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 2)  AS pct_of_revenue,
    ROUND(AVG(oi.price), 2)                                     AS avg_item_price_brl
FROM order_items AS oi
LEFT JOIN v_tech_products AS tp
    ON oi.product_id = tp.product_id
GROUP BY segment;

/* INSIGHT 1.1
   Tech is [13.99 ]% of Olist's revenue. An average tech item costs [ 122.56] BRL,
   vs. [122.56 ] BRL for other products.
   -> Tech items are cheaper than average:based on price alone, Olist's tech 
      buyers do not appear to be a premium audience

*/


-- 1.2 Top 10 categories by revenue, with share and tech flag


SELECT
    p.product_category_name,
    IF(MAX(tp.product_id) IS NULL, 'No', 'Yes')                 AS is_tech,
    ROUND(SUM(oi.price), 2)                                     AS revenue_brl,
    ROUND(100 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 2)  AS pct_of_revenue,
    COUNT(DISTINCT oi.order_id)                                 AS orders,
    COUNT(*)                                                    AS items_sold
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
LEFT JOIN v_tech_products AS tp
    ON oi.product_id = tp.product_id
GROUP BY p.product_category_name
ORDER BY revenue_brl DESC
LIMIT 10;
-- Change ORDER BY to "orders DESC" to see the top 10 by orders.

/* INSIGHT 1.2
   The top 3 categories are beleza_saude , relogios_presentes ,  cama_mesa_banho. The highest tech category is
   informatica_acessorios  at position 5  (6.71 % of revenue).
   -> Olist is a general marketplace led by non_tech categories, not a tech destination.
*/


-- 1.3 Tech categories: average price in BRL and USD

SELECT
    tp.product_category_name,
    COUNT(*)                                     AS items_sold,
    ROUND(AVG(oi.price), 2)                      AS avg_price_brl,
    ROUND(AVG(oi.price / fx.brl_per_usd), 2)     AS avg_price_usd
FROM order_items AS oi
JOIN v_tech_products AS tp
    ON oi.product_id = tp.product_id
JOIN orders AS o
    ON oi.order_id = o.order_id
JOIN v_fx_rates AS fx
    ON YEAR(o.order_purchase_timestamp) = fx.yr
GROUP BY tp.product_category_name
ORDER BY avg_price_usd DESC;

/* INSIGHT 1.3
   The tech category with the highest average price is pcs,
   with an average item price of 331.80 USD.
   Most tech categories have an average item price below 41.05 USD.

   -> Higher-priced tech exists on Olist, but it is not typical across most tech categories.

   PART 1 CONCLUSION:
   Tech represents 13.99% of Olist's revenue, and tech items have a lower
   average price than non-tech items.
*/

/* =====================================================================
   PART 2 - SELLERS: who sells tech, and how concentrated is revenue?
   ===================================================================== */

-- 2.1 Tech sellers as a share of all active sellers

SELECT
    COUNT(DISTINCT oi.seller_id)                                                AS active_sellers,
    COUNT(DISTINCT CASE WHEN tp.product_id IS NOT NULL THEN oi.seller_id END)   AS tech_sellers,
    ROUND(100 * COUNT(DISTINCT CASE WHEN tp.product_id IS NOT NULL THEN oi.seller_id END)
              / COUNT(DISTINCT oi.seller_id), 2)                                AS pct_tech_sellers
FROM order_items AS oi
LEFT JOIN v_tech_products AS tp
    ON oi.product_id = tp.product_id;

/* INSIGHT 2.1
   492 of 3095 active sellers ([15.90 ]%) sell at least one tech item.
*/


-- 2.2 Sellers per tech category
SELECT
    tp.product_category_name,
    COUNT(DISTINCT oi.seller_id)   AS sellers,
    COUNT(DISTINCT oi.order_id)    AS orders,
    ROUND(COUNT(DISTINCT oi.order_id) / COUNT(DISTINCT oi.seller_id), 1) AS orders_per_seller
FROM order_items AS oi
JOIN v_tech_products AS tp
    ON oi.product_id = tp.product_id
GROUP BY tp.product_category_name
ORDER BY sellers DESC;

/* INSIGHT 2.2
   informatica_acessorios has the most sellers (287); tablets_impressao_imagem has the fewest (6).
   -> Categories with few sellers but many orders have less competition
      for a new entrant like Lumetta.
       -> Seller presence varies widely across tech categories, with much stronger
      competition in computers & accessories than in smaller tech segments.

*/


-- 2.3 Top 10 sellers: revenue, share and cumulative share

SELECT
    seller_id,
    ROUND(SUM(price), 2)                                               AS revenue_brl,
    ROUND(100 * SUM(price) / SUM(SUM(price)) OVER (), 2)               AS pct_of_revenue,
    ROUND(100 * SUM(SUM(price)) OVER (ORDER BY SUM(price) DESC)
              / SUM(SUM(price)) OVER (), 2)                            AS cumulative_pct
FROM order_items
GROUP BY seller_id
ORDER BY revenue_brl DESC
LIMIT 10;

 /* INSIGHT 2.3
   The top 10 sellers (out of 3095) generate 13.15% of revenue.
   -> Revenue is spread out: a few large sellers do not
      dominate the marketplace.
*/


/* =====================================================================
   PART 3 - GEOGRAPHY: where are sellers, customers and tech buyers?
   ===================================================================== */

-- 3.1 Sellers and orders by state, side by side

WITH sellers_by_state AS (
    SELECT s.seller_state AS state, COUNT(DISTINCT s.seller_id) AS active_sellers
    FROM sellers AS s
    JOIN order_items AS oi
        ON s.seller_id = oi.seller_id
    GROUP BY s.seller_state
),
orders_by_state AS (
    SELECT c.customer_state AS state, COUNT(*) AS orders
    FROM orders AS o
    JOIN customers AS c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_state
)
SELECT
    ob.state,
    ob.orders,
    ROUND(100 * ob.orders / SUM(ob.orders) OVER (), 2)                         AS pct_of_orders,
    COALESCE(sb.active_sellers, 0)                                             AS active_sellers,
    ROUND(100 * COALESCE(sb.active_sellers, 0) / SUM(sb.active_sellers) OVER (), 2) AS pct_of_sellers
FROM orders_by_state AS ob
LEFT JOIN sellers_by_state AS sb
    ON ob.state = sb.state
ORDER BY ob.orders DESC
LIMIT 10;

/* INSIGHT 3.1
   SP has 41.98% of orders and 59.74% of sellers.
   -> Both demand and supply are concentrated in the South-East.
*/


-- 3.2 Tech demand by customer state (states with 100+ tech items)
SELECT
    c.customer_state,
    COUNT(*)                                                   AS tech_items,
    ROUND(SUM(oi.price), 2)                                    AS tech_revenue_brl,
    ROUND(100 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 2) AS pct_of_tech_revenue,
    ROUND(AVG(oi.price), 2)                                    AS avg_tech_price_brl,
    ROUND(AVG(oi.price / fx.brl_per_usd), 2)                   AS avg_tech_price_usd
FROM order_items AS oi
JOIN v_tech_products AS tp
    ON oi.product_id = tp.product_id
JOIN orders AS o
    ON oi.order_id = o.order_id
JOIN customers AS c
    ON o.customer_id = c.customer_id
JOIN v_fx_rates AS fx
    ON YEAR(o.order_purchase_timestamp) = fx.yr
GROUP BY c.customer_state
HAVING COUNT(*) >= 100
ORDER BY tech_revenue_brl DESC;
-- Note: pct_of_tech_revenue is out of the states shown (HAVING filters first).

/* INSIGHT 3.2
   SP, RJ and MG together account for 61.83% of tech revenue.
   The highest average tech price is in SP ( 29.19 USD).

*/


/* =====================================================================
   PART 4 - CUSTOMER SATISFACTION (delivered orders only)
   ===================================================================== */

-- 4.1 Review score: late vs. on-time orders

SELECT
    CASE
        WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
        THEN 'Late' ELSE 'On Time'
    END                                                          AS delivery_status,
    COUNT(*)                                                     AS reviewed_orders,
    ROUND(AVG(r.review_score), 2)                                AS avg_review_score,
    ROUND(100 * AVG(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END), 2) AS pct_bad_reviews
FROM orders AS o
JOIN v_order_ratings AS r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;

/* INSIGHT 4.1
   Late orders score 2.27 on average vs. 4.29 for on-time orders, and 62.36% of
   late orders get a 1-2 star review (vs. 9.23%).
   -> Late delivery is the clearest cause of unhappy customers.
*/


-- 4.2 Price vs. review score per category (categories with 100+ orders)


WITH category_items AS (
    SELECT p.product_category_name, oi.order_id, oi.price,
           tp.product_id IS NOT NULL AS is_tech
    FROM order_items AS oi
    JOIN products AS p
        ON oi.product_id = p.product_id
    LEFT JOIN v_tech_products AS tp
        ON oi.product_id = tp.product_id
    JOIN orders AS o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
),
category_price AS (
    SELECT product_category_name, MAX(is_tech) AS is_tech, AVG(price) AS avg_price
    FROM category_items
    GROUP BY product_category_name
),
category_review AS (
    SELECT ci.product_category_name, COUNT(*) AS reviewed_orders, AVG(r.review_score) AS avg_review
    FROM (SELECT DISTINCT product_category_name, order_id FROM category_items) AS ci
    JOIN v_order_ratings AS r
        ON ci.order_id = r.order_id
    GROUP BY ci.product_category_name
)
SELECT
    cp.product_category_name,
    IF(cp.is_tech = 1, 'Yes', 'No')   AS is_tech,
    ROUND(cp.avg_price, 2)            AS avg_price_brl,
    cr.reviewed_orders,
    ROUND(cr.avg_review, 2)           AS avg_review_score
FROM category_price AS cp
JOIN category_review AS cr
    ON cp.product_category_name = cr.product_category_name
WHERE cr.reviewed_orders >= 100
ORDER BY cp.avg_price DESC;

/* INSIGHT 4.2
   Tech categories score between 4.22 and 4.12; 
   Expensive categories score about the same as lower-priced categories.
   -> Price does not seem to drive satisfaction.
*/
  


-- 4.3 Seller handoff speed vs. review score

--      call it handoff, not shipping - it ends when the carrier gets the parcel.
--      A 3,000-row seller list cannot be read, so sellers are grouped into bands.)
WITH seller_orders AS (
    SELECT DISTINCT
        oi.seller_id,
        o.order_id,
        DATEDIFF(o.order_delivered_carrier_date, o.order_approved_at) AS handoff_days
    FROM order_items AS oi
    JOIN orders AS o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_approved_at IS NOT NULL
      AND o.order_delivered_carrier_date IS NOT NULL
      AND o.order_delivered_carrier_date >= o.order_approved_at
),
seller_stats AS (
    SELECT
        so.seller_id,
        COUNT(*)               AS orders,
        AVG(so.handoff_days)   AS avg_handoff_days,
        AVG(r.review_score)    AS avg_review
    FROM seller_orders AS so
    JOIN v_order_ratings AS r
        ON so.order_id = r.order_id
    GROUP BY so.seller_id
    HAVING COUNT(*) >= 10
)
SELECT
    CASE
        WHEN avg_handoff_days <= 2 THEN '1. Fast (0-2 days)'
        WHEN avg_handoff_days <= 5 THEN '2. Moderate (2-5 days)'
        ELSE                            '3. Slow (5+ days)'
    END                            AS seller_speed,
    COUNT(*)                       AS sellers,
    SUM(orders)                    AS orders,
    ROUND(AVG(avg_review), 2)      AS avg_review_score
FROM seller_stats
GROUP BY seller_speed
ORDER BY seller_speed;


/* INSIGHT 4.3
   Fast sellers average [4.28] stars, while slow sellers average
   [3.82] stars (581 fast sellers vs. 119 slow sellers).

   -> Slow sellers score [0.46] stars lower on average.
      Lumetta would control its own handoff, so this part of the experience
      is partly within its control.
*/

-- 4.4 States with the lowest review scores (states with 500+ reviewed orders)

SELECT
    c.customer_state,
    COUNT(*)                         AS reviewed_orders,
    ROUND(AVG(r.review_score), 2)    AS avg_review_score,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1)
                                     AS avg_delivery_days
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
JOIN v_order_ratings AS r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 500
ORDER BY avg_review_score ASC
LIMIT 5;

/* INSIGHT 4.4
   The lowest-rated states are MA, PA, and BA.
   These states also show relatively long average delivery times.
   -> Lower review scores appear alongside slower delivery, which supports 4.1.

   PART 4 CONCLUSION:
   Satisfaction depends mainly on on-time delivery.
*/

/* =====================================================================
   FINAL CONCLUSION & RECOMMENDATION
   =====================================================================

   1. Market fit:
      Tech represents 13.99% of Olist's revenue.
      Tech items have a lower average price than non-tech items, and most
      tech categories are concentrated at relatively low average price points.

   2. Sellers:
      [pct_tech_sellers from Query 2.1]% of active sellers sell at least one
      tech item, while the top 10 sellers generate only 13.15% of total revenue.

   3. Geography:
      Demand and tech revenue are strongly concentrated in SP and the
      South-East region.

   4. Satisfaction:
      Late orders average 2.27 stars compared with 4.29 for on-time orders.

   Recommendation:
      Do not partner at this stage.

   Supporting reason:
      Olist has a meaningful technology market, but the current evidence does
      not show a strong enough fit with Lumetta's premium positioning:
      higher-value tech demand appears limited, while delivery performance
      remains important to customer satisfaction.

   Condition / next step:
      Reassess the opportunity if stronger evidence of higher-value demand,
      clearer financial information, and stronger delivery-service guarantees
      become available.

   Limitations:
      Data covers 2016-2018; revenue excludes freight; the USD conversion uses
      yearly averages; small states and categories have few orders.
   ===================================================================== */