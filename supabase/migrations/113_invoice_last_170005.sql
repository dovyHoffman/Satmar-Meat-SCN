-- Owner's instruction: last invoice number used = 170005 (next = 170006).
insert into app_settings (key, value, updated_at) values ('invoice_last', '{"n":170005}'::jsonb, now())
on conflict (key) do update set value = excluded.value, updated_at = now();
select value from app_settings where key='invoice_last';
