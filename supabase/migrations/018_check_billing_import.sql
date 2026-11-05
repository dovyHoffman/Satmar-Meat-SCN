-- Read-only check (counts only): can the owner read the saved billing lines through billing_import_rows()?
select set_config('request.jwt.claim.sub', (select id::text from profiles where role = 'owner' and active limit 1), true) as who;
select 'rows_via_function' as what, count(*)::text as n from billing_import_rows();
select 'owner_ok' as what, app_is_owner()::text as n;
