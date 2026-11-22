-- Sunday household text via Dataphone. The API key is stored server side only (nobody can read it from the site).
create table if not exists server_secrets(
  name text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);
alter table server_secrets enable row level security;   -- no policies: only the Edge Function (service role) can read or write
revoke all on server_secrets from anon, authenticated;

create table if not exists sms_log(
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  kind text not null,            -- send | test
  label text not null default '',
  day text not null default '',  -- New York date of the send, used to stop a second send the same day
  n_sent int not null default 0,
  n_invalid int not null default 0,
  note text not null default '',
  by_name text not null default ''
);
alter table sms_log enable row level security;
drop policy if exists p_sms_log_sel on sms_log;
create policy p_sms_log_sel on sms_log for select using (app_is_owner());
