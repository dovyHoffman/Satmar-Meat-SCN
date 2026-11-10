-- Draft of the next weekly list (owner only), and the approve step.
create table if not exists list_draft (
  id int primary key default 1 check (id = 1),
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid
);
alter table list_draft enable row level security;
drop policy if exists p_list_draft_all on list_draft;
create policy p_list_draft_all on list_draft for all using (app_is_owner()) with check (app_is_owner());

-- Approve: existing customers get name, household size, Meals/Box and food type (and are switched on);
-- phone, cell, label notes, note 2 and notes are only filled when they were blank. Customers marked off are switched off.
-- Nothing else is touched and nothing is deleted. Every change is recorded by the history triggers.
create or replace function apply_list_draft(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int; m int;
begin
  if not app_is_owner() then raise exception 'owner only'; end if;
  update customers c set
    name = coalesce(nullif(x.name,''), c.name),
    hh = coalesce(x.hh, c.hh),
    base = coalesce(nullif(x.base,''), c.base::text)::base_t,
    food = coalesce(nullif(x.food,''), c.food::text)::food_t,
    active = true,
    phone = case when coalesce(c.phone,'')='' then coalesce(x.phone,'') else c.phone end,
    cell = case when coalesce(c.cell,'')='' then coalesce(x.cell,'') else c.cell end,
    notes_labels = case when coalesce(c.notes_labels,'')='' then coalesce(x.nl,'') else c.notes_labels end,
    note2 = case when coalesce(c.note2,'')='' then coalesce(x.n2,'') else c.note2 end,
    notes = case when coalesce(c.notes,'')='' then coalesce(x.nt,'') else c.notes end
  from jsonb_to_recordset(p) as x(agency text, ref text, off boolean, name text, hh int, base text, food text, phone text, cell text, nl text, n2 text, nt text)
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
