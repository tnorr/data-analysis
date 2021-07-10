# Data Analysis Demo Projects
This is a portfolio repository for compiling my data analysis projects.

## Project 1: WCA Competitor Growth

#### [Final Tableau dashboard](https://public.tableau.com/views/WCACompetitorGrowth/Dashboard1?:language=en-US&:display_count=n&:origin=viz_share_link)

I created visualizations of how the competitor base of [World Cube Association](https://www.worldcubeassociation.org/) (WCA) has grown over time. The final dashboard showcases 4 elements:
- The number of competitions sanctioned by the WCA each year
- The continuous growth in the number of distinct competitors that attended WCA competitions
- When was the first WCA competition in each country
- How many distinct competitors have competed in each country

The map visualizes how the WCA has expanded into new parts of the world. The charts show an exponential growth in the number of competitors and competitions, as well as the huge impact the COVID-19 pandemic had.

I've used two tables from the WCA database export (https://www.worldcubeassociation.org/results/misc/export.html):
- Competitions: 1 row for every competition, with information about the competition, such as the date and country
- Results: Includes every competitor's all competition results. This table was used to gain information about how many people attended each competition.

## Project 2: Population growth in Finland

In this project I used MySQL to clean data, as well as Python with pandas and matplotlib to handle dataframes and visualize data.


## Project 3: Statistics about street names in Finland

The source data for this project is the BAF_20210626.dat file from (https://www.posti.fi/fi/asiakastuki/postinumerotiedostot). The basis was to convert the .dat file to .csv, ensure the right character set to be compatible with MySQL, import the csv to MySQL and to perform data cleaning in MySQL. Code can be found [here](street-name-statistics/code.sql).

The final statistics:
- [The most common street names](street-name-statistics/most-common-street-names.csv) (includes those with 10 or more occurences)
- [Number of postal regions in each city](street-name-statistics/postal-regions-by-city.csv)
- [Distribution of street names by language in each city](street-name-statistics/street-names-by-language.csv) (this is to show how great percentage of streets have a Swedish name in every city)
