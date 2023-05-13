SET ANSI_WARNINGS OFF -- This command turns off warning to enable your querry run
SET ARITHABORT OFF --This statement controls whether error messages are returned from overflow or divide-by-zero errors during a query
go


--Covid Data Exploration in Microsoft SQL Server 
select * from CovidDeaths

select cast( total_deaths as int)/
cast (total_cases as int)*100 as death_percentage,
location,date,total_cases
from CovidDeaths
order by 1,2

--Lets look at death percentage in Ghana, well thats my country of interest
select cast( total_deaths as float)/
cast (total_cases as float)*100 as death_per,
location,
date,
total_cases
from CovidDeaths
where location = 'Ghana'
order by 1,2

--Lets delve more into the data by looking the highest percentage infected
select max((total_cases/population_density))*100 as percentage_infected,max(total_cases) population_density,
location
from CovidDeaths
where location = 'Ghana'
group by location,population_density 
order by percentage_infected desc



-- lets take a look at percentage infected population and death percentage globally

select cast( total_deaths as int)/
cast (total_cases as int)*100 as death_percentage,
location,
date,
total_cases
from CovidDeaths;


--countries with highest death count per population
select location, max (cast (total_deaths as int)) as death_count
from dbo.CovidDeaths
group by location
order by death_count 

--Lets explore the data by continent
select continent, max (cast (total_deaths as int)) as death_count
from dbo.CovidDeaths
where continent is not null
group by continent
order by death_count desc

--Global numbers
select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as new_deaths
from CovidDeaths
group by date

--Global percentage of cases
select date, continent, sum(new_cases), sum(cast(new_deaths as int)),
sum(cast(new_deaths as int)) / sum(new_cases)*100 as  Deathpercentage
from CovidDeaths
where continent = 'Africa'
group by date, new_cases, continent
order by 1,2


select date, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, 
sum(new_deaths)/ sum(new_cases)*100 as DeathPercentage
from CovidDeaths
group by date


--Joining the CovidDeath table to the Vaccination table

select * from CovidDeaths dea
join CovidVaccination vac on dea.location = vac.location
and dea.date =  vac.date



-- Lets Take a look at the total population vs vaccination

--USE CTE
with popvsvac(continent, location,date, population_density, new_vaccination, rolling_Pvaccinated)
as(
select dea.continent, dea.location, dea.date, dea.population_density, vac.new_vaccinations,
sum(convert(int,new_vaccinations)) over (partition by dea.location 
order by dea.population_density,dea.date) as rolling_Pvaccinated

from CovidDeaths dea
join CovidVaccination vac on dea.location = vac.location
and dea.date =  vac.date
where dea.continent is not null)

select *, (rolling_Pvaccinated/population_density)*100 as percentage_of_rollingVac
from popvsvac


--TEMP TABLE
DROP table if exists #populationvaccinated
CREATE TABLE #populationvaccinated
(Continent nvarchar (255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
rolling_Pvaccinated numeric)

Insert into  #populationvaccinated
select dea.continent, dea.location, dea.date, dea.population_density, vac.new_vaccinations,
sum(convert(int,new_vaccinations)) over (partition by dea.location 
order by dea.population_density,dea.date) as rolling_Pvaccinated
from CovidDeaths dea
join CovidVaccination vac on dea.location = vac.location
and dea.date =  vac.date
where dea.continent is not null



--Selecting the entire data we just created
select *, (rolling_Pvaccinated/population)*100 as percentage_of_rollingVac
from #populationvaccinated



-- NOW, Lets create a view for later use/visuals
create view populationvaccinated as 
select dea.continent, dea.location, dea.date,
dea.population_density, 
vac.new_vaccinations,
sum(convert(int,new_vaccinations)) 
over (partition by dea.location 
order by dea.population_density,dea.date) 
as rolling_Pvaccinated
from CovidDeaths dea
join CovidVaccination vac on dea.location = vac.location
and dea.date =  vac.date
where dea.continent is not null
--order by 2,3

-- Viewing the table
select * from populationvaccinated