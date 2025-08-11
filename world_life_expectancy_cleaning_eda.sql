-- World Life Expectancy -- Data Cleaning and EDA
/*
Project: World Life Expectancy — Data Cleaning & EDA
Goal: Clean and prepare the World Life Expectancy dataset by removing duplicates,
      handling missing values, and correcting inconsistencies to ensure data quality.
      Perform exploratory data analysis (EDA) to identify trends and relationships
      between life expectancy and factors such as GDP, BMI, and adult mortality
      across different countries and years.
*/


############ DATA CLEANING

SELECT * 
FROM World_Life_Expectancy.world_life_expectancy;


########## 1. Removing Duplicate Records

-- Identify duplicates based on the combination of Country and Year.
SELECT country, year, CONCAT(country, year), COUNT(CONCAT(country, year))
FROM world_life_expectancy
GROUP BY country, year, CONCAT(country, year) 
HAVING COUNT(CONCAT(country, year)) > 1;

-- The CONCAT of Country and Year should be unique for each record. 
-- If the COUNT value is 2 or more, it indicates duplicate records.
-- Example: Ireland 2022, Senegal 2009, and Zimbabwe 2019 have duplicates.
-- Next, we identify their Row_IDs so we can delete them.

SELECT * 
FROM (
    SELECT Row_ID,
           CONCAT(country, year),
           ROW_NUMBER() OVER (PARTITION BY CONCAT(country, year) ORDER BY CONCAT(country, year)) AS Row_Num
    FROM world_life_expectancy
) AS Row_Table 
WHERE Row_Num > 1;

-- We use a subquery here because WHERE is evaluated before the ROW_NUMBER() function is applied.
-- This gives us the Row_IDs of duplicate rows (Row_Num > 1), which we can then remove.

DELETE FROM world_life_expectancy
WHERE Row_ID IN (
    SELECT Row_ID 
    FROM (
        SELECT Row_ID,
               CONCAT(country, year),
               ROW_NUMBER() OVER (PARTITION BY CONCAT(country, year) ORDER BY CONCAT(country, year)) AS Row_Num
        FROM world_life_expectancy
    ) AS Row_Table 
    WHERE Row_Num > 1
);


########## 2. Handling Missing Data in the Status Column

-- Identify rows with missing Status values.
SELECT * 
FROM world_life_expectancy
WHERE Status = '';

-- The Status should match other rows from the same country in different years.
-- We check the distinct values in the column.

SELECT DISTINCT Status
FROM world_life_expectancy
WHERE Status <> '';

-- The dataset contains only two possible statuses: 'Developing' and 'Developed'.
-- We fill missing Status values by matching them with another record from the same country.

-- Fill missing Status values with 'Developing'.
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.country = t2.country
SET t1.Status = 'Developing' 
WHERE t1.Status = ''
  AND t2.Status <> ''
  AND t2.Status = 'Developing';

-- Fill missing Status values with 'Developed'.
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.country = t2.country
SET t1.Status = 'Developed' 
WHERE t1.Status = ''
  AND t2.Status <> ''
  AND t2.Status = 'Developed';

-- Logic: For any row where Status is missing, look for another row from the same country 
-- that has a non-empty Status. If that value is 'Developing' (or 'Developed'), update accordingly.


########## Handling Missing Data in the LifeExpectancy Column

-- Identify missing LifeExpectancy values.
SELECT * 
FROM world_life_expectancy
WHERE Lifeexpectancy = '';

-- Example check for a specific country.
SELECT * 
FROM world_life_expectancy
WHERE Country = 'Afghanistan';

-- Observation: Life expectancy typically increases year by year.
-- For missing values, we can take the average of the year before and the year after.

-- Build a reference table to calculate averages for missing years.
SELECT t1.Country, t1.Year, t1.Lifeexpectancy, 
       t2.Country, t2.Year, t2.Lifeexpectancy, 
       t3.Country, t3.Year, t3.Lifeexpectancy,
       ROUND((t2.Lifeexpectancy + t3.Lifeexpectancy) / 2, 1) AS Average
FROM world_life_expectancy t1
JOIN world_life_expectancy t2 
    ON t1.Country = t2.Country 
    AND t1.Year = t2.Year - 1 
JOIN world_life_expectancy t3 
    ON t1.Country = t3.Country 
    AND t1.Year = t3.Year + 1 
WHERE t1.Lifeexpectancy = '';

-- Update missing LifeExpectancy values with the calculated average.
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2 
    ON t1.Country = t2.Country 
    AND t1.Year = t2.Year - 1 
