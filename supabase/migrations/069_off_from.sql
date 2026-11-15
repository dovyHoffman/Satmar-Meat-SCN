-- A customer switched off from the card goes off the billing from this week on, never from earlier weeks.
alter table customers add column if not exists off_from date;
