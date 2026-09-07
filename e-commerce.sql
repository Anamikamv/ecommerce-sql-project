create database if not exists ecommerce_sql_project;

use ecommerce_sql_project;


-- =========================================================
-- 2. drop old tables if they exist
-- =========================================================

drop table if exists payments;
drop table if exists orders;
drop table if exists sellers;
drop table if exists products;
drop table if exists customers;


-- =========================================================
-- 3. create customers table
-- =========================================================

create table customers (
    customer_id int primary key,
    customer_name varchar(100) not null,
    city varchar(50),
    signup_date date,
    phone varchar(15)
);


-- =========================================================
-- 4. create products table
-- =========================================================

create table products (
    product_id int primary key,
    product_name varchar(100) not null,
    category varchar(50),
    price decimal(10,2)
);


-- =========================================================
-- 5. create sellers table
-- =========================================================

create table sellers (
    seller_id int primary key,
    seller_name varchar(100) not null,
    city varchar(50)
);


-- =========================================================
-- 6. create orders table
-- =========================================================

create table orders (
    order_id int primary key,
    customer_id int,
    product_id int,
    seller_id int,
    quantity int,
    order_date date,
    status varchar(20),

    foreign key (customer_id)
        references customers(customer_id),

    foreign key (product_id)
        references products(product_id),

    foreign key (seller_id)
        references sellers(seller_id)
);


-- =========================================================
-- 7. create payments table
-- =========================================================

create table payments (
    payment_id int primary key,
    order_id int,
    amount decimal(10,2),
    payment_type varchar(30),
    payment_status varchar(20),

    foreign key (order_id)
        references orders(order_id)
);


-- =========================================================
-- 8. check tables
-- =========================================================

show tables;


-- =========================================================
-- 9. check table structure
-- =========================================================

describe customers;
describe products;
describe sellers;
describe orders;
describe payments;


-- =========================================================
-- 10. after csv import - check record counts
-- =========================================================

select count(*) as total_customers
from customers;

select count(*) as total_products
from products;

select count(*) as total_sellers
from sellers;

select count(*) as total_orders
from orders;

select count(*) as total_payments
from payments;


-- =========================================================
-- beginner questions
-- =========================================================


-- q1. list all customers from kochi.

select *
from customers
where city = 'Kochi';


-- q2. show all orders placed in the last 30 days
-- of the available dataset.

select *
from orders
where order_date >=
(
    select max(order_date)
    from orders
) - interval 30 day;


-- q3. find the 10 most expensive products.

select *
from products
order by price desc
limit 10;


-- q4. list all orders with status 'delivered'.

select *
from orders
where status = 'Delivered';


-- q5. find customers who signed up in 2025.

select *
from customers
where year(signup_date) = 2025;


-- q6. display all products in electronics category.

select *
from products
where category = 'Electronics';


-- q7. show orders with quantity greater than 2.

select *
from orders
where quantity > 2;


-- q8. count total number of customers.

select count(*) as total_customers
from customers;


-- =========================================================
-- intermediate questions
-- =========================================================


-- q9. what is the total revenue generated?

select
    sum(amount) as total_revenue
from payments
where payment_status = 'Paid';


-- q10. which product category has sold the most units?

select
    p.category,
    sum(o.quantity) as units_sold
from orders o
join products p
    on o.product_id = p.product_id
where o.status <> 'Cancelled'
group by p.category
order by units_sold desc
limit 1;


-- q11. top 5 customers by total amount spent.

select
    c.customer_id,
    c.customer_name,
    sum(p.amount) as total_spent
from customers c
join orders o
    on c.customer_id = o.customer_id
join payments p
    on o.order_id = p.order_id
where p.payment_status = 'Paid'
group by
    c.customer_id,
    c.customer_name
order by total_spent desc
limit 5;


-- q12. sellers who generated more than 15000 revenue.

select
    s.seller_id,
    s.seller_name,
    sum(p.amount) as revenue
from sellers s
join orders o
    on s.seller_id = o.seller_id
join payments p
    on o.order_id = p.order_id
where p.payment_status = 'Paid'
group by
    s.seller_id,
    s.seller_name
having sum(p.amount) > 15000
order by revenue desc;


-- q13. what is the average order value?

select
    round(avg(amount), 2) as average_order_value
from payments
where payment_status = 'Paid';


-- q14. orders and average payment value by payment type.

select
    payment_type,
    count(*) as order_count,
    round(avg(amount), 2) as average_payment
from payments
group by payment_type
order by order_count desc;


-- q15. number of orders for each customer.

select
    c.customer_id,
    c.customer_name,
    count(o.order_id) as order_count
