Select * 
From Project..CovidDeaths
Where Continent is not null
Order by 3,4

--Select * 
--From Project..CovidVaccinations
--Order by 3,4

Select location, date, total_cases, new_cases, total_deaths, population
From Project..CovidDeaths
Order by 1,2

-- Total Cases Vs Total Deaths

Select location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
from Project..CovidDeaths
Where location like'%states%'
order by 1,2

	DROP VIEW IF EXISTS TotalCasesVsTotalDeaths;

CREATE VIEW TotalCasesVsTotalDeaths AS
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (TRY_CAST(total_deaths AS float) / NULLIF(TRY_CAST(total_cases AS float), 0)) * 100 AS DeathPercentage
FROM 
    Project..CovidDeaths
WHERE 
    location LIKE '%states%';

	SELECT *
FROM TotalCasesVsTotalDeaths
ORDER BY location, date;


-- Total Cases Vs Total Population

Select location, date, total_cases, population, 
(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS PercentPopulationInfected
from Project..CovidDeaths
Where location like'%states%'
order by 1,2

CREATE VIEW TotalCasesVsTotalPopulation AS
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (TRY_CAST(total_deaths AS float) / NULLIF(TRY_CAST(total_cases AS float), 0)) * 100 AS PercentPopulationInfected
FROM 
    Project..CovidDeaths
WHERE 
    location LIKE '%states%';

	SELECT *
FROM TotalCasesVsTotalPopulation
ORDER BY location, date;

--Highest Infection Amount Vs Population

Select location, population, MAX(total_cases) as HighestInfectionCount, 
(CONVERT(float,MAX (total_cases)) / NULLIF(CONVERT(float, population), 0)) * 100 AS PercentPopulationInfected
from Project..CovidDeaths
--Where location like'%states%'
Group by location, population
order by PercentPopulationInfected desc
	Create View HighestInfectionRate AS
		Select location, population, Max(total_cases) as HighestInfectionCount
		From Project..CovidDeaths
		Group by total_cases, location, population

		Select *
		From HighestInfectionRate
		Order by HighestInfectionCount desc

-- Highest Death Count per Population

Select location, population, MAX(cast(total_deaths as float)) as TotalDeathCount 
From Project..CovidDeaths
--Where location like'%states%'
Group by location, population
order by TotalDeathCount desc

-- Total Death Count Per Country

Select Location, Max(Cast(Total_deaths as float)) as TotalDeathCount
From Project..CovidDeaths
Where continent is not null
Group by location
Order by TotalDeathCount desc

-- Total Death Count Per Continent

Select continent, Max(Cast(Total_deaths as float)) as TotalDeathCount
From Project..CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount desc


-- Global Numbers

Select date, SUM(Cast(new_cases as float)) as total_cases, SUM(Cast(new_deaths as float)) as total_deaths, 
Case
When sum(cast(new_cases as float)) = 0 THEN 0
Else (sum(cast(new_deaths as float))/sum(cast(new_cases as float)))*100 End AS DeathPercentage
From Project..CovidDeaths
Where continent is not null
Group by date
Order by 1,2

-- CovidDeathStatistics View

Drop View IF Exists CovidDeathStatistics;

Use Project;
Create view CovidDeathStatistics AS
SELECT date,
    SUM(CAST(new_cases AS float)) AS total_cases,
    SUM(CAST(new_deaths AS float)) AS total_deaths,
    CASE
        WHEN SUM(CAST(new_cases AS float)) = 0 THEN 0
        ELSE (SUM(CAST(new_deaths AS float)) / SUM(CAST(new_cases AS float))) * 100
    END AS DeathPercentage
FROM
    Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date

Select * From CovidDeathStatistics

-- Total Population vs Vaccinations

WITH PopvsVac (Continent, location, date, population, New_vaccinations, RollingPeopleVaccinated) AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        TRY_CAST(dea.population AS float) AS population,
        TRY_CAST(vac.new_vaccinations AS float) AS new_vaccinations,
        SUM(TRY_CAST(vac.new_vaccinations AS float)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS RollingPeopleVaccinated
    FROM
        Project..CovidDeaths dea
    JOIN
        Project..CovidVaccinations vac
    ON
        dea.location = vac.location
        AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
)

SELECT
    Continent,
    location,
    MAX(date) AS LatestDate,
    MAX(population) AS TotalPopulation,
    MAX(RollingPeopleVaccinated) AS TotalVaccinated,
    CASE
        WHEN MAX(population) = 0 THEN 0
        ELSE (MAX(RollingPeopleVaccinated) / MAX(population)) * 100
    END AS VaccinationPercentage
FROM
    PopvsVac
GROUP BY
    Continent, location
ORDER BY
    Continent, location;

 -- Vaccination Percentage


 With PopvsVac (Continent, location, date, population, New_vaccinations, RollingPeopleVaccinated)
 as
 (
Select dea.continent, dea.location, dea.date, TRY_Cast(dea.population as float) as population, Try_Cast(vac.new_vaccinations as float) as new_vaccinations,
 Sum (Try_Cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date)
 AS RollingPeopleVaccinated

From Project..CovidDeaths dea
Join Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
	Where dea.continent is not null

)
Select *,
Case
	WHEN Population = 0 then 0
	ELSE (RollingPeopleVaccinated/population) *100
End AS VaccinationPercentage
From PopvsVac
Order by population desc


-- Percentage Population Vaccinated

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
New_vaccinations float,
RollingPeopleVaccinated float

)
Insert into #PercentPopulationVaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 Sum (Cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date)
 AS RollingPeopleVaccinated
From Project..CovidDeaths dea
Join Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
	Where dea.continent is not null

	Select *,
	 CASE
        WHEN SUM(CAST(Population AS float)) = 0 THEN 0
        ELSE (SUM(CAST(RollingPeopleVaccinated AS float)) / SUM(CAST(Population AS float))) * 100
    END AS PercentageVaccinated
	From #PercentPopulationVaccinated
	Group by continent, location, date, population, new_vaccinations, RollingPeopleVaccinated;



--Rolling People Vaccinated

--Drop View IF Exists PercentPopulationVaccinated;

	Use Project;
	CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    Project..CovidDeaths dea
JOIN 
    Project..CovidVaccinations vac
ON 
    dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;

Select *
From PercentPopulationVaccinated