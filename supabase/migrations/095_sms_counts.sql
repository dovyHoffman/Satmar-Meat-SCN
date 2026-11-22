-- READ ONLY: counts only (no names or numbers).
select
  count(*) filter (where active) as active_customers,
  count(*) filter (where active and coalesce(hh,0)>0) as active_with_hh,
  count(*) filter (where active and coalesce(hh,0)>0 and no_sms) as active_hh_nosms_phone,
  count(*) filter (where active and coalesce(hh,0)>0 and no_sms_cell) as active_hh_nosms_cell,
  count(*) filter (where active and coalesce(hh,0)>0 and no_sms and no_sms_cell) as both_flags,
  count(*) filter (where active and coalesce(hh,0)>0 and regexp_replace(coalesce(phone,''),'\D','','g')<>'') as with_phone,
  count(*) filter (where active and coalesce(hh,0)>0 and regexp_replace(coalesce(cell,''),'\D','','g')<>'') as with_cell,
  count(*) filter (where no_sms) as all_nosms_phone,
  count(*) filter (where no_sms_cell) as all_nosms_cell
from customers;
