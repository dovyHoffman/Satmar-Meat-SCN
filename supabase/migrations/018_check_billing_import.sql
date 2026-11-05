-- Read-only check: how many billing lines and order IDs are saved (counts only, no names).
select 'billing_import' as what, tab_date::text as a, company as b, count(*)::text as n, max(batch) as c from billing_import group by tab_date, company
union all
select 'order_map', '', '', count(*)::text, max(updated_at)::text from order_map
order by 1, 2 desc, 3;
