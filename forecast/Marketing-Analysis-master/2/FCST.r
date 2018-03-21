
# SQL 
sqlQuery(db, "USE charity2")

query = "SELECT a.contact_id,
         DATEDIFF(20160119, MAX(a.act_date)) / 365 AS 'recency',
                COUNT(a.amount) AS 'frequency',
                IF(COUNT(a.amount) / (j.CampFreq) IS NULL, 0, 
                IF(AVG(a.amount) < 5 , 0 , (AVG(a.amount) / 5)) ) AS 'Campaign', 
                AVG(a.amount) AS 'avgamount',
                MAX(a.amount) AS 'maxamount',
                CASE WHEN q.prefix = 'MR' THEN '1'
                     WHEN q.prefix = 'MME' THEN '0'
                     WHEN q.prefix = 'MMME' THEN '0'
                     WHEN q.prefix = 'NA' THEN '0'
                     WHEN q.prefix = 'ME' THEN '0'
                     WHEN q.prefix = 'AU' THEN '0'
                     ELSE 1 END AS 'Gender',

                IF(c.counter IS NULL, 0, 1) AS 'loyal',
                c.targetamount AS 'targetamount'
         FROM acts a
         LEFT JOIN (SELECT contact_id, 
                    COUNT(amount) AS counter, 
                    AVG(amount) AS targetamount
                    FROM acts
                    WHERE (act_date >= 20160119) AND
                    (act_date <  20170119) AND
                    (act_type_id = 'DO')
                    GROUP BY contact_id) AS c

         ON c.contact_id = a.contact_id
         RIGHT JOIN (SELECT id,
                            prefix_id AS prefix
                     FROM contacts
                     WHERE tag_int_1 = 0) as q
         on a.contact_id = q.id
         LEFT JOIN (SELECT contact_id,
                    COUNT(action_date) AS 'CampFreq'
                    FROM actions
                    GROUP BY contact_id) AS j
         on a.contact_id = j.contact_id
         WHERE  (a.act_type_id = 'DO') AND (a.act_date < 20160118)
         GROUP BY 1;"

data = sqlQuery(db, query)

# Extract prediction data from database

query = "SELECT a.contact_id,
         DATEDIFF(20160118, MAX(a.act_date)) / 365 AS 'recency',
         COUNT(a.amount) AS 'frequency',
         IF(COUNT(a.amount) / (j.CampFreq) IS NULL, 0, 
         IF(AVG(a.amount) < 5 , 0 , (AVG(a.amount) / 5) )) AS 'Campaign', 
         AVG(a.amount) AS 'avgamount',
         CASE WHEN q.prefix = 'MR' THEN '1'
              WHEN q.prefix = 'MME' THEN '0'
              WHEN q.prefix = 'MMME' THEN '0' 
              WHEN q.prefix = 'NA' THEN '0'
              WHEN q.prefix = 'ME' THEN '0'
              WHEN q.prefix = 'AU' THEN '0'
              ELSE 1 END AS 'Gender',
              MAX(a.amount) AS 'maxamount'
         FROM acts a
         RIGHT JOIN (SELECT id,
                     prefix_id AS prefix
                     FROM contacts
                     WHERE tag_int_1 = 1) as q
         on a.contact_id = q.id
         LEFT JOIN (SELECT contact_id,
                    COUNT(action_date) AS 'CampFreq'
                    FROM actions
                    GROUP BY contact_id) AS j

         on a.contact_id = j.contact_id
         WHERE (a.act_type_id = 'DO')
         GROUP BY 1"

newdata = sqlQuery(db, query)

# Show data
print(head(data))

# In-sample, probability model
library(nnet)
data$Campaign[data$Campaign < 1] <- 1
newdata$Campaign[newdata$Campaign < 1] <- 1
newdata$recency[newdata$recency == 0] <- 1


# In-sample, donation amount model

# Note that the amount model only applies to a subset of donors...
z = which(!is.na(data$targetamount))
print(head(data[z, ]))
amount.model = lm(formula = log(targetamount) ~ log(avgamount) + 
                    log(maxamount) + Gender + Campaign,
                  data = data[z, ])

