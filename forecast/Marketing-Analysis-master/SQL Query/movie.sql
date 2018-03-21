# 1) Find the titles of all movies directed by Steven Spielberg. 
SELECT title
FROM `Movie`
WHERE director = &#39;Steven Spielberg&#39;;

# 2) Find all years that have a movie that received a rating of 4 or 5, and sort
#    them in increasing order. 

SELECT title
FROM Movie
WHERE mID IN (SELECT mID
FROM Rating
WHERE stars &gt;= 4
ORDER BY stars ASC)

# 3) Find the titles of all movies that have no ratings. 
SELECT title
FROM Movie
WHERE mID NOT IN (SELECT mID
FROM Rating
ORDER BY stars ASC)

# 4) For all cases where the same reviewer rated the same movie twice and
#    gave it a higher rating the second time, return the reviewer&#39;s name and
#    the title of the movie. 
SELECT Re.Name, M.title
FROM Rating r1
INNER JOIN Rating r2 ON r2.mID = r1.mID AND r2.rID= r1.rID
INNER JOIN Reviewer Re ON Re.rID = r1.rID

INNER JOIN Movie M ON M.mID = r1.mID
WHERE r1.stars &lt; r2.stars
ORDER BY r1.ratingDate

# 5) For each movie that has at least one rating, find the highest number of
#    stars that movie received. Return the movie title and number of stars. Sort
#    by movie title. 

SELECT title, MAX(stars)
FROM Movie
INNER JOIN Rating r ON r.mID = Movie.mID
GROUP BY Movie.title

# 6) For each movie, return the title and the &#39;rating spread&#39;, that is, the
#    difference between highest and lowest ratings given to that movie. Sort by
#    rating spread from highest to lowest, then by movie title.
SELECT M.title, MAX(r1.stars) - MIN(r2.stars) AS rating_spread
FROM Rating r1
INNER JOIN Rating r2 ON r2.mID = r1.mID
INNER JOIN Movie M ON M.mID = r1.mID
GROUP BY r1.mID

# 7) Find the difference between the average rating of movies released before
#    1980 and the average rating of movies released after 1980. (Make sure to
#    calculate the average rating for each movie, then the average of those
#    averages for movies before 1980 and movies after. Don&#39;t just calculate the
#    overall average rating before and after 1980.) 
SELECT TELL, AVG(rate1)
FROM (
SELECT r1.mID,
AVG(r1.stars) AS rate1,
CASE WHEN M1.year &gt; 1980 THEN 1 ELSE 0 END AS TELL,
M1.year AS year
FROM Rating r1
INNER JOIN Movie M1 ON M1.mID = r1.mID
GROUP BY r1.mID
) A
GROUP BY TELL

# 8) For all pairs of reviewers such that both reviewers gave a rating to the
#    same movie, return the name of both reviewers. Eliminate duplicates,
#    don’t pair reviewers with themselves, and include each pair only once. For
#    each pair, return the names in the pair in alphabetical order.
SELECT CONCAT(Re1.name, &#39;, &#39;, Re2.name) AS Pair
FROM Rating r1
INNER JOIN Rating r2 ON r2.mID = r1.mID AND r2.stars = r1.stars
INNER JOIN Reviewer Re1 ON Re1.rID = r1.rID
INNER JOIN Reviewer Re2 ON Re2.rID = r2.rID
WHERE r2.rID &lt; r1.rID



# 9) Find the movie(s) with the highest average rating. Return the movie
#    title(s) and average rating.
SELECT title, average_rating
FROM Movie
INNER JOIN (SELECT mID, AVG(stars) as average_rating
FROM Rating
GROUP BY mID
ORDER BY average_rating DESC) r ON r.mID = Movie.mID
