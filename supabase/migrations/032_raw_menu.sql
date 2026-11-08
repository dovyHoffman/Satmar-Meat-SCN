-- Raw Menu: weekly grocery + meat box planning (replaces the Raw Menu Google Sheet, one tab per week).
create table if not exists raw_box_types (
  code text primary key,
  name text not null default '',
  kind text not null default 'grocery',        -- grocery | meat
  budget numeric,                              -- default budget per box ($)
  sort int not null default 100,
  active boolean not null default true
);
create table if not exists raw_items (
  id bigserial primary key,
  name text not null,
  name_key text not null unique,
  vendor text not null default '',
  nutrient text not null default '',
  credits numeric,
  units_per_case numeric,
  case_price numeric,
  last_used date,
  uses int not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists raw_weeks (
  id bigserial primary key,
  label text not null unique,                  -- e.g. 11/2
  week_date date,
  status text not null default 'draft',        -- draft | live
  note text not null default '',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);
create table if not exists raw_week_counts (
  week_id bigint not null references raw_weeks(id),
  code text not null,
  ordered numeric,                              -- boxes ordered (the number used for the order)
  counted numeric,                              -- boxes counted on the dashboard (when known)
  budget numeric,                               -- budget per box this week
  primary key (week_id, code)
);
create table if not exists raw_week_items (
  id bigserial primary key,
  week_id bigint not null references raw_weeks(id),
  item_id bigint references raw_items(id),
  section text not null default 'grocery',     -- grocery | meat
  name text not null,
  vendor text not null default '',
  qty jsonb not null default '{}'::jsonb,      -- units per box, by box code
  units_per_case numeric,
  case_price numeric,                          -- meat: price per unit
  cases_ordered numeric,
  ordered boolean not null default false,
  received boolean not null default false,
  nutrient text not null default '',
  credits numeric,
  comment text not null default '',
  sort int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists raw_week_items_week on raw_week_items(week_id);
alter table raw_box_types enable row level security;
alter table raw_items enable row level security;
alter table raw_weeks enable row level security;
alter table raw_week_counts enable row level security;
alter table raw_week_items enable row level security;
do $$ declare t text; begin
 foreach t in array array['raw_box_types','raw_items','raw_weeks','raw_week_counts','raw_week_items'] loop
  execute format('drop policy if exists p_%1$s_all on %1$s', t);
  execute format('create policy p_%1$s_all on %1$s for all using (app_is_owner() or app_has_page(''raw'')) with check (app_is_owner() or app_has_page(''raw''))', t);
 end loop;
end $$;
drop trigger if exists audit_raw_items on raw_items;
drop trigger if exists audit_raw_weeks on raw_weeks;
drop trigger if exists audit_raw_week_items on raw_week_items;
drop trigger if exists audit_raw_week_counts on raw_week_counts;
drop trigger if exists nd_raw_items on raw_items;
drop trigger if exists nd_raw_weeks on raw_weeks;
create trigger audit_raw_items after insert or update on raw_items for each row execute function audit_row();
create trigger audit_raw_weeks after insert or update on raw_weeks for each row execute function audit_row();
create trigger audit_raw_week_items after insert or update on raw_week_items for each row execute function audit_row();
create trigger nd_raw_items before delete on raw_items for each row execute function no_delete();
create trigger nd_raw_weeks before delete on raw_weeks for each row execute function no_delete();
insert into raw_box_types (code,name,kind,budget,sort) values
 ('A','Box A','grocery',110,1),('B','Box B','grocery',90,2),('C','Box C','grocery',25,3),('MN','Middleton (MN)','grocery',35,4),
 ('S','Meat S','meat',null,10),('M','Meat M','meat',null,11),('L','Meat L','meat',null,12),
 ('Sc','No beef Sc','meat',null,13),('Mc','No beef Mc','meat',null,14),('Lc','No beef Lc','meat',null,15)
on conflict (code) do nothing;
