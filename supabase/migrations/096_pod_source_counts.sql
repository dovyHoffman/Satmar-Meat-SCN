-- READ ONLY: counts only (no names, phones or IDs). Are this week's linked deliveries really ours?
with d as (
  select order_id, customer_id,
         coalesce(nullif(snap->>'letters',''),'') as letters,
         exists (select 1 from order_map m where m.order_id = deliveries.order_id) as in_export
  from deliveries
  where customer_id is not null
    and coalesce(delivered_at, synced_at) >= '2026-11-16 05:00:00+00'
)
select count(*) as linked_this_week,
       count(*) filter (where letters <> '') as with_box_letters,
       count(*) filter (where in_export) as in_uploaded_export,
       count(*) filter (where letters = '' and not in_export) as neither_letters_nor_export,
       count(*) filter (where letters = '' and in_export) as export_but_no_letters
from d;
