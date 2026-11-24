-- Chat: a person can edit the text of his own message. Only body and edited_at can change for non-owners.
alter table chat_messages add column if not exists edited_at timestamptz;
create or replace function chat_edit_guard() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if app_is_owner() then return new; end if;
  if old.sender is distinct from auth.uid() or old.deleted_at is not null then raise exception 'You can only edit your own messages'; end if;
  if (to_jsonb(new) - 'body' - 'edited_at') <> (to_jsonb(old) - 'body' - 'edited_at') then raise exception 'Only the text of a message can be edited'; end if;
  return new;
end $$;
drop trigger if exists trg_chat_edit_guard on chat_messages;
create trigger trg_chat_edit_guard before update on chat_messages for each row execute function chat_edit_guard();
drop policy if exists p_chat_upd_own on chat_messages;
create policy p_chat_upd_own on chat_messages for update using (sender = auth.uid()) with check (sender = auth.uid());
