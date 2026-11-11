-- Past weeks on a customer card: the weeks that only exist in the billing sheet (Billing SCN 82 import),
-- with the receipt / proof-of-delivery links written there. Read only.
create or replace function customer_billing_history(p_ref text)
returns table(tab_date date, company text, ref text, base text, food text, hh int, links text[])
language sql stable security definer set search_path = public as $$
  with newest as (select x.tab_date, x.company, max(x.batch) batch from billing_import x group by x.tab_date, x.company)
  select b.tab_date, b.company, b.ref, b.base, b.food, b.hh, b.links
  from billing_import b join newest n on n.tab_date=b.tab_date and n.company=b.company and n.batch=b.batch
  where lower(regexp_replace(b.ref,'[^a-zA-Z0-9]','','g')) = lower(regexp_replace(coalesce(p_ref,''),'[^a-zA-Z0-9]','','g'))
    and coalesce(p_ref,'')<>''
    and (app_is_owner() or app_has_page('customers') or app_has_page('billing'))
  order by b.tab_date desc, b.company
$$;
grant execute on function customer_billing_history(text) to authenticated;
