select delivery_date, count(*) rows_, count(*) filter (where line is not null) with_line from delivery_sends group by 1 order by 1 desc limit 20;
