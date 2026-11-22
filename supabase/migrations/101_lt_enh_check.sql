-- READ ONLY. LT file for 11/14 (13 HH families): compare with saved 11/14 list and current customers.
with v(ref, tot, e, h, t) as (values
('LT00001',6,4,2,'Meals'),('LT00048',3,1,2,'Meals'),('LT00050',6,3,3,'Meals'),('LT00072',1,1,0,'Meals'),
('LT00078',4,2,2,'Meals'),('LT00090',4,2,2,'Meals'),('LT00094',4,1,3,'Meals'),('LT00098',4,2,2,'Meals'),
('LT00122',1,1,0,'Box'),('LT00134',3,1,2,'Box'),('LT00147',1,1,0,'Meals'),('LT00219',8,4,4,'Box'),('LT00414',1,1,0,'Meals'))
select v.ref, v.t as file_type, v.tot as file_total, v.e as file_enh, v.h as file_hh,
  (select string_agg(s.base||'/'||s.food||' hh='||s.hh||' enh='||coalesce(s.enh,0), ' ; ') from billing_snap s where s.week='2026-11-14' and s.agency='LT' and s.agency_ref=v.ref) as snap_1114,
  (select string_agg(c.base||'/'||c.food||' hh='||c.hh||' enh='||coalesce(c.enh,0)||' active='||c.active, ' ; ') from customers c where c.agency='LT' and c.agency_ref=v.ref) as customer_now
from v order by v.ref;
