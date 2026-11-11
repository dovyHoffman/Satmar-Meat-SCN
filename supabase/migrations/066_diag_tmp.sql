select json_build_object(
 'cols',(select json_agg(column_name) from information_schema.columns where table_name='deliveries' and table_schema='public'),
 'null_total',(select count(*) from deliveries where customer_id is null),
 'null_photo',(select count(*) from deliveries where customer_id is null and coalesce(array_length(photo_urls,1),0)>0),
 'null_by_wk',(select json_agg(x) from (select week_label w,count(*) n from deliveries where customer_id is null group by 1 order by 2 desc limit 8) x),
 'order_map',(select count(*) from order_map),
 'om_cols',(select json_agg(column_name) from information_schema.columns where table_name='order_map' and table_schema='public'),
 'om_sample',(select json_agg(x) from (select order_id,app_id,letters from order_map limit 4) x)) r;
