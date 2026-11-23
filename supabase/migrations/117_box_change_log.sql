-- READ ONLY. When/who changed Type or Food on the 8 customers (ids and the changed values only).
select c.agency, c.agency_ref, a.at, a.user_name, a.action,
  a.old->>'base' old_base, a.new->>'base' new_base, a.old->>'food' old_food, a.new->>'food' new_food, a.old->>'hh' old_hh, a.new->>'hh' new_hh
from customers c join audit_log a on a.table_name='customers' and a.row_id=c.id::text
where (c.agency, c.agency_ref) in (('CCS','FAM-1417'),('CCS','FAM-1494'),('LH','PU05648Q'),('LH','SB80984J'),('LH','TJ64378F'),('LH','TY52701G'),('LH','VB63593S'),('RY','Posen - 8453236127'))
  and (a.old->>'base' is distinct from a.new->>'base' or a.old->>'food' is distinct from a.new->>'food')
order by c.agency, c.agency_ref, a.at;
