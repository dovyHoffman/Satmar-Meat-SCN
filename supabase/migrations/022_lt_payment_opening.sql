-- LT (Light House NY) from the QuickBooks reports of 11/05/2026.
-- Payment: check 1025, 10/20/2026, $39,113.00.
insert into payments (company, paid_on, amount, ptype, ref, note)
select 'LT','2026-10-20',39113.00,'check','1025','From QuickBooks Payments report 11/05/2026'
where not exists (select 1 from payments where company='LT' and ref='1025' and paid_on='2026-10-20');
-- Starting balance: open invoices on the QuickBooks Customer Open Balance report (15 invoices, 07/21 to 10/27) = 120,235.00,
-- aged from the invoice date as of 11/05/2026. The payment above is already taken off those invoices in QuickBooks.
insert into opening_balances (company, as_of, cur, d30, d60, d90, d120)
values ('LT','2026-11-05',19356,32447,42386,26046,0)
on conflict (company) do nothing;
