-- Order IDs and box letters from the Scanovator export (ORDERS tabs): order number -> Application ID + case description.
-- The delivery feed does not send these two fields, so the owner uploads them once from the Import page.
create table if not exists order_map (
  order_id text primary key,                 -- Scanovator "Order ID"
  app_id text not null default '',           -- "Application ID" (our customer ID)
  letters text not null default '',          -- "case description", e.g. "C,E"
  updated_at timestamptz not null default now()
);
alter table order_map enable row level security;
-- no policies: only the owner function below and the sync function (service role) touch this table.

create or replace function save_order_map(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not app_is_owner() then raise exception 'not allowed'; end if;
  insert into order_map (order_id, app_id, letters)
  select x->>'o', coalesce(x->>'a',''), coalesce(x->>'l','')
  from jsonb_array_elements(p) x
  where coalesce(x->>'o','') <> ''
  on conflict (order_id) do update
    set app_id = excluded.app_id, letters = excluded.letters, updated_at = now();
  get diagnostics n = row_count;
  -- deliveries already saved get their box letters right away
  update deliveries d
     set snap = coalesce(d.snap,'{}'::jsonb) || jsonb_build_object('letters', replace(upper(m.letters), ',', ' '))
    from order_map m
   where m.order_id = d.order_id and m.letters <> '';
  return n;
end $$;
grant execute on function save_order_map(jsonb) to authenticated;
