-- Fresh safety copy right before the first approval (after the Note 2 cleanup). Copies only.
create table if not exists bk_20261114b_customers as select * from customers;
create table if not exists bk_20261114b_change_requests as select * from change_requests;
create table if not exists bk_20261114b_list_draft as select * from list_draft;
alter table bk_20261114b_customers enable row level security;
alter table bk_20261114b_change_requests enable row level security;
alter table bk_20261114b_list_draft enable row level security;
