-- READ ONLY. CCS customers not in the saved 11/14 list (ids, type, household only), and CCS box counts in the list.
select (select coalesce(json_agg(json_build_object('ref',c.agency_ref,'base',c.base,'food',c.food,'hh',c.hh,'enh',coalesce(c.enh,0),'active',c.active)),'[]'::json)
  from customers c where c.agency='CCS' and c.agency_ref not in (select agency_ref from billing_snap where week='2026-11-14' and agency='CCS')) not_in_list,
 (select count(*) from billing_snap where week='2026-11-14' and agency='CCS' and base='box') box_in_list,
 (select count(*) from customers where agency='CCS' and base='box' and active) box_active_now;
