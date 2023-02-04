--Analyze the data by finding the answers to the questions below:
--1. Find the top 3 customers who have the maximum count of orders.

SELECT TOP 3 Cust_ID, COUNT(Ord_ID) as total_order
from dbo.e_commerce
Group BY Cust_ID
ORDER BY total_order DESC;
--2. Find the customer whose order took the maximum time to get shipping.

SELECT TOP 1 Cust_ID , Daystakenforshipping
FROM dbo.e_commerce
ORDER BY Daystakenforshipping DESC;
--3. Count the total number of unique customers in January and how many of them
--came back every month over the entire year in 2011

SELECT DISTINCT Cust_ID, Customer_Name, 
                COUNT(Cust_ID) --OVER() as January_customers
        FROM dbo.e_commerce
        WHERE MONTH(Order_Date) = 1 
                AND YEAR(Order_Date) = 2011
        GROUP BY Cust_ID, Customer_Name;

--second part
WITH cte as
(SELECT DISTINCT Cust_ID
        FROM dbo.e_commerce_data
        WHERE MONTH(Order_Date) = 1 
                AND YEAR(Order_Date) = 2011)
SELECT MONTH(d.Order_Date) as months_2011, COUNT(DISTINCT cte.Cust_ID) as total_customers
        FROM cte, dbo.e_commerce_data d 
        WHERE cte.Cust_ID = d.Cust_ID AND YEAR(d.Order_Date) = 2011
        GROUP BY MONTH(d.Order_Date)
        ORDER BY MONTH(d.Order_Date);

--4. Write a query to return for each user the time elapsed between the first
--purchasing and the third purchasing, in ascending order by Customer ID.

WITH cte AS(
        SELECT Cust_ID, Customer_Name, 
                COUNT(Ord_ID) as total_orders 
        FROM dbo.e_commerce
        GROUP BY Cust_ID, Customer_Name
        HAVING COUNT(Ord_ID) > 2), t2 AS (
SELECT cte.Cust_ID, cte.Customer_Name, d.Order_Date,
        LEAD(d.Order_Date, 2) OVER 
                (PARTITION BY cte.Cust_ID, cte.Customer_Name 
                ORDER BY cte.Cust_ID, d.Order_Date) as third_order,
        ROW_NUMBER() OVER(PARTITION BY cte.Cust_ID, cte.Customer_Name 
                    ORDER BY cte.Cust_ID, d.Order_Date) AS order_number
        FROM cte, dbo.e_commerce d
        WHERE cte.Cust_ID = d.Cust_ID) 
SELECT t2.Cust_ID, t2.Customer_Name, t2.Order_Date, t2.third_order, 
        DATEDIFF(DAY, Order_Date, third_order) as time_elapse
        FROM t2 
        WHERE t2.order_number = 1;

--5. Write a query that returns customers who purchased both product 11 and
--product 14, as well as the ratio of these products to the total number of
--products purchased by the customer.

WITH cte as 
        (
        SELECT Cust_ID, Customer_Name
        FROM dbo.e_commerce
        WHERE Prod_ID = 'Prod_11'
        INTERSECT -- intersection of prod_11 and 14 buyers
        SELECT Cust_ID, Customer_Name
        FROM dbo.e_commerce_data
        WHERE Prod_ID = 'Prod_14'
        )
            SELECT cte.Cust_ID, cte.Customer_Name, d.Prod_ID,
                CASE 
                WHEN d.prod_ID IN ('Prod_11', 'Prod_14') THEN 1 ELSE 0 END as prod_11_14,
                COUNT(d.prod_ID) OVER(PARTITION BY cte.Cust_ID, cte.Customer_Name) as total_products
            FROM cte, dbo.e_commerce d 
            WHERE cte.Cust_ID = d.Cust_ID AND cte.Customer_Name = d.Customer_Name
            ORDER BY cte.Cust_ID;

--second part

            WITH cte as 
    (
        SELECT Cust_ID, Customer_Name
            FROM dbo.e_commerce
            WHERE Prod_ID = 'Prod_11'
        INTERSECT 
        SELECT Cust_ID, Customer_Name
            FROM dbo.e_commerce
            WHERE Prod_ID = 'Prod_14'
    )
, t2 as (
        SELECT DISTINCT cte.Cust_ID, cte.Customer_Name,
            SUM(CASE WHEN d.prod_ID IN ('Prod_11', 'Prod_14') THEN 1 ELSE 0 END) 
            OVER (PARTITION BY cte.Cust_ID, cte.Customer_Name) as prod_11_14,
            COUNT(d.prod_ID) OVER(PARTITION BY cte.Cust_ID, cte.Customer_Name) as total_products
        FROM cte, dbo.e_commerce d 
        WHERE cte.Cust_ID = d.Cust_ID AND cte.Customer_Name = d.Customer_Name
                )
SELECT t2.Cust_ID, 
        t2.Customer_Name, 
        t2.prod_11_14, t2.total_products,
        100 *t2.prod_11_14/t2.total_products as Percentage_11_14
        FROM t2
        ORDER BY t2.Cust_ID;

        --Customer Segmentation
--Categorize customers based on their frequency of visits. The following steps
--will guide you. If you want, you can track your own way.
--1. Create a “view” that keeps visit logs of customers on a monthly basis. (For
--each log, three field is kept: Cust_id, Year, Month)

