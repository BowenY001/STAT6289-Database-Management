use covid_19;

-- format database
ALTER TABLE `covid_19`.`countrycontinent` 
DROP PRIMARY KEY,
ADD PRIMARY KEY (`country`),
ADD UNIQUE INDEX `code_2_UNIQUE` (`code_2` ASC),
ADD UNIQUE INDEX `code_3_UNIQUE` (`code_3` ASC);
;

ALTER TABLE `covid_19`.`vaccination_data` 
CHANGE COLUMN `ISO3` `ISO3` VARCHAR(50) NOT NULL ,
CHANGE COLUMN `DATA_SOURCE` `DATA_SOURCE` VARCHAR(50) NULL DEFAULT NULL ,
CHANGE COLUMN `DATE_UPDATED` `DATE_UPDATED` VARCHAR(50) NULL DEFAULT NULL ,
CHANGE COLUMN `PERSONS_FULLY_VACCINATED` `PERSONS_FULLY_VACCINATED` VARCHAR(50) NULL DEFAULT NULL ,
CHANGE COLUMN `FIRST_VACCINE_DATE` `FIRST_VACCINE_DATE` VARCHAR(50) NULL DEFAULT NULL ,
CHANGE COLUMN `PERSONS_BOOSTER_ADD_DOSE` `PERSONS_BOOSTER_ADD_DOSE` VARCHAR(50) NULL DEFAULT NULL ,
CHANGE COLUMN `PERSONS_BOOSTER_ADD_DOSE_PER100` `PERSONS_BOOSTER_ADD_DOSE_PER100` VARCHAR(50) NULL DEFAULT NULL ,
ADD PRIMARY KEY (`ISO3`);
;

ALTER TABLE `covid_19`.`who_covid19_global_data` 
CHANGE COLUMN `﻿Date_reported` `﻿Date_reported` VARCHAR(50) NOT NULL ,
CHANGE COLUMN `Country_code` `Country_code` VARCHAR(50) NOT NULL ,
ADD PRIMARY KEY (`﻿Date_reported`, `Country_code`);
;
ALTER TABLE `covid_19`.`world_population` 
CHANGE COLUMN `CCA3` `CCA3` VARCHAR(50) NOT NULL ,
ADD PRIMARY KEY (`CCA3`);
;

-- Normalization
ALTER TABLE vaccination_data
DROP COLUMN COUNTRY,
DROP COLUMN WHO_REGION;
;
ALTER TABLE who_covid19_global_data
DROP COLUMN Country,
DROP COLUMN WHO_region
;
ALTER TABLE world_population
DROP COLUMN `Country/Territory`,
DROP COLUMN Capital,
DROP COLUMN Continent;


-- vaccination data combine with population into percent
select cc.country, cc.code_3 as code, 
cc.continent as Continent,
cc.sub_region as subRegion, 
vd.TOTAL_VACCINATIONS as VaccineAdministered,
vd.PERSONS_VACCINATED_1PLUS_DOSE as 'Vaccine at least 1 does',
vd.PERSONS_VACCINATED_1PLUS_DOSE/wp.`2022 Population`*100 as 'at least 1 does %', 
vd.PERSONS_FULLY_VACCINATED as 'fullVaccined',
vd.PERSONS_FULLY_VACCINATED/wp.`2022 Population`*100 as 'fullVaccined%', 
vd.PERSONS_BOOSTER_ADD_DOSE as 'booster does',
vd.PERSONS_BOOSTER_ADD_DOSE/wp.`2022 Population`*100 as 'booster does%',
vd.NUMBER_VACCINES_TYPES_USED
from countrycontinent cc join vaccination_data vd
on  cc.code_3 =vd.ISO3 
join world_population wp
on wp.CCA3 = cc.code_3
;

