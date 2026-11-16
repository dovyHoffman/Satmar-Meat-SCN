select 'inv_'||company||'_'||coalesce(left(note,14),'') k, count(*)||' · '||sum(amount)||' · '||min(inv_date)||'..'||max(inv_date)||' voided '||count(*) filter(where voided) v from invoices where company in ('LH','LT') group by company, left(note,14)
union all select 'pay_'||company, count(*)||' · '||sum(amount)||' · '||min(paid_on)||'..'||max(paid_on)||' voided '||count(*) filter(where voided) from payments where company in ('LH','LT') group by company
union all select 'open_'||company, coalesce(as_of::text,'')||' cur'||coalesce(cur,0)||' 30:'||coalesce(d30,0)||' 60:'||coalesce(d60,0)||' 90:'||coalesce(d90,0)||' 120:'||coalesce(d120,0) from opening_balances where company in ('LH','LT')
order by 1;
