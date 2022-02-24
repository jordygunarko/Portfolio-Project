--Overview of the tables that are being used

SELECT *
FROM
  PortfolioProject.dbo.CovidDeaths
ORDER BY 3,4

SELECT *
FROM
  PortfolioProject.dbo.CovidVaccinations
ORDER BY 3,4

--Preview the data that we are going to be using

SELECT
  Location, date, total_cases, new_cases, total_deaths, population
FROM
  PortfolioProject.dbo.CovidDeaths
ORDER BY
  Location, date

-- Total Cases vs Total Deaths
-- Looking at how many cases and deaths are, and the death rate percentage from the total of cases
-- Shows the probability of dying if a person contracts COVID generally

SELECT
  Location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS death_percentage
FROM
  PortfolioProject.dbo.CovidDeaths
ORDER BY
  Location, date

-- Looking at how many cases and deaths are in Indonesia, and the death rate percentage from the total of cases

SELECT
  Location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS death_percentage
FROM
  PortfolioProject.dbo.CovidDeaths
WHERE
  Location = 'Indonesia'
ORDER BY 
  date

-- Looking at Total Cases vs Population
-- Shows percentage of the population that contracted COVID in Indonesia

SELECT
  Location, date, total_cases, population, ((total_cases/population)*100) AS infection_rate
FROM
  PortfolioProject.dbo.CovidDeaths
WHERE
  Location = 'Indonesia'
ORDER BY 
  date

-- Looking at Countries with the highest infection rate, compared with population

SELECT
  Location, population, MAX(total_cases) AS highest_infection_count, MAX (((total_cases/population)*100)) AS infection_rate
FROM
  PortfolioProject.dbo.CovidDeaths
GROUP BY
  Location, population
ORDER BY
  infection_rate DESC

-- Looking at individual Countries where it has the highest death count, compared with population

-- If the continent is not null, the location used is going to be an individual country within that continent, so we can filter using the WHERE statement
-- This will exclude whole continents and groupings of countries

SELECT
  Location, population, MAX(CAST(total_deaths as bigint)) AS death_count
FROM
  PortfolioProject.dbo.CovidDeaths
WHERE
  continent is not null
GROUP BY
  Location, population
ORDER BY
  death_count DESC

--Looking at Continents where it has the highest death count, compared with population

--If the continent is null, the location used is going to be the whole continent, so we can filter using the WHERE statement
--The table groups different incomes in the 'location' column, so we're also excluding it using the NOT LIKE statement
--'World', 'International' is not a continent, and 'European Union' is a part of the 'Europe' continent. We're excluding these using the NOT IN statement

SELECT
  location, population, MAX(CAST(total_deaths as bigint)) AS death_count
FROM
  PortfolioProject.dbo.CovidDeaths
WHERE
  continent is null
  AND location NOT LIKE '%income%'
  AND location NOT IN ('World', 'European Union', 'International')
GROUP BY
  location, population
ORDER BY
  death_count DESC


-- Global Numbers
-- Since we have rows that are showing stats for individual countries AND continents, we're excluding continent numbers in order to not calculate it twice

SELECT
  SUM(new_cases) AS total_cases, SUM(cast(new_deaths as bigint)) AS total_deaths, SUM(cast(new_deaths as bigint)) / SUM(new_cases) * 100 AS death_percentage
FROM
  PortfolioProject.dbo.CovidDeaths
WHERE
  continent is not null

-- Grouping it by date, showing the stats on particular dates

SELECT
  date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as bigint)) AS total_deaths, SUM(cast(new_deaths as bigint)) / SUM(new_cases) * 100 AS death_percentage
FROM
  PortfolioProject.dbo.CovidDeaths
WHERE
  continent is not null
GROUP BY
  date
ORDER BY 
  date

-- Total number of Vaccinations of each country's Population

SELECT
  de.continent, de.location, de.date, de.population, va.new_vaccinations, SUM(CAST(va.new_vaccinations AS bigint)) OVER (PARTITION BY de.Location ORDER BY de.location, de.date ROWS UNBOUNDED PRECEDING) AS rolling_count_people_vaccinated
FROM
  PortfolioProject.dbo.CovidDeaths AS de
JOIN
  PortfolioProject.dbo.CovidVaccinations AS va
  ON de.location = va.location
  AND de.date = va.date
WHERE
  de.continent is not null
ORDER BY 
  de.location, de.date

-- Showing the percentage of population that's vaccinated,
-- by using CTE to do further calculations on the newly created "rolling_count_people_vaccinated" column

WITH population_and_vaccination (continent, location, date, population, new_vaccinations, rolling_count_people_vaccinated) AS(

SELECT
  de.continent, de.location, de.date, de.population, va.new_vaccinations, SUM(CAST(va.new_vaccinations AS bigint)) OVER (PARTITION BY de.Location ORDER BY de.location, de.date ROWS UNBOUNDED PRECEDING) AS rolling_count_people_vaccinated
FROM
  PortfolioProject.dbo.CovidDeaths AS de
JOIN
  PortfolioProject.dbo.CovidVaccinations AS va
  ON de.location = va.location
  AND de.date = va.date
WHERE
  de.continent is not null
  )

SELECT 
  *, (rolling_count_people_vaccinated/population)*100 AS percentage_population_vaccinated
FROM
  population_and_vaccination

--Creating a View of Total number of Vaccinations of each country's Population, for visualizations

CREATE VIEW population_and_vaccination AS
SELECT
  de.continent, de.location, de.date, de.population, va.new_vaccinations, SUM(CAST(va.new_vaccinations AS bigint)) OVER (PARTITION BY de.Location ORDER BY de.location, de.date ROWS UNBOUNDED PRECEDING) AS rolling_count_people_vaccinated
FROM
  PortfolioProject.dbo.CovidDeaths AS de
JOIN
  PortfolioProject.dbo.CovidVaccinations AS va
  ON de.location = va.location
  AND de.date = va.date
WHERE
  de.continent is not null

--Preview the View created

SELECT *
FROM population_and_vaccination
