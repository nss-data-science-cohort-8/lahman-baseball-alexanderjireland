-- 1. Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH vandyplayers AS (
	SELECT DISTINCT playerid, namegiven
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

-- 2. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", 
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

-- 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
-- Do the same for home runs per game. Do you see any trends? 
-- (Hint: For this question, you might find it helpful to look at the generate_series function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)

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

WITH years AS (
	SELECT generate_series(1920, 2020, 10) AS decades
	)
SELECT decades, ROUND(SUM(so) * 1.0/SUM(g), 2) AS avg_strikeouts_per_game, ROUND(SUM(hr) * 1.0/SUM(g), 2) AS avg_homeruns_per_game
FROM teams AS t
INNER JOIN years
ON t.yearid < (decades + 10) AND t.yearid >= decades
GROUP BY decades
ORDER BY decades;

-- It looks like the average number of homeruns a game has steadily, but slowly increased, while strikeouts per game has steadily increased at a much higher rate.


-- 4. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases. 
-- Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.

WITH stolen_base_batters AS (
	SELECT (sb + cs) AS stolen_base_attempts, sb, yearid, playerid, namegiven, CONCAT(namefirst, ' ', namelast) AS fullname
	FROM people
	INNER JOIN batting
	USING(playerid)
)
SELECT fullname, SUM(sb) AS total_stolen_bases, SUM(stolen_base_attempts) AS total_stolen_base_attempts, ROUND((100.0 * SUM(sb)/SUM(stolen_base_attempts)), 2) AS pct_successful_stolen_base_attempts
FROM stolen_base_batters
WHERE yearid = 2016
GROUP BY fullname
HAVING SUM(stolen_base_attempts) >= 20
ORDER BY pct_successful_stolen_base_attempts DESC;

-- 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
-- What is the smallest number of wins for a team that did win the world series? 
-- Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. 
-- Then redo your query, excluding the problem year. 
-- How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? 
-- What percentage of the time?

SELECT yearid, teamid, g, w AS max_wins_no_ws
FROM teams
WHERE wswin = 'N'
	AND yearid BETWEEN 1970 AND 2016
ORDER BY max_wins_no_ws DESC
LIMIT 1;

SELECT yearid, teamid, g, w AS min_wins_won_ws
FROM teams
WHERE wswin = 'Y'
	AND yearid != 1981
	AND yearid BETWEEN 1970 AND 2016
ORDER BY min_wins_won_ws
LIMIT 1;

-- only 110-ish games were played in 1981, rather than 162.
SELECT COUNT(*) AS num_teams_best_record_and_won_ws, 100 * (COUNT(*) / (2016.0 - 1970)) AS pct_best_record_won
FROM (
	WITH year_and_max_num_wins AS (
		SELECT DISTINCT ON(yearid) yearid, w AS max_wins
		FROM teams
		WHERE yearid BETWEEN 1970 AND 2016
		ORDER BY yearid, w DESC
	)
	SELECT *
	FROM teams
	RIGHT JOIN year_and_max_num_wins
	ON year_and_max_num_wins.yearid = teams.yearid AND year_and_max_num_wins.max_wins = teams.w
	)
WHERE wswin = 'Y';

-- 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.
	SELECT CONCAT(namefirst, ' ', namelast) AS fullname, m.lgid, awardid, teamid
	FROM awardsmanagers
	INNER JOIN people
	USING (playerid)
	INNER JOIN salaries
	USING (playerid)
	INNER JOIN managers AS m
	USING (teamid)
	WHERE m.lgid = 'AL' 
		AND awardid = 'TSN Manager of the Year';


WITH al_tsn_winners AS (
	SELECT CONCAT(namefirst, ' ', namelast) AS fullname, m.lgid, awardid, teamid
	FROM awardsmanagers
	INNER JOIN people
	USING (playerid)
	INNER JOIN salaries
	USING (playerid)
	INNER JOIN managers AS m
	USING (teamid)
	WHERE m.lgid = 'AL' 
		AND awardid = 'TSN Manager of the Year'
	),
nl_tsn_winners AS (
	SELECT CONCAT(namefirst, ' ', namelast) AS fullname, m.lgid, awardid, teamid
	FROM awardsmanagers
	INNER JOIN people
	USING (playerid)
	INNER JOIN salaries
	USING (playerid)
	INNER JOIN managers AS m
	USING (teamid)
	WHERE m.lgid = 'NL'
		AND awardid = 'TSN Manager of the Year'
	)
SELECT DISTINCT fullname, al.teamid AS al_team, nl.teamid AS nl_team
FROM al_tsn_winners AS al
INNER JOIN nl_tsn_winners AS nl
USING(fullname);

-- 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). 
-- Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

