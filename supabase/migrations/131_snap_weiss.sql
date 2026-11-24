with i as (insert into billing_snap(week,agency,agency_ref,name,base,food,hh,enh) select '2026-11-21',agency,agency_ref,name,base,food,hh,coalesce(enh,0) from customers where agency='RY' and agency_ref='Weiss - 3475815977' on conflict do nothing returning 1)
select (select count(*) from i) inserted, (select count(*) from billing_snap where week='2026-11-21') snap_rows_now;
