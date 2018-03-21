## non-correlated subquery

```sql
SELECT * 
FROM flights 
WHERE origin in (
    SELECT code 
    FROM airports 
    WHERE elevation > 2000);
```
* take the result set of the inner query
* use it to filter on the flights table, to find the flight detail that meets the elevation criteria


## the average total distance flown by day of week and month
```sql
SELECT a.dep_month,
       a.dep_day_of_week,
       AVG(a.flight_distance) AS average_distance 
  FROM (
        SELECT dep_month,
               dep_day_of_week,
               dep_date,
               SUM(distance) AS flight_distance
          FROM flights
         GROUP BY 1,2,3
       ) a
 GROUP BY 1,2
 ORDER BY 1,2;
 ```
* inner query: provides the sum of distance by day
* outer query: uses the inner query’s result set to compute the average by day of week of a given month.


## correlated subquery
(the subquery can not be run independently of the outer query)


(The order of operations is important in a correlated subquery:
* A row is processed in the outer query.
* Then, for that particular row in the outer query, the subquery is executed.
```sql 
SELECT id
FROM flights AS f
WHERE distance > (
 SELECT AVG(distance)
 FROM flights
 WHERE carrier = f.carrier);
``` 
