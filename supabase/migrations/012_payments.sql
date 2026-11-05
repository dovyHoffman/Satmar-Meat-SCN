-- Payments received from companies, and starting balances (current / 30 / 60 / 90 / 120+ days).
-- Nothing is ever deleted: a wrong payment is voided and stays visible. Every change goes to History.
create table if not exists payments (
  id bigserial primary key,
  company text not null references agencies(code),
  paid_on date not null,
  amount numeric(14,2) not null check (amount > 0),
  ptype text not null default 'check',        -- check, ach, wire, zelle, cash, card, other
  ref text not null default '',               -- check number / reference
  note text not null default '',
  voided boolean not null default false,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);
create table if not exists opening_balances (
  company text primary key references agencies(code),
  as_of date not null,                        -- the date these balances were taken
  cur numeric(14,2) not null default 0,       -- 0-29 days
  d30 numeric(14,2) not null default 0,       -- 30-59 days
  d60 numeric(14,2) not null default 0,       -- 60-89 days
  d90 numeric(14,2) not null default 0,       -- 90-119 days
  d120 numeric(14,2) not null default 0,      -- 120+ days
  updated_at timestamptz not null default now()
);
alter table payments enable row level security;
alter table opening_balances enable row level security;
drop policy if exists p_pay_read on payments;
drop policy if exists p_pay_ins on payments;
drop policy if exists p_pay_upd on payments;
create policy p_pay_read on payments for select using (app_has_page('billing'));
create policy p_pay_ins on payments for insert with check (app_has_page('billing'));
create policy p_pay_upd on payments for update using (app_has_page('billing')) with check (app_has_page('billing'));
drop policy if exists p_ob_read on opening_balances;
drop policy if exists p_ob_ins on opening_balances;
drop policy if exists p_ob_upd on opening_balances;
create policy p_ob_read on opening_balances for select using (app_has_page('billing'));
create policy p_ob_ins on opening_balances for insert with check (app_has_page('billing'));
create policy p_ob_upd on opening_balances for update using (app_has_page('billing')) with check (app_has_page('billing'));
drop trigger if exists audit_payments on payments;
drop trigger if exists audit_opening on opening_balances;
drop trigger if exists nd_payments on payments;
drop trigger if exists nd_opening on opening_balances;
create trigger audit_payments after insert or update on payments for each row execute function audit_row();
create trigger audit_opening after insert or update on opening_balances for each row execute function audit_row();
create trigger nd_payments before delete on payments for each row execute function no_delete();
create trigger nd_opening before delete on opening_balances for each row execute function no_delete();
