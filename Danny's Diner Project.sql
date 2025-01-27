CREATE DATABASE Dannys_diner;
USE Dannys_diner;

CREATE TABLE sales(
customer_id VARCHAR(1),
order_date DATE,
product_id INTEGER
);
INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', '1'),
    ('A', '2021-01-01', '2'),
    ('A', '2021-01-07', '2'),
    ('A', '2021-01-10', '3'),
    ('A', '2021-01-11', '3'),
    ('A', '2021-01-11', '3'),
    ('B', '2021-01-01', '2'),
    ('B', '2021-01-02', '2'),
    ('B', '2021-01-04', '1'),
    ('B', '2021-01-11', '1'),
    ('B', '2021-01-16', '3'),
    ('B', '2021-02-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-07', '3');

CREATE TABLE menu(
product_id INTEGER,
product_name VARCHAR(5),
price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	('1', 'sushi', '10'),
    ('2', 'curry', '15'),
    ('3', 'ramen', '12');

CREATE TABLE members 
(customer_id VARCHAR(1), join_date DATE);

INSERT INTO members
	(customer_id, join_date)
VALUES
	('A','2021-01-07'),
    ('B','2021-01-09');

-- 1.What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) AS total_spent
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT s.customer_id, COUNT(DISTINCT s.order_date) AS days_visited
FROM sales s
GROUP BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?

With customer_first_purchase AS (
	SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
	FROM sales s
	GROUP BY s.customer_id
)
SELECT cfp.customer_id, cfp.first_purchase_date, m.product_name
FROM customer_first_purchase cfp
JOIN sales s ON s.customer_id = cfp.customer_id
AND cfp.first_purchase_date = s.order_date
JOIN menu m ON m.product_id = s.product_id;

-- 4. what was the most purchase item on the menu and how many times was it purchased by all customers?

SELECT m.product_name, COUNT(*) AS total_purchased
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchased DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

SELECT 
	s.customer_id, 
    m.product_name, 
    COUNT(*) AS purchase_count,
	ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER by COUNT(*) DESC) AS position
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name;


-- 6. Which Item was purchased first by the customer after they became a member?

WITH first_purchase_after_membership AS(
	SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
    FROM sales s
    JOIN members ms ON s.customer_id = ms.customer_id
    WHERE s.order_date >= ms.join_date
    GROUP BY s.customer_id
)

SELECT fpam.customer_id, m.product_name
FROM first_purchase_after_membership fpam
JOIN sales s ON s.customer_id = fpam.customer_id
AND fpam.first_purchase_date = s.order_date
JOIN menu m ON s.product_id = m.product_id;

-- 7. Which Item was purchased just before the customer became a member?

WITH last_purchase_before_membership AS (
	SELECT s.customer_id, MAX(s.order_date) AS last_purchase_date
	FROM sales s
	JOIN members ms ON s.customer_id = ms.customer_id
	WHERE s.order_date < ms.join_date
	GROUP BY s.customer_id
)
SELECT lpbm.customer_id, m.product_name
FROM last_purchase_before_membership lpbm
JOIN sales s ON lpbm.customer_id = s.customer_id
AND lpbm.last_purchase_date = s.order_date
JOIN menu m ON s.product_id = m.product_id;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(*) AS total_items, SUM(m.price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members ms ON s.customer_id = ms.customer_id
WHERE s.order_date < ms.join_date
GROUP BY s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? 

SELECT s.customer_id, SUM(
	CASE
    WHEN m.product_name = 'sushi' THEN m.price*20
    ELSE m.price*10 END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id, SUM(
	CASE
    WHEN s.order_date BETWEEN ms.join_date AND DATE_ADD(ms.join_date, INTERVAL 7 DAY)
    THEN m.price*20
    WHEN m.product_name = 'sushi' THEN m.price*20
    ELSE m.price*10 END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members ms ON s.customer_id = ms.customer_id
WHERE s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
GROUP BY s.customer_id;

-- 11. Recreate the table output using the available data

SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE WHEN s.order_date >= ms.join_date THEN 'Y'
ELSE 'N' END AS member
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members ms ON s.customer_id = ms.customer_id
ORDER BY s.customer_id, s.order_date;

-- 12. Rank all the things

WITH customers_data AS (
	SELECT s.customer_id, s.order_date, m.product_name, m.price,
	CASE
		WHEN s.order_date < ms.join_date THEN 'N'
		WHEN s.order_date >= ms.join_date THEN 'Y'
		ELSE 'N' END AS member
	FROM sales s
	LEFT JOIN members ms ON s.customer_id = ms.customer_id
	JOIN menu m ON s.product_id = m.product_id
)
SELECT *,
CASE WHEN member = 'N' THEN NULL
ELSE ROW_NUMBER() OVER(PARTITION BY customer_id, member ORDER BY order_date)
END AS ranking
FROM customers_data
ORDER BY customer_id AND Order_date;