-- CCS raw box price by household size.
insert into agency_hh_prices (agency, hh, price) values
 ('CCS',1,131),('CCS',2,204),('CCS',3,274),('CCS',4,335),('CCS',5,390),
 ('CCS',6,460),('CCS',7,504),('CCS',8,567),('CCS',9,631),('CCS',10,695)
on conflict (agency, hh) do nothing;
