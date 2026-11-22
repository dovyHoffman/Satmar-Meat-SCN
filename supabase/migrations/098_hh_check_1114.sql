-- READ ONLY, counts only. Week 11/14 saved billing list vs the customer list, per company.
with s as (select agency, agency_ref, base, hh, coalesce(enh,0) as enh from billing_snap where week = '2026-11-14'),
c as (select agency, agency_ref, base, hh, coalesce(enh,0) as enh from customers where active)
select coalesce(s.agency, c.agency) as company,
  (select count(*) from s s2 where s2.agency = coalesce(s.agency,c.agency)) as snap_rows,
  (select coalesce(sum(hh),0) from s s2 where s2.agency = coalesce(s.agency,c.agency)) as snap_hh,
  (select coalesce(sum(enh),0) from s s2 where s2.agency = coalesce(s.agency,c.agency)) as snap_enh,
  (select count(*) from c c2 where c2.agency = coalesce(s.agency,c.agency)) as cust_active,
  (select coalesce(sum(hh),0) from c c2 where c2.agency = coalesce(s.agency,c.agency)) as cust_hh,
  (select coalesce(sum(enh),0) from c c2 where c2.agency = coalesce(s.agency,c.agency)) as cust_enh,
  count(*) filter (where s.agency_ref is not null and c.agency_ref is not null and s.hh is distinct from c.hh) as hh_differs,
  count(*) filter (where s.agency_ref is not null and c.agency_ref is not null and s.enh is distinct from c.enh) as enh_differs,
  count(*) filter (where s.agency_ref is null) as only_in_customers,
  count(*) filter (where c.agency_ref is null) as only_in_snap
from s full join c on s.agency = c.agency and s.agency_ref = c.agency_ref
group by 1 order by 1;
