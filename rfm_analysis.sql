CREATE TABLE sales(
	ORDERNUMBER INT NOT NULL,
	QUANTITYORDERED INT NOT NULL,
	PRICEEACH NUMERIC (5,2) NOT NULL,
	ORDERLINENUMBER INT NOT NULL,
	SALES NUMERIC (10,2) NOT NULL,
	ORDERDATE DATE NOT NULL,
	STATUS VARCHAR(10) NOT NULL,
	QTR_ID INT NOT NULL,
	MONTH_ID INT NOT NULL,
	YEAR_ID INT NOT NULL,
	PRODUCTLINE VARCHAR (20) NOT NULL,
	MSRP INT NOT NULL,
	PRODUCTCODE VARCHAR(10) NOT NULL,
	CUSTOMERNAME VARCHAR(50) NOT NULL,
	PHONE VARCHAR (20) NOT NULL,
	ADDRESSLINE1 VARCHAR(50) NOT NULL,
	ADDRESSLINE2 VARCHAR(50),
	CITY VARCHAR(20) NOT NULL,
	STATE VARCHAR (20),
	POSTALCODE VARCHAR(10),
	COUNTRY VARCHAR (20) NOT NULL,
	TERRITORY VARCHAR (20),
	CONTACTLASTNAME VARCHAR(20) NOT NULL,
	CONTACTFIRSTNAME VARCHAR(20) NOT NULL,
	DEALSIZE VARCHAR(10) NOT NULL);

SELECT * FROM sales;

SELECT DISTINCT STATUS FROM sales; --nice to plot
SELECT DISTINCT YEAR_ID FROM sales; 
SELECT DISTINCT PRODUCTLINE FROM sales;--nice to plot
SELECT DISTINCT COUNTRY FROM sales; --nice to plot
SELECT DISTINCT DEALSIZE FROM sales; --nice to plot
SELECT DISTINCT TERRITORY FROM sales; --nice to plot

-----------------------ANALYSIS---------------------------
--GROUPING SALES BY PRODUTLINE
SELECT productline, SUM(SALES) AS revenue FROM sales 
GROUP BY productline
ORDER BY 2 DESC;

--GROUPING SALES BY YEAR
SELECT year_id, SUM(SALES) AS revenue FROM sales 
GROUP BY year_id
ORDER BY 2 DESC;

--In 2005, they only operated for 5 months which makes the revenue low
SELECT DISTINCT month_id FROM sales WHERE year_id =2005; 

--GROUPING SALES BY YEAR
SELECT dealsize, SUM(sales) AS revenue FROM sales 
GROUP BY dealsize
ORDER BY 2 DESC;

--WHAT WAS THE BEST MONTH FOR SALES IN A SPECIFIC YEAR? HOW MUCH WAS EARNED IN THAT MONTH?
SELECT month_id,SUM(sales) AS revenue, COUNT(ordernumber) AS frequency
FROM sales
WHERE year_id=2004
GROUP BY month_id
ORDER BY 2 DESC;

--November seems to be the best month, what product do they sell in November? -Classic
SELECT month_id, productline, SUM(sales) revenue, COUNT(ordernumber)
FROM SALES
WHERE year_id=2004 AND month_id=11
GROUP BY month_id, productline
ORDER BY 3 DESC;


--Who is our best customer (RFM)
DROP TABLE IF EXISTS rfm;
WITH rfm AS
(
	SELECT customername,
	SUM(sales) MonetaryValue,
	AVG(sales) AvgMonetaryValue,
	COUNT(ordernumber) Frequency,
	MAX(orderdate) last_order_date,
	(SELECT MAX(orderdate) FROM SALES) max_order_date, --max order date from all customers
	(SELECT MAX(orderdate) FROM SALES)-MAX(orderdate) recency
FROM SALES
GROUP BY customername 
),
rfm_calc AS
(
	SELECT rfm.*,
	NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
	NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
	NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
	
	FROM rfm 
)
SELECT rfm_calc.*, rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
CONCAT(rfm_recency::VARCHAR, rfm_frequency::VARCHAR, rfm_monetary::VARCHAR) AS rfm_cell_string
INTO rfm
FROM rfm_calc

SELECT * FROM rfm;


SELECT CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	CASE 
		WHEN rfm_cell_string IN ('111', '112' , '121', '122', '123', '132', '211', '212','221', '114', '141') THEN 'Lost customer'  --lost customers
		WHEN rfm_cell_string IN ('232','133', '134', '143', '244', '334', '343', '344', '144') THEN 'Slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		WHEN rfm_cell_string IN ('311', '411', '331') THEN 'New customers'
		WHEN rfm_cell_string IN ('222', '223', '233', '322') THEN 'Potential churners'
		WHEN rfm_cell_string IN ('323', '333','321', '422', '332', '432') THEN 'Active' --(Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string IN ('433', '434', '443', '444') THEN 'Loyal'
	END rfm_segment
from rfm


