use walmartsales;
select * from walmart;

--                                                            TASK 1

-- Walmart wants to identify which branch has exhibited the highest sales growth over time



SELECT Branch, 
MONTHNAME(STR_TO_DATE(Date, '%d-%m-%Y')) AS months,
ROUND(SUM(Total), 2) AS monthly_sales
FROM walmart
GROUP BY Branch, months
ORDER BY Branch,monthly_sales desc;

-- To calculate growth rate, compare month over month:

SELECT Branch, months, monthly_sales,
LAG(monthly_sales) OVER (PARTITION BY Branch ORDER BY months) AS prev_month_sales,
ROUND(((monthly_sales - LAG(monthly_sales) OVER (PARTITION BY Branch ORDER BY months))
/ LAG(monthly_sales) OVER (PARTITION BY Branch ORDER BY months)) * 100, 2) AS growth_rate
FROM (
    SELECT Branch, 
           MONTH(STR_TO_DATE(Date, '%d-%m-%Y')) AS months,
           ROUND(SUM(Total), 2) AS monthly_sales
    FROM walmart
    GROUP BY Branch, months
) t;


--                                                            TASK 2

-- Walmart needs to determine which product line contributes the highest profit to each branch.
--  The profit margin should be calculated based on the difference between the gross income and cost of goods sold

SELECT Branch, `Product line`, profit
FROM (
    SELECT Branch,
           `Product line`,
           ROUND(SUM(cogs - `gross income`), 3) AS profit,
           RANK() OVER (PARTITION BY Branch ORDER BY SUM(cogs - `gross income`) DESC) AS rnk
    FROM walmart
    GROUP BY Branch, `Product line`
) t
WHERE rnk = 1;

--                                                            TASK 3

--  Walmart wants to segment customers based on their average spending behavior. Classify customers 
-- into 3 tiers: High, Medium, and Low spenders based on their total purchase amounts.


WITH customer_spending AS (
    SELECT `Customer ID`,
           ROUND(SUM(Total), 2) AS Total_spending
    FROM walmart
    GROUP BY `Customer ID`
)
SELECT `Customer ID`, Total_spending,
CASE 
	WHEN tier = 3 THEN 'High'
	WHEN tier = 2 THEN 'Medium'
	WHEN tier = 1 THEN 'Low'
END AS Sales_Segment
FROM (
    SELECT `Customer ID`, Total_spending,
	NTILE(3) OVER (ORDER BY total_spending) AS tier
    FROM customer_spending
) t
ORDER BY `Customer ID`,total_spending DESC;

--                                                            TASK 4

-- Walmart suspects that some transactions have unusually high or low sales compared to the average for the
-- product line. Identify these anomalies. 

WITH product_stats AS (
    SELECT 
        `Product line`,
        ROUND(AVG(Total),3) AS avg_sales,
        ROUND(STD(Total),3) AS std_dev
    FROM walmart
    GROUP BY `Product line`
)
SELECT 
    w.`Invoice ID`,
    w.Branch,
    w.`Product line`,
    w.Total,
    s.avg_sales,
    s.std_dev,
    CASE 
        WHEN w.Total > s.avg_sales + 2 * s.std_dev THEN 'High Anomaly'
        WHEN w.Total < s.avg_sales - 2 * s.std_dev THEN 'Low Anomaly'
        ELSE 'Normal'
    END AS anomaly_status
FROM walmart w
JOIN product_stats s
    ON w.`Product line` = s.`Product line`
WHERE (w.Total > s.avg_sales + 2 * s.std_dev
    OR w.Total < s.avg_sales - 2 * s.std_dev)
ORDER BY w.`Product line`, w.Total DESC;

--                                                            TASK 5

-- Walmart needs to determine the most popular payment method in each city to tailor marketing strategies

SELECT city ,payment ,counts FROM
	(SELECT DISTINCT city,payment,count(Payment) as counts, 
	DENSE_RANK() OVER (PARTITION BY city ORDER BY COUNT(Payment) DESC) AS rnk 
FROM walmart GROUP BY city,Payment ORDER BY city,counts DESC) t
WHERE rnk=1  ;


--                                                            TASK 6

-- Walmart wants to understand the sales distribution between male and female customers on a monthly basis.

SELECT MONTHNAME(STR_TO_DATE(Date, '%d-%m-%y')) AS Months ,Gender,
ROUND(SUM(Total),3) AS sales
FROM walmart 
GROUP BY Months,Gender ORDER BY Months,sales DESC;



--                                                            TASK 7

-- Walmart wants to know which product lines are preferred by different customer types(Member vs. Normal).



SELECT `Customer type`, `Product line`, customer_count
FROM (
    SELECT `Customer type`,`Product line`,
           COUNT(*) AS customer_count,
           RANK() OVER (PARTITION BY `Customer type` ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart
    GROUP BY `Customer type`, `Product line`
) t
WHERE rnk = 1 OR rnk=2 or rnk=3 ;


--                                                            TASK 8

--  Walmart needs to identify customers who made repeat purchases within a specific time frame within 30 day

WITH purchase_seq AS (
  SELECT
    `Customer ID`,
    STR_TO_DATE(Date, '%d-%m-%Y') AS txn_date,
    LAG(STR_TO_DATE(Date, '%d-%m-%Y')) OVER (
        PARTITION BY `Customer ID`
        ORDER BY STR_TO_DATE(Date, '%d-%m-%Y')
    ) AS prev_date
  FROM walmart
)
SELECT `Customer ID`,
       COUNT(*) AS repeat_purchase_count
FROM purchase_seq
WHERE prev_date IS NOT NULL
  AND DATEDIFF(txn_date, prev_date) <= 30
GROUP BY `Customer ID`
ORDER BY repeat_purchase_count DESC;

--                                                            TASK 9

--  Walmart wants to reward its top 5 customers who have generated the most sales Revenue.

SELECT `Customer ID` , ROUND(SUM(Total),2) AS sales_revenue
FROM walmart
GROUP BY `Customer ID` ORDER BY sales_revenue DESC 
LIMIT 5;


--                                                            TASK 10

--  Walmart wants to analyze the sales patterns to determine which day of the week brings the highest sales

SELECT DAYNAME(STR_TO_DATE(Date, '%d-%m-%Y')) AS day_of_week,
ROUND(SUM(Total),2) AS total_sales
FROM walmart 
GROUP BY  day_of_week
ORDER BY total_sales DESC ;


--                                   ------ ADDITIONAL-------

--      TOTAL SALES BY HOURS

SELECT HOUR(Time) as Hours ,
ROUND(SUM(Total),2) as Total_sales
FROM walmart 
GROUP BY Hours ORDER BY Total_sales DESC;

--  TOTAL SALES BY DAY PART AND PRODUCT LINE

SELECT 
    CASE 
        WHEN HOUR(Time) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN HOUR(Time) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN HOUR(Time) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END AS Day_Part,
    `Product line`,
    ROUND(SUM(Total),2) AS Total_Sales
FROM walmart
GROUP BY Day_Part, `Product line`
ORDER BY Day_Part, Total_Sales DESC ;


