-- 11/14 saved list: FAM-1251 household 2 per the owner's CCS file.
update billing_snap set hh=2 where week='2026-11-14' and agency='CCS' and agency_ref='FAM-1251' and hh=1;
select agency_ref, base, hh, enh from billing_snap where week='2026-11-14' and agency='CCS' and agency_ref='FAM-1251';
