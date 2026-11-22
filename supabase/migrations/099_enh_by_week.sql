-- READ ONLY, counts only: Enhanced saved in each week's billing list, per company (CCS, LT, UJO).
select week, agency, count(*) as rows, sum(hh) as hh, sum(coalesce(enh,0)) as enh,
       count(*) filter (where coalesce(enh,0) > 0) as rows_with_enh
from billing_snap
where agency in ('CCS','LT','UJO') and week >= '2026-10-24'
group by week, agency order by agency, week;