from customers c
left join orders o
    on c.customer_id = o.customer_id
group by
    c.customer_id,
    c.customer_name
order by order_count desc;


-- q16. revenue by month.

select
    date_format(o.order_date, '%Y-%m') as month,
    sum(p.amount) as monthly_revenue
from orders o
join payments p
    on o.order_id = p.order_id
where p.payment_status = 'Paid'
group by date_format(o.order_date, '%Y-%m')
order by month;


-- q17. best-selling product by units.

select
    p.product_id,
    p.product_name,
    sum(o.quantity) as units_sold
from products p
join orders o
    on p.product_id = o.product_id
where o.status <> 'Cancelled'
group by
    p.product_id,
    p.product_name
order by units_sold desc
limit 1;


-- q18. cities having more than 8 customers.

select
    city,
    count(*) as customer_count
from customers
group by city
having count(*) > 8
order by customer_count desc;


-- =========================================================
-- advanced questions
-- =========================================================


-- q19. rank products by revenue within each category.

with product_revenue as
(
    select
        p.product_id,
        p.product_name,
        p.category,
        sum(pay.amount) as revenue
    from products p
    join orders o
        on p.product_id = o.product_id
    join payments pay
        on o.order_id = pay.order_id
    where pay.payment_status = 'Paid'
    group by
        p.product_id,
        p.product_name,
        p.category
)

select
    *,
    dense_rank() over
    (
        partition by category
        order by revenue desc
    ) as category_rank
from product_revenue
order by
    category,
    category_rank;


-- q20. customers who spent more than average customer spend.

with customer_spend as
(
    select
        c.customer_id,
        c.customer_name,

        coalesce
        (
            sum
            (
                case
                    when p.payment_status = 'Paid'
                    then p.amount
                    else 0
                end
            ),
            0
        ) as total_spent

    from customers c

    left join orders o
        on c.customer_id = o.customer_id

    left join payments p
        on o.order_id = p.order_id

    group by
        c.customer_id,
        c.customer_name
)

select *
from customer_spend
where total_spent >
(
    select avg(total_spent)
    from customer_spend
)
order by total_spent desc;


-- q21. repeat customers with more than 2 orders.

select
    c.customer_id,
    c.customer_name,
    count(o.order_id) as order_count
from customers c
join orders o
    on c.customer_id = o.customer_id
group by
    c.customer_id,
    c.customer_name
having count(o.order_id) > 2
order by order_count desc;


-- q22. rank sellers by revenue.

with seller_revenue as
(
    select
        s.seller_id,
        s.seller_name,

        sum
        (
            case
                when p.payment_status = 'Paid'
                then p.amount
                else 0
            end
        ) as revenue

    from sellers s

    left join orders o
        on s.seller_id = o.seller_id

    left join payments p
        on o.order_id = p.order_id

    group by
        s.seller_id,
        s.seller_name
)

select
    *,
    rank() over
    (
        order by revenue desc
    ) as revenue_rank
from seller_revenue
order by revenue_rank;


-- q23. create monthly sales summary view.

drop view if exists monthly_sales_summary;

create view monthly_sales_summary as

select
    date_format(o.order_date, '%Y-%m') as month,
    count(o.order_id) as order_count,

    sum
    (
        case
            when p.payment_status = 'Paid'
            then p.amount
            else 0
        end
    ) as revenue

from orders o

join payments p
    on o.order_id = p.order_id

group by date_format(o.order_date, '%Y-%m');


-- display view

select *
from monthly_sales_summary
order by month;


-- q24. full order history of customers.

drop view if exists customer_order_history;

create view customer_order_history as

select
    c.customer_id,
    c.customer_name,
    c.city,

    o.order_id,
    o.order_date,
    o.status,

    pr.product_name,
    pr.category,
    o.quantity,

    s.seller_name,

    p.amount,
    p.payment_type,
    p.payment_status

from customers c

join orders o
    on c.customer_id = o.customer_id

join products pr
    on o.product_id = pr.product_id

join sellers s
    on o.seller_id = s.seller_id

join payments p
    on o.order_id = p.order_id;


-- display customer order history

select *
from customer_order_history
order by
    customer_id,
    order_date;


-- q25. find each customer's latest order.

with ranked_orders as
(
    select
        c.customer_id,
        c.customer_name,
        o.order_id,
        o.order_date,
        o.status,

        row_number() over
        (
            partition by c.customer_id
            order by
                o.order_date desc,
                o.order_id desc
        ) as rn

    from customers c

    join orders o
        on c.customer_id = o.customer_id
)

select *
from ranked_orders
where rn = 1
order by customer_id;


-- =========================================================
-- project completed
-- =========================================================