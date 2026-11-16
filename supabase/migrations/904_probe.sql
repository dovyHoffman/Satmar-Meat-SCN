select json_build_object(
 'cust',(select json_agg(x) from (select agency_ref,name,base,food,hh,enh,active from customers where agency='LT' and agency_ref in ('LT00001','LT00122','LT00050','LT00134','LT00219')) x),
 'snap',(select json_agg(x) from (select week,agency_ref,base,food,hh,enh from billing_snap where agency='LT' and agency_ref in ('LT00001','LT00122','LT00050','LT00134','LT00219') order by week) x),
 'enh_counts',(select json_agg(x) from (select agency,count(*) n from customers where enh>0 group by 1) x),
 'snap_enh',(select json_agg(x) from (select week,agency,count(*) n from billing_snap where enh>0 group by 1,2 order by 1,2) x)
) as r;
