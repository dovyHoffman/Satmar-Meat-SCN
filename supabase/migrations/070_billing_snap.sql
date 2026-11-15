-- Billing of a past week is frozen: what each customer was (type, household) the week before a change lands.
create table if not exists billing_snap(
  week date not null, agency text not null, agency_ref text not null,
  name text, base text, food text, hh int, enh int default 0,
  primary key (week, agency, agency_ref));
alter table billing_snap enable row level security;
drop policy if exists p_snap_read on billing_snap;
drop policy if exists p_snap_ins on billing_snap;
create policy p_snap_read on billing_snap for select using (app_is_owner() or app_has_page('billing'));
create policy p_snap_ins on billing_snap for insert with check (app_is_owner());
create trigger nd_billing_snap before delete on billing_snap for each row execute function no_delete();
