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

# I'm creating a temporary table that includes every street only once. Whenever the zip code and the street names match, I know it's a duplicate so I'm assigning row numbers and including only those with row number 1.
CREATE TEMPORARY TABLE addressData2 AS 
(WITH address_distinct AS 
	(SELECT *,  
		IF(apt_type = 0, 0, 1) has_apartments, 
		row_number() OVER (PARTITION by zip_code, street_fi, street_sv ORDER BY apt_type) rn 
	FROM addressdata) 
SELECT zip_code, region_fi, region_sv, street_fi, street_sv, has_apartments, city_fi, city_sv 
FROM address_distinct 
WHERE rn = 1);
# 253178 row(s) affected Records: 253178  Duplicates: 0  Warnings: 0



# Finding the most common street names 
SELECT street_fi streetName, COUNT(DISTINCT zip_code) total
FROM addressdata2
WHERE street_fi is not NULL 
	AND street_fi not LIKE 'PL %'
    AND street_fi <> 'Poste restante'
GROUP BY 1
ORDER BY 2 desc
LIMIT 100;

/* Results: 100 most common street names in Finland:
+----------------+-------+
| streetName     | total |
+----------------+-------+
| Rantatie       |   262 |
| Koulutie       |   196 |
| Kirkkotie      |   194 |
| Rinnetie       |   165 |
| Teollisuustie  |   163 |
| Kuusitie       |   159 |
| Myllytie       |   158 |
| Mäkitie        |   154 |
| Mäntytie       |   148 |
| Rantalantie    |   146 |
| Koivukuja      |   146 |
| Niemeläntie    |   143 |
| Peltotie       |   141 |
| Välitie        |   141 |
| Vanhatie       |   138 |
| Niementie      |   133 |
| Mäkeläntie     |   130 |
| Koivutie       |   130 |
| Pajatie        |   127 |
| Pappilantie    |   125 |
| Riihitie       |   124 |
| Heikkiläntie   |   123 |
| Aholantie      |   122 |
| Peltolantie    |   119 |
| Jokelantie     |   119 |
| Sepäntie       |   117 |
| Koivulantie    |   114 |
| Harjutie       |   112 |
| Asematie       |   109 |
| Taipaleentie   |   109 |
| Kuuselantie    |   107 |
| Rauhalantie    |   107 |
| Pihlajatie     |   107 |
| Opintie        |   104 |
| Ojalantie      |   104 |
| Hakalantie     |   103 |
| Hakatie        |   102 |
| Kangastie      |   101 |
| Puistotie      |    99 |
| Koskelantie    |    95 |
| Oikotie        |    95 |
| Pajutie        |    95 |
| Honkatie       |    95 |
| Mäntyläntie    |    94 |
| Kalliotie      |    94 |
| Koivuniementie |    93 |
| Koivistontie   |    93 |
| Seppäläntie    |    92 |
| Katajatie      |    92 |
| Anttilantie    |    92 |
| Niittytie      |    92 |
| Harjuntie      |    91 |
| Myllymäentie   |    90 |
| Metsolantie    |    89 |
| Rajalantie     |    89 |
| Alatie         |    88 |
| Rajatie        |    87 |
| Kivimäentie    |    87 |
| Korpelantie    |    86 |
| Kiviniementie  |    85 |
| Keskustie      |    85 |
| Mattilantie    |    85 |
| Urheilutie     |    85 |
| Rantakuja      |    84 |
| Kanervatie     |    82 |
| Haapatie       |    82 |
| Korventie      |    82 |
| Lehtolantie    |    81 |
| Toivolantie    |    81 |
| Jokitie        |    80 |
| Koivumäentie   |    79 |
| Harjulantie    |    79 |
| Metsätie       |    79 |
| Jussilantie    |    79 |
| Mäntykuja      |    78 |
| Leppätie       |    78 |
| Mikkolantie    |    78 |
| Kiveläntie     |    77 |
| Järvenpääntie  |    77 |
| Yrittäjäntie   |    74 |
| Mäkikuja       |    74 |
| Haapaniementie |    74 |
| Peräläntie     |    73 |
| Saarentie      |    73 |
| Männistöntie   |    72 |
| Purotie        |    72 |
| Palomäentie    |    71 |
| Mäntyniementie |    71 |
| Rinnekuja      |    71 |
| Koulukuja      |    70 |
| Uutelantie     |    70 |
| Koulukatu      |    70 |
| Koivurannantie |    70 |
| Kauppatie      |    70 |
| Joensuuntie    |    70 |
| Salmelantie    |    69 |
| Kiertotie      |    69 |
| Sahantie       |    69 |
| Lehtimäentie   |    68 |
| Saarelantie    |    68 |
+----------------+-------+
*/