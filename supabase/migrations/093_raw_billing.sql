-- Raw billing review: what the company actually charged per case, next to what the menu person entered.
-- Menu data is never changed by this table. Page key: rawbill ("Menu · Raw billing").
create table if not exists raw_billing(
  week_id bigint not null references raw_weeks(id),
  item_id bigint not null references raw_week_items(id),
  charged numeric,                 -- price per case the company charged
  expected_at numeric,             -- the menu price per case at the moment it was entered
  comment text not null default '',
  reviewed boolean not null default false,   -- billing accepted a difference
  updated_by uuid default auth.uid(),
  updated_by_name text not null default '',
  updated_at timestamptz not null default now(),
  primary key (week_id, item_id)
);
alter table raw_billing enable row level security;
drop policy if exists p_raw_billing_sel on raw_billing;
drop policy if exists p_raw_billing_ins on raw_billing;
drop policy if exists p_raw_billing_upd on raw_billing;
create policy p_raw_billing_sel on raw_billing for select using (app_is_owner() or app_has_page('raw') or app_has_page('rawbill'));
create policy p_raw_billing_ins on raw_billing for insert with check (app_is_owner() or app_has_page('rawbill'));
create policy p_raw_billing_upd on raw_billing for update using (app_is_owner() or app_has_page('rawbill')) with check (app_is_owner() or app_has_page('rawbill'));
-- the billing person can read the menu tables (read only)
do $$ declare t text; begin
 foreach t in array array['raw_box_types','raw_items','raw_weeks','raw_week_counts','raw_week_items'] loop
  execute format('drop policy if exists p_%1$s_bill_sel on %1$s', t);
  execute format('create policy p_%1$s_bill_sel on %1$s for select using (app_has_page(''rawbill''))', t);
 end loop;
end $$;
drop trigger if exists audit_raw_billing on raw_billing;
drop trigger if exists nd_raw_billing on raw_billing;
create trigger audit_raw_billing after insert or update on raw_billing for each row execute function audit_row();
create trigger nd_raw_billing before delete on raw_billing for each row execute function no_delete();
