select (select count(*) from deliveries where customer_id is null) unmatched_total,
 (select count(*) from deliveries where customer_id is null and synced_at>='2026-11-01') unmatched_recent,
 (select count(*) from order_map) order_map_rows,
 (select count(*) from order_map m join deliveries d on d.order_id=m.order_id) map_with_delivery,
 (select count(*) from deliveries where delivered_at>='2026-10-31' and customer_id is not null) matched_this_week,
 (select count(distinct driver) from deliveries where delivered_at>='2026-10-31') drivers,
 (select string_agg(distinct driver, ', ') from (select driver from deliveries where delivered_at>='2026-10-31' limit 60) x) sample_drivers;
