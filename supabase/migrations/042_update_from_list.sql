-- Weekly list upload: for customers that already exist, refresh name, household size, food type, box type, area and who is on the list.
-- Never touches phone, cell, address, email or notes. Every change is recorded by the normal history triggers. Nothing is deleted.
create or replace function update_customers_from_list(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not app_is_owner() then raise exception 'owner only'; end if;
  update customers c set name = x.name, hh = x.hh, base = x.base::base_t, food = x.food::food_t, area = x.area::area_t, middleton = x.middleton, active = x.active
  from jsonb_to_recordset(p) as x(agency text, ref text, name text, hh int, base text, food text, area text, middleton boolean, active boolean)
  where c.agency = x.agency
    and c.id_norm = lower(regexp_replace(x.ref,'[\s\-]+','','g'))
    and (c.name, c.hh, c.base::text, c.food::text, c.area::text, c.middleton, c.active) is distinct from (x.name, x.hh, x.base, x.food, x.area, x.middleton, x.active);
  get diagnostics n = row_count;
  return n;
end $$;
grant execute on function update_customers_from_list(jsonb) to authenticated;
