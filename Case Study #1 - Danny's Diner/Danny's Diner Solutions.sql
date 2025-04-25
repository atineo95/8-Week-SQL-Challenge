select s.customer_id, sum(m.price) as totalSpent
from sales s
inner join menu m on
s.product_id = m.product_id
group by s.customer_id;

#How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as totalVisits
from sales
group by customer_id;

#What was the first item from the menu purchased by each customer?
with ranking as (
	select s.customer_id, m.product_name,
	dense_rank() over (partition by customer_id order by order_date asc) as rankingProducts
	from sales s
	inner join menu m on 
	s.product_id = m.product_id
)
select *
from ranking
where rankingProducts = 1;

#What is the most purchased item on the menu and how many times was it purchased by all customers?
select * from (
	select m.product_name, count(s.product_id) purchasedAmount
	from menu m 
	join sales s on 
	m.product_id = s.product_id
	group by m.product_name
) as purchase 
order by purchasedamount desc
limit 1;

#Which item was the most popular for each customer?
with joinedTables as (
	select m.product_name, s.customer_id, count(s.product_id) as purchasedAmount
	from menu m
	join sales s on 
	m.product_id = s.product_id
	group by m.product_name, s.customer_id
)
select * from (
	select *,
	dense_rank() over (partition by customer_id order by purchasedAmount desc) as purchaseRank
	from joinedTables
) as rankings
where purchaseRank = 1;

#Which item was purchased first by the customer after they became a member?
with filteredTable as (
	select s.customer_id, s.order_date, s.product_id
	from sales s
	join members me on
	me.customer_id = s.customer_id 
	where s.order_date > me.join_date
), ranking as(
	select f.customer_id, f.order_date, f.product_id, 
	rank() over (partition by customer_id order by order_date asc) as ordered,
	m.product_name
	from filteredTable f
	left join menu m on
	f.product_id = m.product_id
)
select *
from ranking
where ordered = 1;

#What is the total items and amount spent for each member before they became a member?
with filteredTable as (
	select s.customer_id, s.order_date, s.product_id
	from sales s
	join members me on
	me.customer_id = s.customer_id 
	where s.order_date < me.join_date
)
select f.customer_id, count(*) as totalItems, sum(m.price) amountSpent
from filteredTable f
join menu m on 
f.product_id = m.product_id
group by f.customer_id;

#If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with points as (
	select s.customer_id, 
	case
		when m.product_name = 'sushi' then m.price * 10 * 2
		else m.price *10
	end as points
	from sales s 
	join menu m on
	s.product_id = m.product_id
)
select customer_id, sum(points)
from points
group by customer_id;

#In the first week after a customer joins the program (including their join date) 
#they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with endDates as(
	select *,
	DATE_ADD(join_date, interval 6 day) as endDate 
	from members
),
qualifiedMembers as(
	select s.customer_id, m.product_name, m.price, s.order_date, e.join_date, e.endDate
	from sales s
	join menu m on
	s.product_id = m.product_id
	join endDates e on
	s.customer_id = e.customer_id
	where s.order_date >= e.join_date
	and s.order_date <= '2021-01-31'
),
points as (
	select customer_id, product_name, price,
	case 
		when order_date between join_date and endDate then price * 10 * 2
		when product_name = 'sushi' then price * 10 * 2
		else price * 10
	end as points
	from qualifiedMembers
)
select customer_id, sum(points) as totalPoints
from points
group by customer_id;
