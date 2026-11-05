-- Old delivery lists imported from the "Labels Delivery" Google Sheet: one row per old line, grouped by tab name (A_11_3 ...).
create table if not exists delivery_archive (
  tab text not null,
  rowno int not null,
  delivery_date date,
  line jsonb not null,
  imported_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  primary key (tab, rowno)
);
alter table delivery_archive enable row level security;
drop policy if exists p_da_read on delivery_archive;
drop policy if exists p_da_ins on delivery_archive;
drop policy if exists p_da_upd on delivery_archive;
create policy p_da_read on delivery_archive for select using (app_has_page('delivery'));
create policy p_da_ins on delivery_archive for insert with check (app_is_owner());
create policy p_da_upd on delivery_archive for update using (app_is_owner()) with check (app_is_owner());
drop trigger if exists nd_delivery_archive on delivery_archive;
create trigger nd_delivery_archive before delete on delivery_archive for each row execute function no_delete();
create or replace function archive_tabs() returns table(tab text, delivery_date date, n bigint)
language sql stable security invoker as $$
  select tab, min(delivery_date), count(*) from delivery_archive group by tab
$$;
