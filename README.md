# World Life Expectancy – SQL Data Cleaning & Exploration

**Skills Used:** SQL (MySQL), Data Cleaning, Data Exploration, Window Functions, Joins, Aggregations, EDA, Data Quality Checks

This project was completed as the **capstone** of *Alex Freberg’s SQL course on AnalystBuilder*.  
It applies real-world data cleaning and exploratory analysis techniques to the **World Life Expectancy** dataset.  
The work focuses on identifying and correcting data quality issues, handling missing values, removing duplicates, and performing in-depth exploratory data analysis (EDA) to uncover trends and correlations.

---

## Key Steps

### 1. Data Quality Checks & Duplicate Removal
- Identified duplicate records using `GROUP BY` and `HAVING`.
- Applied `ROW_NUMBER()` with a self-join to isolate and remove duplicates.

### 2. Handling Missing Values
- Filled missing `Status` values (Developing / Developed) using matching records from the same country.
- Replaced missing `LifeExpectancy` values with the average of the previous and next year for that country.

### 3. Exploratory Data Analysis (EDA)
- Measured life expectancy changes over 15 years for each country.
- Analyzed GDP vs. Life Expectancy, showing a strong positive relationship.
- Compared Developed vs. Developing countries.
- Explored BMI and its relationship to Life Expectancy.
- Examined Adult Mortality trends with rolling totals.

---

## Insights
- Countries with higher GDP generally have a **~20-year advantage** in life expectancy over low-GDP countries.
- Developed countries have higher life expectancy on average, but the sample size is smaller than for developing countries.
- Higher BMI correlates with longer life expectancy, possibly due to wealth and better healthcare access.

---

## Repository Contents
- `world_life_expectancy_cleaning_eda.sql` → Complete SQL code with professional, detailed comments.
- `WorldLifeExpectancy.csv` → Original dataset.

---

## Next Steps
- Create visualizations in Tableau or Power BI to better illustrate trends.
- Apply statistical correlation testing to quantify relationships between variables.
