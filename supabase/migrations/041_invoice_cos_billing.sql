-- Anyone with the Billing page may add/edit the per-company invoice details (emails, CC, name, address)
drop policy if exists p_app_settings_invoice_ins on app_settings;
create policy p_app_settings_invoice_ins on app_settings for insert with check (key='invoice_cos' and (app_is_owner() or app_has_page('billing')));
drop policy if exists p_app_settings_invoice_upd on app_settings;
create policy p_app_settings_invoice_upd on app_settings for update using (key='invoice_cos' and (app_is_owner() or app_has_page('billing'))) with check (key='invoice_cos' and (app_is_owner() or app_has_page('billing')));
drop policy if exists p_app_settings_invoice_sel on app_settings;
create policy p_app_settings_invoice_sel on app_settings for select using (key='invoice_cos' and (app_is_owner() or app_has_page('billing')));
