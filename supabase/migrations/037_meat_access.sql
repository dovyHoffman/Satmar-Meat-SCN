do $$ declare t text; begin
 foreach t in array array['raw_box_types','raw_items','raw_weeks','raw_week_counts','raw_week_items'] loop
  execute format('drop policy if exists p_%1$s_all on %1$s', t);
  execute format('create policy p_%1$s_all on %1$s for all using (app_is_owner() or app_has_page(''raw'') or app_has_page(''meat'')) with check (app_is_owner() or app_has_page(''raw'') or app_has_page(''meat''))', t);
 end loop;
end $$;
