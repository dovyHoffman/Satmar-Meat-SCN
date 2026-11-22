-- READ ONLY, counts only. Week 11/14 saved billing list vs the customer list, per company.
with s as (select agency, agency_ref, hh, coalesce(enh,0) as enh from billing_snap where week = '2026-11-14'),
c as (select agency, agency_ref, hh, coalesce(enh,0) as enh from customers where active),
j as (
  select coalesce(s.agency, c.agency) as company,
         s.agency_ref as sref, c.agency_ref as cref,
         s.hh as shh, c.hh as chh, s.enh as senh, c.enh as cenh
  from s full join c on s.agency = c.agency and s.agency_ref = c.agency_ref
)
select company,
  count(sref) as snap_rows, coalesce(sum(shh),0) as snap_hh, coalesce(sum(senh),0) as snap_enh,
  count(cref) as cust_active, coalesce(sum(chh),0) as cust_hh, coalesce(sum(cenh),0) as cust_enh,
  count(*) filter (where sref is not null and cref is not null and shh is distinct from chh) as hh_differs,
  count(*) filter (where sref is not null and cref is not null and senh is distinct from cenh) as enh_differs,
  count(*) filter (where sref is null) as only_in_customers,
  count(*) filter (where cref is null) as only_in_snap
from j group by company order by company;
