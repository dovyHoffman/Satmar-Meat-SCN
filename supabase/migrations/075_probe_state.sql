select 'active' k, count(*)::text v from customers where active
union all select 'total', count(*)::text from customers
union all select 'snap', count(*)::text from billing_snap
union all select 'draft', (select jsonb_build_object('cur',(payload->'W'->'cur'->>'label'),'next_rows',jsonb_array_length(coalesce(payload->'W'->'next'->'rows','[]'::jsonb)),'cur_rows',jsonb_array_length(coalesce(payload->'W'->'cur'->'rows','[]'::jsonb)),'prev',(payload->'W'->'prev'->>'label'),'apv',(payload->'W'->'apv'->>'label'))::text from list_draft where id=1)
union all select 'bk_cust', count(*)::text from bk_20261114b_customers
union all select 'bk_active', count(*)::text from bk_20261114b_customers where active
union all select 'wh_weeks', string_agg(distinct week_start::text, ',') from week_history;
