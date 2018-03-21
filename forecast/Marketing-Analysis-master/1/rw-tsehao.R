library(readr)
top_donators_lifetime <- read_csv("~/Documents/MSc/Elective/Marketing Analysis/assignment 01/top donators lifetime.csv")
library(dplyr)
library(RODBC)
library(ggplot2)
library(scales)
library(plyr)
library(tidyr)
library(ggrepel)

# Connect to MySQL (use your own credentials)
db = odbcConnect("odd", uid="root", pwd="77#481122bB?")
sqlQuery(db, "USE charity")



###80:20 rule: who are TOP DONORS####


# transform
e <- arrange(top_donators_lifetime, desc(SumAmount)) %>%
  mutate(
    cumsum = cumsum(SumAmount),
    freq = round(SumAmount / sum(SumAmount), 10),
    cum_freq = cumsum(freq),
    seq = round((seq(1, 18945) / 18945)*100,4)
  )

# plot
ggplot(data=e, aes(x=seq, y=cum_freq*100, SumAmount, colour = SumAmount, group=1)) +
  geom_line(size=3.5) +
  xlab("% of donators (ranking by individual sum & top-down)") +
  ylab("% of contribution") +
  scale_y_continuous(breaks=c(80), labels=c("80%")) +
  scale_x_continuous(breaks=c(20.1161), labels=c("20.1161%"))


# --> 80$ falls at ranking#3811, so start by 3800 donors as TOP LIST



## Amount of regular donations by year among TOP DONORS ##

money_by_year_DO=sqlQuery(db,
                          "SELECT YEAR(ActDate) as 'year',
                          SUM(Amount) as 'sum_do'
                          FROM prime
                          WHERE ActType='DO'
                          GROUP BY 1
                          ORDER BY 1")

#by years, among top donors (3800 people)
ggplot(money_by_year_DO,aes(x=factor(year),y=sum_do))+
  geom_bar(stat='identity',fill='orange')+
  labs(x='Year')+
  geom_text(aes(label=paste(format(round(sum_do/1000),0), "k")),
            color='black',size=3,vjust=-0.5)+
  scale_y_continuous(name='Amount of regular donations',labels=comma)


## Seasonality: Money collected by month ############

money_by_month=sqlQuery(db,
                        "SELECT year(ActDate) as 'year',
                        month(ActDate) as'month',
                        sum(Amount) as 'sum_amount'
                        FROM prime
                        GROUP BY 1,2
                        ORDER BY 1")

ggplot(money_by_month,
       aes(x=factor(month),
           y=sum_amount,color=factor(year),
           group=factor(year),fill=factor(year))) + 
  geom_line()+
  geom_point()+
  labs(x='Month',y='Amount of donations')+
  scale_y_continuous(name='Amount of donations',labels = comma)

# Follow the same seasonality, even in 2011 abnormal peak in Sep

#### Donations by year and by typ: Contribution on type ##


num_donations_by_year=sqlQuery(db,
                               "SELECT YEAR(ActDate) as 'year', 
                               ActType as 'type',
                               COUNT(ContactId) as 'num_donations' 
                               FROM acts
                               GROUP BY 1,2
                               ORDER BY 1")

num_donations_by_year <- 
  ddply(num_donations_by_year,"year",
        transform,
        pc_donations=round(num_donations/sum(num_donations)*100))
col=c('orange','darkred')
ggplot(num_donations_by_year,
      aes(x=factor(year),y=num_donations,fill=type))+
  geom_bar(stat='identity',position = 'stack')+
  labs(x='Year')+
  geom_text(aes(label=paste(format(pc_donations,0), "%")),
            color='black',size=3,
            vjust=-0.5,position = position_stack())+
  scale_y_continuous(name='Count of donations',labels = comma)+
  scale_fill_manual(values=col)



