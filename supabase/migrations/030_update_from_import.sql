-- Lets the owner refresh household size, food type, box type and area of EXISTING customers from the Customer_data file.
-- Never touches name, address, phone, notes or the active flag. Every change is recorded by the normal history triggers.
create or replace function update_customers_from_import(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not app_is_owner() then raise exception 'owner only'; end if;
  update customers c set hh = x.hh, base = x.base::base_t, food = x.food::food_t, area = x.area::area_t, middleton = x.middleton
  from jsonb_to_recordset(p) as x(agency text, ref text, hh int, base text, food text, area text, middleton boolean)
  where c.agency = x.agency
    and c.id_norm = lower(regexp_replace(x.ref,'[\s\-]+','','g'))
    and (c.hh, c.base::text, c.food::text, c.area::text, c.middleton) is distinct from (x.hh, x.base, x.food, x.area, x.middleton);
  get diagnostics n = row_count;
  return n;
end $$;
grant execute on function update_customers_from_import(jsonb) to authenticated;
