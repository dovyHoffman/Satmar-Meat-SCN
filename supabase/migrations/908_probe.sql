with b as (select max(batch) m from billing_import where tab_date='2026-11-10' and company='LT')
select rowno::text||'|'||ref k, base||' '||coalesce(food,'')||' hh'||hh||' enh'||enh||' links'||cardinality(links) v from billing_import, b where tab_date='2026-11-10' and company='LT' and batch=b.m order by rowno;
