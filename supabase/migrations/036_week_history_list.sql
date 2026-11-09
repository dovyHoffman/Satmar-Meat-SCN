-- The whole list of one past week (from the SCN Sheet week tab), so billing can use LAST week's list
-- instead of today's active list. Only the owner or the Billing page can read it.
create or replace function week_history_list(w date)
returns table(ref text, in_list boolean, box_codes text, food_type text, location text, company text, request text, hh text, flags text)
language sql stable security definer set search_path = public as $$
  select h.ref, h.in_list, h.box_codes, h.food_type, h.location, h.company, h.request, h.hh, h.flags
  from week_history h
  where h.week_start = w
    and (app_is_owner() or app_has_page('billing'))
    and h.batch = (select max(x.batch) from week_history x where x.week_start = w)
  order by h.rowno
$$;
grant execute on function week_history_list(date) to authenticated;
