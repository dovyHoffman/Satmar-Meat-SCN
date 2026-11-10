-- Speeds the recent-deliveries read (filter and sort by delivered_at). No data changes.
create index if not exists deliveries_delivered_at_idx on deliveries(delivered_at desc nulls last, order_id);
create index if not exists deliveries_customer_idx on deliveries(customer_id, delivered_at desc);
