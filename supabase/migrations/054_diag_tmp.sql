select json_build_object(
 'by_agency_area_recent',(select json_agg(x) from (select c.agency, coalesce(c.middleton,false) mid, count(*) n from deliveries d join customers c on c.id=d.customer_id where d.delivered_at>='2026-10-12' group by 1,2 order by 1,2) x),
 'active_by_agency_area',(select json_agg(x) from (select agency, coalesce(middleton,false) mid, count(*) n from customers where active group by 1,2 order by 1,2) x),
 'rechy',(select json_agg(json_build_object('ref',c.agency_ref,'name',c.name,'active',c.active,'mid',c.middleton,'deliveries',(select count(*) from deliveries d where d.customer_id=c.id))) from customers c where c.name ilike 'Rechy%')) as r;
