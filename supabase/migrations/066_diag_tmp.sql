select json_build_object(
 'cust',(select json_agg(x) from (select id,name,agency,agency_ref,area::text a,active from customers where agency_ref ilike '%9583%') x),
 'dl',(select json_agg(x) from (select d.week_label,d.delivered_at,d.synced_at,coalesce(array_length(d.photo_urls,1),0) photos,(coalesce(d.receipt_url,'')<>'') rec from deliveries d join customers c on c.id=d.customer_id where c.agency_ref ilike '%9583%' order by d.synced_at desc) x)) r;
