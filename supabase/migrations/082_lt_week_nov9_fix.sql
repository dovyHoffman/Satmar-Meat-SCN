-- LT invoice, week of 11/9 (key 2026-11-07): follow the LT export (Total / Enhanced / HH).
-- Two families have a Meals case AND a Box case: split into two billing rows each.
update billing_snap set base='meals', food='meals', hh=5, enh=0 where week='2026-11-07' and agency='LT' and agency_ref='LT00001';
update billing_snap set base='meals', food='meals', hh=1, enh=0 where week='2026-11-07' and agency='LT' and agency_ref='LT00050';
insert into billing_snap (week, agency, agency_ref, name, base, food, hh, enh)
select week, agency, agency_ref||' (2)', name, 'box', (select food from billing_snap where week='2026-11-07' and agency='LT' and agency_ref='LT00122'),
  case agency_ref when 'LT00001' then 1 else 5 end, case agency_ref when 'LT00001' then 0 else 2 end
from billing_snap where week='2026-11-07' and agency='LT' and agency_ref in ('LT00001','LT00050')
on conflict (week, agency, agency_ref) do update set base=excluded.base, food=excluded.food, hh=excluded.hh, enh=excluded.enh;
update billing_snap set base='box', hh=3, enh=1 where week='2026-11-07' and agency='LT' and agency_ref='LT00134';
update billing_snap set base='box', hh=8, enh=3 where week='2026-11-07' and agency='LT' and agency_ref='LT00219';
update billing_snap set base='box', hh=1, enh=0 where week='2026-11-07' and agency='LT' and agency_ref='LT00122';
select agency_ref k, base||' hh'||hh||' enh'||enh||' '||coalesce(food,'') v from billing_snap where week='2026-11-07' and agency='LT' and (base='box' or agency_ref like '%(2)' or agency_ref in ('LT00001','LT00050')) order by 1;
select 'meals_cust_hh' k, count(*)||' / '||coalesce(sum(hh),0) v from billing_snap where week='2026-11-07' and agency='LT' and base='meals';
