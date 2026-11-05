-- Read-only check (counts only): can the owner read the saved billing lines through billing_import_rows()?
do $$
declare n int; m int; t text;
begin
  perform set_config('request.jwt.claim.sub', (select id::text from profiles where role = 'owner' and active limit 1), true);
  select count(*) into n from billing_import_rows();
  select count(*) into m from billing_import;
  raise exception 'ROWS_VIA_FUNCTION=% ROWS_IN_TABLE=%', n, m;
end $$;
