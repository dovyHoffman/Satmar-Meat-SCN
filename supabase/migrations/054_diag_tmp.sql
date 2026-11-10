select c.id, c.agency, c.agency_ref, c.name, c.active from customers c where c.agency_ref ilike 'RV61371%' or c.name ilike 'Rachel%Hershkov%' or c.name ilike 'Hershkov%';
select d.order_id, d.week_label, d.delivered_at, d.driver, d.customer_id, c.agency_ref from deliveries d join customers c on c.id=d.customer_id where c.agency_ref ilike 'RV61371%' or c.name ilike '%Hershkov%' order by d.delivered_at desc nulls last limit 30;
select min(delivered_at), max(delivered_at), count(*) from deliveries;
select date_trunc('week', delivered_at) w, count(*) from deliveries group by 1 order by 1 desc limit 14;
