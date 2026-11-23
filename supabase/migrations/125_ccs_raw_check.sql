select 'pending_raw_requests' as k, count(*) from change_requests r join customers c on c.id=r.customer_id where r.status='pending' and c.agency='CCS' and c.base='meals' and r.payload->>'food' in ('raw','rawnb')
union all select 'ccs_meals_now_raw', count(*) from customers where agency='CCS' and base='meals' and active and food in ('raw','rawnb');
