-- READ ONLY. Invoices made from the site (note 'Week ...'): number, company, week; and the saved 'last invoice number'.
select (select value from app_settings where key='invoice_last') last_setting,
 (select coalesce(json_agg(json_build_object('co',company,'no',inv_no,'note',note,'void',voided,'created',created_at) order by id),'[]'::json) from invoices where note like 'Week %') site_made;
