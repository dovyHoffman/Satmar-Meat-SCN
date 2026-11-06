-- OR (Ohros) from the QuickBooks reports of 11/05/2026.
insert into invoices (company, inv_date, inv_no, amount, note) values
 ('OR','2026-07-07','72778',10040.00,'QuickBooks'),
 ('OR','2026-07-14','72859',9595.00,'QuickBooks'),
 ('OR','2026-07-21','72889',1890.00,'QuickBooks'),
 ('OR','2026-07-28','72728',1890.00,'QuickBooks'),
 ('OR','2026-08-04','67555',1890.00,'QuickBooks')
on conflict do nothing;
insert into payments (company, paid_on, amount, ptype, ref, note)
select 'OR', v.d::date, v.a, v.t, v.r, 'From QuickBooks Payments report 11/05/2026'
from (values
 ('2026-10-20',9450.00,'check','1049'),
 ('2026-07-21',20660.00,'card','cc')
) as v(d,a,t,r)
where not exists (select 1 from payments p where p.company='OR' and p.paid_on=v.d::date and p.amount=v.a);
-- Open balance 22,125.00 on 11/05/2026 aged by invoice date
insert into opening_balances (company, as_of, cur, d30, d60, d90, d120)
values ('OR','2026-11-05',0,0,0,15265.00,6860.00)
on conflict (company) do nothing;
