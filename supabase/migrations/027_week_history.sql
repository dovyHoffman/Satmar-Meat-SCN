-- Weekly history of each customer, read from the week tabs of the SCN Sheet (Week 10/31-11/7 and so on).
-- Only what the card needs: customer ID, on the list or not, box codes, food type, location, customer request, change.
-- No names, phones or addresses are stored here. Nothing is deleted; uploading a week again adds a newer batch.
create table if not exists week_history (
  week_start date not null,
  rowno int not null,
  batch text not null,
  ref text not null,
  ref_n text not null,
  in_list boolean not null default true,
  box_codes text not null default '',
  food_type text not null default '',
  location text not null default '',
  company text not null default '',
  request text not null default '',
  change text not null default '',
  change_note text not null default '',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  primary key (week_start, rowno, batch)
);
create index if not exists week_history_ref on week_history (ref_n, week_start);
alter table week_history enable row level security;
-- no policies: only the two functions below read or write it.
drop trigger if exists nd_week_history on week_history;
create trigger nd_week_history before delete on week_history for each row execute function no_delete();

create or replace function save_week_history(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not app_is_owner() then raise exception 'not allowed'; end if;
  insert into week_history (week_start, rowno, batch, ref, ref_n, in_list, box_codes, food_type, location, company, request, change, change_note)
  select (x->>'w')::date, (x->>'r')::int, x->>'b', x->>'i', lower(regexp_replace(x->>'i','\s','','g')),
         coalesce((x->>'l')::boolean, true), coalesce(x->>'x',''), coalesce(x->>'f',''), coalesce(x->>'a',''),
         coalesce(x->>'c',''), coalesce(x->>'q',''), coalesce(x->>'g',''), coalesce(x->>'n','')
  from jsonb_array_elements(p) x
  on conflict (week_start, rowno, batch) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;
grant execute on function save_week_history(jsonb) to authenticated;

create or replace function week_history_for(p text)
returns table(week_start date, in_list boolean, box_codes text, food_type text, location text, company text, request text, change text, change_note text)
language sql stable security definer set search_path = public as $$
  select h.week_start, h.in_list, h.box_codes, h.food_type, h.location, h.company, h.request, h.change, h.change_note
  from week_history h
  where h.ref_n = lower(regexp_replace(p,'\s','','g'))
    and (app_is_owner() or app_has_page('customers') or app_has_page('changes'))
    and h.batch = (select max(x.batch) from week_history x where x.week_start = h.week_start)
  order by h.week_start desc
$$;
grant execute on function week_history_for(text) to authenticated;
