-- POD links typed in by hand for a customer in a billing week (when the driver app has none). One link per company + customer + week.
create table if not exists manual_pods (
  id bigserial primary key,
  company text not null references agencies(code),
  ref text not null,
  week text not null,
  url text not null,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company, ref, week)
);
alter table manual_pods enable row level security;
drop policy if exists p_mp_read on manual_pods;
drop policy if exists p_mp_ins on manual_pods;
drop policy if exists p_mp_upd on manual_pods;
create policy p_mp_read on manual_pods for select using (app_has_page('billing'));
create policy p_mp_ins on manual_pods for insert with check (app_has_page('billing'));
create policy p_mp_upd on manual_pods for update using (app_has_page('billing')) with check (app_has_page('billing'));
drop trigger if exists audit_manual_pods on manual_pods;
drop trigger if exists nd_manual_pods on manual_pods;
create trigger audit_manual_pods after insert or update on manual_pods for each row execute function audit_row();
create trigger nd_manual_pods before delete on manual_pods for each row execute function no_delete();
