select 'dup' as src, k as agency, 'to' as f, regexp_replace(coalesce(v->>'to',''),'^[^@,; ]+@','','g') as dom from app_settings, jsonb_each(value) as e(k,v) where key='dup_emails'
union all select 'dup', k, 'cc', regexp_replace(coalesce(v->>'cc',''),'[^@,; ]+@','','g') from app_settings, jsonb_each(value) as e(k,v) where key='dup_emails'
union all select 'inv', k, 'to', regexp_replace(coalesce(v->>'emails',''),'[^@,; ]+@','','g') from app_settings, jsonb_each(value) as e(k,v) where key='invoice_cos'
union all select 'inv', k, 'cc', regexp_replace(coalesce(v->>'cc',''),'[^@,; ]+@','','g') from app_settings, jsonb_each(value) as e(k,v) where key='invoice_cos'
order by 1,2,3;
