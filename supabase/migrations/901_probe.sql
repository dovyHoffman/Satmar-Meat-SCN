select json_build_object(
 'deliveries_total',(select count(*) from deliveries),
 'linked',(select count(*) from deliveries where customer_id is not null),
 'not_in_order_map',(select count(*) from deliveries d where not exists (select 1 from order_map o where o.order_id::text=d.order_id::text)),
 'linked_not_in_map',(select count(*) from deliveries d where customer_id is not null and not exists (select 1 from order_map o where o.order_id::text=d.order_id::text)),
 'order_map_rows',(select count(*) from order_map),
 'since_oct1_not_in_map',(select count(*) from deliveries d where delivered_at>='2026-10-01' and not exists (select 1 from order_map o where o.order_id::text=d.order_id::text))
) as r;
