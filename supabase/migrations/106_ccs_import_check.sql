-- READ ONLY. Which sheet import holds CCS 11/14 (counts only).
select tab_date, batch, count(*) rows_, sum(case when ref='FAM-1645' then 1 else 0 end) has_1645, max(delivered_at) last_d
from billing_import where company='CCS' and tab_date>='2026-11-09' group by 1,2 order by 1,2;
