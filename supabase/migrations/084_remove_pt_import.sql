-- remove the 28 PT invoices that were just imported from "Invoice PT.xlsx" (wrong amounts). Backup first.
create table if not exists bk_20261116b_invoices as select * from invoices;
alter table invoices disable trigger nd_invoices;
with a as (delete from invoices where company='PT' and note='Imported from Invoice PT.xlsx' returning 1)
select json_build_object('removed',(select count(*) from a),'pt_left',(select count(*) from invoices where company='PT'),'invoices_left',(select count(*) from invoices)) as r;
alter table invoices enable trigger nd_invoices;
