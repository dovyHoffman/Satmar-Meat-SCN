-- One-time safety copy taken right before the first "Approve all ticked boxes" (2026-11-14).
-- Copies only; nothing is changed. RLS on with no policies = nobody can read them from the website.
create table if not exists bk_20261114_customers as select * from customers;
create table if not exists bk_20261114_change_requests as select * from change_requests;
create table if not exists bk_20261114_list_draft as select * from list_draft;
alter table bk_20261114_customers enable row level security;
alter table bk_20261114_change_requests enable row level security;
alter table bk_20261114_list_draft enable row level security;
