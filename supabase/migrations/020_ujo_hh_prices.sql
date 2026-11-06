-- UJO raw box price by household size. Column D (per person per week) x household size = the box price.
insert into agency_hh_prices (agency, hh, price) values
 ('UJO',1,134.87),('UJO',2,209.70),('UJO',3,281.76),('UJO',4,344.57),('UJO',5,401.85),
 ('UJO',6,472.98),('UJO',7,517.32),('UJO',8,582.91),('UJO',9,648.50),('UJO',10,714.09)
on conflict (agency, hh) do nothing;
