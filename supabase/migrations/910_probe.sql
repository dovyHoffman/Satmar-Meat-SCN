select 'pt_left' k, count(*)::text v from invoices where company='PT' union all select 'all_left', count(*)::text from invoices;
