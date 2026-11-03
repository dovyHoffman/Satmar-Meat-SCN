-- Lets staff record WHICH box (e.g. E or A) a delivery carried. Needs the customers page.
create or replace function set_delivery_letters(p_order text, p_letters text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not (app_has_page('customers') or app_is_owner()) then raise exception 'not allowed'; end if;
  update deliveries
     set snap = coalesce(snap,'{}'::jsonb) || jsonb_build_object('letters', coalesce(p_letters,''))
   where order_id = p_order;
end $$;
grant execute on function set_delivery_letters(text, text) to authenticated;
