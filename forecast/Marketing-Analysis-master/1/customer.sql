
# Use a specific database
USE charity;

# Clean tables for the exercise
DROP TABLE top;
DROP TABLE prime;
DROP TABLE periods;
DROP TABLE segments;

# find the lifetime donation amount of each donator
SELECT c.ContactId,
	   c.FirstName,
       c.ZipCode,
       p.SumAmount
FROM contacts AS c
LEFT JOIN (SELECT ContactId, SUM(Amount) AS SumAmount, ActDate
		FROM acts
		GROUP bY ContactID) AS p  
ON c.ContactId = p.ContactId
WHERE p.SumAmount IS NOT NULL
GROUP BY c.ContactID
order by 6 DESC;


# take the top 3800 donors to generate a new contact list
SELECT c.sq,
	   c.ContactId,
	   c.prefix,
	   c.FirstName,
       c.ZipCode,
       p.SumAmount
FROM contacts AS c
LEFT JOIN (SELECT ContactId, SUM(Amount) AS SumAmount, ActDate
		FROM acts
		GROUP bY ContactID) AS p  
ON c.ContactId = p.ContactId
WHERE p.SumAmount IS NOT NULL
GROUP BY c.ContactID
order by 4 DESC
LIMIT 3800;



# Create a new table in SQL for put new top list
CREATE TABLE Top (
  Sq        INT UNSIGNED NOT NULL,
  ContactId INT UNSIGNED NOT NULL,
  Prefix    CHAR(10),
  FirstName CHAR(32),
  ZipCode   CHAR(5),
  Donation  INT UNSIGNED DEFAULT '0',
  PRIMARY KEY (Sq),
  KEY IdxContactId (ContactId)
  )
ENGINE = MyISAM;

# Load the txt file into the table

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 5.7/Uploads/top_3800.txt' 
INTO TABLE Top;



# acts among 3800 top people, lifetime
SELECT a.sq,
	   a.contactId,
       a.Amount,
	   a.ActDate,
       a.ActType,
       a.PaymentType,
       a.MessageId,
       p.Zipcode
FROM acts AS a
LEFT JOIN (SELECT *
		   FROM Top) AS p  
ON a.ContactId = p.ContactId
WHERE Zipcode IS NOT NULL;



# Create a new table in SQL for put new top list
CREATE TABLE prime (
  Sq        INT UNSIGNED NOT NULL,
  ContactId INT UNSIGNED NOT NULL,
  Amount      FLOAT DEFAULT '0',
  ActDate     DATE,
  ActType     CHAR(2),
  PaymentType CHAR(2),
  MessageId   CHAR(10),
  ZipCode   CHAR(5),
  PRIMARY KEY (Sq),
  KEY IdxContactId (ContactId),
  KEY IdxActDate   (ActDate)
  )
ENGINE = MyISAM;


# Load the txt file into the table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 5.7/Uploads/top_3800_acts.txt' 
INTO TABLE prime;



CREATE TABLE periods (
  PeriodId INTEGER NOT NULL,
  FirstDay DATE NOT NULL,
  LastDay DATE NOT NULL,
  PRIMARY KEY (PeriodId)
)
ENGINE = MyISAM;


# Define 11 periods
INSERT INTO periods
VALUES ( 0, 20121101, 20131031),
       ( 1, 20111101, 20121031),
       ( 2, 20101101, 20111031),
       ( 3, 20091101, 20101031),
       ( 4, 20081101, 20091031),
       ( 5, 20071101, 20081031),
       ( 6, 20061101, 20071031),
       ( 7, 20051101, 20061031),
       ( 8, 20041101, 20051031),
       ( 9, 20031101, 20041031),
       (10, 20021101, 20031031);


# Create a segment table
# It will store to which segment each donor belonged
# in each period
CREATE TABLE segments (
  Sq INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  ContactId INTEGER UNSIGNED NOT NULL,
  PeriodId INTEGER NOT NULL,
  Segment VARCHAR(6),
  PRIMARY KEY (Sq),
  INDEX IdxContactId(ContactId),
  INDEX IdxPeriodId(PeriodId)
)
ENGINE = MyISAM;

# This will create a placeholder for all
# contact-by-period possible combinations
INSERT INTO segments (ContactId, PeriodId)
SELECT a.ContactId, p.PeriodId
FROM prime a,
     periods p
GROUP BY 1, 2;


# Create the AUTO segment
UPDATE
  segments s,
  (SELECT ContactId, PeriodId
   FROM   prime a, periods p
   WHERE  (a.ActDate <= p.LastDay) AND
          (a.ActDate >= p.FirstDay) AND
          (a.ActType LIKE 'PA')) AS d
SET
  s.Segment = "AUTO"
WHERE
  (s.ContactId = d.ContactId) AND
  (s.PeriodId = d.PeriodId);


# Create the NEW segment
UPDATE
  segments s,
  (SELECT ContactId, PeriodId
   FROM periods p,
        (SELECT ContactId, MIN(ActDate) AS FirstAct
         FROM prime
         GROUP BY 1) AS f
   WHERE (f.FirstAct <= p.LastDay) AND
         (f.FirstAct >= p.FirstDay)) AS d
