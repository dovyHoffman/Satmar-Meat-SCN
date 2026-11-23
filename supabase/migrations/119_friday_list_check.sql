-- READ ONLY. What the Friday 11/20 list approval (12:17 PM New York) changed, by field (counts only), and leftover mismatches.
with a as (select * from audit_log where table_name='customers' and at >= '2026-11-20 17:10:00+00' and at < '2026-11-20 17:30:00+00' and action='UPDATE')
select (select count(*) from a) rows_changed,
 (select count(*) from a where old->>'base' is distinct from new->>'base') base_changed,
 (select count(*) from a where old->>'food' is distinct from new->>'food') food_changed,
 (select count(*) from a where old->>'hh' is distinct from new->>'hh') hh_changed,
 (select count(*) from a where old->>'enh' is distinct from new->>'enh') enh_changed,
 (select count(*) from a where old->>'name' is distinct from new->>'name') name_changed,
 (select count(*) from a where old->>'active'='true' and new->>'active'='false') switched_off,
 (select count(*) from a where old->>'active'='false' and new->>'active'='true') switched_on,
 (select coalesce(json_agg(json_build_object('from',o,'to',n,'n',k)),'[]'::json) from (select old->>'base' o, new->>'base' n, count(*) k from a where old->>'base' is distinct from new->>'base' group by 1,2) t) base_moves,
 (select count(*) from customers where active and agency='CCS' and base='meals' and food::text in ('raw','rawnb')) ccs_meals_with_raw,
 (select count(*) from customers where active and base='box' and food::text not in ('raw','rawnb')) box_other_food,
 (select count(*) from customers where active and base='meals' and food::text in ('raw','rawnb') and agency<>'CCS') meals_with_raw_non_ccs;
