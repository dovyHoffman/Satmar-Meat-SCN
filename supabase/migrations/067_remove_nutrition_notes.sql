-- Remove the "Nutrition review completed..." text from Note 2 (kept: anything written before it, e.g. "Raw foods.").
-- Backup of every changed row first (id + old note2).
create table if not exists bk_20261114_note2 as
  select id, agency, agency_ref, name, note2 from customers where note2 ~* 'nutrition review';
alter table bk_20261114_note2 enable row level security;
update customers
   set note2 = btrim(substr(note2, 1, greatest(position(lower('nutrition review') in lower(note2)) - 1, 0)))
 where note2 ~* 'nutrition review';
