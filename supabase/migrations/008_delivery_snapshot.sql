-- Remembers which box (food, household size, area) the customer had when each delivery happened.
alter table deliveries add column if not exists snap jsonb;
