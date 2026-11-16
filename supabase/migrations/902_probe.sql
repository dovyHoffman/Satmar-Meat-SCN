select json_build_object(
 'inv',(select json_agg(x) from (select company,note,count(*) n,sum(amount) s,bool_or(voided) v from invoices group by company,note order by company) x),
 'pay',(select json_agg(x) from (select company,note,ptype,count(*) n,sum(amount) s from payments group by company,note,ptype order by company) x),
 'open',(select count(*) from opening_balances),
 'cols',(select json_agg(column_name) from information_schema.columns where table_name='payments')
) as r;
