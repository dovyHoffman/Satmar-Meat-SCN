select json_build_object(
 'active_by_area',(select json_agg(x) from (select coalesce(area,'(none)') a,count(*) n from customers where active group by 1 order by 2 desc) x),
 'deliv_by_area_4w',(select json_agg(x) from (select coalesce(c.area,'(none)') a,count(*) n,count(distinct c.id) custs from deliveries d join customers c on c.id=d.customer_id where d.delivered_at>=now()-interval '28 days' group by 1 order by 2 desc) x),
 'bp_by_agency_active',(select json_agg(x) from (select agency,count(*) n from customers where active and area='bp' group by 1) x),
 'bp_deliv_total',(select count(*) from deliveries d join customers c on c.id=d.customer_id where c.area='bp'),
 'bp_deliv_withpod',(select count(*) from deliveries d join customers c on c.id=d.customer_id where c.area='bp' and (coalesce(array_length(d.photo_urls,1),0)>0 or d.receipt_url is not null)),
 'bp_sample',(select json_agg(x) from (select c.agency_ref,c.name,c.agency from customers c where c.active and c.area='bp' order by random() limit 6) x),
 'bp_deliv_sample',(select json_agg(x) from (select d.week_label,d.delivered_at,c.agency_ref from deliveries d join customers c on c.id=d.customer_id where c.area='bp' order by d.delivered_at desc nulls last limit 6) x)) r;
