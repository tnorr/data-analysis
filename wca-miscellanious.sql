--Average of all successful solves ever by event:
SELECT eventId, 
ROUND((SUM(IF(value1>0,value1,0)+IF(value2>0,value2,0)+IF(value3>0,value3,0)+IF(value4>0,value4,0)+IF(value5>0,value5,0))
/SUM(IF(value1>0,1,0)+IF(value2>0,1,0)+IF(value3>0,1,0)+IF(value4>0,1,0)+IF(value5>0,1,0)))/100,2) AS 'AvgOfSuccesses'
FROM `Results`
GROUP BY eventId

--3 or more same solves in average:
SELECT * FROM `Results`
WHERE 
((value1=value2 AND (value1=value3 OR value1=value4 OR value1=value5)) OR
(value1=value3 AND (value1=value4 OR value1=value5)) OR
(value1=value4 AND value1=value5) OR
(value2=value3 AND (value2=value4 OR value2=value4)) OR
(value2=value4 AND value2=value5) OR
(value3=value4 AND value3=value5)) AND
(IF(value1>0,1,0)+IF(value2>0,1,0)+IF(value3>0,1,0)+IF(value4>0,1,0)+IF(value5>0,1,0))>2 AND eventId IN ('333', '222', 'minx', 'pyram')
ORDER BY best DESC

--MMDD matching a 3x3 single:
SELECT DISTINCT id, name, year, month, day FROM
(SELECT p.id, p.name, value1, value2, value3, value4, value5, year, month, day, CONCAT(IF(LENGTH(month)=1,0,''),month,IF(LENGTH(day)=1,0,''),day) AS 'mmdd' FROM Persons p
JOIN Results r ON p.id=r.personId
WHERE eventId='333' AND (value1=CONCAT(IF(LENGTH(month)=1,0,''),month,IF(LENGTH(day)=1,0,''),day) OR value2=CONCAT(IF(LENGTH(month)=1,0,''),month,IF(LENGTH(day)=1,0,''),day) OR value3=CONCAT(IF(LENGTH(month)=1,0,''),month,IF(LENGTH(day)=1,0,''),day) OR value4=CONCAT(IF(LENGTH(month)=1,0,''),month,IF(LENGTH(day)=1,0,''),day) OR value5=CONCAT(IF(LENGTH(month)=1,0,''),month,IF(LENGTH(day)=1,0,''),day)) AND year<>0) T
ORDER BY month ASC, day ASC

--3x3 single by first name letter:
SELECT firstLetter, personId, name, 
	CASE 
	WHEN eventId='333mbf' THEN CONCAT(99-LEFT(best,2)+RIGHT(best,2),'/',99-LEFT(best,2)+2*RIGHT(best,2), ' ', TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM (SUBSTRING(SEC_TO_TIME(SUBSTRING(best,4,4)),2,10))))))))
	WHEN eventId='333fm' THEN best
	ELSE TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM (SUBSTRING(SEC_TO_TIME(best/100),2,10)))))))
	END 'single'
FROM
	(SELECT 
	SUBSTRING(name,1,1) AS 'firstLetter',
	personId, name, eventId, best,
		(MIN(best) OVER (PARTITION BY SUBSTRING(name,1,1))) 'letterBest'
	FROM RanksSingle r
	JOIN Persons p ON r.personId=p.id
	WHERE eventId='333') X
WHERE best=letterBest
ORDER BY best
LIMIT 40

--3x3 single by last name letter:
SELECT nameLetter, personId, name, 
	CASE 
	WHEN eventId='333mbf' THEN CONCAT(99-LEFT(best,2)+RIGHT(best,2),'/',99-LEFT(best,2)+2*RIGHT(best,2), ' ', TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM (SUBSTRING(SEC_TO_TIME(SUBSTRING(best,4,4)),2,10))))))))
	WHEN eventId='333fm' THEN best
	ELSE TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM (SUBSTRING(SEC_TO_TIME(best/100),2,10)))))))
	END 'single'
