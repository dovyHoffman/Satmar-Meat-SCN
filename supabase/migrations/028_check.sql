do $$ declare a int; b text; c int; begin
select count(*) into a from week_history;
select string_agg(distinct week_start::text,',') into b from week_history;
select count(*) into c from week_history where ref_n=lower(regexp_replace('UJO - 2267','\s','','g'));
raise exception 'rows=% weeks=[%] ujo2267=%',a,b,c;
end $$;
