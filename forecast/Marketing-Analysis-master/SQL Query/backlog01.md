## REPLACE & Global

```sql
regexp_replace(address, '\d', '!', 'g') as address
# The g means Global, and causes the replace call to replace all matches, not just the first one.
```
remove all numbers in the address column and replace with '!'


```sql
CREATE FUNCTiON increment(integer) RETURNS integer
AS 'select $1 + 1'
LANGUAGE SQL
```
[sql documentation](https://www.postgresql.org/docs/9.1/static/sql-createfunction.html)

Create a basic Increment function which Increments on the age field of the peoples table. The function should be called increment, it needs to take 1 integer and increment that number by 1.


## NULLIF() + COALESCE() 
[A handy but little-known SQL function: NULLIF()](http://weblogs.sqlteam.com/jeffs/archive/2007/09/27/sql-nullif-function.aspx)
```sql
SELECT id,
coalesce(nullif(name,''), '[product name not found]') as name,
price, 
coalesce(nullif(card_name,''), '[card name not found]') as card_name,
card_number, 
transaction_date
FROM eusales 
where price > 50 and price is not null
limit 100;
```

## FILTER + WHERE
```sql 
SELECT
  EXTRACT(MONTH FROM payment_date)        AS month,
  COUNT(*)                                AS total_count,
  SUM(amount)                             AS total_amount,
  COUNT(*)    FILTER (WHERE staff_id = 1) AS mike_count,
  SUM(amount) FILTER (WHERE staff_id = 1) AS mike_amount,
  COUNT(*)    FILTER (WHERE staff_id = 2) AS jon_count,
  SUM(amount) FILTER (WHERE staff_id = 2) AS jon_amount
FROM payment
GROUP BY month
ORDER BY month;
``` 

## Multiple where condition
```sql
Select name,country from travelers where country not in ('Canada','Mexico','USA')
```
where country not in ('Canada','Mexico','USA') <- cleaner

## Who is the main key?  
(sales should be
```sql
SELECT 
  to_date(to_char(s.transaction_date, 'YYYY-MM-DD'), 'YYYY-MM-DD') as day,
  d.name as department,
  COUNT(s.id) as sale_count
  FROM department d
    JOIN sale s on d.id = s.id
  group by day, d.name
  order by day asc;
```

## Cumulative Sum
```sql
select DATE(created_at) as date,
       count(created_at) as count,
       CAST(sum(count(created_at)) over (order by DATE(created_at) ) as integer) as total
from posts
group by date
order by date;
# ref: http://www.silota.com/docs/recipes/sql-running-total.html

## or 

SELECT date,
       count,
       cast(sum(count) OVER (ORDER BY date) as smallint) AS total 
FROM
(
SELECT created_at::date as date, count(id)
FROM posts 
GROUP BY 1 
ORDER BY 1
) t
ORDER BY 1

```


## convert from string to date
```sql
1. date_trunc('day', created_at) as day
2. created_at::DATE "day", description
3. created_at::timestamp::date as day
4. to_char(created_at, 'YYYY-MM-DD')::date as day
5. date(e.created_at) as day
6. cast(created_at as DATE) as day
7. to_date(to_char(created_at,'YYYY-MM-DD'),'YYYY-MM-DD') as day

```


## Rank over //  COALESCE + NULLIF
```sql
SELECT RANK() OVER (ORDER BY SUM(points) DESC),
  COALESCE(NULLIF(clan,''), '[no clan specified]') AS clan,
  SUM(points) AS total_points,
  COUNT(*) AS total_people
FROM people 
GROUP BY clan
ORDER BY total_points DESC

## or ##

select 
  row_number() over (order by sum(points) desc) "rank",
  CASE WHEN clan = '' THEN '[no clan specified]' else clan END "clan", 
  sum(points) "total_points", 
  count(*) "total_people" 
from 
  people 
group by 
  clan 
order by 
  sum(points) desc;
  
## use "WITH"

with clans as(
  select
    coalesce(nullif(clan,''),'[no clan specified]') clan,
    sum(points) total_points,
    count(*) total_people
  from people
  group by clan
)
  
select
  rank() over (order by total_points desc) "rank",
  clan,
  total_points,
  total_people
from clans

```


## LATERAL Subqueries
[More like a correlated subquery](https://stackoverflow.com/questions/28550679/what-is-the-difference-between-lateral-and-a-subquery-in-postgresql)
a function or subquery to the right of a LATERAL join typically has to be evaluated many times - once for each row left of the LATERAL join - just like a correlated subquery - while a plain subquery is evaluated once only.

```sql
select cat.id as "category_id", category, title, pos.views, pos.id as "post_id"
from
(select c.id, category
from categories c
order by category asc
) cat
 LEFT JOIN LATERAL
(
select p.category_id, p.title, p.views, p.id
from posts p
where p.category_id = cat.id
order by p.views desc 
Limit 2
)pos ON TRUE
;
```

### SELECTING with multiple WHERE conditions on same column

```sql
WITH a as (SELECT film_id
    FROM film_actor
   WHERE actor_id IN (105, 122)
GROUP BY film_id
  HAVING COUNT(actor_id) = 2)
  
Select title from film inner join a on a.film_id = film.film_id
```
https://stackoverflow.com/questions/4047484/selecting-with-multiple-where-conditions-on-same-column
```sql
SELECT f.title 
  FROM film f 
  INNER JOIN film_actor a ON f.film_id = a.film_id
  INNER JOIN film_actor b ON f.film_id = b.film_id
  WHERE a.actor_id = 105 AND b.actor_id = 122
  ORDER BY title;
```


