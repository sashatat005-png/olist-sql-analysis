# olist-sql-analysis
SQL analysis of the Olist Brazilian e-commerce dataset
# Lumetta x Olist: Should a Premium Tech Brand Sell on Olist?

SQL analysis of the Olist Brazilian e-commerce dataset to assess whether Lumetta, a premium technology retailer, should partner with the Olist marketplace.

## Business Context

Lumetta is a premium technology retailer considering entry into the Brazilian market through Olist, a large online marketplace.

The main business question is:

**Is Olist a strong enough fit for Lumetta's premium positioning to justify a partnership?**

## Key Findings

- **Market fit:** Tech represents **13.99% of Olist's product revenue**. Tech items also have a lower average price than non-tech items, suggesting that technology is a meaningful but not dominant premium segment on the marketplace.

- **Marketplace structure:** The highest-ranking tech category is **Computers & Accessories**, which ranks **5th by revenue**. This indicates that Olist has a meaningful technology market but remains a broad general marketplace.

- **Seller concentration:** The **top 10 sellers generate only 13.15% of total product revenue**, suggesting that marketplace revenue is relatively distributed rather than dominated by a small number of sellers.

- **Geography:** Both overall demand and technology demand are strongly concentrated in **São Paulo and the South-East region**, making this the most important geographic market in the dataset.

- **Customer satisfaction:** Late orders receive an average review score of **2.27**, compared with **4.29** for on-time orders. Delivery performance therefore appears strongly associated with customer satisfaction.

## Recommendation

**Do not partner with Olist at this stage.**

Olist has a real and meaningful technology market, but the available evidence does not show a strong enough fit with Lumetta's premium positioning. Higher-value technology demand appears limited compared with lower-priced categories, while delivery performance remains important to customer satisfaction.

The opportunity should be reassessed if stronger evidence of higher-value demand, clearer financial information, and stronger delivery-service guarantees become available.

## Dataset

**Brazilian E-Commerce Public Dataset by Olist**

Source: Kaggle — Brazilian E-Commerce Public Dataset by Olist

- Period: **2016–2018**
- Approximately **100,000 orders**
- Main tables used:
  - `orders`
  - `order_items`
  - `products`
  - `customers`
  - `sellers`
  - `order_reviews`
  - `product_category_name_translation`

The raw dataset is not included in this repository and should be downloaded separately from Kaggle.

## Approach

The analysis was organised around four business areas:

1. **Market Fit**
   - Tech versus non-tech pricing and revenue
   - Top categories by revenue and orders
   - Tech-category pricing in BRL and USD

2. **Seller Market**
   - Number of active technology sellers
   - Sellers by technology category
   - Revenue concentration among top sellers

3. **Geography**
   - Distribution of sellers and customers by state
   - Technology demand and revenue by state

4. **Customer Satisfaction**
   - Late versus on-time delivery
   - Price versus review score
   - Seller handoff speed versus reviews
   - Regional differences in satisfaction

## Key Definitions

### Technology Categories

The following Olist categories were classified as technology:

- `eletronicos`
- `informatica_acessorios`
- `pcs`
- `tablets_impressao_imagem`
- `telefonia`
- `telefonia_fixa`
- `audio`
- `consoles_games`
- `cine_foto`

### Revenue

Revenue is defined as:

**SUM(order_items.price)**

This represents product price only and excludes freight.

### Late Delivery

An order is considered late when it is delivered on a **later calendar day** than its estimated delivery date.

### USD Conversion

Brazilian Real prices were converted to USD using **yearly average exchange rates**, applying one consistent conversion rule throughout the analysis.

## Data Quality Improvements

Several data-quality issues were addressed during the analysis:

- Used **one review score per order** to avoid duplicated reviews when joining order-level and item-level tables.
- Used `COUNT(DISTINCT order_id)` when calculating order counts from `order_items`.
- Compared delivery dates at the **calendar-date level** when identifying late orders.
- Used a `LEFT JOIN` when separating technology and non-technology products to avoid silently excluding products with missing categories.
- Applied one consistent yearly USD conversion method.
- Excluded impossible seller-handoff timestamps where the carrier date occurred before order approval.

## Repository Structure

```text
olist-sql-analysis/
│
├── README.md
├── olist_lumetta_market_analysis_edited.sql
└── images/
```

## How to Reproduce

1. Install **MySQL 8**.
2. Download the Brazilian E-Commerce Public Dataset by Olist.
3. Import the dataset into a MySQL database called `olist`.
4. Run `olist_lumetta_market_analysis_edited.sql`.
5. Review the query outputs and INSIGHT sections for the business conclusions.

## Skills Demonstrated

- SQL using MySQL 8
- Joins
- Common Table Expressions (CTEs)
- Views
- Window functions
- CASE expressions
- Aggregations
- `COUNT(DISTINCT ...)`
- Data-quality validation
- Currency conversion
- Business analysis
- Data storytelling
- Translating technical findings into a business recommendation

## Limitations and Next Steps

- The dataset covers **2016–2018**, so current Brazilian e-commerce conditions may differ.
- Revenue excludes freight costs.
- USD conversion uses yearly average exchange rates rather than transaction-day exchange rates.
- Some states and technology categories have relatively small samples.
- The dataset does not directly classify customers or products as **premium**.
- The analysis does not contain Lumetta-specific partnership fees, operating costs, or profit margins.

A useful next step would be to compare Olist's market data with Lumetta's own product prices, margins, customer profile, and required delivery-service levels.

## Author
Sama Shatat  
Data Analysis Bootcamp Project
