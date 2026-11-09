create table if not exists invoice_emails (
  id bigserial primary key,
  company text not null default '',
  week text not null default '',
  inv_no text not null default '',
  amount numeric,
  to_list text[] not null default '{}',
  cc_list text[] not null default '{}',
  subject text not null default '',
  ok boolean not null default false,
  error text,
  sent_by uuid,
  sent_at timestamptz not null default now()
);
alter table invoice_emails enable row level security;
drop policy if exists p_invoice_emails_sel on invoice_emails;
create policy p_invoice_emails_sel on invoice_emails for select using (app_is_owner() or app_has_page('billing'));
drop trigger if exists nd_invoice_emails on invoice_emails;
create trigger nd_invoice_emails before delete on invoice_emails for each row execute function no_delete();