JOIN world_life_expectancy t3 
    ON t1.Country = t3.Country 
    AND t1.Year = t3.Year + 1 
SET t1.Lifeexpectancy = ROUND((t2.Lifeexpectancy + t3.Lifeexpectancy) / 2, 1)
WHERE t1.Lifeexpectancy = '';

-- After running the update, the following query should return zero rows.
SELECT * 
FROM world_life_expectancy
WHERE Lifeexpectancy = '';


#### Exploratory Data Analysis (EDA)

-- 1. Life expectancy changes over 15 years.
SELECT Country, MIN(Lifeexpectancy), MAX(Lifeexpectancy)
FROM world_life_expectancy
GROUP BY Country
ORDER BY Country DESC;

-- Some countries have min or max values of zero (data quality issue).
-- Filter out those countries.
SELECT Country, 
       MIN(Lifeexpectancy), 
       MAX(Lifeexpectancy)
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(Lifeexpectancy) <> 0
   AND MAX(Lifeexpectancy) <> 0
ORDER BY Country DESC;

-- Find countries with the largest increase in life expectancy.
SELECT Country, 
       MIN(Lifeexpectancy), 
       MAX(Lifeexpectancy),
       ROUND(MAX(Lifeexpectancy) - MIN(Lifeexpectancy), 1) AS Life_Increase_15_Years
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(Lifeexpectancy) <> 0
   AND MAX(Lifeexpectancy) <> 0
ORDER BY Life_Increase_15_Years DESC;


-- 2. Average life expectancy by year (all countries).
SELECT Year, ROUND(AVG(Lifeexpectancy), 2)
FROM world_life_expectancy
WHERE Lifeexpectancy <> 0
GROUP BY Year
ORDER BY Year;


-- 3. Correlation between Life Expectancy and GDP.
SELECT Country, ROUND(AVG(Lifeexpectancy), 1) AS Life_Exp, ROUND(AVG(GDP), 1) AS GDP
FROM world_life_expectancy
GROUP BY Country;

-- Filter out rows where GDP or LifeExpectancy are zero.
SELECT Country, ROUND(AVG(Lifeexpectancy), 1) AS Life_Exp, ROUND(AVG(GDP), 1) AS GDP
FROM world_life_expectancy
WHERE GDP > 0
  AND Lifeexpectancy > 0 
GROUP BY Country
ORDER BY GDP ASC;

-- Observation: Countries with higher GDP tend to have higher Life Expectancy.
-- Example: Switzerland, Luxembourg, Qatar have ~20 years higher life expectancy than low-GDP countries.


-- 4. Categorizing GDP and comparing Life Expectancy.
-- Here, we use GDP = 1500 as an approximate threshold.
SELECT 
    SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) AS High_GDP_Count,
    AVG(CASE WHEN GDP >= 1500 THEN Lifeexpectancy ELSE NULL END) AS High_GDP_Lifeexpectancy,
    SUM(CASE WHEN GDP <= 1500 THEN 1 ELSE 0 END) AS Low_GDP_Count,
    AVG(CASE WHEN GDP <= 1500 THEN Lifeexpectancy ELSE NULL END) AS Low_GDP_Lifeexpectancy
FROM world_life_expectancy;

-- This shows a strong positive correlation between GDP and Life Expectancy.


-- 5. Comparing Life Expectancy by Status.
SELECT Status, ROUND(AVG(Lifeexpectancy), 1)
FROM world_life_expectancy
GROUP BY Status;

SELECT Status, COUNT(DISTINCT Country), ROUND(AVG(Lifeexpectancy), 1)
FROM world_life_expectancy
GROUP BY Status;

-- Developed countries have higher Life Expectancy on average, 
-- but since there are fewer of them, the average should be interpreted carefully.


-- 6. Correlation between BMI and Life Expectancy.
SELECT Country, ROUND(AVG(Lifeexpectancy), 1) AS Life_Exp, ROUND(AVG(BMI), 1) AS BMI
FROM world_life_expectancy
WHERE BMI > 0
  AND Lifeexpectancy > 0 
GROUP BY Country
ORDER BY BMI DESC;

-- Higher BMI seems to correlate with higher Life Expectancy,
-- but this might be due to wealthier countries having higher BMI and better healthcare.


-- 7. Adult Mortality trends (rolling total).
SELECT Country,
       Year, 
       Lifeexpectancy,
       AdultMortality,
       SUM(AdultMortality) OVER (PARTITION BY Country ORDER BY Year) AS Rolling_Total
FROM world_life_expectancy;
