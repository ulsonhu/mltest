USE Charity2;

# Clean tables for the exercise
#DROP TABLE periods;
#DROP TABLE segments;

# find the lifetime donation amount of each donator
SELECT c.id,
       c.first_name,
       c.zip_code,
       p.SumAmount
FROM contacts AS c
LEFT JOIN (SELECT contact_id, SUM(amount) AS SumAmount, act_date
	   FROM acts
	   GROUP BY contact_id) AS p  
ON c.id = p.contact_id
WHERE p.SumAmount IS NOT NULL
GROUP BY c.id
order by 4 DESC;


# Create a new table for periods
CREATE TABLE periods (
  PeriodId INTEGER NOT NULL,
  FirstDay DATE NOT NULL,
  LastDay DATE NOT NULL,
  PRIMARY KEY (PeriodId)
)
ENGINE = MyISAM;


# 1990-06-12 to 2017-01-08
# Define 27 periods
INSERT INTO periods
VALUES ( 0, 20160109, 20170108),
       ( 1, 20150109, 20160108),
       ( 2, 20140109, 20150108),
       ( 3, 20130109, 20140108),
       ( 4, 20120109, 20130108),
       ( 5, 20110109, 20120108),
       ( 6, 20100109, 20110108),
       ( 7, 20090109, 20100108),
       ( 8, 20080109, 20090108),
       ( 9, 20070109, 20080108),
       (10, 20060109, 20070108),
       (11, 20050109, 20060108),
       (12, 20040109, 20050108),
       (13, 20030109, 20040108),
       (14, 20020109, 20030108),
       (15, 20010109, 20020108),
       (16, 20000109, 20010108),
       (17, 19990109, 20000108),
       (18, 19980109, 19990108),
       (19, 19970109, 19980108),
       (20, 19960109, 19970108),
       (21, 19950109, 19960108),
       (22, 19940109, 19950108),
       (23, 19930109, 19940108),
       (24, 19920109, 19930108),
       (25, 19910109, 19920108),
       (26, 19900602, 19910108);
              

# Create a segment table
# It will store to which segment each donor belonged
# in each period
CREATE TABLE segments (
  Sq INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  ContactId INTEGER UNSIGNED NOT NULL,
  PeriodId INTEGER NOT NULL,
  Segment VARCHAR(6),
  C_Channel  VARCHAR(6),
  PRIMARY KEY (Sq),
  INDEX IdxContactId(ContactId),
  INDEX IdxPeriodId(PeriodId)
)
ENGINE = MyISAM;

INSERT INTO segments (ContactId, PeriodId)
SELECT a.contact_id, p.PeriodId
FROM acts a,
     periods p
GROUP BY 1, 2;


ALTER TABLE segments
ADD P_Amount INT NOT NULL DEFAULT 0


# Create the AUTO segment
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND
          (a.act_type_id LIKE 'PA')) AS d
SET
  s.Segment = "AUTO"
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId);


# Create the NEW segment
UPDATE
  segments s,
  (SELECT contact_id, PeriodId
   FROM periods p,
        (SELECT contact_id, MIN(act_date) AS FirstAct
         FROM acts
         GROUP BY 1) AS f
   WHERE (f.FirstAct <= p.LastDay) AND
         (f.FirstAct >= p.FirstDay)) AS d
   SET
   s.Segment = "NEW"
   WHERE
   (s.ContactId = d.contact_id) AND
   (s.PeriodId = d.PeriodId) AND
   (s.Segment IS NULL);


UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, SUM(a.amount) AS generosity
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND
          (a.act_type_id LIKE 'DO')
   GROUP BY 1, 2) AS d
SET
  s.Segment = IF(generosity < 100, "BOTTOM", "TOP")
WHERE
  (s.ContactId = d.contact_id) AND
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

# run this part again and again

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


################################
##### Counting for Channel #####
################################


# web counting 
ALTER TABLE segments
ADD Web INT NOT NULL DEFAULT 0;

# Create the Telephone segment
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, count(a.amount) as times
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND
          (a.channel_id LIKE 'WW')
   GROUP BY contact_id) AS d
