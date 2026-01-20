SELECT 
    c.country,
    cat.category,
    SUM(f.amount) AS total_sales
FROM public."FactSales" AS f
LEFT JOIN public."DimCountry" AS c
    ON f.countryid = c.countryid
LEFT JOIN public."DimCategory" AS cat
    ON f.categoryid = cat.categoryid
GROUP BY GROUPING SETS (c.country, cat.category)
ORDER BY total_sales DESC;


SELECT 
    d.Year,
    c.country,
    SUM(f.amount) AS total_sales
FROM public."FactSales" AS f
LEFT JOIN public."DimDate" AS d
    ON f.dateid = d.dateid
LEFT JOIN public."DimCountry" AS c
    ON f.countryid = c.countryid
GROUP BY ROLLUP (d.Year, c.country)
ORDER BY d.Year, c.country;


SELECT 
    d.Year,
    c.country,
    AVG(f.amount) AS avg_sales
FROM public."FactSales" AS f
LEFT JOIN public."DimDate" AS d
    ON f.dateid = d.dateid
LEFT JOIN public."DimCountry" AS c
    ON f.countryid = c.countryid
GROUP BY CUBE (d.Year, c.country)
ORDER BY d.Year, c.country;


CREATE MATERIALIZED VIEW public.total_sales_per_country AS
(
    SELECT 
        c.country,
        SUM(f.amount) AS total_sales
    FROM public."FactSales" AS f
    LEFT JOIN public."DimCountry" AS c
        ON f.countryid = c.countryid
    GROUP BY c.country
)
WITH DATA;

REFRESH MATERIALIZED VIEW public.total_sales_per_country;

SELECT * FROM public.total_sales_per_country;
