-- remove the invoices / payments that were imported earlier from the QuickBooks reports (so they can be uploaded again).
-- Invoices made on the site (note "Week ..") and the test payment stay. Backup first.
create table if not exists bk_20261116_invoices as select * from invoices;
create table if not exists bk_20261116_payments as select * from payments;
alter table invoices disable trigger nd_invoices;
alter table payments disable trigger nd_payments;
with a as (delete from invoices where note = 'QuickBooks' returning 1),
     b as (delete from payments where note like 'From QuickBooks%' returning 1)
select json_build_object('invoices_removed',(select count(*) from a),'payments_removed',(select count(*) from b),
  'invoices_left',(select count(*) from invoices),'payments_left',(select count(*) from payments)) as r;
alter table invoices enable trigger nd_invoices;
alter table payments enable trigger nd_payments;