SET
  s.Web = d.times
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId);

# drop the column
# ALTER TABLE segments DROP COLUMN Web;

# create column for counting "Web"
ALTER TABLE segments
ADD Web INT NOT NULL DEFAULT 0;

# Create Web count
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, count(a.amount) as times
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND
          (a.channel_id LIKE 'WW')
   GROUP BY a.contact_id, p.PeriodId) AS d
SET
  s.Web = d.times
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId);




# create column for counting "Mail"
ALTER TABLE segments
ADD Mail INT NOT NULL DEFAULT 0;

# Create mail count
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, count(a.amount) as times
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND
          (a.channel_id LIKE 'MA')
   GROUP BY a.contact_id, p.PeriodId) AS d
SET
  s.Mail = d.times
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId);



# create column for counting "Telephone"
ALTER TABLE segments
ADD Phone INT NOT NULL DEFAULT 0;

# Create Phone count
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, count(a.amount) as times
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND
          (a.channel_id LIKE 'TE')
   GROUP BY a.contact_id, p.PeriodId) AS d
SET
  s.Phone = d.times
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId);


# create column for counting "Street"
ALTER TABLE segments
ADD Street INT NOT NULL DEFAULT 0;

# Create Phone count
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, count(a.amount) as times
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND
          (a.channel_id LIKE 'ST')
   GROUP BY a.contact_id, p.PeriodId) AS d
SET
  s.Street = d.times
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId);


##################################################################
####### Create individual donation amount for each period ########
##################################################################

ALTER TABLE segments
ADD P_Amount INT NOT NULL DEFAULT 0

# WEB
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, sum(a.amount) as money
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND 
          (a.channel_id LIKE 'WW')
   GROUP BY  a.contact_id, p.PeriodId) AS d
SET
  s.P_Amount = d.money
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId);

# Create individual donation amount for each period *(MAIL)
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, sum(a.amount) as money
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND 
          (a.channel_id LIKE 'MA')
   GROUP BY a.contact_id, p.PeriodId) AS d
SET
  s.P_Amount = d.money
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId) AND 
  (s.P_Amount = 0);

  
  # Create individual donation amount for each period *(Street)
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, sum(a.amount) as money
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND 
          (a.channel_id LIKE 'ST')
   GROUP BY a.contact_id, p.PeriodId) AS d
SET
  s.P_Amount = d.money
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId) AND 
  (s.P_Amount = 0);


  # Create individual donation amount for each period *(Telephone)
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, sum(a.amount) as money
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND 
          (a.channel_id LIKE 'TE')
   GROUP BY a.contact_id, p.PeriodId) AS d
SET
  s.P_Amount = d.money
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId) AND 
  (s.P_Amount = 0);
  

  # Create individual donation amount for each period *(Event) No one
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, sum(a.amount) as money
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND 
          (a.channel_id LIKE 'EV')
   GROUP BY a.contact_id, p.PeriodId) AS d
SET
  s.P_Amount = d.money
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId) AND 
  (s.P_Amount = 0);
  

  # Create individual donation amount for each period *(QU) ...WHAT?
UPDATE
  segments s,
  (SELECT a.contact_id, p.PeriodId, sum(a.amount) as money
   FROM   acts a, periods p
   WHERE  (a.act_date <= p.LastDay) AND
          (a.act_date >= p.FirstDay) AND 
          (a.channel_id LIKE 'QU')
   GROUP BY a.contact_id, p.PeriodId) AS d
SET
  s.P_Amount = d.money
WHERE
  (s.ContactId = d.contact_id) AND
  (s.PeriodId = d.PeriodId) AND 
  (s.P_Amount = 0);
  
  

##############
### Report ###
##############


# Count segment members per period
SELECT PeriodId, Segment, COUNT(*)
FROM segments
GROUP BY 1, 2
ORDER BY 2, 1 DESC;


