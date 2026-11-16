select 'inv_'||company||'_'||id k, inv_date||' '||inv_no||' '||amount||' '||coalesce(left(note,22),'')||case when voided then ' VOIDED' else '' end v from invoices where company in ('LH','LT') and inv_date>='2026-10-20'
union all select 'pay_'||company||'_'||id, paid_on||' '||amount||' '||coalesce(ref,'')||case when voided then ' VOIDED' else '' end from payments where company in ('LH') and paid_on>='2026-10-01'
order by 1;
