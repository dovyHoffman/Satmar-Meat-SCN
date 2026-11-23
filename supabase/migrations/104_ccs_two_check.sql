-- READ ONLY. The two CCS differences: customer card, saved row, and any delivery in the week (counts only).
select c.agency_ref, c.base, c.food, c.hh, coalesce(c.enh,0) enh, c.active,
 (select count(*) from billing_snap s where s.week='2026-11-14' and s.agency='CCS' and s.agency_ref=c.agency_ref) in_snap,
 (select count(*) from billing_snap s where s.week='2026-11-07' and s.agency='CCS' and s.agency_ref=c.agency_ref) in_snap_1107
from customers c where c.agency='CCS' and c.agency_ref in ('FAM-1645','FAM-1251');
