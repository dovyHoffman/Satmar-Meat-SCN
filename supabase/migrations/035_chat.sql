-- Team chat: everyone with the Chat page (and the owner) can read and write; nobody can delete.
create table if not exists chat_messages (
  id bigserial primary key,
  room text not null default 'team',
  sender uuid default auth.uid(),
  sender_name text not null default '',
  body text not null check (length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);
alter table chat_messages enable row level security;
drop policy if exists p_chat_read on chat_messages;
drop policy if exists p_chat_ins on chat_messages;
create policy p_chat_read on chat_messages for select using (app_is_owner() or app_has_page('chat'));
create policy p_chat_ins on chat_messages for insert with check ((app_is_owner() or app_has_page('chat')) and sender = auth.uid());
drop trigger if exists nd_chat on chat_messages;
create trigger nd_chat before delete on chat_messages for each row execute function no_delete();
create index if not exists chat_messages_room_id on chat_messages(room, id desc);
