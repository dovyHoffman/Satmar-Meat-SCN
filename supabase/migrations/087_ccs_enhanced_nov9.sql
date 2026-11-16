-- CCS week of 11/9 (sheet tab 2026-11-10): Enhanced column of the CCS file for the 3 Meals families that have Enhanced + HH.
with v(ref, e) as (values ('7C9H9Y',2),('P34M94',1),('KDMD3R',1))
update billing_import b set enh = v.e from v
where b.tab_date='2026-11-10' and b.company='CCS' and b.ref=v.ref
  and b.batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='CCS');
select 'ccs_enh_rows' k, count(*)::text v from billing_import where tab_date='2026-11-10' and company='CCS' and enh>0
  and batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='CCS');
