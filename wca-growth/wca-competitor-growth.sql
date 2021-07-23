# Temporary table is used to compute some useful data about competitions

DROP TABLE IF EXISTS competitionStats;
CREATE TEMPORARY TABLE competitionStats AS (


#I'm using CTEs to get a list of every distinct competitor and their first ever WCA competition.

WITH firstCompetition AS (
	WITH personCompetitions AS (
		SELECT personId, competitionId, year, endMonth, endDay,
		row_number() OVER (PARTITION BY personId ORDER BY year, endMonth, endDay ASC) comp_index
		FROM (SELECT DISTINCT personId, competitionId FROM Results) personCompetitions_unordered
		JOIN Competitions c ON personCompetitions_unordered.competitionId = c.id)
	SELECT personId, competitionId FROM personCompetitions
	WHERE comp_index = 1)


SELECT 
	id, countryId, year, 
		CONVERT(CONCAT(year, '-', endMonth, '-', endDay), date) competition_endDate, 
	COUNT(id) OVER (PARTITION BY countryId, year) countryYearlyComps,
    IFNULL(competitors, 0) competitors,
    IFNULL(newcomers, 0) newcomers
FROM Competitions
#For each competition I'm joining the total number of competitors, as well as the number of newcomers (people that had never attended a WCA competition before).
INNER JOIN
	(SELECT competitionId, COUNT(DISTINCT personId) competitors
	FROM Results
    GROUP BY competitionId) competitors
		ON Competitions.id = competitors.competitionId
LEFT JOIN
	(SELECT competitionId, COUNT(DISTINCT personId) newcomers
    FROM firstCompetition
    GROUP BY competitionId) newcomers
		ON Competitions.id = newcomers.competitionId
ORDER BY countryId, 4
);

# Ready to query some statistics:

# 1. Rolling number of new competitors over time
SELECT id, competition_endDate, DATEDIFF(current_date(), competition_endDate) days_since_competition, newcomers,
SUM(newcomers) OVER (ORDER BY competition_endDate) rolling_global_competitors
FROM competitionStats;

# 2. Number of competitions every year
SELECT year, COUNT(*) competitions
FROM competitionStats
GROUP BY 1
ORDER BY 1;

# 3. Days since the first competition in every country to see how the WCA has expanded into new areas
WITH countryFirstCompetition AS (
SELECT id, countryId, year, competition_endDate, row_number() OVER (PARTITION BY countryId ORDER BY competition_endDate) rn
FROM competitionStats
)
SELECT countryId, year, competition_endDate, DATEDIFF(current_date(), competition_endDate) days_since_first_competition
FROM countryFirstCompetition
WHERE rn = 1 
AND countryId NOT LIKE 'X_' #These are used for competitions in multiple countries simultaneously
ORDER BY 4 DESC;

# 4. Number of competitors in each country
SELECT countryId, COUNT(DISTINCT personId)
FROM (SELECT DISTINCT personId, competitionId FROM Results) r
JOIN Competitions c ON r.competitionId = c.id
GROUP BY countryId
ORDER BY 2;