CREATE or ALTER VIEW vw_customer_visits 
AS 
        SELECT Cust_ID,
            YEAR(Order_Date) AS Year,
            MONTH(Order_Date) AS Month
        FROM dbo.e_commerce

---2. Create a “view” that keeps the number of monthly visits by users. (Show
--separately all months from the beginning business)

CREATE or ALTER  VIEW vw_monthly_visits AS
        SELECT
                YEAR(order_date) as Year, 
                MONTH(order_date) as Month, 
                COUNT(*) as monthly_visits
        FROM dbo.e_commerce
        GROUP BY YEAR(order_date), MONTH(order_date);

--3. For each visit of customers, create the next month of the visit as a separate
--column.

SELECT Cust_ID, 
        Customer_Name,
	Ord_ID,
        Order_Date,
	MONTH(LEAD(Order_Date) OVER (PARTITION BY Cust_ID, Customer_Name 
                                ORDER BY Cust_ID, Order_Date)) 
                                as next_order_month
	FROM dbo.e_commerce



--4. Calculate the monthly time gap between two consecutive visits by each
--customer.

SELECT Cust_ID, 
        Customer_Name,
	Ord_ID,
        Order_Date,
	LEAD(Order_Date) OVER (PARTITION BY Cust_ID, Customer_Name ORDER BY Cust_ID, Order_Date) as next_order,
       DATEDIFF(MONTH,Order_Date, LEAD(Order_Date) OVER (PARTITION BY Cust_ID, Customer_Name 
                                                      ORDER BY Cust_ID, Order_Date)) 
                                                      as time_gap_between_orders
				FROM dbo.e_commerce;

/*5. Categorise customers using average time gaps. Choose the most fitted
labeling model for you.
For example:
o Labeled as churn if the customer hasn't made another purchase in the
months since they made their first purchase.
o Labeled as regular if the customer has made a purchase every month.
Etc.*/

WITH cte AS(
    SELECT Cust_ID, 
                Customer_Name,
	        Ord_ID,
                Order_Date,
		LEAD(Order_Date) OVER (PARTITION BY Cust_ID, Customer_Name 
                                        ORDER BY Cust_ID, Order_Date) as next_order,
            DATEDIFF(MONTH,Order_Date, 
                        LEAD(Order_Date) 
                        OVER (PARTITION BY Cust_ID, Customer_Name 
                                ORDER BY Cust_ID, Order_Date)) 
                                 as time_gap_between_orders
	FROM dbo.e_commerce
        )
SELECT Cust_ID, 
        Customer_Name, 
        AVG(time_gap_between_orders) as avg_time_gap,
        CASE
        WHEN AVG(time_gap_between_orders) IS NULL THEN 'Churn'
        WHEN AVG(time_gap_between_orders) <= 24 THEN 'Regular'
        END AS churn_status
FROM cte 
GROUP BY Cust_ID, Customer_Name
ORDER BY AVG(time_gap_between_orders);


/*Month-Wise Retention Rate
Find month-by-month customer retention ratei since the start of the business.
There are many different variations in the calculation of Retention Rate. But we will
try to calculate the month-wise retention rate in this project.
So, we will be interested in how many of the customers in the previous month could
be retained in the next month.
Proceed step by step by creating “views”. You can use the view you got at the end of
the Customer Segmentation section as a source.
1. Find the number of customers retained month-wise. (You can use time gaps)*/

SELECT * from order_time_gap
WHERE time_gap_between_orders is not null
order by time_gap_between_orders

WITH CTE AS (
SELECT  cust_id, YEAR(order_Date) as years, MONTH(Order_Date) as months,
        COUNT(cust_ID) OVER(PARTITION BY YEAR(order_Date), MONTH(Order_Date) 
                                ORDER BY YEAR(order_Date), MONTH(Order_Date)) as monthly_retained
        FROM order_time_gap
WHERE time_gap_between_orders = 1)
SELECT years, months, COUNT(monthly_retained) as monthly_retained_customers
FROM CTE
GROUP BY years, months
ORDER BY years, months;



---2. Calculate the month-wise retention rate.


DECLARE @counter INT, @max_months INT, @retained_customers INT, @total_customers_per_month INT  
SET @counter = 1 
SET @max_months = (SELECT MAX(months) FROM monthly_retained_customers) 

WHILE @counter < @max_months
	BEGIN 
			SET @retained_customers = (SELECT COUNT(DISTINCT cust_id) 
                                                FROM monthly_retained_customers
                                                WHERE months = @counter +1 
                                                        AND Cust_ID IN 
                                                                (
                                                                SELECT DISTINCT Cust_ID 
                                                                FROM monthly_retained_customers
                                                                WHERE months = @counter
                                                                ))
                        SET @total_customers_per_month = (SELECT COUNT (DISTINCT Cust_ID) 
                                                        FROM monthly_retained_customers
                                                        WHERE months = @counter + 1)

			PRINT 'Retention rate is ' 
                                + CAST(100 * @retained_customers / @total_customers_per_month AS VARCHAR(2))
                                + '% for the '
                                + CAST(@counter +1 AS VARCHAR (2))
                                + '. month.'

			SET @counter +=1
	END  