formula = "loyal ~ (recency * frequency) + log(recency) + 
           log(frequency) + log(avgamount) + Gender + log(Campaign)"
prob.model = multinom(formula, data = data)

# out$probs  = predict(object = prob.model, newdata = newdata, type = "probs")
out$amount = exp(predict(object = amount.model, newdata = newdata))
out$probss  = predict(object = prob.model, newdata = newdata, type = "probs")
out$score  = out$probss * out$amount * 1.43 # take probablity 70% to be targets
out$loyal = as.numeric(out$score > 5)

# Show results
print(head(out))

# Who is likely to be worth more than 5 EUR?
z = which(out$score > 5)
print(length(z))




# Evaluation of DO prediction
probs  = out$probss



# Rank order target variable in decreasing order of (predicted) probability
target = out$loyal[order(probs, decreasing=TRUE)] / length(which(out$loyal == 1))
gainchart = c(0, cumsum(target))

# Create a random selection sequence
random = seq(0, to = 1, length.out = length(out$loyal))

# Create the "perfect" selection sequence
# all the 1s will be on top, and followed by zero
perfect = out$loyal[order(out$loyal, decreasing=TRUE)] / length(which(out$loyal == 1))
perfect = c(0, cumsum(perfect))

# Plot gain chart, add random line
plot(gainchart)
lines(random)
lines(perfect)

# Compute 1%, 5%, 10%, and 25% lift and improvement
# from two vectors: gain chart and perfect
q = c(0.01, 0.05, 0.10, 0.25)
x = quantile(gainchart, probs = q, na.rm = TRUE)
z = quantile(perfect,   probs = q, na.rm = TRUE)

print("Hit rate:")
print(x)
print("Lift:")
print(x/q)
print("Improvement:")
print((x-q)/(z-q))


# Close the connection
odbcClose(db)




# Query for PA customer

sqlQuery(db, "USE charity2")

# Extract calibration data from database
query = "SELECT a.contact_id,
         DATEDIFF(20160119, MAX(a.act_date)) / 365 AS 'recency',
         COUNT(a.amount) AS 'frequency',
         IF(COUNT(a.amount) / (j.CampFreq) IS NULL, 0, 
         IF(AVG(a.amount) < 5 , 0 , (AVG(a.amount) / 5) ) ) AS 'Campaign',
         AVG(a.amount) AS 'avgamount',
         MAX(a.amount) AS 'maxamount',

         CASE WHEN q.prefix = 'MR' THEN '1'
              WHEN q.prefix = 'MME' THEN '0'
              WHEN q.prefix = 'MMME' THEN '0'
              WHEN q.prefix = 'NA' THEN '0'
              WHEN q.prefix = 'ME' THEN '0'
              WHEN q.prefix = 'AU' THEN '0'
         ELSE 1 END AS 'Gender',

         IF(c.counter IS NULL, 0, 1) AS 'loyal',
         c.targetamount AS 'targetamount'

         FROM acts a
         LEFT JOIN (SELECT contact_id, 
                    COUNT(amount) AS counter, 
                    AVG(amount) AS targetamount
                    FROM acts
                    WHERE (act_date >= 20160119) AND
                          (act_date <  20170119) AND
                          (act_type_id = 'PA')
                    GROUP BY contact_id) AS c

         ON c.contact_id = a.contact_id
         RIGHT JOIN (SELECT id,
                            prefix_id AS prefix
                     FROM contacts
                     WHERE tag_int_1 = 0) as q

         on a.contact_id = q.id
         LEFT JOIN (SELECT contact_id,
                    COUNT(action_date) AS 'CampFreq'
                    FROM actions
                    GROUP BY contact_id) AS j
         on a.contact_id = j.contact_id
         WHERE  (a.act_type_id = 'PA') 
                AND (a.act_date < 20160118)
         GROUP BY 1;"
data = sqlQuery(db, query)

# Show data
print(head(data))


# Extract prediction data from database