SELECT CONCAT(namefirst, ' ', namelast) AS fullname, salary/so AS salary_over_strikeouts, playerid, yearid
FROM people
INNER JOIN pitching
USING (playerid)
INNER JOIN salaries
USING (playerid, yearid)
WHERE g >= 10
	AND yearid = 2016
ORDER BY salary_over_strikeouts DESC; --Now to consider players who played for more than one team in a year

WITH select_2016_pitchers AS (
	SELECT playerid, CONCAT(namefirst, ' ', namelast) AS fullname, SUM(g) AS total_games_played, SUM(so) AS total_strikeouts, AVG(salary) AS salary
	FROM people
	INNER JOIN pitching
	USING (playerid)
	INNER JOIN salaries
	USING (playerid, yearid)
	WHERE yearid = 2016
	GROUP BY playerid, fullname
	HAVING SUM(g) >= 10
	ORDER BY playerid
	)
SELECT fullname, salary/total_strikeouts AS salary_over_strikeouts
FROM select_2016_pitchers
ORDER BY salary_over_strikeouts DESC
LIMIT 1;

-- 8. Find all players who have had at least 3000 career hits. 
-- Report those players' names, total number of hits, and the year they were inducted into the hall of fame 
-- (If they were not inducted into the hall of fame, put a null in that column.) 
-- Note that a player being inducted into the hall of fame is indicated by a 'Y' in the inducted column of the halloffame table.

WITH year_inducted AS (
	SELECT playerid, yearid AS year_inducted_to_hof
	FROM people
	INNER JOIN halloffame
	USING(playerid)
	WHERE inducted = 'Y'
)
SELECT 
	CONCAT(namefirst, ' ', namelast) AS fullname, 
	SUM(h) AS career_hits,
	year_inducted_to_hof
FROM people
INNER JOIN batting
USING(playerid)
LEFT JOIN year_inducted
USING(playerid)
GROUP BY playerid, fullname, year_inducted_to_hof
HAVING SUM(h) >= 3000
ORDER BY career_hits DESC;

-- 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

SELECT fullname
FROM (
	WITH player_hits_per_year AS (
		SELECT 
			playerid,
			CONCAT(namefirst, ' ', namelast) AS fullname, 
			SUM(h) AS num_hits,
			teamid,
			yearid
		FROM people
		INNER JOIN batting
		USING(playerid)
		GROUP BY playerid, teamid, yearid, fullname
		ORDER BY playerid
	)
	SELECT p.fullname, teamid, SUM(num_hits) AS total_hits_per_team
	FROM player_hits_per_year as p
	GROUP BY teamid, p.fullname
	HAVING SUM(num_hits) >= 1000
	ORDER BY p.fullname
)
GROUP BY fullname
HAVING COUNT(teamid) > 1;

-- 10. Find all players who hit their career highest number of home runs in 2016. 
-- Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
-- Report the players' first and last names and the number of home runs they hit in 2016.

WITH player_max_hrs AS (
	SELECT playerid, CONCAT(namefirst, ' ', namelast) AS fullname, MAX(hr) AS max_hrs, COUNT(DISTINCT yearid) AS num_years_in_league
	FROM people
	INNER JOIN batting
	USING(playerid)
	GROUP BY playerid, fullname
	HAVING MAX(hr) > 0
		AND COUNT(DISTINCT yearid) >= 10
	ORDER BY max_hrs DESC
)
SELECT fullname, hr
FROM people
INNER JOIN batting
USING(playerid)
INNER JOIN player_max_hrs
USING(playerid)
WHERE hr = max_hrs
	AND yearid = 2016
ORDER BY hr DESC;
	

-- After finishing the above questions, here are some open-ended questions to consider.

-- Open-ended questions

-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- In this question, you will explore the connection between number of wins and attendance.

-- a. Does there appear to be any correlation between attendance at home games and number of wins?
-- b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?