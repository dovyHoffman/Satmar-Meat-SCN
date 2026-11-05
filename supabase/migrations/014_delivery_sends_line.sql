-- Keep a copy of exactly what was sent (the file row), so "Previous deliveries" shows it as it was.
alter table delivery_sends add column if not exists line jsonb;
