-- READ ONLY. The 6 CCS families the owner listed (Enhanced + HH): what the saved 11/14 list and the customer list hold now.
with v(ref, tot, e) as (values ('FAM-3907',4,3),('FAM-1417',3,2),('FAM-1448',9,5),('FAM-1423',2,1),('FAM-1426',3,2),('FAM-1494',2,1))
select v.ref, v.tot as file_total, v.e as file_enh,
  (select string_agg(s.base||'/'||s.food||' hh='||s.hh||' enh='||coalesce(s.enh,0), ' ; ') from billing_snap s where s.week='2026-11-14' and s.agency='CCS' and s.agency_ref=v.ref) as snap_1114,
  (select string_agg(c.base||'/'||c.food||' hh='||c.hh||' enh='||coalesce(c.enh,0)||' active='||c.active, ' ; ') from customers c where c.agency='CCS' and c.agency_ref=v.ref) as customer_now
from v order by v.ref;
