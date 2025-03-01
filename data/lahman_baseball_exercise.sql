-- Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH vandyplayers AS (
	SELECT *
	FROM people
	INNER JOIN collegeplaying
	USING(playerid)
	WHERE schoolid LIKE 'vandy'
)
SELECT playerid, namegiven, SUM(salary)::NUMERIC::MONEY AS total_salary_earned_over_career
FROM vandyplayers
INNER JOIN salaries
USING(playerid)
GROUP BY playerid, namegiven
ORDER BY total_salary_earned_over_career DESC;

-- David Taylor earned the most money over the course of his career in the MLB.

-- Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", 
-- those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.

WITH position_group_putouts AS (
	SELECT 
		CASE WHEN pos LIKE '_F' THEN 'Outfield'
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery' END position_group,
		po,
		yearid
	FROM people
	INNER JOIN fielding
	USING(playerid)
)
SELECT position_group, SUM(po) as total_num_putouts
FROM position_group_putouts
WHERE yearid = 2016
GROUP BY position_group
ORDER by total_num_putouts DESC;

-- Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the generate_series function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)

WITH decade_teams AS (
	SELECT 
		10 * (yearid/10) AS decade, 
		(so * 1.0/g) AS strikeouts_per_game, 
		(hr * 1.0/g) AS homeruns_per_game, 
		teams.*
	FROM teams
)
SELECT decade, ROUND(AVG(strikeouts_per_game), 2) AS avg_strikeouts_per_game, ROUND(AVG(homeruns_per_game), 2) AS avg_homeruns_per_game
FROM decade_teams
WHERE decade >= 1920
GROUP BY decade
ORDER BY decade;

-- It looks like the average number of homeruns a game has steadily, but slowly increased, while strikeouts per game has steadily increased at a much higher rate.


-- Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases. 
-- Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.

WITH stolen_base_batters AS (
	SELECT (sb + cs) AS stolen_base_attempts, sb, yearid, playerid, namegiven
	FROM people
	INNER JOIN batting
	USING(playerid)
)
SELECT namegiven, SUM(sb) AS total_stolen_bases, SUM(stolen_base_attempts) AS total_stolen_base_attempts, ROUND((100.0 * SUM(sb)/SUM(stolen_base_attempts)), 2) AS pct_successful_stolen_base_attempts
FROM stolen_base_batters
WHERE yearid = 2016
GROUP BY namegiven
HAVING SUM(stolen_base_attempts) >= 20
ORDER BY pct_successful_stolen_base_attempts DESC;

-- From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
-- What is the smallest number of wins for a team that did win the world series? 
-- Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. 
-- Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? 
-- What percentage of the time?

SELECT *
FROM teams;



-- Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

-- Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the inducted column of the halloffame table.

-- Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

-- Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

-- After finishing the above questions, here are some open-ended questions to consider.

-- Open-ended questions

-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- In this question, you will explore the connection between number of wins and attendance.

-- a. Does there appear to be any correlation between attendance at home games and number of wins?
-- b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?