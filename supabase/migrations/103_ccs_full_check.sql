-- READ ONLY. CCS full file for 11/14 vs saved 11/14 list (ids and numbers only).
with v(ref,tot,e,t) as (values ),
s as (select agency_ref ref, base, hh, coalesce(enh,0) enh from billing_snap where week='2026-11-14' and agency='CCS')
select (select count(*) from v) file_rows, (select count(*) from s) snap_rows,
 (select count(*) from v where ref not in (select ref from s)) in_file_not_snap,
 (select count(*) from s where ref not in (select ref from v)) in_snap_not_file,
 (select coalesce(json_agg(ref),'[]'::json) from v where ref not in (select ref from s)) ids_file_only,
 (select coalesce(json_agg(ref),'[]'::json) from s where ref not in (select ref from v)) ids_snap_only,
 (select coalesce(json_agg(json_build_object('ref',v.ref,'file',v.t||' hh'||v.tot||' enh'||v.e,'snap',s.base||' hh'||s.hh||' enh'||s.enh)),'[]'::json) from v join s using(ref) where v.t<>s.base or v.tot<>s.hh or v.e<>s.enh) diffs;
