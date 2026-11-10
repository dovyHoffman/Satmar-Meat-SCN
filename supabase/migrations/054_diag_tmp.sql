select json_build_object('cust',(select json_agg(json_build_object('id',c.id,'ref',c.agency_ref,'name',c.name,'active',c.active,'agency',c.agency)) from customers c where c.agency_ref ilike 'RV61371%' or c.name ilike '%Hershkov%'),
 'deliv',(select json_agg(json_build_object('oid',d.order_id,'wk',d.week_label,'at',d.delivered_at,'cid',d.customer_id)) from deliveries d join customers c on c.id=d.customer_id where c.agency_ref ilike 'RV61371%' or c.name ilike '%Hershkov%'),
 'nullcust',(select count(*) from deliveries where customer_id is null),
 'minat',(select min(delivered_at) from deliveries)) as r;
