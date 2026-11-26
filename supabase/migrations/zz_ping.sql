select now()::text a, (select count(*) from customers)::text b;
