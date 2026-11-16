select 'price_'||agency k, 'box '||coalesce(box_price::text,'-')||' meal '||coalesce(meal_price::text,'-') v from agency_prices where agency='CCS'
union all select 'hh_'||hh, coalesce(price::text,'-') from agency_hh_prices where agency='CCS'
union all select 'inv_'||inv_no, amount::text||' '||inv_date||' '||note from invoices where company='CCS' order by 1;
