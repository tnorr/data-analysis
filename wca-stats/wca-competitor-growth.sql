# Computing some useful data about competitions into a temporary table
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

# Number of competitions (straight to Power BI):
SELECT countryId, TRIM(LEADING "_" FROM continentId) continent, year, countryYearlyComps FROM competitionStats
JOIN countries ON competitionStats.countryId = countries.id
GROUP BY 1, 3
ORDER BY 4
INTO OUTFILE 'D:/yearlyComps.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

# 3x3 results (to Python for further manipulation):
SELECT r.personId, r.countryId, r.competitionId, MIN(r.best) best_single, c.start_date
FROM results r
JOIN competitions c ON r.competitionId = c.id 
WHERE eventId = '333'
GROUP BY personId, competitionId
ORDER BY personId, c.start_date
INTO OUTFILE 'D:/333singles.csv'
FIELDS TERMINATED BY ','
ESCAPED BY ""
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
;

# Number of new competitors over time (to Power BI)
SELECT id, competition_endDate, DATEDIFF(current_date(), competition_endDate) days_since_competition, newcomers,
SUM(newcomers) OVER (ORDER BY competition_endDate) rolling_global_competitors
FROM competitionStats
INTO OUTFILE 'D:/newcomers.csv'
FIELDS TERMINATED BY ','
ESCAPED BY ""
ENCLOSED BY '"'
LINES TERMINATED BY '\n';