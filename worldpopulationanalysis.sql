CREATE DATABASE worldpopulation;

USE worldpopulation;

DESCRIBE pop_data;
SELECT * FROM pop_data;


ALTER TABLE pop_data 
RENAME COLUMN cca2 TO country_code;


#Checking for Duplicates

SELECT * FROM
( 
SELECT *,
ROW_NUMBER() OVER(PARTITION BY country ORDER BY country)
AS row_num 
FROM pop_data
)X
WHERE row_num>1;
/*The Query Didn't returned any row Therefore there is no 
Duplicate country in the Dataset*/




/*Checking  % Increase In population From 
 Previous Population census */
WITH CTE1 AS
(
SELECT country, country_code, '1980' AS year, pop1980 AS population FROM pop_data 
UNION
SELECT country, country_code, '2000' AS population, pop2000 AS population FROM pop_data 
UNION
SELECT country, country_code, '2010' AS population, pop2010 AS population FROM pop_data 
UNION
SELECT country, country_code, '2022' AS population, 
pop2022 AS population FROM pop_data),

CTE2 AS
(
SELECT country, country_code, year,
LAG(year,1,0) OVER (PARTITION BY country ORDER BY year  ASC) AS previous_yr, population ,
LAG(population,1,0) OVER (PARTITION BY country ORDER BY year  ASC) AS previous_yr_pop
FROM CTE1 ORDER BY country
 )
 
SELECT *,
CONCAT(
ROUND(IFNULL(((population-previous_yr_pop)*100.0/previous_yr_pop),""),2),
       " % Increase/Decrease from year ",previous_yr
	  )
AS population_growth
FROM CTE2;





/*Top 3 Countries With Highest Population In
1980, 2000, 2010, 2022 */

WITH CTE1 AS 
(SELECT '2022' AS year, country AS Top3_Most_Populated_country,
 pop2022 AS population 
FROM pop_data 
ORDER BY pop2022 DESC LIMIT 3),

CTE2 AS
(SELECT '2010' AS year, country AS Top3_Most_Populated_country, 
pop2010 AS population 
 FROM pop_data 
 ORDER BY pop2010 DESC LIMIT 3),

 CTE3 AS
(SELECT '2000' AS year, country AS Top3_Most_Populated_country,
 pop2000 AS population
FROM pop_data 
ORDER BY pop2000 DESC LIMIT 3),

CTE4 AS
(SELECT '1980' AS year, country AS Top3_Most_Populated_country,
 pop1980 AS population
FROM pop_data 
ORDER BY pop1980 DESC LIMIT 3)

SELECT * FROM CTE1 
UNION 
SELECT * FROM CTE2
UNION
SELECT * FROM CTE3
UNION
SELECT * FROM CTE4;





#Showing World's Population In All Population Census Years

SELECT "World",
SUM(pop1980) as `population (in 1980)`,
SUM(pop2000) as `population (in 2000)`,
SUM(pop2010) as `population (in 2010)`,
SUM(pop2022) as `population (in 2022)`
FROM pop_data;





/*Showing Growth Rate Of World Population In Each Census Year*/

WITH CTE AS 
(SELECT 
SUM(pop1980) as pop_1980,
SUM(pop2000) as pop_2000,
SUM(pop2010) as pop_2010,
SUM(pop2022) as pop_2022
FROM pop_data),
CTE2 AS(
SELECT "2022" AS year, pop_2022 AS population FROM CTE UNION
SELECT "2000" AS year, pop_2000 AS population FROM CTE UNION
SELECT "2010" AS year, pop_2010 AS population FROM CTE UNION
SELECT "1980" AS year, pop_1980 AS population FROM CTE),
CTE3 AS(
SELECT *,LEAD(population,1,0) OVER(ORDER BY year DESC) AS previous_yr_pop
FROM CTE2)

SELECT *,
CONCAT(ROUND((population-previous_yr_pop)*100.0/previous_yr_pop,2)," % Increase") 
AS growth_rate
FROM CTE3;





#Showing Population Density of All countries Over All Census Years

SELECT country, country_code,
ROUND(pop1980/landAreaKm,2) as Density_1980,
ROUND(pop2000/landAreaKm,2) as Density_2000,
ROUND(pop2010/landAreaKm,2) as Density_2010,
ROUND(pop2022/landAreaKm,2) as Density_2022
FROM pop_data;





