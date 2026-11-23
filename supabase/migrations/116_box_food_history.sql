-- READ ONLY. For the 8 Box-with-meals-food customers: what the saved weekly billing lists held (type/food/hh), ids only.
with v(ag, ref) as (values ('CCS','FAM-1417'),('CCS','FAM-1494'),('LH','PU05648Q'),('LH','SB80984J'),('LH','TJ64378F'),('LH','TY52701G'),('LH','VB63593S'),('RY','Posen - 8453236127'))
select v.ag, v.ref,
 (select string_agg(s.week::text||' '||s.base||'/'||s.food||' hh'||s.hh, ' ; ' order by s.week desc) from (select * from billing_snap x where x.agency=v.ag and x.agency_ref=v.ref order by week desc limit 4) s) snaps,
 (select c.base||'/'||c.food||' hh'||c.hh from customers c where c.agency=v.ag and c.agency_ref=v.ref limit 1) now_
from v order by 1,2;
