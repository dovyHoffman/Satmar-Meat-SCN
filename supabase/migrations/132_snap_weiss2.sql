with u as (update billing_snap set base='meals', hh=1, enh=0 where week='2026-11-21' and agency='RY' and agency_ref='Weiss - 3475815977' returning 1),
i as (insert into billing_snap(week,agency,agency_ref,name,base,food,hh,enh) select '2026-11-21','RY','Weiss - 3475815977 (2)',name,'box','raw',1,0 from billing_snap where week='2026-11-21' and agency='RY' and agency_ref='Weiss - 3475815977' on conflict do nothing returning 1)
select (select count(*) from u) meals_row_updated, (select count(*) from i) box_row_inserted;
