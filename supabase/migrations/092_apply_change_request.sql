-- Friday 12:00 pm to Sunday 7:00 pm (New York): a customer change takes effect right away, for any signed-in user.
-- Same fields as the owner's "Apply now" button. Outside that window it refuses. A food change needs this week's billing list to be saved already.
create or replace function apply_change_request(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare r change_requests%rowtype; pl jsonb; ny timestamp := (now() at time zone 'America/New_York'); dow int; h int; wk date; c customers%rowtype;
begin
  if auth.uid() is null then raise exception 'sign in first'; end if;
  dow := extract(dow from ny)::int; h := extract(hour from ny)::int;
  if not ((dow = 5 and h >= 12) or dow = 6 or (dow = 0 and h < 19)) then raise exception 'outside the Friday 12:00 pm to Sunday 7:00 pm window'; end if;
  select * into r from change_requests where id = p_id and status = 'pending';
  if not found then raise exception 'this change is not pending'; end if;
  pl := r.payload;
  select * into c from customers where id = r.customer_id;
  if not found then raise exception 'customer not found'; end if;
  if pl ? 'food' and coalesce(pl->>'food','') <> '' then
    wk := date_trunc('week', ny)::date - 2;
    if not exists (select 1 from billing_snap where week = wk) then raise exception 'no_snapshot'; end if;
  end if;
  update customers set
    phone = case when coalesce(pl->>'phone','') <> '' then pl->>'phone' else phone end,
    cell = case when coalesce(pl->>'cell','') <> '' then pl->>'cell' else cell end,
    notes_labels = case when coalesce(pl->>'notes','') <> '' then pl->>'notes' else notes_labels end,
    note2 = case when coalesce(pl->>'note2','') <> '' then pl->>'note2' else note2 end,
    no_sms = case when pl ? 'nosms' and pl->>'nosms' is not null then (pl->>'nosms') in ('1','true') else no_sms end,
    no_sms_cell = case when pl ? 'nosmsc' and pl->>'nosmsc' is not null then (pl->>'nosmsc') in ('1','true') else no_sms_cell end,
    area = case when coalesce(pl->>'area','') <> '' then (case lower(replace(pl->>'area','/','_')) when 'lee' then 'lee' when 'monsey' then 'monsey' when 'monroe' then 'monroe' when 'monsey_monroe' then 'monsey_monroe' when 'bedford' then 'bedford' when 'bp' then 'bp' else 'lee' end)::area_t else area end,
    street = case when pl ? 'a' then pl->'a'->>'st' else street end,
    city = case when pl ? 'a' then pl->'a'->>'city' else city end,
    state = case when pl ? 'a' then pl->'a'->>'state' else state end,
    zip = case when pl ? 'a' then pl->'a'->>'zip' else zip end,
    apt = case when pl ? 'a' then coalesce(pl->>'apt','') else apt end,
    middleton = case when pl->>'food' = 'mid' then true when coalesce(pl->>'food','') <> '' and middleton then false else middleton end,
    food = case when coalesce(pl->>'food','') not in ('','mid') then (pl->>'food')::food_t else food end,
    base = case when coalesce(pl->>'food','') not in ('','mid') then coalesce(nullif(pl->>'base',''), base::text)::base_t else base end
  where id = r.customer_id;
  update change_requests set status = 'applied' where id = p_id;
end $$;
grant execute on function apply_change_request(uuid) to authenticated;
