with n as (select h.* from week_history h where h.batch=(select max(x.batch) from week_history x where x.week_start=h.week_start))
select json_build_object(
 'weeks',(select json_agg(x) from (select week_start,count(*) n,count(*) filter (where request<>'' and request<>'-') req,count(*) filter (where change<>'' and change<>'-') chg,count(*) filter (where change_note<>'' and change_note<>'-') note,count(*) filter (where not in_list) notin from n group by 1 order by 1 desc) x),
 'sample',(select json_agg(x) from (select week_start,left(request,30) rq,left(change,30) ch,left(change_note,40) nt from n where change_note<>'' and change_note<>'-' order by week_start desc limit 6) x)) r;
