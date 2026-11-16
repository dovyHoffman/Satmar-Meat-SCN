with b as (select max(batch) m from billing_import where tab_date='2026-11-10' and company='UJO')
select 'row_'||ref k, base||' '||coalesce(food,'')||' hh'||hh||' enh'||enh v from billing_import, b where tab_date='2026-11-10' and company='UJO' and batch=b.m and (enh>0 or ref in ('UJO - 4691','UJO - 12812','UJO - 13423','APP-609907','UJO - 3440','UJO - 3498','UJO - 9991','UJO - 9979','UJO - 13484','UJO - 9735','UJO - 9620','UJO - 10059','APP-413558','UJO - 12354','UJO - 9774'))
union all select 'tot', count(*)||' rows meals '||count(*) filter(where base='meals')||' hh '||coalesce(sum(hh) filter(where base='meals'),0)||' box '||count(*) filter(where base='box')||' hh '||coalesce(sum(hh) filter(where base='box'),0) from billing_import, b where tab_date='2026-11-10' and company='UJO' and batch=b.m
union all select 'price', 'box '||box_price||' meal '||meal_price from agency_prices where agency='UJO'
union all select 'hh_'||hh, price::text from agency_hh_prices where agency='UJO'
order by 1;
