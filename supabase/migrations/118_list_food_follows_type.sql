-- 1) A new list that changes a customer's type now also changes the food to match (it used to leave the old food: Box with 'meals').
create or replace function apply_list_draft(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int; m int;
begin
  if not app_is_owner() then raise exception 'owner only'; end if;
  update customers c set
    name = coalesce(nullif(x.name,''), c.name),
    hh = coalesce(x.hh, c.hh),
    enh = coalesce(x.enh, c.enh),
    base = coalesce(nullif(x.base,''), c.base::text)::base_t,
    -- the type changed by the list and the file gives no food: the food follows the type (Meals -> Box = raw; Box -> Meals with a raw food = meals)
    food = coalesce(nullif(x.food,''),
             case when nullif(x.base,'') = 'box' and c.base::text <> 'box' and c.food::text not in ('raw','rawnb') then 'raw'
                  when nullif(x.base,'') = 'meals' and c.base::text = 'box' and c.food::text in ('raw','rawnb') then 'meals'
                  else c.food::text end)::food_t,
    active = case when coalesce(x."on",false) then true else c.active end,
    phone = case when coalesce(x.phone,'')<>'' and (coalesce(c.phone,'')='' or length(regexp_replace(c.phone,'\D','','g')) < 10) then x.phone else c.phone end,
    cell = case when coalesce(x.cell,'')<>'' and (coalesce(c.cell,'')='' or regexp_replace(c.cell,'\D','','g') = regexp_replace(coalesce(c.phone,''),'\D','','g')) then x.cell else c.cell end,
    notes_labels = case when coalesce(c.notes_labels,'')='' then coalesce(x.nl,'') else c.notes_labels end,
    note2 = case when coalesce(c.note2,'')='' then coalesce(x.n2,'') else c.note2 end,
    notes = case when coalesce(c.notes,'')='' then coalesce(x.nt,'') else c.notes end
  from jsonb_to_recordset(p) as x(agency text, ref text, off boolean, "on" boolean, name text, hh int, enh int, base text, food text, phone text, cell text, nl text, n2 text, nt text)
  where coalesce(x.off,false) = false
    and c.agency = x.agency and c.id_norm = lower(regexp_replace(x.ref,'[\s\-]+','','g'));
  get diagnostics n = row_count;
  update customers c set active = false
  from jsonb_to_recordset(p) as x(agency text, ref text, off boolean)
  where coalesce(x.off,false) = true and c.active
    and c.agency = x.agency and c.id_norm = lower(regexp_replace(x.ref,'[\s\-]+','','g'));
  get diagnostics m = row_count;
  return n + m;
end $$;
grant execute on function apply_list_draft(jsonb) to authenticated;

-- 2) The 8 active customers changed to Box on 11/20 that still had a meals food: food = raw (type and household untouched).
update customers set food='raw'
where base='box' and active and food::text not in ('raw','rawnb')
  and (agency, agency_ref) in (('CCS','FAM-1417'),('CCS','FAM-1494'),('LH','PU05648Q'),('LH','SB80984J'),('LH','TJ64378F'),('LH','TY52701G'),('LH','VB63593S'),('RY','Posen - 8453236127'));

select (select count(*) from customers where base='box' and active and food::text not in ('raw','rawnb')) box_with_other_food_active,
       (select position('the food follows the type' in pg_get_functiondef('apply_list_draft(jsonb)'::regprocedure)) > 0) function_updated;
