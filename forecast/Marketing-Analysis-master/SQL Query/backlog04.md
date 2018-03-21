```sql

SELECT when_happened, visits_count

FROM (
      SELECT v1.when_happened, count(v2.entry_time) as visits_count
      
      FROM (
            SELECT DISTINCT entry_time as when_happened FROM visits
            ) v1
            
      JOIN visits v2
      on v2.entry_time<= v1.when_happened and v2.exit_time > v1.when_happened
      
      group by v1.when_happened
      
      ) A
ORDER BY visits_count desc, when_happened
LIMIT 1
```

