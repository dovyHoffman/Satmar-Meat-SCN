-- Admin may change the Box settings (which box each household gets). Only this one setting; everything else stays owner-only.
drop policy if exists p_app_settings_bs_ins on app_settings;
drop policy if exists p_app_settings_bs_upd on app_settings;
create policy p_app_settings_bs_ins on app_settings for insert to authenticated
  with check (key = 'box_settings' and exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin' and p.active));
create policy p_app_settings_bs_upd on app_settings for update to authenticated
  using (key = 'box_settings' and exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin' and p.active))
  with check (key = 'box_settings' and exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin' and p.active));
