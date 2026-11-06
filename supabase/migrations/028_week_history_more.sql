-- Week history: add household size and the selection flags (No Beef / Raw / Suppers / Shabbos), and a list of the weeks uploaded.
alter table week_history add column if not exists hh text not null default '';
alter table week_history add column if not exists flags text not null default '';

create or replace function save_week_history(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not app_is_owner() then raise exception 'not allowed'; end if;
  insert into week_history (week_start, rowno, batch, ref, ref_n, in_list, box_codes, food_type, location, company, request, change, change_note, hh, flags)
  select (x->>'w')::date, (x->>'r')::int, x->>'b', x->>'i', lower(regexp_replace(x->>'i','\s','','g')),
         coalesce((x->>'l')::boolean, true), coalesce(x->>'x',''), coalesce(x->>'f',''), coalesce(x->>'a',''),
         coalesce(x->>'c',''), coalesce(x->>'q',''), coalesce(x->>'g',''), coalesce(x->>'n',''),
         coalesce(x->>'h',''), coalesce(x->>'z','')
  from jsonb_array_elements(p) x
  on conflict (week_start, rowno, batch) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;
grant execute on function save_week_history(jsonb) to authenticated;

drop function if exists week_history_for(text);
create function week_history_for(p text)
returns table(week_start date, in_list boolean, box_codes text, food_type text, location text, company text, request text, change text, change_note text, hh text, flags text)
language sql stable security definer set search_path = public as $$
  select h.week_start, h.in_list, h.box_codes, h.food_type, h.location, h.company, h.request, h.change, h.change_note, h.hh, h.flags
  from week_history h
  where h.ref_n = lower(regexp_replace(p,'\s','','g'))
    and (app_is_owner() or app_has_page('customers') or app_has_page('changes'))
    and h.batch = (select max(x.batch) from week_history x where x.week_start = h.week_start)
  order by h.week_start desc
$$;
grant execute on function week_history_for(text) to authenticated;

create or replace function week_history_weeks()
returns table(week_start date)
language sql stable security definer set search_path = public as $$
  select distinct h.week_start from week_history h
  where (app_is_owner() or app_has_page('customers') or app_has_page('changes'))
  order by 1 desc
$$;
grant execute on function week_history_weeks() to authenticated;
