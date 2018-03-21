# Create 

CREATE TABLE IF NOT EXISTS `city_dim` (
  `city_sk` int(6) unsigned NOT NULL,
  `name` varchar(100) unsigned NOT NULL,
  `state_sk` int(200) NOT NULL,
  PRIMARY KEY (`city_sk`)
) DEFAULT CHARSET=utf8;
INSERT INTO `city_dim` (`city_sk`, `name`, `state_sk`) VALUES
  ('1', 'Berlin', '1'),
  ('2', 'Paris', '1'),
  ('3', 'Napier', '2'),
  ('4', 'Auckland', '2'),
  ('5', 'Mumbai', '2'),
  ('7', 'London', '3');

CREATE TABLE IF NOT EXISTS `people` (
  `uuid` varchar(50) unsigned NOT NULL,
  `first_name` varchar(100) unsigned NOT NULL,
  `last_name` varchar(100) unsigned NOT NULL,
  `city_sk` int(6) NOT NULL,
  PRIMARY KEY (`uuid`)
) DEFAULT CHARSET=utf8;
INSERT INTO `people` (`uuid`, `first_name`, `last_name`, `city_sk`) VALUES
  ('7e718f1p105a8da29k81ef3ea5f12872', 'Anna', 'Lugi', '5'),
  ('7e718f1p105a8da29k81ef3ea5f12873', 'A', 'C', '3'),
  ('7e718f1p105a8da29k81ef3ea5f12874', 'A', 'D', '2'),
  ('7e718f1p105a8da29k81ef3ea5f12875', 'A', 'E', '1'),
  ('7e718f1p105a8da29k81ef3ea5f12876', 'A', 'F', '2'),
  ('7e718f1p105a8da29k81ef3ea5f12877', 'A', 'G', '7'),
  ('7e718f1p105a8da29k81ef3ea5f12878', 'A', 'H', '3');

CREATE TABLE IF NOT EXISTS `state_dim` (
  `state_sk` int(6) unsigned NOT NULL,
  `name` varchar(100) unsigned NOT NULL,
  `is_in` int(1) NOT NULL,
  PRIMARY KEY (`state_sk`)
) DEFAULT CHARSET=utf8;
INSERT INTO `state_dim` (`state_sk`, `name`, `is_in`) VALUES
  ('1', 'World', '1'),
  ('2', 'Peace', '1'),
  ('3', '65dayofstatic', '0'),
  ('4', 'Los Campesinos!', '0');



# computes the amount of people per city

Select city_dim.name as 'city name', 
       ppl.count as 'the amount of people'
from  (select city_sk, count(*) as count from  `people` group by city_sk ) ppl
	  # get the user count per city
left join city_dim on (city_dim.city_sk = ppl.city_sk)



# computes the amount of people from a state with is_in True.

select state.name as 'state name',  city.count as 'the amount of people'
from (
	Select ppl.city_sk, ppl.count, cd.state_sk as state
		from  (select city_sk, count(*) as count from  people group by city_sk ) ppl
		# get the user count per city
	left join city_dim cd on (cd.city_sk = ppl.city_sk)
	) city
	# acquire the count of people by city, mapping to state_dim schema
left join state_dim state on ((city.state = state.state_sk))
where state.is_in = 1 # condition filter for EU location 
