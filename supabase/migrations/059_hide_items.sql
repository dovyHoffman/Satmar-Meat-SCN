-- "Delete" in the item library hides the item (old weeks keep their lines; nothing is erased).
alter table raw_items add column if not exists hidden boolean not null default false;
