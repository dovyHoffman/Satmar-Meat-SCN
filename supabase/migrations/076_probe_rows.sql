select 'keys' k, (select string_agg(distinct kk, ',') from list_draft, jsonb_array_elements(payload->'W'->'cur'->'rows') r, jsonb_object_keys(r) kk where id=1) v
union all select 'sample', (select r::text from list_draft, jsonb_array_elements(payload->'W'->'cur'->'rows') r where id=1 and coalesce(r->>'request','')<>'' limit 1)
union all select 'withreq', (select count(*)::text from list_draft, jsonb_array_elements(payload->'W'->'cur'->'rows') r where id=1 and coalesce(r->>'request','')<>'')
union all select 'withchange', (select count(*)::text from list_draft, jsonb_array_elements(payload->'W'->'cur'->'rows') r where id=1 and coalesce(r->>'change','')<>'');
