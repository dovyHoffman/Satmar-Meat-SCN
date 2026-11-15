-- Office chat (room 'team') + Support (room 'support:<user id>'): photos, voice notes and files.
-- Office chat: the owner and everyone with the Chat page. Support: each user talks only with the owner.
-- Nobody can delete (no_delete trigger from 035 stays). Files live in the private bucket 'chat-files'.
alter table chat_messages add column if not exists kind text not null default 'text';
alter table chat_messages add column if not exists file_path text;
alter table chat_messages add column if not exists file_name text;
alter table chat_messages add column if not exists file_type text;
alter table chat_messages add column if not exists file_size bigint;
alter table chat_messages add column if not exists duration int;
alter table chat_messages alter column body set default '';
alter table chat_messages drop constraint if exists chat_messages_body_check;
alter table chat_messages drop constraint if exists chat_messages_body_len;
alter table chat_messages add constraint chat_messages_body_len check (length(body) <= 4000);
alter table chat_messages drop constraint if exists chat_messages_has_content;
alter table chat_messages add constraint chat_messages_has_content check (length(body) > 0 or file_path is not null);
alter table chat_messages drop constraint if exists chat_messages_kind_ok;
alter table chat_messages add constraint chat_messages_kind_ok check (kind in ('text','image','voice','file'));

drop policy if exists p_chat_read on chat_messages;
drop policy if exists p_chat_ins on chat_messages;
create policy p_chat_read on chat_messages for select using (
  app_is_owner()
  or (room = 'team' and app_has_page('chat'))
  or (room = 'support:' || auth.uid()::text)
);
create policy p_chat_ins on chat_messages for insert with check (
  sender = auth.uid() and (
    app_is_owner()
    or (room = 'team' and app_has_page('chat'))
    or (room = 'support:' || auth.uid()::text)
  )
);

insert into storage.buckets (id, name, public, file_size_limit)
values ('chat-files', 'chat-files', false, 26214400)
on conflict (id) do update set file_size_limit = 26214400;

drop policy if exists p_chatf_read on storage.objects;
drop policy if exists p_chatf_ins on storage.objects;
create policy p_chatf_read on storage.objects for select to authenticated using (
  bucket_id = 'chat-files' and (
    app_is_owner()
    or (name like 'team/%' and app_has_page('chat'))
    or (name like 'support/' || auth.uid()::text || '/%')
  )
);
create policy p_chatf_ins on storage.objects for insert to authenticated with check (
  bucket_id = 'chat-files' and (
    app_is_owner()
    or (name like 'team/%' and app_has_page('chat'))
    or (name like 'support/' || auth.uid()::text || '/%')
  )
);
