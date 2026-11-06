-- RY (RY Events) from the QuickBooks Customer Open Balance report of 11/05/2026. No payments report received yet.
insert into invoices (company, inv_date, inv_no, amount, note) values
 ('RY','2026-07-21','72895',18690.00,'QuickBooks'),
 ('RY','2026-07-28','72727',22470.00,'QuickBooks'),
 ('RY','2026-08-04','67554',25620.00,'QuickBooks'),
 ('RY','2026-08-11','10838',24870.00,'QuickBooks'),
 ('RY','2026-08-18','67583',24750.00,'QuickBooks'),
 ('RY','2026-08-25','72841',31340.00,'QuickBooks'),
 ('RY','2026-09-01','67514',14110.00,'QuickBooks'),
 ('RY','2026-09-08','69535',26460.00,'QuickBooks'),
 ('RY','2026-09-15','69547',26230.00,'QuickBooks'),
 ('RY','2026-09-22','69562',27180.00,'QuickBooks'),
 ('RY','2026-09-29','69566',25430.00,'QuickBooks'),
 ('RY','2026-10-06','590446',10340.00,'QuickBooks'),
 ('RY','2026-10-13','592767',12590.00,'QuickBooks'),
 ('RY','2026-10-20','68125',13400.00,'QuickBooks'),
 ('RY','2026-10-27','68173',14020.00,'QuickBooks')
on conflict do nothing;
-- Open balance 317,500.00 on 11/05/2026 aged by invoice date
insert into opening_balances (company, as_of, cur, d30, d60, d90, d120)
values ('RY','2026-11-05',40010.00,115640.00,95070.00,66780.00,0)
on conflict (company) do nothing;
