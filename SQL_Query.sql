SELECT *
FROM Covid_Project..covid_deaths

SELECT *
FROM Covid_Project..covid_vaccinations

SELECT Location, date, population, total_cases, (total_cases/population)*100 as InfectionPercentage
FROM Covid_Project..covid_deaths

-- Looking at total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM Covid_Project..covid_deaths
WHERE location like '%states%' and continent is not null
order by 1,2


-- Looking at countries with highest infection rate compared to population
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectionPercentage
FROM Covid_Project..covid_deaths
GROUP BY location, population
ORDER BY InfectionPercentage DESC


-- Showing countries with the highest death count per population
SELECT Location, MAX(CAST(total_deaths AS int)) as TotalDeathCount
FROM Covid_Project..covid_deaths
WHERE continent is not null
GROUP BY location, population
ORDER BY TotalDeathCount DESC

-- lets break things down by continent
-- Showing continents with the highest death count
SELECT continent, MAX(CAST(total_deaths AS int)) as TotalDeathCount
FROM Covid_Project..covid_deaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Global numbers
SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM Covid_Project..covid_deaths
WHERE continent is not null
order by 1,2


-- Joining the two tables together
SELECT *
FROM Covid_Project..covid_deaths dea
JOIN Covid_Project..covid_vaccinations vax
	ON dea.location = vax.location
	AND dea.date = vax.date

-- Looking at total population vs vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
FROM Covid_Project..covid_deaths dea
JOIN Covid_Project..covid_vaccinations vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null
ORDER BY 1,2,3


-- Create a rolling count
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(CONVERT(bigint,vax.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as rollingvax
FROM Covid_Project..covid_deaths dea
JOIN Covid_Project..covid_vaccinations vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null
ORDER BY 1,2,3

-- Use CTE

WITH PopvsVax (Continent, Location, Date, Population,new_vaccinations, rollingvax)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(CONVERT(bigint,vax.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as rollingvax
FROM Covid_Project..covid_deaths dea
JOIN Covid_Project..covid_vaccinations vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null
)
SELECT *, (rollingvax/Population)*100 percentVaxxed
FROM PopvsVax


-- TEMP TABLE

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Data datetime,
Population numeric,
New_vaccinatations numeric,
Rollingvax numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(CONVERT(bigint,vax.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as rollingvax
FROM Covid_Project..covid_deaths dea
JOIN Covid_Project..covid_vaccinations vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null
ORDER BY 1,2,3

SELECT *, (rollingvax/Population)*100 percentVaxxed
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE view PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(CONVERT(bigint,vax.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as rollingvax
FROM Covid_Project..covid_deaths dea
JOIN Covid_Project..covid_vaccinations vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null


SELECT *
FROM PercentPopulationVaccinated