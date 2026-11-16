-- UJO week of 11/9: the 4 Box families are all Enhanced (Enhanced = Total in the UJO file).
with v(ref, e) as (values ('UJO - 4032',1),('UJO - 2595',1),('UJO - 3706',3),('UJO - 13091',2))
update billing_import b set enh = v.e from v
where b.tab_date='2026-11-10' and b.company='UJO' and b.base='box' and b.ref=v.ref
  and b.batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='UJO');
select 'ujo_box_enh' k, coalesce(sum(enh),0)::text v from billing_import where tab_date='2026-11-10' and company='UJO' and base='box'
  and batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='UJO');
