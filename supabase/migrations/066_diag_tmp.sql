select json_build_object(
 'phone_ok_by_area',(select json_agg(x) from (select area::text a,count(*) n,count(*) filter (where regexp_replace(coalesce(phone,''),'\D','','g') ~ '^1?[2-9]\d\d[2-9]\d{6}$') ok from customers where active group by 1) x),
 'last_sync_by_area',(select json_agg(x) from (select c.area::text a,max(d.synced_at) s,max(d.delivered_at) dl,max(d.week_label) wl from deliveries d join customers c on c.id=d.customer_id group by 1) x),
 'bp_by_week',(select json_agg(x) from (select to_char(coalesce(d.delivered_at,d.synced_at),'MM-DD') dt,count(*) n from deliveries d join customers c on c.id=d.customer_id where c.area::text='bp' group by 1 order by 1 desc limit 15) x),
 'lee_by_week',(select json_agg(x) from (select to_char(coalesce(d.delivered_at,d.synced_at),'MM-DD') dt,count(*) n from deliveries d join customers c on c.id=d.customer_id where c.area::text='lee' group by 1 order by 1 desc limit 8) x),
 'nullcust',(select count(*) from deliveries where customer_id is null)) r;
