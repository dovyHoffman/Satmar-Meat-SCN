-- READ ONLY. The 5 customers Friday's list moved Box -> Meals (current food), and active CCS Meals customers with a raw food (ids only).
with a as (select * from audit_log where table_name='customers' and at >= '2026-11-20 17:10:00+00' and at < '2026-11-20 17:30:00+00' and action='UPDATE')
select (select coalesce(json_agg(json_build_object('agency',c.agency,'ref',c.agency_ref,'food',c.food,'hh',c.hh,'active',c.active)),'[]'::json)
        from a join customers c on c.id::text=a.row_id where a.old->>'base'='box' and a.new->>'base'='meals') box_to_meals,
       (select coalesce(json_agg(json_build_object('ref',agency_ref,'food',food,'hh',hh)),'[]'::json)
        from customers where active and agency='CCS' and base='meals' and food::text in ('raw','rawnb')) ccs_meals_raw;
