-- READ ONLY: customer numbers only
select a.new->>'code' as id_a, a.new->>'agency_ref' as ref, a.old->>'food' as was, a.new->>'food' as now, a.new->>'hh' as hh
from audit_log a where a.table_name='customers' and a.action='UPDATE' and a.new->>'agency'='CCS' and a.old->>'food' in ('raw','rawnb') and a.new->>'food' not in ('raw','rawnb') and a.new->>'base'='meals' and (a.at at time zone 'America/New_York')::date='2026-11-22'
order by 2;
