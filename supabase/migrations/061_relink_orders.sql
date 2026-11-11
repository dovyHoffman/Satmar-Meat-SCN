-- Link deliveries that have no customer yet, using the order -> Application ID map.
-- Only exact ID matches that fit exactly ONE customer. Safe to run again.
with n as (select id, lower(regexp_replace(agency_ref,'[^a-zA-Z0-9]','','g')) k from customers where coalesce(agency_ref,'')<>''),
u as (select k, (array_agg(id))[1] id from n group by k having count(*)=1),
x as (
  update deliveries d set customer_id=u.id
  from order_map m join u on u.k=lower(regexp_replace(m.app_id,'[^a-zA-Z0-9]','','g'))
  where m.order_id=d.order_id and d.customer_id is null
  returning d.order_id, (coalesce(array_length(d.photo_urls,1),0)>0) ph)
select json_build_object('linked',(select count(*) from x),'with_photo',(select count(*) from x where ph),'still_unlinked',(select count(*) from deliveries where customer_id is null)) r;
