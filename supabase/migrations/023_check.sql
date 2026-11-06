do $$ declare a int; b int; c int; d text; begin
select count(*) into a from payments where company='LT';
select count(*) into b from opening_balances where company='LT';
select count(*) into c from invoices where company='LT';
select string_agg(paid_on::text||' '||amount::text||' '||voided::text,'; ') into d from payments;
raise exception 'payments_LT=% opening_LT=% invoices_LT=% all_payments=[%]',a,b,c,d;
end $$;