-- vaccination data combine with population into percent order by fullvaccinationrate
select cc.country,
cc.continent as Continent,
wp.`2022 Population` as population,
vd.PERSONS_VACCINATED_1PLUS_DOSE as 'Vaccine at least 1 does',
vd.PERSONS_VACCINATED_1PLUS_DOSE/wp.`2022 Population`*100 as 'at least 1 does %', 
vd.PERSONS_FULLY_VACCINATED as 'fullVaccined',
vd.PERSONS_FULLY_VACCINATED/wp.`2022 Population`*100 as 'fullVaccined%'
from countrycontinent cc join vaccination_data vd
on  cc.code_3 =vd.ISO3 
join world_population wp
on wp.CCA3 = cc.code_3
order by `fullVaccined%` DESC
limit 10
;

-- vaccination data combine with population into percent order by fullvaccinationrate
select cc.country,
cc.continent as Continent,
wp.`2022 Population` as population,
vd.PERSONS_VACCINATED_1PLUS_DOSE as 'Vaccine at least 1 does',
vd.PERSONS_VACCINATED_1PLUS_DOSE/wp.`2022 Population`*100 as 'at least 1 does %', 
vd.PERSONS_FULLY_VACCINATED as 'fullVaccined',
vd.PERSONS_FULLY_VACCINATED/wp.`2022 Population`*100 as 'fullVaccined%'
from countrycontinent cc join vaccination_data vd
on  cc.code_3 =vd.ISO3 
join world_population wp
on wp.CCA3 = cc.code_3
order by `fullVaccined%`
limit 10
;


-- continent fullvaccined rate three group
select a.Countinent as Countinent, total_country, 
COALESCE(`number of country fullvaccined rate below 25%`,0) as `number of country fullvaccined rate below 25%`,
COALESCE(`number of country fullvaccined rate below 25%`,0)/total_country*100 as `Percent of country fullvaccined rate below 25%`, 
COALESCE(`number of country fullvaccined rate 25%-50%`,0) as `number of country fullvaccined rate 25%-50%`,
COALESCE(`number of country fullvaccined rate 25%-50%`,0)/total_country*100 as `Percent of country fullvaccined rate 25%-50%`,
COALESCE(`number of country fullvaccined rate above 50%`,0) as `number of country fullvaccined rate above 50%`,
COALESCE(`number of country fullvaccined rate above 50%`,0)/total_country*100 as `Percent of country fullvaccined rate above 50%`
from
(select cc.continent as Countinent, count(*) as total_country
from countrycontinent cc join vaccination_data vd
on  cc.code_3 =vd.ISO3 
join world_population wp
on wp.CCA3 = cc.code_3
group by cc.continent
) a
left join 
(
select cc.continent as Countinent, count(*) as `number of country fullvaccined rate below 25%`
from countrycontinent cc left join vaccination_data vd
on  cc.code_3 =vd.ISO3 
join world_population wp
on wp.CCA3 = cc.code_3
where vd.PERSONS_FULLY_VACCINATED/wp.`2022 Population`*100 <25
group by cc.continent
) b
on a.Countinent = b.Countinent
left join 
(
select cc.continent as Countinent, count(*) as `number of country fullvaccined rate 25%-50%`
from countrycontinent cc 
join vaccination_data vd on  cc.code_3 =vd.ISO3 
join world_population wp on wp.CCA3 = cc.code_3
where vd.PERSONS_FULLY_VACCINATED/wp.`2022 Population`*100 >=25 and vd.PERSONS_FULLY_VACCINATED/wp.`2022 Population`*100 <50
group by cc.continent
) c
on a.Countinent = c.Countinent
left join 
(
select cc.continent as Countinent, count(*) as `number of country fullvaccined rate above 50%`
from countrycontinent cc join vaccination_data vd on  cc.code_3 =vd.ISO3 
join world_population wp on wp.CCA3 = cc.code_3
where vd.PERSONS_FULLY_VACCINATED/wp.`2022 Population`*100 >=50 
group by cc.continent
) d
on a.Countinent = d.Countinent
order by `Percent of country fullvaccined rate below 25%` DESC
;


