-- Saved invoices (number, date, amount) per company. Editable; every change goes to History; nothing is deleted.
create table if not exists invoices (
  id bigserial primary key,
  company text not null references agencies(code),
  inv_date date not null,
  inv_no text not null default '',
  amount numeric(14,2) not null check (amount >= 0),
  note text not null default '',
  voided boolean not null default false,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists invoices_company_no on invoices (company, inv_no) where inv_no <> '';
alter table invoices enable row level security;
drop policy if exists p_inv_read on invoices;
drop policy if exists p_inv_ins on invoices;
drop policy if exists p_inv_upd on invoices;
create policy p_inv_read on invoices for select using (app_has_page('billing'));
create policy p_inv_ins on invoices for insert with check (app_has_page('billing'));
create policy p_inv_upd on invoices for update using (app_has_page('billing')) with check (app_has_page('billing'));
drop trigger if exists audit_invoices on invoices;
drop trigger if exists nd_invoices on invoices;
create trigger audit_invoices after insert or update on invoices for each row execute function audit_row();
create trigger nd_invoices before delete on invoices for each row execute function no_delete();
-- LT (Light House NY): QuickBooks Customer Open Balance report 11/05/2026
insert into invoices (company, inv_date, inv_no, amount, note) values
 ('LT','2026-07-21','72734',189.00,'QuickBooks'),
 ('LT','2026-07-28','72729',12495.00,'QuickBooks'),
 ('LT','2026-08-04','67556',13362.00,'QuickBooks'),
 ('LT','2026-08-11','10839',13061.00,'QuickBooks'),
 ('LT','2026-08-18','67584',10794.00,'QuickBooks'),
 ('LT','2026-08-25','72842',10038.00,'QuickBooks'),
 ('LT','2026-09-01','67515',8493.00,'QuickBooks'),
 ('LT','2026-09-08','69527',7681.00,'QuickBooks'),
 ('LT','2026-09-15','69543',6925.00,'QuickBooks'),
 ('LT','2026-09-22','69563',6736.00,'QuickBooks'),
 ('LT','2026-09-29','89568',6358.00,'QuickBooks'),
 ('LT','2026-10-06','590449',4747.00,'QuickBooks'),
 ('LT','2026-10-13','592772',6200.00,'QuickBooks'),
 ('LT','2026-10-20','68124',6767.00,'QuickBooks'),
 ('LT','2026-10-27','68174',6389.00,'QuickBooks')
on conflict do nothing;
