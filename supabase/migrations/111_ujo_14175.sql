-- UJO 11/14 saved list: add UJO - 14175 (Meals, household 6, Enhanced 6) from the owner's UJO file.
insert into billing_snap (week, agency, agency_ref, name, base, food, hh, enh)
select '2026-11-14','UJO','UJO - 14175', c.name, 'meals', coalesce(nullif(c.food::text,''),'meals'), 6, 6
from customers c where c.agency='UJO' and c.agency_ref='UJO - 14175' limit 1
on conflict do nothing;
select count(*) snap_rows, sum(case when agency_ref='UJO - 14175' then 1 else 0 end) has_14175 from billing_snap where week='2026-11-14' and agency='UJO';