# Count Channel members per period
SELECT PeriodId, C_Channel, COUNT(*), SUM(P_Amount)
FROM segments
GROUP BY 1, 2
ORDER BY 2, 1 DESC;




# the movement of the donors 2015-2016 vs. 2016-2017
SELECT old.C_Channel As '2015-2016', 
	   new.C_Channel As '2016-2017',
       COUNT(old.C_Channel) As '2015-2016 numbers',
	   COUNT(new.C_Channel) As '2016-2017 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 1) AND
      (new.PeriodId = 0)
GROUP BY 1, 2
ORDER BY 1, 2;



# the movement of the donors 2014-2015 vs. 2015-2016
SELECT old.C_Channel As '2014-2015', 
	   new.C_Channel As '2015-2016',
       COUNT(old.C_Channel) As '2014-2015 numbers',
	   COUNT(new.C_Channel) As '2015-2016 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 2) AND
      (new.PeriodId = 1)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2013-2014 vs. 2014-2015
SELECT old.C_Channel As '2013-2014', 
	   new.C_Channel As '2014-2015',
       COUNT(old.C_Channel) As '2013-2014 numbers',
	   COUNT(new.C_Channel) As '2014-2015 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 3) AND
      (new.PeriodId = 2)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2012-2013 vs. 2013-2014
SELECT old.C_Channel As '2012-2013', 
	   new.C_Channel As '2013-2014',
       COUNT(old.C_Channel) As '2012-2013 numbers',
	   COUNT(new.C_Channel) As '2013-2014 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 4) AND
      (new.PeriodId = 3)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2011-2012 vs. 2012-2013
SELECT old.C_Channel As '2011-2012', 
	   new.C_Channel As '2012-2013',
       COUNT(old.C_Channel) As '2011-2012 numbers',
	   COUNT(new.C_Channel) As '2012-2013 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 5) AND
      (new.PeriodId = 4)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2010-2011 vs. 2011-2012
SELECT old.C_Channel As '2010-2011', 
	   new.C_Channel As '2011-2012',
       COUNT(old.C_Channel) As '2010-2011 numbers',
	   COUNT(new.C_Channel) As '2011-2012 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 6) AND
      (new.PeriodId = 5)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2009-2010 vs. 2010-2011
SELECT old.C_Channel As '2009-2010', 
	   new.C_Channel As '2010-2011',
       COUNT(old.C_Channel) As '2009-2010 numbers',
	   COUNT(new.C_Channel) As '2010-2011 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 7) AND
      (new.PeriodId = 6)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2008-2009 vs. 2009-2010
SELECT old.C_Channel As '2008-2009', 
	   new.C_Channel As '2009-2010',
       COUNT(old.C_Channel) As '2008-2009 numbers',
	   COUNT(new.C_Channel) As '2009-2010 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 8) AND
      (new.PeriodId = 7)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2007-2008 vs. 2008-2009
SELECT old.C_Channel As '2007-2008', 
	   new.C_Channel As '2008-2009',
       COUNT(old.C_Channel) As '2007-2008 numbers',
	   COUNT(new.C_Channel) As '2008-2009 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 9) AND
      (new.PeriodId = 8)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2006-2007 vs. 2007-2008
SELECT old.C_Channel As '2006-2007', 
	   new.C_Channel As '2007-2008',
       COUNT(old.C_Channel) As '2006-2003 numbers',
	   COUNT(new.C_Channel) As '2007-2008 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 10) AND
      (new.PeriodId = 9)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2005-2006 vs. 2006-2007
SELECT old.C_Channel As '2005-2006', 
	   new.C_Channel As '2006-2007',
       COUNT(old.C_Channel) As '2005-2006 numbers',
	   COUNT(new.C_Channel) As '2006-2007 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 11) AND
      (new.PeriodId = 10)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2004-2005 vs. 2005-2006
SELECT old.C_Channel As '2004-2005', 
	   new.C_Channel As '2005-2006',
       COUNT(old.C_Channel) As '2004-2005 numbers',
	   COUNT(new.C_Channel) As '2005-2006 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 12) AND
      (new.PeriodId = 11)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2003-2004 vs. 2004-2005
