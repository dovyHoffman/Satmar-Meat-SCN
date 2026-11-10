-- Item library for the Meat Menu: every meat item is kept with a short code (for example 102 for chicken bottoms).
alter table raw_items add column if not exists code text;
alter table raw_items add column if not exists section text not null default 'grocery';
create unique index if not exists raw_items_code_uq on raw_items (lower(code)) where code is not null and code <> '';
-- keep the meat items already used in weeks: put them in the library and link them
insert into raw_items (name, name_key, section, case_price, units_per_case, last_used, uses)
select distinct on (k) trim(i.name), k, 'meat', i.case_price, 1, w.week_date, 1
from (select i.*, lower(regexp_replace(trim(i.name), '\s+', ' ', 'g')) as k from raw_week_items i where i.section = 'meat' and i.item_id is null) i
join raw_weeks w on w.id = i.week_id
order by k, w.week_date desc nulls last
on conflict (name_key) do nothing;
update raw_week_items i set item_id = r.id
from raw_items r
where i.section = 'meat' and i.item_id is null and r.name_key = lower(regexp_replace(trim(i.name), '\s+', ' ', 'g'));
update raw_items r set section = 'meat'
where r.section <> 'meat' and exists (select 1 from raw_week_items i where i.item_id = r.id and i.section = 'meat')
  and not exists (select 1 from raw_week_items i where i.item_id = r.id and i.section <> 'meat');
