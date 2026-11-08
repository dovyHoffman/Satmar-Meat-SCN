select (select count(*) from deliveries) total,
 (select count(*) from deliveries where delivered_at>=now()-interval '10 days') last10d,
 (select count(*) from deliveries where delivered_at is null) no_delivered_at,
 (select count(*) from deliveries where coalesce(array_length(photo_urls,1),0)>0 or coalesce(receipt_url,'')<>'') with_links,
 (select count(distinct customer_id) from deliveries) custs,
 (select min(delivered_at) from deliveries) mn,(select max(delivered_at) from deliveries) mx,
 (select max(synced_at) from deliveries) last_sync;
