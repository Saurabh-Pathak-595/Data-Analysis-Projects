drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21'); 

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'), 
(2,'2015-01-15'), 
(3,'2014-04-11'); 

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-4-19',2),(3,'2019-12-18',1),(2,'2020-7-20',3),(1,'2019-10-23',2),(1,'2018-3-19',3),
(3,'2016-12-20',2),(1,'2016-11-9',1),(1,'2016-5-20',3),(2,'2017-9-24',1),(1,'2017-3-11',2),
(1,'2016-3-11',1),(3,'2016-11-10',1),(3,'2017-12-7',2),(3,'2016-12-15',2),(2,'2017-11-8',2),(2,'2018-9-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- 1.  what is the total amount each customer spent on zomato.
select userid,sum(price) as `amount spent` from sales s left join product p on s.product_id=p.product_id group by 1 order by 1;

-- 2.  How many days has each customer visited zomato?
Select userid, count(distinct created_date) as count_of_days_visited from sales group by 1;

-- 3.  What was the first product purchased by each customer?
select userid, created_date as first_purchase_date, product_id as first_product 
 from (Select *, rank() over(partition by userid order by created_date) as rnk from sales)s where s.rnk=1;
 
-- 4.  What is the most purchased item on the menu and how many times was it purchased by all the customers?
Select product_id as `most purchased item product id:` from sales group by 1 order by count(product_id) desc limit 1;
Select userid, count(product_id) as `no. of times ordered` from sales where 
  product_id=(Select product_id as `most purchased item product id:` from sales group by 1 order by count(product_id) desc limit 1) group by 1 order by 1;
-- Alternate method:
select userid,product_id, count(*) from sales group by userid,product_id having product_id=2 order by userid;

-- 5.  Which item was the most popular for each customer?
select * from (select *, rank() over(partition by userid order by c.`no of times ordered` desc) as rnk from 
(Select *, count(*) as `no of times ordered` from sales group by userid, product_id)c)f where rnk=1;

-- 6.  which item was purchased by the customer after they became a member?
Select * from (Select s.userid,created_date,product_id,gold_signup_date, rank() over (partition by s.userid order by created_date) as rnk from 
sales s right join goldusers_signup g on s.userid=g.userid and s.created_date>=g.gold_signup_date)r where r.rnk=1;

-- 7.  which item was purchased just before the customer became a member?
Select * from (Select s.userid,created_date,product_id,gold_signup_date, rank() over (partition by s.userid order by created_date desc) as rnk from 
sales s right join goldusers_signup g on s.userid=g.userid and s.created_date<g.gold_signup_date)r where r.rnk=1;

-- 8.  What is the total orders and amount spent for each member before they became a member?
select s.userid, count(*) as `no. of orders`, sum(price) as `total amount spent`  from sales s 
right join goldusers_signup g on s.userid=g.userid and s.created_date<g.gold_signup_date 
left join product p on p.product_id=s.product_id group by s.userid;

/* 9.  if buying each product genereates points for ex. 5 Rs = 2 points and each product has different purchasing points 
       for ex. for p1 5rs=1 zomato point for p2 10rs=5 zomato point  and for p3 5rs=1 zomato point, calculate points collected by each customer 
       and for which product most points have been given till now. */
-- first calculating product wise total points
-- method 1
with points (userid,created_date,product_id,product_name,price, `sum`) as (Select s.userid,created_date,s.product_id,product_name,price, sum(price) as `sum` from sales s left join product p on s.product_id=p.product_id 
group by s.userid,product_id order by s.userid)
Select *,if(product_name in ('p1','p3'),round(sum/5),round(sum/2)) as `product wise total points` from points;
-- method 2
select *, if(product_name in ('p1','p3'),round(points.sum/5),round(sum/2)) as `product wise total points` from 
(Select s.userid,created_date,s.product_id,product_name,price, sum(price) as `sum` from sales s left join product p on s.product_id=p.product_id 
group by s.userid,product_id order by s.userid)points;

-- Now calculating total points collected by each customer.

Select userid, sum(final_p.`product wise total points`) as total_points_collected, sum(final_p.`product wise total points`)*2.5 as total_cashback_earned from 
(select points.*, if(product_name in ('p1','p3'),round(points.sum/5),round(sum/2)) as `product wise total points` from 
(Select s.userid,created_date,s.product_id,product_name,price, sum(price) as `sum` from sales s left join product p on s.product_id=p.product_id 
group by s.userid,product_id order by s.userid)points)final_p group by userid;

-- now calculating for which product most points have been given till now.
-- Method 1:
Select product_name,sum(most.`product wise total points`) as product_wise_total_points_irrespective_of_user from 
(select *, if(product_name in ('p1','p3'),round(points.sum/5),round(sum/2)) as `product wise total points` from 
(Select s.userid,created_date,s.product_id,product_name,price, sum(price) as `sum` from sales s left join product p on s.product_id=p.product_id 
group by s.userid,product_id order by s.userid)points)most group by product_name order by product_wise_total_points_irrespective_of_user desc limit 1;

-- Method 2:
select * from 
(select *, rank() over (order by product_wise_total_points_irrespective_of_user desc)  as rnk from
(Select product_name,sum(most.`product wise total points`) as product_wise_total_points_irrespective_of_user from 
(select *, if(product_name in ('p1','p3'),round(points.sum/5),round(sum/2)) as `product wise total points` from 
(Select s.userid,created_date,s.product_id,product_name,price, sum(price) as `sum` from sales s left join product p on s.product_id=p.product_id 
group by s.userid,product_id order by s.userid)points)most group by product_name)fin)ennd where rnk=1;

/* 10. In the first one year after a customer joins the gold program (including their join date) irrespective of what the customer has purchased
they earn 5 zomato points for every 10 rs spend who earned more 1 or 3 and what was their points earnings in their first year? */

Select *, rank() over (order by points desc) as rnk from 
(Select s.userid,created_date,s.product_id,gold_signup_date,product_name, price, round(price/2) as points   
from sales s right join goldusers_signup g 
on s.userid=g.userid and s.created_date>=g.gold_signup_date and s.created_date<=date_add(g.gold_signup_date, interval 1 year)
left join product p on s.product_id=p.product_id)per;

-- 11. rank all the transaction of the customer.
Select *, rank() over(partition by userid order by created_date) as rnk  from sales;

-- 12. rank all the transactions for each member whenever they are a zomato gold member for every non gold member transaction mark as na
Select userid,created_date,product_id, gold_signup_date,if(rnk=0,"na",rnk) as `rank` from 
(Select *, if(gold_signup_date is null,0,rank() over(partition by userid order by created_date desc)) as rnk from
(Select s.userid,created_date,product_id,gold_signup_date from sales s left join goldusers_signup g on s.userid=g.userid and s.created_date>=g.gold_signup_date)grp)grouped;













