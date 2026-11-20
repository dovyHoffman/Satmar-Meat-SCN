-- "What is new" approvals: every signed-in user can read, only the owner can change.
drop policy if exists p_app_settings_wn_sel on app_settings;
drop policy if exists p_app_settings_wn_ins on app_settings;
drop policy if exists p_app_settings_wn_upd on app_settings;
create policy p_app_settings_wn_sel on app_settings for select to authenticated using (key = 'whatsnew_ok');
create policy p_app_settings_wn_ins on app_settings for insert to authenticated with check (key = 'whatsnew_ok' and app_is_owner());
create policy p_app_settings_wn_upd on app_settings for update to authenticated using (key = 'whatsnew_ok' and app_is_owner()) with check (key = 'whatsnew_ok' and app_is_owner());
