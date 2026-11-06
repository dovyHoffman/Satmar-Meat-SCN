-- CCS from the QuickBooks reports of 11/05/2026.
-- Invoices (original amounts)
insert into invoices (company, inv_date, inv_no, amount, note) values
 ('CCS','2026-08-04','67558',116625.00,'QuickBooks'),
 ('CCS','2026-08-11','10841',110389.00,'QuickBooks'),
 ('CCS','2026-08-18','67586',107321.00,'QuickBooks'),
 ('CCS','2026-08-25','72844',103653.00,'QuickBooks'),
 ('CCS','2026-09-01','67517',35152.00,'QuickBooks'),
 ('CCS','2026-09-08','69529',58365.00,'QuickBooks'),
 ('CCS','2026-09-15','69545',106754.00,'QuickBooks'),
 ('CCS','2026-09-22','69565',108204.50,'QuickBooks'),
 ('CCS','2026-09-29','89569',113874.50,'QuickBooks'),
 ('CCS','2026-10-06','590450',32785.00,'QuickBooks'),
 ('CCS','2026-10-13','592769',31851.00,'QuickBooks'),
 ('CCS','2026-10-20','68127',42940.50,'QuickBooks'),
 ('CCS','2026-10-27','68175',47258.00,'QuickBooks')
on conflict do nothing;
-- Payments
insert into payments (company, paid_on, amount, ptype, ref, note)
select 'CCS', v.d::date, v.a, v.t, v.r, 'From QuickBooks Payments report 11/05/2026'
from (values
 ('2026-09-24',90000.00,'ach','ach'),
 ('2026-09-22',71395.50,'ach','ach'),
 ('2026-09-22',109603.50,'ach','ach'),
 ('2026-09-04',20122.00,'ach','ach'),
 ('2026-09-04',22000.00,'ach','ach'),
 ('2026-08-18',225000.00,'check','30944'),
 ('2026-08-11',25000.00,'ach','ach'),
 ('2026-07-21',25000.00,'ach','ach')
) as v(d,a,t,r)
where not exists (select 1 from payments p where p.company='CCS' and p.paid_on=v.d::date and p.amount=v.a);
-- Starting balance: open balance 925,172.50 on 11/05/2026 aged by invoice date
insert into opening_balances (company, as_of, cur, d30, d60, d90, d120)
values ('CCS','2026-11-05',122049.50,419983.00,356515.00,26625.00,0)
on conflict (company) do nothing;
