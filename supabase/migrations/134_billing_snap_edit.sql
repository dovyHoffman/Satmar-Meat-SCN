-- Let the owner / billing page edit a saved billing week line (type, food, households, Enhanced). Every change is kept in History.
drop policy if exists p_snap_upd on billing_snap;
create policy p_snap_upd on billing_snap for update using (app_is_owner() or app_has_page('billing')) with check (app_is_owner() or app_has_page('billing'));
drop trigger if exists audit_billing_snap on billing_snap;
create trigger audit_billing_snap after insert or update on billing_snap for each row execute function audit_row();
