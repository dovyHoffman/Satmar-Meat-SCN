select c.agency, coalesce(c.area::text,'-') area, c.middleton mid, count(*) active_customers,
 count(*) filter (where exists(select 1 from deliveries d where d.customer_id=c.id and d.delivered_at>='2026-10-31')) with_pod_this_week,
 count(*) filter (where exists(select 1 from deliveries d where d.customer_id=c.id and d.delivered_at>='2026-10-31' and coalesce(array_length(d.photo_urls,1),0)>0)) with_photo
from customers c where c.active group by 1,2,3 order by 1,2,3;