-- continent one does rate three group
select a.Countinent as Countinent, total_country, 
COALESCE(`number of country one does rate below 25%`,0) as `number of country one does rate below 25%`, 
COALESCE(`number of country one does rate below 25%`,0)/total_country*100 as `Percent of country one does rate below 25%`, 
COALESCE(`number of country one does rate 25%-50%`,0) as `number of country one does rate 25%-50%`,
COALESCE(`number of country one does rate 25%-50%`,0)/total_country*100 as `Percent of country one does rate 25%-50%`,
COALESCE(`number of country one does rate above 50%`,0) as `number of country one does rate above 50%`, 
COALESCE(`number of country one does rate above 50%`,0)/total_country*100 as `Percent of country one does rate above 50%`
from
(select cc.continent as Countinent, count(*) as total_country
from countrycontinent cc 
join vaccination_data vd on  cc.code_3 =vd.ISO3 
join world_population wp on wp.CCA3 = cc.code_3
group by cc.continent
) a
left join 
(
select cc.continent as Countinent, count(*) as `number of country one does rate below 25%`
from countrycontinent cc 
join vaccination_data vd on  cc.code_3 =vd.ISO3 
join world_population wp on wp.CCA3 = cc.code_3
where vd.PERSONS_VACCINATED_1PLUS_DOSE/wp.`2022 Population`*100 <25
group by cc.continent
) b
on a.Countinent = b.Countinent
left join 
(
select cc.continent as Countinent, count(*) as `number of country one does rate 25%-50%`
from countrycontinent cc 
join vaccination_data vd on  cc.code_3 =vd.ISO3 
join world_population wp on wp.CCA3 = cc.code_3
where vd.PERSONS_VACCINATED_1PLUS_DOSE/wp.`2022 Population`*100 >=25 
and vd.PERSONS_VACCINATED_1PLUS_DOSE/wp.`2022 Population`*100 <50
group by cc.continent
) c
on a.Countinent = c.Countinent
left join 
(
select cc.continent as Countinent, count(*) as `number of country one does rate above 50%`
from countrycontinent cc 
join vaccination_data vd on  cc.code_3 =vd.ISO3 
join world_population wp on wp.CCA3 = cc.code_3
where vd.PERSONS_VACCINATED_1PLUS_DOSE/wp.`2022 Population`*100 >=50 
group by cc.continent
) d
on a.Countinent = d.Countinent
;



select
a.continent,
Cumulative_cases/`2022 Population`*100 as "case rate%",
Cumulative_deaths/Cumulative_cases*100 as "covid death rate (death/cases)in %",
`vaccine at least 1 does`/`2022 Population`*100 as `one does rate`,
`fullVaccined`/`2022 Population`*100 as `fullvaccine rate`,
Cumulative_deaths/`2022 Population`*100 as "death/Population"
from
(select cc.continent as continent, count(*) as total_country
from countrycontinent cc 
join vaccination_data vd on  cc.code_3 =vd.ISO3 
join world_population wp on wp.CCA3 = cc.code_3
group by cc.continent
) a
left join 
(
select 
cc.continent,
sum(`2022 Population`) as `2022 Population`
from world_population wp
join countrycontinent cc on cc.code_3 = wp.CCA3
group by continent
) b
on a.continent = b.continent
left join
(
select 
cc.continent,
sum(New_cases) as Cumulative_cases,sum(New_deaths) as Cumulative_deaths
from who_covid19_global_data wcld 
join countrycontinent cc on wcld.Country_code = cc.code_2
group by continent
) c
on a.continent = c.continent
left join
(
select
cc.continent as Continent,
sum(vd.PERSONS_VACCINATED_1PLUS_DOSE) as 'Vaccine at least 1 does',
sum(vd.PERSONS_FULLY_VACCINATED) as 'fullVaccined'
from countrycontinent cc join vaccination_data vd
on  cc.code_3 =vd.ISO3 
join world_population wp
on wp.CCA3 = cc.code_3
group by cc.continent
) d
on a.continent = d.continent
;
-- -----------------------------------------------------------------------------------------------------------------------------------

##each country total case and deaths
SELECT co.Country,wh.Country_code,max(Cumulative_cases) AS total_cases,max(Cumulative_deaths) AS total_deaths
From who_covid19_global_data wh join countrycontinent co on wh.Country_code = co.code_2
group by wh.Country_code;

