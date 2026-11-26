-- Dashboard "New list" box: Admin can READ only the counts the owner publishes (no customer data). Owner write rights are unchanged.
drop policy if exists p_app_settings_nls_sel on app_settings;
create policy p_app_settings_nls_sel on app_settings for select to authenticated
  using (key = 'newlist_summary' and (app_is_owner() or app_has_page('dashboard')));
