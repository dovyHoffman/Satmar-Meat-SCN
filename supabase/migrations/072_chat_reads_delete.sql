-- Read receipts (who has read up to which message) and admin delete (soft: the text/file is removed, a "deleted" mark stays).
alter table chat_messages add column if not exists deleted_at timestamptz;
drop policy if exists p_chat_upd on chat_messages;
create policy p_chat_upd on chat_messages for update using (app_is_owner()) with check (app_is_owner());

create table if not exists chat_reads(
  room text not null, user_id uuid not null, last_id bigint not null default 0, updated_at timestamptz not null default now(),
  primary key (room, user_id));
alter table chat_reads enable row level security;
drop policy if exists p_cr_sel on chat_reads;
drop policy if exists p_cr_ins on chat_reads;
drop policy if exists p_cr_upd on chat_reads;
create policy p_cr_sel on chat_reads for select using (app_is_owner() or user_id = auth.uid());
create policy p_cr_ins on chat_reads for insert with check (user_id = auth.uid() and (
  app_is_owner() or (room = 'team' and app_has_page('chat')) or (room = 'menus' and app_has_page('menuchat')) or room = 'support:' || auth.uid()::text));
create policy p_cr_upd on chat_reads for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists p_chatf_del on storage.objects;
create policy p_chatf_del on storage.objects for delete to authenticated using (bucket_id = 'chat-files' and app_is_owner());
