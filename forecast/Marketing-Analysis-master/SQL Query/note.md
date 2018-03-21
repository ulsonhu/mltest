
### WHERE

Common operators used with the WHERE clause are:
* = equals
* != not equals
* \> greater than
* \< less than
* \>= greater than or equal to
* \<= less than or equal to

### LIKE
* _ substitute any individual character here without breaking the pattern. 
* % matches zero or more missing letters in the pattern.
  * A% matches all movies with names that begin with "A"
  * %a matches all movies that end with "a

### BETWEEN 
filter the result set within a certain range. (numbers, text or dates)

### ORDER
* DESC descending order 
* ASC ascending order

### COUNT
* \* where the column is not NULL

***

### Foreign Key
a column that contains the primary key of another table in the database.

* We use foreign keys and primary keys to connect rows in two different tables
* do not need to be unique and can be NULL.

Merge the rows, called a join.

Merge the columns, called a union.

#### (Cross Join)  
* table_name.column_name
#### (Inner) JOIN
* JOIN table_name ON 
* table_name.primary_key = table_name.primary_key
#### LEFT Outer JOIN
left table is the main source, and right table give supplimentary info (if matches) or NULL values (if not matches)

#### UNION
```sql
SELECT column_name(s) FROM table1
UNION
SELECT column_name(s) FROM table2;
```
#### Union All
allow duplicate values - 

#### Intersect
combine two SELECT statements, but returns rows only from the first SELECT statement that are identical to a row in the second SELECT statement

#### EXCEPT 
returns distinct rows from the first SELECT statement that aren’t output by the second SELECT statement.


***

### AS = Aliases

### COUNT(CASE WHEN)
 look at an entire result set, but want to implement conditions on certain aggregates.
```sql
SELECT    state, 
    COUNT(CASE WHEN elevation >= 2000 THEN 1 ELSE NULL END) as count_high_elevation_aiports 
FROM airports 
GROUP BY state;
```


#### CAST
```sql 
SELECT CAST(number1 AS REAL) / number3;: 
```
Returns the result as a real number by casting one of the values as a real number, rather than an integer.


#### Concatenate
```sql
SELECT string1 || ' ' || string2;
```
