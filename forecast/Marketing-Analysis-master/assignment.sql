
CREATE TABLE IF NOT EXISTS `Movie` (
  `mID` int(6) unsigned NOT NULL,
  `title` varchar(200)  NOT NULL,
  `year` int(5) NOT NULL,
  `director` varchar(200),
  PRIMARY KEY (`mID`)
) DEFAULT CHARSET=utf8;
INSERT INTO `Movie` (`mID`, `title`, `year`, `director`) VALUES
  ('101', 'Gone with the Wind', '1939', 'Victor Fleming'),
  ('102', 'Star Wars', '1977', 'George Lucas'),
  ('103', 'The Sound of Music', '1965', 'Robert Wise'),
  ('104', 'E.T.', '1982', 'Steven Spielberg'),
  ('105', 'Titanic', '1997', 'James Cameron'),
  ('106', 'Snow White', '1937', NULL),
  ('107', 'Avatar', '2009', 'James Cameron'),
  ('108', 'Raiders of the Lost Ark', '1981', 'Steven Spielberg');

CREATE TABLE IF NOT EXISTS `Reviewer` (
  `rID` int(6) unsigned NOT NULL,
  `name` varchar(200)  NOT NULL,
  PRIMARY KEY (`rID`)
) DEFAULT CHARSET=utf8;
INSERT INTO `Reviewer` (`rID`, `name`) VALUES
('201', 'Sarah Martinez'),
('202', 'Daniel Lewis'),
('203', 'Brittany Harris'),
('204', 'Mike Anderson'),
('205', 'Chris Jackson'),
('206', 'Elizabeth Thomas'),
('207', 'James Cameron'),
('208', 'Ashley White');

CREATE TABLE IF NOT EXISTS `Rating` (
  `rID` int(6) unsigned NOT NULL,
  `mID` int(6) unsigned NOT NULL,
  `stars` int(2) unsigned NOT NULL,  
  `ratingDate` DATE) 
  DEFAULT CHARSET=utf8;
INSERT INTO `Rating` (`rID`, `mID`, `stars`, `ratingDate`) VALUES
('201', '101', '2', '2011-01-22'),
('201', '101', '4', '2011-01-27'),
('203', '103', '2', '2011-01-20'),
('203', '108', '4', '2011-01-12'),
('203', '108', '2', '2011-01-30'),
('204', '101', '3', '2011-01-09'),
('205', '103', '3', '2011-01-27'),
('205', '104', '2', '2011-01-22'),
('205', '108', '4', NULL),
('206', '107', '3', '2011-01-15'),
('206', '106', '5', '2011-01-19'),
('207', '107', '5', '2011-01-20'),
('208', '104', '3', '2011-01-02');



# 1
SELECT title
FROM `Movie`
WHERE director = 'Steven Spielberg';

# 2
SELECT title
FROM Movie
WHERE mID IN (SELECT mID
FROM Rating
WHERE stars >= 4 
ORDER BY stars ASC)


# 3
SELECT title
FROM Movie
WHERE mID NOT IN (SELECT mID
FROM Rating
ORDER BY stars ASC)



#4)	For all cases where the same reviewer rated the same movie twice and 
#  	gave it a higher rating the second time, 
#  	return the reviewer's name and the title of the movie. 

SELECT Re.Name, M.title
FROM Rating r1 
INNER JOIN Rating r2 ON r2.mID = r1.mID AND r2.rID= r1.rID
INNER JOIN Reviewer Re ON Re.rID = r1.rID
INNER JOIN Movie M ON M.mID = r1.mID
WHERE r1.stars < r2.stars
ORDER BY r1.ratingDate

# 5) For each movie that has at least one rating, 
#    find the highest number of stars that movie received. 
#    Return the movie title and number of stars. Sort by movie title. 

SELECT title, MAX(stars)
FROM Movie
INNER JOIN Rating r ON r.mID = Movie.mID
GROUP BY Movie.title

# 6) For each movie, return the title and the 'rating spread', that is, 
#    the difference between highest and lowest ratings given to that movie. 

#    Sort by rating spread from highest to lowest, then by movie title.

SELECT M.title, MAX(r1.stars) - MIN(r2.stars) AS rating_spread
FROM Rating r1 
INNER JOIN Rating r2 ON r2.mID = r1.mID
INNER JOIN Movie M ON M.mID = r1.mID
GROUP BY r1.mID

# 7) Find the difference between the average rating of movies released before 1980 and 
#    the average rating of movies released after 1980. 

#    (Make sure to calculate the average rating for each movie, then the average of those averages 
#    for movies before 1980 and movies after. Don't just calculate the overall average rating before and after 1980.)

SELECT TELL, AVG(rate1)
FROM (
SELECT r1.mID, 
       AVG(r1.stars) AS rate1, 
       CASE WHEN M1.year > 1980 THEN 1 ELSE 0 END AS TELL,
       M1.year AS year
FROM Rating r1 
INNER JOIN Movie M1 ON M1.mID = r1.mID
GROUP BY r1.mID
) A
GROUP BY TELL

# 8) For all pairs of reviewers such that both reviewers gave a rating to the same movie, 
#    return the name of both reviewers. Eliminate duplicates, don’t pair reviewers with themselves, 
#    and include each pair only once. For each pair, return the names in the pair in alphabetical order.

SELECT CONCAT(Re1.name, ', ', Re2.name) AS Pair
FROM Rating r1 
INNER JOIN Rating r2 ON r2.mID = r1.mID AND r2.stars = r1.stars
INNER JOIN Reviewer Re1 ON Re1.rID = r1.rID 
INNER JOIN Reviewer Re2 ON Re2.rID = r2.rID 
WHERE r2.rID < r1.rID

# 9) Find the movie(s) with the highest average rating. Return the movie title(s) and average rating.

SELECT title, average_rating
FROM Movie
INNER JOIN (SELECT mID, AVG(stars) as average_rating
FROM Rating
GROUP BY mID
ORDER BY average_rating DESC) r ON r.mID = Movie.mID
