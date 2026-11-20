-- New box Bc = box B for customers who asked for Raw / Box - No Beef (shown in the No Beef section)
insert into menus (code, info, lines) values ('Bc', '', array[]::text[]) on conflict (code) do nothing;
insert into raw_box_types (code,name,kind,budget,sort) values ('Bc','No beef B','grocery',null,5) on conflict (code) do nothing;
