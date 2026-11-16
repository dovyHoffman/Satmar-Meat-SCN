-- UJO week of 11/9 (sheet tab 2026-11-10): Enhanced column of the UJO file (Total stays the household total; HH = Total - Enhanced).
with v(ref, e) as (values
 ('UJO - 4691',1),('UJO - 12812',4),('UJO - 13423',2),('APP-609907',2),('UJO - 3440',2),('UJO - 3498',2),('UJO - 9991',3),
 ('UJO - 9979',4),('UJO - 13484',1),('UJO - 9735',3),('UJO - 9620',4),('UJO - 10059',2),('APP-413558',3),('UJO - 12354',2),('UJO - 9774',1))
update billing_import b set enh = v.e from v
where b.tab_date='2026-11-10' and b.company='UJO' and b.ref=v.ref
  and b.batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='UJO');
select 'ujo_enh_rows' k, count(*)::text v from billing_import where tab_date='2026-11-10' and company='UJO' and enh>0
  and batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='UJO');