SET
  s.Segment = "NEW"
WHERE
  (s.ContactId = d.ContactId) AND
  (s.PeriodId = d.PeriodId) AND
  (s.Segment IS NULL);


# Create the ACTIVE/HYPER-ACTIVE segment
UPDATE
  segments s,
  (SELECT a.ContactId, 
		  PeriodId, 
          COUNT(a.AMOUNT) AS frequency
   FROM   prime a, periods p
   WHERE  (a.ActDate <= p.LastDay) AND
          (a.ActDate >= p.FirstDay) AND
          (a.ActType LIKE 'DO')
   GROUP BY 1, 2
   ) AS d
SET
  s.Segment = IF(frequency > 1, "HYPER", "ACTIVE")
WHERE
  (s.ContactId = d.ContactId) AND
  (s.PeriodId = d.PeriodId) AND
  (s.Segment IS NULL);



# Create the WARM segment
UPDATE
  segments s,
  (SELECT ContactId, PeriodId
   FROM   segments
   WHERE  (Segment LIKE "NEW")    OR
          (Segment LIKE "AUTO")   OR
          (Segment LIKE "BOTTOM") OR
          (Segment LIKE "TOP")) AS a
SET
  s.Segment = "WARM"
WHERE
  (s.ContactId = a.ContactId) AND
  (s.PeriodId = a.PeriodId - 1) AND
  (s.Segment IS NULL);


# Create the COLD segment
UPDATE
  segments s,
  (SELECT ContactId, PeriodId
   FROM   segments
   WHERE  Segment LIKE "WARM") AS a
SET
  s.Segment = "COLD"
WHERE
  (s.ContactId = a.ContactId) AND
  (s.PeriodId = a.PeriodId - 1) AND
  (s.Segment IS NULL);


# Create the LOST segment, multiple times
UPDATE
  segments s,
  (SELECT ContactId, PeriodId
   FROM   segments
   WHERE  (Segment LIKE "COLD") OR
          (Segment LIKE "LOST")) AS a
SET
  s.Segment = "LOST"
WHERE
  (s.ContactId = a.ContactId) AND
  (s.PeriodId = a.PeriodId - 1) AND
  (s.Segment IS NULL);


# Count segment members per period
SELECT PeriodId, Segment, COUNT(*)
FROM segments
GROUP BY 1, 2
ORDER BY 2, 1 DESC;


# the movement of the donors
SELECT old.Segment, new.Segment, COUNT(new.Segment)
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 1) AND
      (new.PeriodId = 0)
GROUP BY 1, 2
ORDER BY 1, 2;


# Report the financial contribution of each segment
SELECT
  s.Segment,
  COUNT(DISTINCT(s.ContactId)) AS 'numdonors',
  COUNT(a.Amount)              AS 'numdonations',
  CEILING(AVG(a.Amount))       AS 'avgamount',
  CEILING(SUM(a.Amount))       AS 'totalgenerosity'
FROM
  segments s,
  periods p,
  prime a
WHERE
  (s.ContactId = a.ContactId) AND
  (s.PeriodId = 10) AND #change by years
  (p.PeriodId = 10) AND #change by years
  (a.ActDate >= p.FirstDay) AND
  (a.ActDate <= p.LastDay)
GROUP BY 1
ORDER BY totalgenerosity DESC;

# take one specific year, to see when they starts and when they left
# did not use this code for report
SELECT c.ContactId,
	   c.FirstName,
       CASE WHEN 99999 = c.ZipCode THEN NULL
			ELSE c.ZipCode END AS 'Postal Code',
       ouuu.SumAmount As Year_SUM, 
       CASE WHEN 2003 = MAX(YEAR(zz.ActDate)) THEN 'LEAVE at the same year'
			WHEN MAX(YEAR(zz.ActDate)) - 2003 < 3 THEN 'LEAVE within 2 years' 
       ELSE MAX(YEAR(zz.ActDate)) END AS 'Last Donation',
	   CASE WHEN 2003 = MIN(YEAR(zz.ActDate)) THEN 'First time donation'
       ELSE MIN(YEAR(zz.ActDate)) END AS Historical  
FROM contacts AS c 
LEFT JOIN (SELECT ac.ContactId, 
				  ac.ActDate,
                  p.SumAmount
		   FROM acts AS ac
		   JOIN (SELECT ContactId, 
			     SUM(Amount) AS SumAmount
			     FROM acts
			     WHERE YEAR(ActDate) = 2003
			     GROUP bY 1
                ) AS p  
		ON ac.ContactId = p.ContactId
        GROUP BY 1
        ) AS ouuu
ON c.ContactId = ouuu.ContactId
LEFT JOIN (SELECT ContactId,
				  ActDate
		   FROM acts 
        ) AS zz
ON c.ContactId = zz.ContactId
WHERE ouuu.SumAmount IS NOT NULL
#WHERE p.SUM_AT_2007 IS NOT NULL
GROUP BY c.ContactID
ORDER BY 4 DESC;

