-- Lets the site ask only for customers changed since its last visit (saved copy on each device).
alter table customers add column if not exists updated_at timestamptz not null default now();
create index if not exists customers_updated_at_idx on customers(updated_at);
create or replace function touch_customer_updated() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;
drop trigger if exists z_touch_customer_updated on customers;
create trigger z_touch_customer_updated before update on customers for each row execute function touch_customer_updated();
