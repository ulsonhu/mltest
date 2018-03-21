
# Basic Data Treatement
New variables:

### gender (from Prefix)
- compaign (only those whose average mount > 5 euros, and solicited in the past, return an investment return rate as (AVG(a.amount) / 5) )
- Since PA and DO have different characteristics among donators, I make the predictions individually. Here I have 3 Thresholds

### 70%
Grab the IDs which are predicted having more than 70% making the donations (probibility x amount x 1.43 = score)
- Prediction (based on amount times probabilty) > 5 euros
- People who makes both PA and DO, since they joinedPA group, if they are regarded as possible candidates in PA donators, they are included in my solicitation list.
- People who makes donations in DO that average amount is larger than 20 euros