FROM
	(SELECT 
	SUBSTRING((CASE
		WHEN SUBSTRING(REVERSE(name),1,1)=')' THEN REVERSE(SUBSTRING_INDEX(REVERSE(SUBSTRING_INDEX(name,'(',1)),' ',2))
		WHEN name NOT LIKE '% %' THEN name
		ELSE REVERSE(SUBSTRING_INDEX(REVERSE(name),' ',1))
		END),1,1) 'nameLetter',
	personId, name, eventId, best,
		(MIN(best) OVER (PARTITION BY SUBSTRING((CASE
			WHEN SUBSTRING(REVERSE(name),1,1)=')' THEN REVERSE(SUBSTRING_INDEX(REVERSE(SUBSTRING_INDEX(name,'(',1)),' ',2))
			WHEN name NOT LIKE '% %' THEN name
			ELSE REVERSE(SUBSTRING_INDEX(REVERSE(name),' ',1))
			END),1,1))) 'letterBest'
	FROM RanksSingle r
	JOIN Persons p ON r.personId=p.id
	WHERE eventId='333') X
WHERE best=letterBest
ORDER BY best
LIMIT 40



--Competitors in organized competitions:
SELECT u.name, COUNT(*) AS 'competitors', COUNT(DISTINCT personId) AS 'distinct_competitors', COUNT(DISTINCT competition_id) AS 'comps_organized'
FROM `competition_organizers` c JOIN users u ON c.organizer_id=u.id
JOIN (SELECT DISTINCT personId, competitionId FROM Results) x
ON c.competition_id=x.competitionId
GROUP BY organizer_id
ORDER BY 2 DESC

--Competitors and organizers in competitions:
SELECT competition_id, COUNT(DISTINCT personId) 'competitors', COUNT(DISTINCT organizer_id) 'organizers'
FROM `competition_organizers` c JOIN users u ON c.organizer_id=u.id
JOIN (SELECT DISTINCT personId, competitionId FROM Results) x
ON c.competition_id=x.competitionId
GROUP BY competition_id
ORDER BY 2 DESC


--Format results (requires fields 'eventId' and 'best'):
CASE 
	WHEN eventId='333mbf' THEN CONCAT(99-LEFT(best,2)+RIGHT(best,2),'/',99-LEFT(best,2)+2*RIGHT(best,2), ' ', TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM (SUBSTRING(SEC_TO_TIME(SUBSTRING(best,4,4)),2,10))))))))
	WHEN eventId='333fm' THEN best
	ELSE TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM (SUBSTRING(SEC_TO_TIME(best/100),2,10)))))))
END



--Every name has same initial:
SELECT first AS 'letter', COUNT(*) AS 'number' FROM
	(SELECT *, 
	IF(names>2, SUBSTRING(REVERSE(SUBSTRING_INDEX(REVERSE(SUBSTRING_INDEX(name,' ',2)),' ',1)),1,1), first) AS 'second',
	IF(names>3, SUBSTRING(REVERSE(SUBSTRING_INDEX(REVERSE(SUBSTRING_INDEX(name,' ',3)),' ',1)),1,1), first) AS 'third' FROM
		(SELECT id, name, LENGTH(name)-LENGTH(REPLACE(name,' ',''))+1 AS 'names', first, last FROM
			(SELECT id, TRIM(TRAILING ' ' FROM SUBSTRING_INDEX(name, '(', 1)) AS 'name',
			SUBSTRING(name,1,1) AS 'first',
			SUBSTRING(IF(SUBSTRING(REVERSE(name),1,1)=')', REVERSE(SUBSTRING_INDEX(REVERSE(SUBSTRING_INDEX(name,'(',1)),' ',2)), REVERSE(SUBSTRING_INDEX(REVERSE(name),' ',1))), 1, 1) AS 'last'
			FROM `Persons`) x
		) y
	WHERE names>1 AND names<5 AND first=last
	HAVING second=third AND first=second) z
GROUP BY 1 ORDER BY 2 DESC
LIMIT 30

--Worst results ever:
SELECT personId, personName, eventId, (CASE 
	WHEN eventId='333mbf' THEN CONCAT(99-LEFT(best,2)+RIGHT(best,2),'/',99-LEFT(best,2)+2*RIGHT(best,2), ' ', TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM (SUBSTRING(SEC_TO_TIME(SUBSTRING(best,4,4)),2,10))))))))
	WHEN eventId='333fm' THEN best
	ELSE TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM TRIM(LEADING ':' FROM TRIM(LEADING '0' FROM (SUBSTRING(SEC_TO_TIME(best/100),2,10)))))))
