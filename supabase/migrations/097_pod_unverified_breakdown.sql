-- READ ONLY: counts only. Of this week's linked deliveries that have no box letters, which area are the customers in?
select c.area,
       count(*) as deliveries_without_letters,
       count(*) filter (where d.order_id ~ '^[0-9]+$') as numeric_order_id,
       count(*) filter (where d.order_id !~ '^[0-9]+$') as other_order_id
from deliveries d join customers c on c.id = d.customer_id
where d.customer_id is not null
  and coalesce(d.delivered_at, d.synced_at) >= '2026-11-16 05:00:00+00'
  and coalesce(nullif(d.snap->>'letters',''),'') = ''
group by c.area order by 2 desc;
