SELECT COUNT(*) FROM walmart
SELECT * FROM walmart
DROP TABLE walmart;

SELECT 
	payment_method,
	COUNT(*) AS Total_Count
FROM walmart
GROUP BY 1


SELECT
	COUNT(DISTINCT(branch))
FROM walmart

-- Q1
-- What are the different payment methods, and how many transactions and
-- items were sold with each method?
SELECT 
	payment_method,
	COUNT(*) as Total_transactions,
	SUM(quantity) as nO_Item_sold
FROM walmart
GROUP BY 1;


-- Q2 Which category received the highest average rating in each branch?
SELECT *
FROM (
	SELECT
		branch,
		category,
		AVG(rating) as AvgRating,
		RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) as rnk
	FROM walmart
	GROUP BY 1,2
)
WHERE rnk = 1


-- Q3 
SELECT *
FROM (
    SELECT 
        branch,
        TO_CHAR(date, 'FMDay') AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER (
            PARTITION BY branch 
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM walmart
    GROUP BY branch, TO_CHAR(date, 'FMDay')
) AS sub
WHERE rnk = 1;

-- Q4 How many items were sold through each payment method?
SELECT 
	payment_method,
	SUM(quantity) as No_Quantity
FROM walmart
GROUP BY 1

-- Q5 What are the average, minimum, and maximum ratings for each category in each city?
SELECT
	city,
	category,
	MIN(rating) as MinRating,
	AVG(rating) as AvgRating,
	MAX(rating) as MaxRating
FROM walmart
GROUP BY 1,2


-- Q6 What is the total profit for each category, ranked from highest to lowest?
SELECT
	category,
	SUM(total) as total_revenue,
	SUM(total  * profit_margin) as Total_Profit
FROM walmart
GROUP BY 1;

-- Q7 What is the most frequently used payment method in each branch?
WITH cte
AS
(
SELECT 
		branch,
		payment_method,
		COUNT(*) AS Total_Trans,
		RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk 
	FROM walmart
	GROUP BY 1,2
)

SELECT * FROM cte
WHERE rnk = 1

-- Q8 How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
SELECT 
branch,
CASE 
	WHEN EXTRACT(HOUR FROM (time::time)) < 12  THEN 'Morning'
	WHEN EXTRACT(HOUR FROM (time::time)) BETWEEN 12 AND 17  THEN 'Afternoon'
	ELSE 'Evening'
	END shift,
	COUNT(*) AS NO_TRANSACTION
FROM walmart
GROUP BY 1,2
ORDER BY 1,3 DESC

-- Q9 Which branches experienced the largest decrease in revenue compared to the previous year?
WITH revenue_2022 AS (
    SELECT
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE EXTRACT(YEAR FROM date) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE EXTRACT(YEAR FROM date) = 2023
    GROUP BY branch
)

SELECT 
    ls.branch,
    ls.revenue AS revenue_2022,
    cs.revenue AS revenue_2023,
    ROUND(
        ((ls.revenue - cs.revenue)::numeric / ls.revenue::numeric) * 100,
        2
    ) AS revenue_decrease_percent
FROM revenue_2022 ls
JOIN revenue_2023 cs
    ON ls.branch = cs.branch
WHERE cs.revenue < ls.revenue
ORDER BY revenue_decrease_percent DESC
LIMIT 5;






WITH yearly_revenue AS (
    SELECT
        branch,
        EXTRACT(YEAR FROM date) AS year,
        SUM(total) AS revenue
    FROM walmart
    GROUP BY branch, year
)

SELECT 
    branch,
    year,
    revenue,
    previous_year,
    ROUND(
        ((previous_year - revenue) / previous_year)::numeric * 100,
        2
    ) AS revenue_decrease_percent
FROM (
    SELECT 
        branch,
        year,
        revenue,
        LAG(revenue) OVER (PARTITION BY branch ORDER BY year) AS previous_year
    FROM yearly_revenue
) sub
WHERE revenue < previous_year;
