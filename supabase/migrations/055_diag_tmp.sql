select json_build_object(
 'weeks',(select json_agg(x) from (select w.id,w.label,w.week_date,w.status,(select count(*) from raw_week_items i where i.week_id=w.id and i.section='meat') meat_items,(select count(*) from raw_week_items i where i.week_id=w.id and i.section<>'meat') grocery_items,(select json_agg(json_build_object('c',c.code,'o',c.ordered)) from raw_week_counts c where c.week_id=w.id) counts from raw_weeks w order by w.week_date desc nulls last, w.id desc limit 25) x),
 'types',(select json_agg(json_build_object('code',code,'kind',kind,'sort',sort,'active',active)) from raw_box_types),
 'lib_total',(select count(*) from raw_items),
 'meat_items_nolib',(select count(*) from raw_week_items where section='meat' and item_id is null),
 'meat_items_total',(select count(*) from raw_week_items where section='meat'),
 'meat_distinct_names',(select count(distinct lower(name)) from raw_week_items where section='meat'),
 'sample_meat',(select json_agg(distinct name) from (select name from raw_week_items where section='meat' limit 40) s)) as r;
