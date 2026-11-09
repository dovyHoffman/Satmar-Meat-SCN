-- "Previous deliveries" can be given to a person without "Delivery" (creating new deliveries).
-- Reading what was already sent is allowed with either page; creating (insert) still needs the Delivery page.
drop policy if exists p_ds_read on delivery_sends;
create policy p_ds_read on delivery_sends for select using (app_has_page('delivery') or app_has_page('delivery_prev'));
drop policy if exists p_da_read on delivery_archive;
create policy p_da_read on delivery_archive for select using (app_has_page('delivery') or app_has_page('delivery_prev'));
