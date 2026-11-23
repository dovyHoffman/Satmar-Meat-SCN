-- READ ONLY. Who recorded the 11/23 delivery sends and when (counts, batch, user, time; no customer data).
select s.batch, s.delivery_date, count(*) rows_, min(s.created_at) first_at, max(s.created_at) last_at,
  (select coalesce(string_agg(distinct a.user_name, ', '),'?') from audit_log a where a.table_name='delivery_sends' and a.new->>'batch'=s.batch) users
from delivery_sends s where s.delivery_date='2026-11-23' group by s.batch, s.delivery_date order by min(s.created_at);
