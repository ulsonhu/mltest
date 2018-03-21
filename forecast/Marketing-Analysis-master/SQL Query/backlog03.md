### Calculating Month-Over-Month Percentage Growth Rate
The resulting set should be ordered chronologically by date.

* date - (DATE) a first date of the month
* count - (INT) a number of posts in a given month
* percent_growth - (TEXT) a month-over-month growth rate expressed in percents
* percent growth rate can be negative
* percent growth rate should be rounded to one digit after the decimal point and immediately followed by a percent symbol "%". See the desired output below for the reference.


```sql 
SELECT cast(month||''||'-01' as DATE) as date, 
       cast (num as int4) as count, 
       Round((num - cast(lag(num) over (ORDER BY month) AS numeric(10,1))) / 
       cast(lag(num) over (ORDER BY month) AS numeric(10,1))*100,1)||''||'%' as percent_growth
FROM
(
SELECT to_char(date, 'YYYY-MM') as month,
       SUM(count) as num
FROM
(
SELECT cast(created_at as DATE) as date, count(*)
FROM posts 
GROUP BY 1 
ORDER BY 1
) t
GROUP BY month
ORDER BY month) m
ORDER BY date

```

***
[louisrivers](https://www.codewars.com/users/louisrivers), [Ittovh](https://www.codewars.com/users/Ittovh)

```sql
SELECT 
  date_trunc('month', created_at)::date AS date,
  COUNT(*),
  ROUND((COUNT(*)*1.00/lag(COUNT(*), 1) OVER (ORDER BY date_trunc('month', created_at)::date)-1)*100,1)||'%' AS percent_growth
FROM posts
GROUP BY date
ORDER BY date
```

***
[techalchemy](https://www.codewars.com/users/techalchemy)

```sql
WITH month_counts as (
  SELECT
    date_trunc('MONTH', created_at)::date as date,
    count(*)
  from
    posts
  group by
    date_trunc('MONTH', created_at)
)

SELECT
  m.date,
  m.count,
  CASE WHEN prior_month.count IS NULL then NULL
       ELSE round(((m.count - prior_month.count) * 100)::numeric / prior_month.count, 1)::text || '%' 
   END as percent_growth
FROM
  month_counts m
  LEFT JOIN month_counts prior_month ON (m.date - '1 Month'::interval)::DATE = prior_month.date
order by
  m.date asc
```