#Predicting Growth Rate in 2030,2050 from 2022 

WITH CTE AS(SELECT country, pop2022, pop2030, pop2050, 
ROUND((pop2030-pop2022)*100.0/pop2022,2) AS growth_rate_by2030 ,
ROUND((pop2050-pop2022)*100.0/pop2022,2) AS growth_rate_by2050 
FROM pop_data)

SELECT country, pop2022, pop2030, pop2050, 
CASE 
WHEN growth_rate_by2030>0 
THEN concat('+',growth_rate_by2030,'%')
ELSE concat(growth_rate_by2030,'%') 
END as Growth_Rate2030,
CASE
WHEN growth_rate_by2050>0 
THEN concat('+',growth_rate_by2050,'%')
ELSE concat(growth_rate_by2050,'%') 
END as growth_rate2050
FROM CTE;





#Showing  Countries With Rapid Growth in years from 1980 to 2022
SELECT country,pop1980,pop2022,
ROUND(100.0*(pop2022-pop1980)/pop1980,2) AS `growth_rate (in %)`
FROM pop_data
ORDER BY `growth_rate (in %)` DESC;





#Showing countries with Population Decline in years from 1980-2022

SELECT * FROM
(
SELECT country,pop1980,pop2022,
ROUND(100.0*(pop2022-pop1980)/pop1980,2) AS `growth_rate (in %)`
FROM pop_data
ORDER BY `growth_rate (in %)`ASC
)X
WHERE `growth_rate (in %)`<0;





#Showing Top 10 Countries Which are Expected to Grow Rapidly by 2050
with CTE AS
(
SELECT country, pop2022, pop2050,
ROUND((pop2050-pop2022)*100.0/pop2022,2) AS `growth_by_2050 (in %)` 
FROM pop_data
)

SELECT * FROM CTE 
WHERE `growth_by_2050 (in %)` >0
ORDER BY `growth_by_2050 (in %)`DESC LIMIT 10;





#Showing Top 10 Countries Which are Expected to Decline Rapidly by 2050
WITH CTE AS
(
SELECT country, pop2022, pop2050,
ROUND((pop2050-pop2022)*100.0/pop2022,2) AS `growth_by_2050 (in %)` 
FROM pop_data
)

SELECT * FROM CTE 
WHERE `growth_by_2050 (in %)` <0
ORDER BY `growth_by_2050 (in %)` LIMIT 10;



/*Showing the Population Estimation of 3 Most Populous Country By 2030 & 2050
i.e. China, India, US */

WITH CTE AS(SELECT country, pop2022, pop2030, pop2050, 
ROUND((pop2030-pop2022)*100.0/pop2022,2) AS growth_rate_by2030 ,
ROUND((pop2050-pop2022)*100.0/pop2022,2) AS growth_rate_by2050 
FROM pop_data
WHERE country_code IN ('IN','CN','US'))

SELECT country, pop2022, pop2030, pop2050, 
CASE 
WHEN growth_rate_by2030>0 
THEN concat('+',growth_rate_by2030,'%')
ELSE concat(growth_rate_by2030,'%') 
END as Growth_Rate2030,
CASE
WHEN growth_rate_by2050>0 
THEN concat('+',growth_rate_by2050,'%')
ELSE concat(growth_rate_by2050,'%') 
END as growth_rate2050
FROM CTE;





#Showing 5 Most Populous Expected Countries By 2050
SELECT country, country_code, pop2050 AS population
FROM pop_data 
ORDER BY pop2050 DESC LIMIT 5;



#Showing 10 Most Populous Countries In 2022
SELECT country, country_code, pop2022 AS population
FROM pop_data 
ORDER BY pop2022 DESC LIMIT 10;




#Expected Population Of World By 2030 & 2050
SELECT "world", SUM(pop2022) AS`Population (in 2022)`, SUM(pop2030) AS`Population (in 2030)`, 
SUM(pop2050) AS `Population (in 2050)`, 
CONCAT(ROUND(100.0*(SUM(pop2030)-SUM(pop2022))/SUM(pop2022),2),'%') AS growthby2030,
CONCAT(ROUND(100.0*(SUM(pop2050)-SUM(pop2022))/SUM(pop2022),2),'%') AS growthby2050
FROM pop_data ;