SELECT old.C_Channel As '2003-2004', 
	   new.C_Channel As '2004-2005',
       COUNT(old.C_Channel) As '2003-2004 numbers',
	   COUNT(new.C_Channel) As '2004-2005 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 13) AND
      (new.PeriodId = 12)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2002-2003 vs. 2003-2004
SELECT old.C_Channel As '2002-2003', 
	   new.C_Channel As '2003-2004',
       COUNT(old.C_Channel) As '2002-2003 numbers',
	   COUNT(new.C_Channel) As '2003-2004 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 14) AND
      (new.PeriodId = 13)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2001-2002 vs. 2002-2003
SELECT old.C_Channel As '2001-2002', 
	   new.C_Channel As '2002-2003',
       COUNT(old.C_Channel) As '2001-2002 numbers',
	   COUNT(new.C_Channel) As '2002-2003 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 15) AND
      (new.PeriodId = 14)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 2000-2001 vs. 2001-2002
SELECT old.C_Channel As '2000-2001', 
	   new.C_Channel As '2001-2002',
       COUNT(old.C_Channel) As '2000-2001 numbers',
	   COUNT(new.C_Channel) As '2001-2002 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 16) AND
      (new.PeriodId = 15)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 1999-2000 vs. 2000-2001
SELECT old.C_Channel As '1999-2000', 
	   new.C_Channel As '2000-2001',
       COUNT(old.C_Channel) As '1999-2000 numbers',
	   COUNT(new.C_Channel) As '2000-2001 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 17) AND
      (new.PeriodId = 16)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 1998-1999 vs. 1999-2000
SELECT old.C_Channel As '1998-1999', 
	   new.C_Channel As '1999-2000',
       COUNT(old.C_Channel) As '1998-1999 numbers',
	   COUNT(new.C_Channel) As '1999-2000 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 18) AND
      (new.PeriodId = 17)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 1997-1998 vs. 1998-1999
SELECT old.C_Channel As '1997-1998', 
	   new.C_Channel As '1998-1999',
       COUNT(old.C_Channel) As '1997-1998 numbers',
	   COUNT(new.C_Channel) As '1998-1999 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 19) AND
      (new.PeriodId = 18)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 1996-1997 vs. 1997-1998
SELECT old.C_Channel As '1996-1997', 
	   new.C_Channel As '1997-1998',
       COUNT(old.C_Channel) As '1996-1997 numbers',
	   COUNT(new.C_Channel) As '1997-1998 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 20) AND
      (new.PeriodId = 19)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 1995-1996 vs. 1996-1997
SELECT old.C_Channel As '1995-1996', 
	   new.C_Channel As '1996-1997',
       COUNT(old.C_Channel) As '1995-1996 numbers',
	   COUNT(new.C_Channel) As '1996-1997 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 21) AND
      (new.PeriodId = 20)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 1994-1995 vs. 1995-1996
SELECT old.C_Channel As '1994-1995', 
	   new.C_Channel As '1995-1996',
       COUNT(old.C_Channel) As '1994-1995 numbers',
	   COUNT(new.C_Channel) As '1995-1996 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 22) AND
      (new.PeriodId = 21)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 1993-1994 vs. 1994-1995
SELECT old.C_Channel As '1993-1994', 
	   new.C_Channel As '1994-1995',
       COUNT(old.C_Channel) As '1993-1994 numbers',
	   COUNT(new.C_Channel) As '1994-1995 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 23) AND
      (new.PeriodId = 22)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 1992-1993 vs. 1993-1994
SELECT old.C_Channel As '1992-1993', 
	   new.C_Channel As '1993-1994',
       COUNT(old.C_Channel) As '1992-1993 numbers',
	   COUNT(new.C_Channel) As '1993-1994 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 24) AND
      (new.PeriodId = 23)
GROUP BY 1, 2
ORDER BY 1, 2;



