-- READ ONLY. Invoice numbers per company: which numbers are used by more than one saved invoice, and the latest saved ones.
select (select coalesce(json_agg(json_build_object('co',company,'no',inv_no,'n',n)),'[]'::json) from (select company,inv_no,count(*) n from invoices where inv_no<>'' group by 1,2 having count(*)>1) d) dup_numbers,
 (select coalesce(json_agg(json_build_object('co',company,'no',inv_no,'note',note,'date',inv_date,'void',voided) order by id desc),'[]'::json) from (select * from invoices order by id desc limit 14) r) latest_14;