END) AS result FROM (SELECT * FROM (SELECT personId, personName, eventId, value1, value2, value3, value4, value5, 
(MAX(CASE WHEN value1>=value2 AND value1>=value3 AND value1>=value4 AND value1>=value5 THEN value1
WHEN value2>=value1 AND value2>=value3 AND value2>=value4 AND value2>=value5 THEN value2
WHEN value3>=value2 AND value3>=value1 AND value3>=value4 AND value3>=value5 THEN value3
WHEN value4>=value2 AND value4>=value3 AND value4>=value1 AND value4>=value5 THEN value4
WHEN value5>=value2 AND value5>=value3 AND value5>=value4 AND value5=value1 THEN value5 END) OVER (partition by eventId)) AS best FROM `Results`) A
WHERE best IN (value1, value2, value3, value4, value5)) B

--Show event and round counts at once:
SELECT r1.competitionId, r1.eventId, A.competition_event_id, A.rounds_number_of_rounds, r1.results_number_of_rounds, r2.rounds_number_of_events, r3.results_number_of_events FROM
(SELECT competition_id, event_id, competition_event_id, COUNT(*) AS rounds_number_of_rounds
	FROM competition_events ce
    INNER JOIN rounds r ON ce.id=r.competition_event_id
    GROUP BY competition_event_id) A
RIGHT JOIN (SELECT competitionId, eventId, COUNT(*) AS results_number_of_rounds FROM (SELECT DISTINCT competitionId, eventId, roundTypeId FROM Results) results_rounds GROUP BY competitionId, eventId) r1
ON A.competition_id=r1.competitionId AND A.event_id=r1.eventId
LEFT JOIN (SELECT competition_id, COUNT(*) AS rounds_number_of_events FROM competition_events GROUP BY competition_id) r2 
ON r1.competitionId=r2.competition_id
INNER JOIN (SELECT competitionId, COUNT(*) AS results_number_of_events FROM (SELECT DISTINCT competitionId, eventId FROM Results) results_events GROUP BY competitionId) r3
ON r1.competitionId=r3.competitionId

--Organizers not registered:
SELECT competition_id, announced_at, organizer_id, wca_id, users.name FROM competition_organizers co
JOIN Competitions c ON co.competition_id = c.id
LEFT JOIN users ON co.organizer_id = users.id
	WHERE announced_at is not NULL AND use_wca_registration = 1 AND DATEDIFF(registration_close, NOW()) <= 0 AND cancelled_at is NULL
AND CONCAT(competition_id, organizer_id) NOT IN (SELECT CONCAT(competition_id, user_id) FROM registrations)
AND CONCAT(competition_id, IFNULL(wca_id, 0)) NOT IN (SELECT DISTINCT CONCAT(competitionId, personId) FROM Results)
ORDER BY 2 desc
LIMIT 2000

--Percentage of competitors from abroad:
SELECT id CompetitionId, 
	countryId CompetitionCountry, 
	IFNULL(sameC,0) SameCountryCompetitors, 
    IFNULL(diffC,0) DifferentCountryCompetitors, 
    CONCAT(100*IFNULL(diffC,0)/(IFNULL(sameC,0)+IFNULL(diffC,0)), " %") ForeignPercentage
FROM Competitions c
LEFT JOIN
	(SELECT competitionId, COUNT(DISTINCT personId) sameC
	FROM (SELECT DISTINCT competitionId, personId, countryId FROM Results) r1
	JOIN Competitions c1 ON r1.competitionId = c1.id
	WHERE r1.countryId = c1.countryId
	GROUP BY competitionId) same
		ON c.id = same.competitionId
LEFT JOIN
	(SELECT competitionId, COUNT(DISTINCT personId) diffC
	FROM (SELECT DISTINCT competitionId, personId, countryId FROM Results) r2
	JOIN Competitions c2 ON r2.competitionId = c2.id
	WHERE r2.countryId <> c2.countryId
	GROUP BY competitionId) diff
		ON c.id = diff.competitionId
WHERE results_posted_at IS NOT NULL
AND countryId NOT LIKE 'X_'
ORDER BY IFNULL(diffC,0)/(IFNULL(sameC,0)+IFNULL(diffC,0)) DESC, diffC DESC, sameC
