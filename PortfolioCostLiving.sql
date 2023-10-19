/*
Cost of Living - USA : Data Exploration 

Skills used: Joins, CTE's, Aggregate Functions, Converting Data Types, Case Statements, Windows Functions, Temp Tables, Creating Views,

*/


-- Exploring the Data
SELECT *
FROM PortfolioProject..Costs
SELECT *
FROM PortfolioProject..CountyPop

-- There are a lot of different family_member_count variables, for consistency we will assume 
--the national average of 3 people in a household with 2 of them earning income (2p1c)

-- Looking at Median Incomes and Population of counties 
-- There are a lot of different family_member_count variables, for consistency we will assume 
--the national average of 3 people in a household with 2 of them earning income (2p1c)
-- Using a ***JOIN*** to combine the two tables
SELECT Distinct(ID), state, county, median_family_income as income, population 
FROM PortfolioProject..Costs
Join PortfolioProject..CountyPop
ON Costs.area = CountyPop.Geography
WHERE family_member_count = '2p1c'
ORDER BY income 


-- Looking at Median Incomes over $100,000
SELECT Distinct(ID), isMetro, state, county, median_family_income as income
FROM PortfolioProject..Costs
Full Join PortfolioProject..CountyPop
ON Costs.area = CountyPop.Geography
WHERE family_member_count = '2p1c' AND median_family_income > 100000
ORDER BY income DESC


--Creating a ***CTE*** to summarize and sort data
--Using a CTE to see what percentage of income is estimated to spent just on housing by county
WITH CTE_CostOfLiving AS
(
SELECT Distinct(ID), state, county, housing, food, transportation, healthcare, childcare, other, taxes, total_cost as total_cost_of_living, median_family_income, population
FROM PortfolioProject..Costs
Full Join PortfolioProject..CountyPop
ON Costs.area = CountyPop.Geography
WHERE family_member_count = '2p1c'and Median_family_income is not NULL
)
SELECT state, county, housing, total_cost_of_living, (housing/total_cost_of_living)*100 as PercentageHousing 
FROM CTE_CostOfLiving
Order by PercentageHousing DESC


-- Looking at the average median income in each county compared to Population
-- Using ***AGGREGATE*** functions
SELECT state, county, population, AVG(median_family_income) as AvgIncome, AVG((median_family_income/population))*100 as AvgIncomePerPerson
FROM PortfolioProject..Costs
Join PortfolioProject..CountyPop
ON Costs.area = CountyPop.Geography
WHERE Population is not null
Group By state, county, population
Order by AvgIncomePerPerson DESC


-- Comparing incomes in areas that are considered METRO(urban areas) or suburban
-- ***CONVERTING DATA TYPE*** and using a ***CASE STATEMENT*** to clarify table column
SELECT Distinct(ID), state, county, cast(isMetro as int) as METRO, AVG(median_family_income) as avg_family_income,
CASE
    WHEN isMetro = 1 THEN 'YES'
    ELSE 'NO'
END AS City
FROM PortfolioProject..Costs
Full Join PortfolioProject..CountyPop
ON Costs.area = CountyPop.Geography
WHERE ID is not null
Group By ID, state, county, isMetro, median_family_income
Order by avg_family_income DESC


-- USING ***PARTITION*** to compare average yearly costs by state
SELECT Distinct(state), 
	AVG(food) OVER(PARTITION BY state) as AvgFoodCost,
	Avg(housing) OVER(PARTITION BY state) as AvgHousingCost,
	AVG(transportation) OVER(PARTITION BY state) as AvgTransportCost,
	AVG(healthcare) OVER(PARTITION BY state) as AvgHealthCost,
	Avg(childcare) OVER(PARTITION BY state) as AvgChildcareCost,
	AVG(other) OVER(PARTITION BY state) as AvgMiscCost,	
	AVG(taxes) OVER(PARTITION BY state) as AvgTaxes,
	AVG(total_cost) OVER(PARTITION BY state) as AvgTotalCosts
FROM PortfolioProject..Costs
ORDER BY AvgTotalCosts


-- Using CTE to perform Calculation on Partition By in previous query
-- Comparing the Percentage of Food Cost within the Total Cost
With CTE_Average_Costs
as
(
SELECT Distinct(state),
	AVG(food) OVER(PARTITION BY state) as AvgFoodCost,
	Avg(housing) OVER(PARTITION BY state) as AvgHousingCost,
	AVG(transportation) OVER(PARTITION BY state) as AvgTransportCost,
	AVG(healthcare) OVER(PARTITION BY state) as AvgHealthCost,
	Avg(childcare) OVER(PARTITION BY state) as AvgChildcareCost,
	AVG(other) OVER(PARTITION BY state) as AvgMiscCost,	
	AVG(taxes) OVER(PARTITION BY state) as AvgTaxes,
	AVG(total_cost) OVER(PARTITION BY state) as AvgTotalCosts
FROM PortfolioProject..Costs
)
Select State, AvgHousingCost, AvgTotalCosts, (AvgHousingCost/AvgTotalCosts)*100 as PercentHousing
From CTE_Average_Costs
ORDER BY PercentHousing DESC


-- Using ***TEMP TABLE*** Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentofTotalCosts
Create Table #PercentofTotalCosts
(
State varchar (2),
AvgHousingCost numeric,
AvgTaxes numeric,
AvgTotalCosts numeric
)

Insert into #PercentofTotalCosts
SELECT Distinct(PPCosts.State), 
	Avg(housing) OVER(PARTITION BY state) as AvgHousingCost,
	AVG(taxes) OVER(PARTITION BY state) as AvgTaxes,
	AVG(total_cost) OVER(PARTITION BY state) as AvgTotalCosts
FROM PortfolioProject..Costs as PPCosts

Select *, (AvgTaxes/AvgTotalCosts)*100 as PercentTaxes
From #PercentofTotalCosts
ORDER BY PercentTaxes


-- Creating a ***VIEW*** of all Average Costs to store data for later visualizations
Create View PercentTotalCosts as
SELECT Distinct(state),
	AVG(food) OVER(PARTITION BY state) as AvgFoodCost,
	Avg(housing) OVER(PARTITION BY state) as AvgHousingCost,
	AVG(transportation) OVER(PARTITION BY state) as AvgTransportCost,
	AVG(healthcare) OVER(PARTITION BY state) as AvgHealthCost,
	Avg(childcare) OVER(PARTITION BY state) as AvgChildcareCost,
	AVG(other) OVER(PARTITION BY state) as AvgMiscCost,	
	AVG(taxes) OVER(PARTITION BY state) as AvgTaxes,
	AVG(total_cost) OVER(PARTITION BY state) as AvgTotalCosts
FROM PortfolioProject..Costs

--Checking the new view
SELECT * 
From PercentTotalCosts