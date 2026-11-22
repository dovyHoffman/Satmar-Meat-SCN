-- 11/14 saved list only: Enhanced from the owner's CCS and LT files. Customer cards untouched.
with v(ag, ref, e) as (values
('CCS','FAM-3907',3),('CCS','FAM-1417',2),('CCS','FAM-1448',5),('CCS','FAM-1423',1),('CCS','FAM-1426',2),('CCS','FAM-1494',1),
('LT','LT00001',4),('LT','LT00050',3))
update billing_snap s set enh=v.e from v
where s.week='2026-11-14' and s.agency=v.ag and s.agency_ref=v.ref;
select s.agency, s.agency_ref, s.base, s.food, s.hh, s.enh from billing_snap s
where s.week='2026-11-14' and s.agency_ref in ('FAM-3907','FAM-1417','FAM-1448','FAM-1423','FAM-1426','FAM-1494','LT00001','LT00050') order by 1,2;
