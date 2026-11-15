select 'bk_active_not_in_snap' k, count(*)::text v from bk_20261114b_customers b where b.active and not exists (select 1 from billing_snap s where s.week='2026-11-07' and s.agency=b.agency and s.agency_ref=b.agency_ref)
union all select 'snap_not_bk_active', count(*)::text from billing_snap s where s.week='2026-11-07' and not exists (select 1 from bk_20261114b_customers b where b.active and s.agency=b.agency and s.agency_ref=b.agency_ref)
union all select 'snap_weeks', string_agg(distinct week::text, ',') from billing_snap
union all select 'new_since_backup', count(*)::text from customers c where not exists (select 1 from bk_20261114b_customers b where b.id=c.id)
union all select 'turned_off', count(*)::text from customers c join bk_20261114b_customers b on b.id=c.id where b.active and not c.active
union all select 'turned_on', count(*)::text from customers c join bk_20261114b_customers b on b.id=c.id where not b.active and c.active
union all select 'hh_changed', count(*)::text from customers c join bk_20261114b_customers b on b.id=c.id where b.hh is distinct from c.hh
union all select 'base_changed', count(*)::text from customers c join bk_20261114b_customers b on b.id=c.id where b.base is distinct from c.base
union all select 'off_from_set', count(*)::text from customers where off_from is not null
union all select 'sample_not_in_snap', string_agg(b.agency_ref||' '||coalesce(b.name,''), ' | ') from (select * from bk_20261114b_customers b where b.active and not exists (select 1 from billing_snap s where s.week='2026-11-07' and s.agency=b.agency and s.agency_ref=b.agency_ref) limit 8) b;
