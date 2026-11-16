-- LT week of 11/9 (sheet tab 2026-11-10): Enhanced members per the LT export (Total stays as the household total).
update billing_import set enh = case ref when 'LT00050' then 2 when 'LT00134' then 1 when 'LT00219' then 3 end
where tab_date='2026-11-10' and company='LT' and base='box' and ref in ('LT00050','LT00134','LT00219')
  and batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='LT');
select ref k, 'box hh'||hh||' enh'||enh v from billing_import where tab_date='2026-11-10' and company='LT' and base='box'
  and batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='LT') order by ref;