# the movement of the donors 1991-1992 vs. 1992-1993
SELECT old.C_Channel As '1991-1992', 
	   new.C_Channel As '1992-1993',
       COUNT(old.C_Channel) As '1991-1992 numbers',
	   COUNT(new.C_Channel) As '1992-1993 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 25) AND
      (new.PeriodId = 24)
GROUP BY 1, 2
ORDER BY 1, 2;


# the movement of the donors 1990(incomplete)-1991 vs. 1991-1992
SELECT old.C_Channel As '1990-1991', 
	   new.C_Channel As '1991-1992',
       COUNT(old.C_Channel) As '1990-1991 numbers',
	   COUNT(new.C_Channel) As '1991-1992 numbers',
       (COUNT(new.C_Channel) - COUNT(old.C_Channel)) As 'Gain/Loss (later - old)'
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 26) AND
      (new.PeriodId = 25)
GROUP BY 1, 2
ORDER BY 1, 2;


##########################
#####  end of query  #####
##########################



# from 2016-2017 segmentation
# important!

SELECT t.ContactID,
	   con.zip AS ZipCode,
       CASE 
        WHEN q.q.PerWeb >= q.PerMail AND q.PerWeb >= q.PerPhone AND q.PerWeb>= q.perStreet THEN 'Web' 
        WHEN q.PerMail >= q.PerPhone AND q.PerMail>= q.perStreet THEN 'Mail'
        WHEN q.PerPhone >= q.perStreet THEN 'Phone' 
        ELSE 'Street'
       END AS MostLikelyChannel,
	   CASE 
        WHEN q.q.PerWeb >= q.PerMail AND q.PerWeb >= q.PerPhone AND q.PerWeb>= q.perStreet THEN v.WebAmount
        WHEN q.PerMail >= q.PerPhone AND q.PerMail>= q.perStreet THEN aa.MailAmount
        WHEN q.PerPhone >= q.perStreet THEN bb.PhoneAmount
        ELSE cc.StreetAmount
       END AS ExpectedAmount,
	   q.PerWeb,
       v.WebAmount,
       q.PerMail,
       aa.MailAmount,
       q.PerPhone,
       bb.PhoneAmount,
       q.perStreet,
       cc.StreetAmount
FROM segments t
INNER JOIN(SELECT ContactID,
			      C_Channel,
		          SUM(Web)/(SUM(Web)+SUM(Mail)+SUM(Street)+SUM(Phone))AS PerWeb,
		          SUM(Mail)/(SUM(Web)+SUM(Mail)+SUM(Street)+SUM(Phone))AS PerMail,
                  SUM(Phone)/(SUM(Web)+SUM(Mail)+SUM(Street)+SUM(Phone))AS PerPhone,
                  SUM(Street)/(SUM(Web)+SUM(Mail)+SUM(Street)+SUM(Phone))AS PerStreet
		   FROM segments
           GROUP BY ContactID) q
on t.ContactID = q.ContactID
RIGHT JOIN(SELECT s.ContactId AS ID
			FROM
			  segments s,
			  periods p,
			  acts a
			WHERE
			  (s.ContactId = a.contact_id) AND
			  (s.PeriodId = 0) 
              AND
			  (p.PeriodId = 0)   
              AND 
			  (a.act_date >= p.FirstDay) AND
			  (a.act_date <= p.LastDay)
			GROUP BY 1) AS jj
on t.ContactID = jj.ID
left JOIN(SELECT contact_id,
				 AVG(amount) AS  WebAmount
		   FROM acts
           WHERE (channel_id like 'WW')
           GROUP BY contact_id) v
on t.ContactID = v.contact_id
left JOIN(SELECT contact_id,
				 AVG(amount) AS  MailAmount
		   FROM acts
           WHERE (channel_id like 'MA')
           GROUP BY contact_id) aa
on t.ContactID = aa.contact_id
left JOIN(SELECT contact_id,
				 AVG(amount) AS  PhoneAmount
		   FROM acts
           WHERE (channel_id like 'TE')
           GROUP BY contact_id) bb
