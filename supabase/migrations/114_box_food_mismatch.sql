-- READ ONLY. Customers whose Type is Box but whose stored food type is not a box food (raw / rawnb), by agency and active flag (counts only).
select coalesce(json_agg(json_build_object('agency',agency,'food',food,'active',active,'n',n) order by agency,food),'[]'::json) mismatches
from (select agency, food, active, count(*) n from customers where base='box' and food not in ('raw','rawnb') group by 1,2,3) t;
