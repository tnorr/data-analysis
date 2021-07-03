CREATE TABLE osoitteisto (
data VARCHAR(256))
CHARACTER SET utf8mb4;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/BAF_20210626.csv'
INTO TABLE osoitteisto
LINES TERMINATED BY '\n'
;

# With the simple check below I found out that the import made 3 lines enclosed with double quotation marks.
SELECT left(data, 1), count(*) FROM osoitteisto GROUP BY 1;

# I'm cleaning those before moving on:
UPDATE osoitteisto
SET data = REPLACE(data, '"', '') WHERE LEFT(data, 1) = '"';
# 3 row(s) affected Rows matched: 3  Changed: 3  Warnings: 0


# Now I'll split the rows into columns. Different attributes have fixed starting indexes so this is fairly straightforward with substrings.
CREATE TABLE addressData AS (
SELECT 
	SUBSTRING(data, 14, 5) zip_code,
	RTRIM(SUBSTRING(data, 19, 30)) region_fi,
	RTRIM(SUBSTRING(data, 49, 30)) region_sv,
	RTRIM(SUBSTRING(data, 103, 30)) street_fi,
	RTRIM(SUBSTRING(data, 133, 30)) street_sv,
	CONVERT(SUBSTRING(data, 187, 1), unsigned) apt_type,
	REPLACE(SUBSTRING(data, 188, 12), ' ', '') aptNo_smallest,
	REPLACE(SUBSTRING(data, 201, 12), ' ', '') aptNo_greatest,
	RTRIM(SUBSTRING(data, 217, 20)) city_fi,
	RTRIM(SUBSTRING(data, 237, 20)) city_sv
FROM osoitteisto
ORDER BY 1 DESC);
# 404788 row(s) affected Records: 404788  Duplicates: 0  Warnings: 0

# Updating empty values to NULL
UPDATE addressdata SET 
	street_fi = NULL WHERE street_fi = '';
	# 7635 row(s) affected Rows matched: 7635  Changed: 7635  Warnings: 0
UPDATE addressdata 
	SET street_sv = NULL WHERE street_sv = '';
    # 349000 row(s) affected Rows matched: 349000  Changed: 349000  Warnings: 0
UPDATE addressdata
	SET aptNo_smallest = NULL WHERE aptNo_smallest = '';
    # 50488 row(s) affected Rows matched: 50488  Changed: 50488  Warnings: 0
UPDATE addressdata
	SET aptNo_greatest = NULL WHERE aptNo_greatest = '';
    # 132610 row(s) affected Rows matched: 132610  Changed: 132610  Warnings: 0

/*
I'm happy with the table layout now. Here is some example data:
+----------+-----------+-----------+-------------------+-----------+----------+----------------+----------------+-----------+-----------+
| zip_code | region_fi | region_sv | street_fi         | street_sv | apt_type | aptNo_smallest | aptNo_greatest | city_fi   | city_sv   |
+----------+-----------+-----------+-------------------+-----------+----------+----------------+----------------+-----------+-----------+
 |82980    | MÖHKÖ     | MÖHKÖ     | Hakorannantie     | NULL      |        1 | 1a             | 1d             | Ilomantsi | Ilomants
 |82980    | MÖHKÖ     | MÖHKÖ     | Sotkasenvaarantie | NULL      |        1 | 23             | NULL           | Ilomantsi | Ilomants
 |82980    | MÖHKÖ     | MÖHKÖ     | Sotkasenvaarantie | NULL      |        2 | 18             | NULL           | Ilomantsi | Ilomants
 |82980    | MÖHKÖ     | MÖHKÖ     | Piistiinvaarantie | NULL      |        2 | 2              | NULL           | Ilomantsi | Ilomants
 |82980    | MÖHKÖ     | MÖHKÖ     | Timonhiekantie    | NULL      |        1 | 11a            | NULL           | Ilomantsi | Ilomants
+----------+-----------+-----------+-------------------+-----------+----------+----------------+----------------+-----------+-----------+
*/

# I'm creating a table that includes every street only once. Whenever the zip code and the street names match, I know it's a duplicate so I'm assigning row numbers and including only those with row number 1.
CREATE TABLE addressData2 AS 
(WITH address_distinct AS 
	(SELECT *,  
		IF(apt_type = 0, 0, 1) has_apartments, 
		row_number() OVER (PARTITION by zip_code, street_fi, street_sv ORDER BY apt_type) rn 
	FROM addressdata) 
SELECT zip_code, region_fi, region_sv, street_fi, street_sv, has_apartments, city_fi, city_sv 
FROM address_distinct 
WHERE rn = 1);
# 253178 row(s) affected Records: 253178  Duplicates: 0  Warnings: 0



# Finding the most common street names / Yleisimmät kadunnimet
SELECT street_fi streetName, COUNT(DISTINCT zip_code) total
FROM addressdata2
WHERE street_fi is not NULL 
	AND street_fi not LIKE 'PL %'
    AND street_fi <> 'Poste restante'
GROUP BY 1
	HAVING total > 1
ORDER BY 2 desc
LIMIT 100000;

# Postal regions in every city / Postinumeroalueiden lukumäärä kunnittain:
SELECT city_fi, COUNT(distinct zip_code) postal_regions
FROM addressdata2
group by 1 order by 2 desc;


# Percentage of streets having a Swedish name in every city / Ruotsinkielisten kadunnimien osuus kaikista kunnan kaduista:
WITH streetsByLanguage AS
(SELECT city_fi,
	SUM(IF(street_fi is not null,
		IF(street_sv is null, 1, 0), 0)) only_finnish,
	SUM(IF(street_fi is not null,
		IF(street_sv is null, 0, 1), 0)) both_languages,
	SUM(IF(street_fi is null,
		IF(street_sv is null, 0, 1), 0)) only_swedish
FROM addressdata2
GROUP BY 1
)

SELECT *,
	CONCAT(100*(only_swedish+both_languages)/(only_finnish+both_languages+only_swedish), ' %') streetsHavingSwedishName
FROM streetsByLanguage
    ORDER BY (only_swedish+both_languages)/(only_finnish+both_languages+only_swedish) DESC;