##most 10 state total cases
SELECT co.Country,wh.Country_code,co.sub_region,max(Cumulative_cases) AS total_cases,max(Cumulative_deaths) AS total_deaths
From who_covid19_global_data wh join countrycontinent co on wh.Country_code = co.code_2
group by wh.Country_code
order by max(Cumulative_cases) DESC
limit 10;

##most 10 state total deaths
SELECT co.Country,wh.Country_code,co.sub_region,max(Cumulative_cases) AS total_cases,max(Cumulative_deaths) AS total_deaths
From who_covid19_global_data wh join countrycontinent co on wh.Country_code = co.code_2
group by wh.Country_code
order by max(Cumulative_deaths) DESC
limit 10;

##most total cases and deaths in 10 subcontinent
SELECT co.sub_region,sum(New_cases) AS total_cases,sum(New_deaths) AS total_deaths
From who_covid19_global_data wh join countrycontinent co on wh.Country_code = co.code_2
group by co.sub_region
order by total_deaths DESC
limit 10;

##most total cases and deaths in continent
SELECT co.continent,sum(New_cases) AS total_cases,sum(New_deaths) AS total_deaths
From who_covid19_global_data wh join countrycontinent co on wh.Country_code = co.code_2
group by co.continent
order by total_cases DESC;

##average in each continent
select
a.continent,
total_cases, 
total_deaths,
`2022 Population`,
total_cases/`2022 Population` AS case_percent,
total_deaths/`2022 Population` AS deaths_percent_in_population
from
(
select 
cc.continent,
sum(`2022 Population`) as `2022 Population`
from world_population wp
join countrycontinent cc on cc.code_3 = wp.CCA3
group by continent
) a
join
(
select 
cc.continent,
sum(New_cases) as total_cases,sum(New_deaths) as total_deaths
from who_covid19_global_data wh join countrycontinent cc
on wh.Country_code = cc.code_2
group by continent
) b
on a.continent = b.continent
order by case_percent DESC;

##average in country
select
a.Country,
total_cases, 
total_deaths,
`2022 Population`,
total_cases/`2022 Population` AS case_percent,
total_deaths/`2022 Population` AS deaths_percent_in_population
from
(
select 
cc.Country,
`2022 Population`
from world_population wp
left join countrycontinent cc on cc.code_3 = wp.CCA3
group by cc.Country
) a
join
(
select 
cc.Country,
sum(New_cases) as total_cases,sum(New_deaths) as total_deaths
from who_covid19_global_data wh join countrycontinent cc
on wh.Country_code = cc.code_2
group by cc.Country
) b
on a.Country = b.Country
order by total_cases ASC;


##detail in us
select
a.Country,
total_cases, 
total_deaths,
`2022 Population`,
total_cases/`2022 Population` AS case_percent,
total_deaths/`2022 Population` AS deaths_percent_in_population,
total_deaths/total_cases AS deaths_rate
from
(
select 
cc.Country, `2022 Population`
from world_population wp
left join countrycontinent cc on cc.code_3 = wp.CCA3
group by cc.Country
) a
join
(
select 
cc.Country,
sum(New_cases) as total_cases,sum(New_deaths) as total_deaths
from who_covid19_global_data wh join countrycontinent cc
on wh.Country_code = cc.code_2
group by cc.Country
) b
on a.Country = b.Country
where a.Country = 'China'
order by case_percent DESC;

##5 counrty with most cases and last cases by countinent
select
a.Country,
a.continent,
total_cases, 
total_deaths,
`2022 Population`,
total_cases/`2022 Population` AS case_percent,
total_deaths/`2022 Population` AS deaths_percent_in_population
from
(
select
cc.continent,
cc.Country,
`2022 Population`
from world_population wp
left join countrycontinent cc on cc.code_3 = wp.CCA3
group by cc.Country
) a
join
(
select
cc.continent,
cc.Country,
sum(New_cases) as total_cases,sum(New_deaths) as total_deaths
from who_covid19_global_data wh join countrycontinent cc
on wh.Country_code = cc.code_2
group by cc.Country
) b
on a.Country = b.Country
Where a.continent = 'Asia'
group by a.Country
order by total_deaths ASC
limit 5;



