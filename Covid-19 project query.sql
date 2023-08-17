SELECT *
FROM dbo.CovidDeath

SELECT *
from dbo.CovidVaccination

--Select the data to be used
select location, date, total_cases, new_cases, total_deaths, population
from dbo.CovidDeath
order by 1


--What percentage of the population got Covid

select location, date, population, total_cases, round((total_cases/population)*100, 4) as Infected_Percentage
from dbo.CovidDeath
where location like '%Nigeria%'
order by 1,2

--Countries with highest infection rate by population

select location, population, MAX(total_cases) as Highest_infection_rate, MAX((total_cases/population))*100 as Infected_Percentage
from dbo.CovidDeath
--where location like '%states%'
group by location, population
order by Infected_Percentage desc

--Countries with highest death rate by population
select location, MAX(cast(total_deaths as int)) as Highest_death_rate
from dbo.CovidDeath
--where location like '%states%'
where continent is not null
group by location
order by Highest_death_rate desc

--Continents with the highest death rate by population

select continent, MAX(cast(total_deaths as int)) as Highest_death_rate
from dbo.CovidDeath
--where location like '%states%'
where continent is not null
group by continent
order by Highest_death_rate desc

--Total cases vs Total deaths

Select Location, date, total_cases, total_deaths, (cast(total_deaths as int)/(total_cases))*100 as Death_Percentage
From dbo.CovidDeath
Where location like '%states%'
and continent is not null
order by 1,2

--Global Percentage

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as Death_Percentage
From dbo.CovidDeath
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

select *
from dbo.CovidVaccination

--Join the Covid death data to the vaccination data

select *
from dbo.CovidDeath dea
join dbo.CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date

--Total Population vs Total Vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from dbo.CovidDeath dea
join dbo.CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Rollover of people vaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeath dea
Join dbo.CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeath dea
Join dbo.CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeath dea
Join dbo.CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeath dea
Join dbo.CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select*
from PercentPopulationVaccinated