query = " SELECT a.contact_id,
          DATEDIFF(20160118, MAX(a.act_date)) / 365 AS 'recency',
          COUNT(a.amount) AS 'frequency',
          IF(COUNT(a.amount) / (j.CampFreq) IS NULL, 0, 
          IF(AVG(a.amount) < 5 , 0 , (AVG(a.amount) / 5) ) ) AS 'Campaign', 
          AVG(a.amount) AS 'avgamount',

          CASE WHEN q.prefix = 'MR' THEN '1'
              WHEN q.prefix = 'MME' THEN '0'
              WHEN q.prefix = 'MMME' THEN '0'
              WHEN q.prefix = 'NA' THEN '0'
              WHEN q.prefix = 'ME' THEN '0'
              WHEN q.prefix = 'AU' THEN '0'
              ELSE 1 END AS 'Gender',
          MAX(a.amount) AS 'maxamount'

          FROM acts a
          RIGHT JOIN (SELECT id,
                      prefix_id AS prefix
                      FROM contacts
                      WHERE tag_int_1 = 1) as q

          on a.contact_id = q.id
          LEFT JOIN (SELECT contact_id,
                      COUNT(action_date) AS 'CampFreq'
                      FROM actions
                      GROUP BY contact_id) AS j
          on a.contact_id = j.contact_id
          WHERE (a.act_type_id = 'PA')
          GROUP BY 1"
newdata = sqlQuery(db, query)
print(head(newdata))

data$Campaign[data$Campaign < 1] <- 1
newdata$Campaign[newdata$Campaign < 1] <- 1
newdata$recency[newdata$recency == 0] <- 1

# In-sample, probability model
library(nnet)
prob.model = multinom(formula = loyal ~ (recency * frequency) 
                      + log(recency) + log(frequency) 
                      + log(avgamount) + Gender + log(Campaign),
                      data = data)

# In-sample, donation amount model

# Note that the amount model only applies to a subset of donors...
z = which(!is.na(data$targetamount))
print(head(data[z, ]))
amount.model = lm(formula = log(targetamount) ~ log(avgamount) + 
                  log(maxamount) + Gender + Campaign ,
                  data = data[z, ])

# Close the connection
odbcClose(db)


# Out-of-sample predictions
# Do NOT forget to re-transform "log(amount)" into "amount"
outpa = data.frame(contact_id = newdata$contact_id)
outpa$probs  = predict(object = prob.model, newdata = newdata, type = "probs")
outpa$amount = exp(predict(object = amount.model, newdata = newdata))
outpa$score  = outpa$probs * outpa$amount * 1.43 # take probablity 70% to be targets


# Show results
print(head(outpa))

# Who is likely to be worth more than 5 EUR?
z = which(outpa$score > 5)
print(length(z))
outpa$loyal = as.numeric(outpa$score > 5)



## combine the result and Add the 2nd & 3rd thresholds
res <- merge(out,outpa,by="contact_id" ,all = TRUE)

# out(DO) = x, outpa(PA) = y
res$loyal.y[is.na(res$loyal.y)] <- 0
res$loyal.x[is.na(res$loyal.x)] <- 0
res$Result <- rep(0, times = length(res$contact_id))


for (i in 1:length(res$contact_id)) {
  if (res$loyal.y[i] == 1){res$Result[i] = 1}
  else if (res$loyal.x[i] == 1 & res$loyal.y[i] == 0){res$Result[i] = 1}
  else {res$Result[i] = 0}
}


# no matter what happens, I will solicite people 
# predicted to give more than 20 euros
res$Result[res$amount.x > 20] <- 1
res$Result[order(res$contact_id, decreasing=FALSE)]
tableb <- cbind(res$contact_id, res$Result)
setwd("G:/")
write.table(tableb, file = "sub03.txt", sep = "\t",
            row.names = FALSE, col.names = FALSE)
            
            
## Submision Result
# Gross Margin: 891630 EUR
# Costs: 133225 EUR
# Net Margin: 758405 EUR
# You have used up all your attempts.
