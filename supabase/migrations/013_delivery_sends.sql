-- Delivery page: a record of every delivery list that was confirmed (who, when, which date, which customers).
-- Nothing is ever deleted; every change goes to History.
create table if not exists delivery_sends (
  id bigserial primary key,
  batch text not null,                          -- one id per Confirm click
  customer_id uuid not null references customers(id),
  delivery_date date not null,
  admin_note text not null default '',          -- the area (Lee, BP, ...)
  letters text not null default '',             -- box letters sent, e.g. "E,B"
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);
create index if not exists delivery_sends_date on delivery_sends(delivery_date);
alter table delivery_sends enable row level security;
drop policy if exists p_ds_read on delivery_sends;
drop policy if exists p_ds_ins on delivery_sends;
create policy p_ds_read on delivery_sends for select using (app_has_page('delivery'));
create policy p_ds_ins on delivery_sends for insert with check (app_has_page('delivery'));
drop trigger if exists audit_delivery_sends on delivery_sends;
drop trigger if exists nd_delivery_sends on delivery_sends;
create trigger audit_delivery_sends after insert or update on delivery_sends for each row execute function audit_row();
create trigger nd_delivery_sends before delete on delivery_sends for each row execute function no_delete();
update profiles set pages = array_append(pages,'delivery') where role = 'secretary' and not ('delivery' = any(pages));
