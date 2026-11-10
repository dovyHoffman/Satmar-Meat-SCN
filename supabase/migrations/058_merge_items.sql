-- Lets two spellings of the same item be combined into one library item (nothing is deleted; the old one points to the kept one).
alter table raw_items add column if not exists merged_into bigint references raw_items(id);