on t.ContactID = bb.contact_id
LEFT JOIN(SELECT contact_id,
				 AVG(amount) AS  StreetAmount
		   FROM acts
           WHERE (channel_id like 'ST')
           GROUP BY contact_id) cc
on t.ContactID = cc.contact_id
LEFT JOIN(SELECT id,
				 zip_code AS zip
		  FROM contacts
          GROUP BY 1) AS con
ON t.ContactId = con.id
WHERE t.Segment NOT LIKE 'COLD' OR t.Segment NOT LIKE 'LOST'
GROUP BY 1;




# 32893
SELECT t.ContactID,
	   con.zip AS ZipCode,
       CASE 
        WHEN q.q.PerWeb >= q.PerMail AND q.PerWeb >= q.PerPhone AND q.PerWeb>= q.perStreet THEN 'Web' 
        WHEN q.PerMail >= q.PerPhone AND q.PerMail>= q.perStreet THEN 'Mail'
        WHEN q.PerPhone >= q.perStreet THEN 'Phone' 
        ELSE 'Street'
       END AS MostLikelyChannel,
	   CASE 
        WHEN q.q.PerWeb >= q.PerMail AND q.PerWeb >= q.PerPhone AND q.PerWeb>= q.perStreet THEN v.WebAmount
        WHEN q.PerMail >= q.PerPhone AND q.PerMail>= q.perStreet THEN aa.MailAmount
        WHEN q.PerPhone >= q.perStreet THEN bb.PhoneAmount
        ELSE cc.StreetAmount
       END AS ExpectedAmount,
	   q.PerWeb,
       v.WebAmount,
       q.PerMail,
       aa.MailAmount,
       q.PerPhone,
       bb.PhoneAmount,
       q.perStreet,
       cc.StreetAmount
FROM segments t
INNER JOIN(SELECT ContactID,
			      C_Channel,
		          SUM(Web)/(SUM(Web)+SUM(Mail)+SUM(Street)+SUM(Phone))AS PerWeb,
		          SUM(Mail)/(SUM(Web)+SUM(Mail)+SUM(Street)+SUM(Phone))AS PerMail,
                  SUM(Phone)/(SUM(Web)+SUM(Mail)+SUM(Street)+SUM(Phone))AS PerPhone,
                  SUM(Street)/(SUM(Web)+SUM(Mail)+SUM(Street)+SUM(Phone))AS PerStreet
		   FROM segments
           GROUP BY ContactID) q
on t.ContactID = q.ContactID
RIGHT JOIN(SELECT s.ContactId AS ID
			FROM
			  segments s,
			  periods p,
			  acts a
			WHERE
			  (s.ContactId = a.contact_id) AND
			  (s.PeriodId < 3) 
              AND
			  (p.PeriodId < 3)   
              AND 
			  (a.act_date >= p.FirstDay) AND
			  (a.act_date <= p.LastDay)
			GROUP BY 1) AS jj
on t.ContactID = jj.ID
left JOIN(SELECT contact_id,
				 AVG(amount) AS  WebAmount
		   FROM acts
           WHERE (channel_id like 'WW')
           GROUP BY contact_id) v
on t.ContactID = v.contact_id
left JOIN(SELECT contact_id,
				 AVG(amount) AS  MailAmount
		   FROM acts
           WHERE (channel_id like 'MA')
           GROUP BY contact_id) aa
on t.ContactID = aa.contact_id
left JOIN(SELECT contact_id,
				 AVG(amount) AS  PhoneAmount
		   FROM acts
           WHERE (channel_id like 'TE')
           GROUP BY contact_id) bb
on t.ContactID = bb.contact_id
left JOIN(SELECT contact_id,
				 AVG(amount) AS  StreetAmount
		   FROM acts
           WHERE (channel_id like 'ST')
           GROUP BY contact_id) cc
on t.ContactID = cc.contact_id
LEFT JOIN(SELECT id,
				 zip_code AS zip
		  FROM contacts
          GROUP BY 1) AS con
ON t.ContactId = con.id
WHERE t.Segment NOT LIKE 'COLD' OR t.Segment NOT LIKE 'LOST'
GROUP BY 1;


