select coalesce(d.driver,'') driver, (d.delivered_at is not null) delivered, (m.order_id is not null) in_map, count(*) n
from deliveries d left join order_map m on m.order_id=d.order_id where d.customer_id is null group by 1,2,3 order by n desc limit 25;
