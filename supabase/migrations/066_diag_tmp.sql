with u as (select d.order_id,d.photo_urls,m.app_id,lower(regexp_replace(coalesce(m.app_id,''),'[^a-zA-Z0-9]','','g')) k from deliveries d left join order_map m on m.order_id=d.order_id where d.customer_id is null),
cu as (select id,area::text a,agency,lower(regexp_replace(agency_ref,'[^a-zA-Z0-9]','','g')) k,regexp_replace(agency_ref,'\D','','g') dg from customers),
cls as (select u.*, case when app_id is null then 'no_map' when k='' then 'empty' when k ~ '^[0-9]+$' then 'digits_only' else 'other' end kind from u)
select json_build_object(
 'kinds',(select json_agg(x) from (select kind,count(*) n,count(*) filter (where coalesce(array_length(photo_urls,1),0)>0) ph from cls group by 1) x),
 'digits_unique_match',(select count(*) from cls where kind='digits_only' and (select count(*) from cu where cu.dg=cls.k)=1),
 'digits_match_area',(select json_agg(x) from (select cu.a,count(*) n from cls join cu on cu.dg=cls.k where kind='digits_only' and (select count(*) from cu c2 where c2.dg=cls.k)=1 group by 1) x),
 'other_sample',(select json_agg(app_id) from (select app_id from cls where kind='other' limit 12) z),
 'other_matchable',(select count(*) from cls where kind='other' and exists(select 1 from cu where cu.k=cls.k)),
 'digits_sample',(select json_agg(app_id) from (select app_id from cls where kind='digits_only' limit 8) z)) r;
