-- Raw-box price by household size (1-10) for each company. Blank = the flat box price x household is used.
-- Nothing is deleted; every change goes to History.
create table if not exists agency_hh_prices (
  agency text not null references agencies(code),
  hh int not null check (hh between 1 and 10),
  price numeric(12,2) check (price >= 0),
  updated_at timestamptz not null default now(),
  primary key (agency, hh)
);
alter table agency_hh_prices enable row level security;
drop policy if exists p_hhp_read on agency_hh_prices;
drop policy if exists p_hhp_ins on agency_hh_prices;
drop policy if exists p_hhp_upd on agency_hh_prices;
create policy p_hhp_read on agency_hh_prices for select using (app_has_page('billing'));
create policy p_hhp_ins on agency_hh_prices for insert with check (app_has_page('billing'));
create policy p_hhp_upd on agency_hh_prices for update using (app_has_page('billing')) with check (app_has_page('billing'));
drop trigger if exists audit_hhp on agency_hh_prices;
drop trigger if exists nd_hhp on agency_hh_prices;
create trigger audit_hhp after insert or update on agency_hh_prices for each row execute function audit_row();
create trigger nd_hhp before delete on agency_hh_prices for each row execute function no_delete();
-- LT member list
insert into agency_hh_prices (agency, hh, price) values
 ('LT',1,100),('LT',2,159),('LT',3,213),('LT',4,261),('LT',5,303),('LT',6,358),('LT',7,392),('LT',8,441),('LT',9,491),('LT',10,541)
on conflict (agency, hh) do nothing;
