create database electric_vehicle_propulsion_rate_usa;

alter table electric_vehiclepopulation_size_history_by_county
add column New_Date date;

set sql_safe_updates=0;

update electric_vehiclepopulation_size_history_by_county
set New_Date=str_to_date(date, "%M %d %Y");

-- ------------------------------------------------------state list-----------------------------------------------------------------------------------
SELECT if(locate(" ", state, 1) > 0, left(STATE, length(state)-5), state) as state, code
from `state list`;

-- -----------------------------------------------------monthly data--------------------------------------------------------------------------------------
with c as(select new_date as month_last, sum(`Total Vehicles`) as total, sum(`Electric Vehicle (EV) Total`) as ev_total,
sum(`Battery Electric Vehicles (BEVs)`) as BEVs,
sum(`Plug-In Hybrid Electric Vehicles (PHEVs)`) as PHEVs,
sum(`Non-Electric Vehicle Total`) as non_ev_total,
round(sum(`Electric Vehicle (EV) Total`)/sum(`Total Vehicles`)*100.0, 2) as ev_percent,
count(*) as cnt
from ev_population
where left(new_date,4) <> 2023
group by  month_last
order by month_last)

select *, concat(monthname(month_last), " ", left(month_last, 4)) as month_year,
lag(ev_total) over (order by month_last) as lagg,
round((ev_total-lag(ev_total) over (order by month_last))/ev_total*100.0, 2) as mnth_on_mnth_growth_percent
from c;

-- ---------------------------------------------------------yearly population data=(last month of the year data)----------------------------------------------------
with c as(select left(new_date,7) as month_year, sum(`Total Vehicles`) as total, sum(`Electric Vehicle (EV) Total`) as ev_total,
sum(`Battery Electric Vehicles (BEVs)`) as BEVs,
sum(`Plug-In Hybrid Electric Vehicles (PHEVs)`) as PHEVs,
sum(`Non-Electric Vehicle Total`) as non_ev_total,
round(sum(`Electric Vehicle (EV) Total`)/sum(`Total Vehicles`)*100.0, 2) as ev_percent,
count(*) as cnt
from ev_population
where left(new_date,4) <> 2023
group by  month_year
order by month_year)

select *, left(month_year, 4) as yr, lag(ev_total) over (order by month_year) as lagg,
round((ev_total-lag(ev_total) over (order by month_year))/ev_total*100.0, 2) as yr_on_yr_growth_percent
from c
where right(month_year, 2)=12;

-- ------------------------------------------------------County Wise Data-----------------------------------------------------------------------------
select distinct county -- to see how many counties of Washington is present in the data set 
from ev_population
where sTate_code="wa";


/*To query out the county wise data for the year 2017 of Washington and data of vehicles registered under 
Washinngton Transport Department but located in other states categorised under county and state as others*/
create view county_data_2017 as
(select new_date, county, "WA" as state_code, 
sum(`Battery Electric Vehicles (BEVs)`) as BEVs,
sum(`Plug-In Hybrid Electric Vehicles (PHEVs)`) as PHEVs,
sum(`Electric Vehicle (EV) Total`) as ev_total,
sum(`Non-Electric Vehicle Total`) as non_ev_total,
sum(`Total Vehicles`) as total
from ev_population
where year(new_date)=2017 and month(new_date)=12 and state_code="WA"
group by New_Date, county
union
select new_date,"Others" as county, "Others" as state_code,
sum(`Battery Electric Vehicles (BEVs)`) as BEVs,
sum(`Plug-In Hybrid Electric Vehicles (PHEVs)`) as PHEVs,
sum(`Electric Vehicle (EV) Total`) as ev_total,
sum(`Non-Electric Vehicle Total`) as non_ev_total,
sum(`Total Vehicles`) as total
from ev_population
where year(new_date)=2017 and month(new_date)=12 and state_code <> "WA"
group by New_Date);


/*To query out the county wise data for the year 2022 of Washington and data of vehicles registered under 
Washinngton Transport Department but located in other states categorised under county and state as others*/
create view county_data_2022 as
(select new_date, county, "WA" as state_code, 
sum(`Battery Electric Vehicles (BEVs)`) as BEVs,
sum(`Plug-In Hybrid Electric Vehicles (PHEVs)`) as PHEVs,
sum(`Electric Vehicle (EV) Total`) as ev_total,
sum(`Non-Electric Vehicle Total`) as non_ev_total,
sum(`Total Vehicles`) as total
from ev_population
where year(new_date)=2022 and month(new_date)=12 and state_code="WA"
group by New_Date, county
union
select new_date,"Others" as county, "Others" as state_code,
sum(`Battery Electric Vehicles (BEVs)`) as BEVs,
sum(`Plug-In Hybrid Electric Vehicles (PHEVs)`) as PHEVs,
sum(`Electric Vehicle (EV) Total`) as ev_total,
sum(`Non-Electric Vehicle Total`) as non_ev_total,
sum(`Total Vehicles`) as total
from ev_population
where year(new_date)=2022 and month(new_date)=12 and state_code <> "WA"
group by New_Date);


with c as (select c1.county,
c1.new_date as Date_2022,
c1.BEVs as `2022 BEVs`,
c1.PHEVs as `2022 PHEVs`,
c1.ev_total as `2022 ev total`,
c1.non_ev_total as `2022 non ev total`,
c2.new_date as Date_2017,
ifnull(c2.BEVs, 0) as `2017 BEVs`,
ifnull(c2.PHEVs, 0) as `2017 PHEVs`,
ifnull(c2.ev_total, 0) as `2017 ev total`,
ifnull(c2.non_ev_total, 0) as `2017 non ev total`
from county_data_2022 c1 left join county_data_2017 c2 using(county)
)

select *, (`2022 ev total`)-(`2017 ev total`) as EVs_Increased_by
from c
order by evs_increased_by desc;

              
-- -------------------------------------------------------EV_Brand Wise avg price------------------------------------------------------------------
-- to select brands wise effective avg price of cars from the ev_price_dataset
select 
mid(model, locate(" ", model, 1)+1, locate(" ", model, locate(" ", model, 1)+1)-locate(" ", model, 1)-1) as brand,
round(avg(`effective price`),2) as `Avg Price`
from ev_model_price
group by brand
order by `avg price` desc;


