-- Chat groups: "Office chat" (room team, page chat) and "Menus updates" (room menus, page menuchat).
-- Group name + picture live in app_settings key chat_groups. Members list through chat_members().
drop policy if exists p_chat_read on chat_messages;
drop policy if exists p_chat_ins on chat_messages;
create policy p_chat_read on chat_messages for select using (
  app_is_owner()
  or (room = 'team' and app_has_page('chat'))
  or (room = 'menus' and app_has_page('menuchat'))
  or (room = 'support:' || auth.uid()::text)
);
create policy p_chat_ins on chat_messages for insert with check (
  sender = auth.uid() and (
    app_is_owner()
    or (room = 'team' and app_has_page('chat'))
    or (room = 'menus' and app_has_page('menuchat'))
    or (room = 'support:' || auth.uid()::text)
  )
);

drop policy if exists p_chatf_read on storage.objects;
drop policy if exists p_chatf_ins on storage.objects;
drop policy if exists p_chatf_upd on storage.objects;
create policy p_chatf_read on storage.objects for select to authenticated using (
  bucket_id = 'chat-files' and (
    app_is_owner()
    or name like 'group/%'
    or (name like 'team/%' and app_has_page('chat'))
    or (name like 'menus/%' and app_has_page('menuchat'))
    or (name like 'support/' || auth.uid()::text || '/%')
  )
);
create policy p_chatf_ins on storage.objects for insert to authenticated with check (
  bucket_id = 'chat-files' and (
    app_is_owner()
    or (name like 'team/%' and app_has_page('chat'))
    or (name like 'menus/%' and app_has_page('menuchat'))
    or (name like 'support/' || auth.uid()::text || '/%')
  )
);
create policy p_chatf_upd on storage.objects for update to authenticated using (
  bucket_id = 'chat-files' and name like 'group/%' and app_is_owner()
) with check (bucket_id = 'chat-files' and name like 'group/%' and app_is_owner());

drop policy if exists p_app_settings_groups_sel on app_settings;
drop policy if exists p_app_settings_groups_ins on app_settings;
drop policy if exists p_app_settings_groups_upd on app_settings;
create policy p_app_settings_groups_sel on app_settings for select to authenticated using (key = 'chat_groups');
create policy p_app_settings_groups_ins on app_settings for insert to authenticated with check (key = 'chat_groups' and app_is_owner());
create policy p_app_settings_groups_upd on app_settings for update to authenticated using (key = 'chat_groups' and app_is_owner()) with check (key = 'chat_groups' and app_is_owner());

create or replace function chat_members(p_room text)
returns table(id uuid, name text, role text)
language sql stable security definer set search_path = public as $$
  select p.id, coalesce(nullif(p.name,''), p.email), p.role
  from profiles p
  where coalesce(p.active, true)
    and (p.role = 'owner' or (case p_room when 'team' then 'chat' when 'menus' then 'menuchat' end) = any(p.pages))
    and (app_is_owner() or (p_room = 'team' and app_has_page('chat')) or (p_room = 'menus' and app_has_page('menuchat')))
  order by (p.role = 'owner') desc, 2;
$$;
grant execute on function chat_members(text) to authenticated;
