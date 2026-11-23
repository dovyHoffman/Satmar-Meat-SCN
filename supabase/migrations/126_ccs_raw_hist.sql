-- READ ONLY: counts only
select 'cancelled_raw_request' k, (a.at at time zone 'America/New_York')::date d, coalesce(a.user_name,'(sql/none)') u, count(*) n
from audit_log a join customers c on c.id=(a.new->>'customer_id')::uuid
where a.table_name='change_requests' and a.action='UPDATE' and a.new->>'status'='cancelled' and a.old->>'status'='pending' and a.new->'payload'->>'food' in ('raw','rawnb') and c.agency='CCS' and c.base='meals' group by 2,3
union all
select 'cust_food_raw_to_other', (a.at at time zone 'America/New_York')::date, coalesce(a.user_name,'(sql/none)'), count(*)
from audit_log a where a.table_name='customers' and a.action='UPDATE' and a.new->>'agency'='CCS' and a.old->>'food' in ('raw','rawnb') and a.new->>'food' not in ('raw','rawnb') and a.new->>'base'='meals' group by 2,3
union all
select 'cust_food_to_raw', (a.at at time zone 'America/New_York')::date, coalesce(a.user_name,'(sql/none)'), count(*)
from audit_log a where a.table_name='customers' and a.action='UPDATE' and a.new->>'agency'='CCS' and a.new->>'food' in ('raw','rawnb') and a.old->>'food' not in ('raw','rawnb') and a.new->>'base'='meals' group by 2,3
order by 1,2;
