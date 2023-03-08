-- Script to create the Product table and load data into it.

DROP TABLE product;
CREATE TABLE product
( 
    product_category varchar(255),
    brand varchar(255),
    product_name varchar(255),
    price int
);

INSERT INTO product VALUES
('Phone', 'Apple', 'iPhone 12 Pro Max', 1300),
('Phone', 'Apple', 'iPhone 12 Pro', 1100),
('Phone', 'Apple', 'iPhone 12', 1000),
('Phone', 'Samsung', 'Galaxy Z Fold 3', 1800),
('Phone', 'Samsung', 'Galaxy Z Flip 3', 1000),
('Phone', 'Samsung', 'Galaxy Note 20', 1200),
('Phone', 'Samsung', 'Galaxy S21', 1000),
('Phone', 'OnePlus', 'OnePlus Nord', 300),
('Phone', 'OnePlus', 'OnePlus 9', 800),
('Phone', 'Google', 'Pixel 5', 600),
('Laptop', 'Apple', 'MacBook Pro 13', 2000),
('Laptop', 'Apple', 'MacBook Air', 1200),
('Laptop', 'Microsoft', 'Surface Laptop 4', 2100),
('Laptop', 'Dell', 'XPS 13', 2000),
('Laptop', 'Dell', 'XPS 15', 2300),
('Laptop', 'Dell', 'XPS 17', 2500),
('Earphone', 'Apple', 'AirPods Pro', 280),
('Earphone', 'Samsung', 'Galaxy Buds Pro', 220),
('Earphone', 'Samsung', 'Galaxy Buds Live', 170),
('Earphone', 'Sony', 'WF-1000XM4', 250),
('Headphone', 'Sony', 'WH-1000XM4', 400),
('Headphone', 'Apple', 'AirPods Max', 550),
('Headphone', 'Microsoft', 'Surface Headphones 2', 250),
('Smartwatch', 'Apple', 'Apple Watch Series 6', 1000),
('Smartwatch', 'Apple', 'Apple Watch SE', 400),
('Smartwatch', 'Samsung', 'Galaxy Watch 4', 600),
('Smartwatch', 'OnePlus', 'OnePlus Watch', 220);
COMMIT;




-- All the SQL Queries written during the video

select * from product;


-- FIRST_VALUE 
-- Write query to display the most expensive product under each category (corresponding to each record)
--first value selects the first value in each window - therefore the most expensive here as we are ordering window by price desc
--partitioning by category, as we want the most expensive value per category
--I added the second use of first_value to also display most expensive price in another column
select *,
    first_value(product_name) over(partition by product_category order by price desc) as most_exp_product, 
    first_value(price) over(partition by product_category order by price desc) as most_exp_price
from product;



-- LAST_VALUE 
-- Write query to display the least expensive product under each category (corresponding to each record)
--first value query is same logic as above
--last value grabs the last value in order by price desc - need to undo default frame clause for this to work
-- a frame is a subset of a partition
--can use range or row - if you use row, looks at exact current row, even with duplicates. if you use range, will consider last row among the duplicates
select *,
first_value(product_name) 
    over(partition by product_category order by price desc) 
    as most_exp_product,
last_value(product_name) 
    over(partition by product_category order by price desc
    --this is the frame clause
    --range tells what set of rows to consider
    --default is: range between unbounded preceding and current row
    --default frame would only be considering first row when its evaluating first row, first and second row when evaluating seocnd row, etc
    --the frame below tells the query to consider all the rows in the partition
    --can also specify number of rows preceding/following i.e. 2 rows preceding and 2 rows following
        range between unbounded preceding and unbounded following) 
    as least_exp_product    
from product
--just like any other query, can specify values using a WHERE
WHERE product_category ='Phone';



-- Alternate way to write SQL query using Window functions
-- more efficient way to write multiple window query when using the same window for each
select *,
first_value(product_name) over w as most_exp_product,
last_value(product_name) over w as least_exp_product    
from product
WHERE product_category ='Phone'
window w as (partition by product_category order by price desc
            range between unbounded preceding and unbounded following);
            

            
-- NTH_VALUE 
-- Write query to display the Second most expensive product under each category.
-- nth value has exact same logic as first/last, but provide it with a position arguement
select *,
first_value(product_name) over w as most_exp_product,
last_value(product_name) over w as least_exp_product,
nth_value(product_name, 2) over w as second_most_exp_product
from product
window w as (partition by product_category order by price desc
            range between unbounded preceding and unbounded following);



-- NTILE
-- Write a query to segregate all the expensive phones, mid range phones and the cheaper phones.
-- think of this as splitting each window into buckets - sql will try to split as best as possible
select x.product_name, 
case when x.buckets = 1 then 'Expensive Phones'
     when x.buckets = 2 then 'Mid Range Phones'
     when x.buckets = 3 then 'Cheaper Phones' END as Phone_Category
from (
    --this inner query will return the table with buckets as 1, 2, 3, split as per the tiling requirement
    select *,
    --no need for partition here, as we are already only selecting phones with where clause
    -- creates 3 buckets
    ntile(3) over (order by price desc) as buckets
    from product
    where product_category = 'Phone') as x;




-- CUME_DIST (cumulative distribution) ; 
/*  Formula = Current Row no (or Row No with value same as current row) / Total no of rows */

-- Query to fetch all products which are constituting the first 30% 
-- of the data in products table based on price.
-- so its showing that at first record has 3.7% of total price, at second record 7.41% of total price (cumulative of first and second) and so on
-- eventually the last row in whole table will show 100%
-- think of a question like - query the products with lowest 20% sales or query sales reps representing the top 50% of MRR
select product_name, cume_distribution ,cume_dist_percetage
from (
    select *,
    --cumulative distribution as decimal
    cume_dist() over (order by price desc) as cume_distribution,
    --cumulative distribution rounded and shown as percentage
    round(cume_dist() over (order by price desc)::numeric * 100,2)||'%' as cume_dist_percetage
    from product) x
where x.cume_distribution <= 0.3;




-- PERCENT_RANK (relative rank of the current row / Percentage Ranking)
/* Formula = Current Row No - 1 / Total no of rows - 1 */

-- Query to identify how much percentage more expensive is "Galaxy Z Fold 3" when compared to all products.
-- So by calculating its percentage rank, and ordering, we can know where a product falls in the percentile rank
-- think of questions like - what percentile rank for revenue does our recruitment product fall compared to all products
select product_name, per
from (
    select *,
    percent_rank() over(order by price) ,
    round(percent_rank() over(order by price)::numeric * 100, 2) as per
    from product) x
where x.product_name='Galaxy Z Fold 3';

-- for results of this query - its showing that Galaxy Z fold 3 is more expensive than 80.77% of our products

