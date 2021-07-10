CREATE TABLE langdata (
city VARCHAR(30),
language VARCHAR(30),
gender VARCHAR(30),
year VARCHAR(10),
people VARCHAR(10),
PRIMARY KEY (city, language, gender, year));

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/013_11rm_2020_20210704-152525.csv'
INTO TABLE langdata
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

UPDATE langdata
	SET city = REPLACE(city, '"', '');
UPDATE langdata
	SET language = REPLACE(language, '"', '');
UPDATE langdata
	SET gender = REPLACE(gender, '"', '');
UPDATE langdata
	SET year = REPLACE(year, '"', '');
UPDATE langdata
	SET people = REPLACE(people, '"', '');
UPDATE langdata
	SET people = NULL WHERE people LIKE '%...%';

ALTER TABLE langdata MODIFY people MEDIUMINT;


# Dataset to export:
SELECT city, year, SUM(people) total FROM langdata
WHERE language IN ('KOTIMAISET KIELET YHTEENSÄ', 'VIERASKIELISET YHTEENSÄ') AND gender = 'Yhteensä'
GROUP BY 1, 2
ORDER BY IF(city = 'KOKO MAA', 0, 1), 1, 2
LIMIT 10000;

# I exported the result set to a csv and started working in Python