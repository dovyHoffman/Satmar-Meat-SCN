-- Settings > Access by category: which pages each role (Admin, Manager, Office secretary) gets. Owner only.
drop policy if exists p_app_settings_rp_sel on app_settings;
drop policy if exists p_app_settings_rp_ins on app_settings;
drop policy if exists p_app_settings_rp_upd on app_settings;
create policy p_app_settings_rp_sel on app_settings for select to authenticated using (key = 'role_pages' and app_is_owner());
create policy p_app_settings_rp_ins on app_settings for insert to authenticated with check (key = 'role_pages' and app_is_owner());
create policy p_app_settings_rp_upd on app_settings for update to authenticated using (key = 'role_pages' and app_is_owner()) with check (key = 'role_pages' and app_is_owner());
