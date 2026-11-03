-- Menu and Billing pages: seed menus and prices, and give billing staff a safe way to read deliveries.
-- Safe to run more than once; it never overwrites a menu or price you already changed.

-- 1) Menus (from the Dip List, Menus tab)
insert into menus (code, info, lines) values
('A','Delivery date: Tuesday / Wed
Type food: Meals / Raw
Household: Meals 5+ Raw 2+',array['Mix salad','Corn cake square','Dryed mango','Pita chips','Chocolate chips','Racket Chip','Nutty chaw','Grapes','Clementines','Persian','Grape tomato','peppers','Falafel','Guacamole','Thousand Islands dressing','Yogurt 32 oz','Orange Juice','3 grain','Egg kichel','Herring','peaches bag','carrots','Chumuss','Rosemary Cockies','Gronola','Peanuts','Fruit strip','Pop treos']::text[]),
('B','Delivery date: Tuesday / Wed
Type food: Meals / Raw
Household: Meals 5+ Raw 2+',array['Mix salad','Pita','Corn cake square','Dryed mango','Grapes','Clementines','Persian','Grape tomato','Falafel','Orange Juice','3 grain','Egg kichel','Herring','peaches bag','carrots','Chumuss','Gronola','Peanuts','Fruit strip','Pop treos','Meat']::text[]),
('C','Delivery date: Tuesday / Wed
Type food: Meals
Household: 2',array['Corn cake square','Pita chips','Onion garlic rings','Nutty chaw','Guacamole','Thousand Islands dressing','Gronola','Peanuts','Totrila chip']::text[]),
('F','Delivery date: Tuesday / Wed
Type food: Meals / Raw
Household: Suppers 3-4, Raw 1, Shabbos 3-7','{}'::text[]),
('D','Delivery date: Tuesday / Wed
Type food: Raw
Household: Raw 5+',array['3 dozen Eggs','1 Apple cider','2lb rye bread','pk cammomile tea','4 lg onion','4 loose carrots','1 checked celery','pk clementines','Chulent mix','galgal crackers','American cheese 12oz','6 cans chunk light tuna 6oz','Banana bunch','1 mayonaise','1 persian cucumbers','1 givat cream cheese 8oz','1 givat cottage cheese 16 oz','1 pk choc chip cookies','Streit matzo WW','1 canola oil']::text[]),
('3','Delivery date: Thursday / Friday
Type food: Shabbos
Household: 2-4',array['Lima Beans 8 oz.','Bella onion dip','mild Jalapeno dip','mommy''s babagenush 8 oz.','olive salad','Tomato dip 12oz','Gefilte fish prepack 12oz','salmon fillet per 2','gala meat - med','Blueberry pie crumble','Kishka 12 oz','lukshen kugel small','potato kugel Med','cucumber salad 15 oz','chicken soup 32oz','farfel 12 oz.','matzah balls','noodles 8 oz.','Matjash Herring','TURKEY ROLL','2 heimish chala','mango smoothie']::text[]),
('5','Delivery date: Thursday / Friday
Type food: Shabbos
Household: 5+','{}'::text[]),
('G','Delivery date: Thursday / Friday
Type food: Shabbos
Household: 1','{}'::text[]),
('E','Delivery date: Monday
Type food: Meals
Household: Meals, Suppers 4+',array['buternut squash soup','veg root soup','sweet tangy chicken fingers ready to bake','chcken loaf','baked rice','shlishkes','potato bourekas','mushromm suace','tuna salad','honey pecon mango salad','broccoli & cauliflower ready to bake','snackers','mango smoothie']::text[]),
('H','Delivery date: Wednesday
Type food: Meals
Household: Meals, Suppers 1-2',array['veg root soup','sweet tangy chicken fingers ready to bake','baked rice','shlishkes','potato bourekas','mushromm suace','tuna salad','honey pecon mango salad','broccoli & cauliflower ready to bake','snackers','mango smoothie']::text[]),
('S','Delivery date: Tuesday
Type food: Raw
Household: 2-3',array['1 Beef Mock Minute Steak','1 Chicken Fingers','1 Chicken Bottems','1 Pack of Cold Cuts']::text[]),
('M','Delivery date: Tuesday
Type food: Raw
Household: 4+',array['1 Beef Mock Minute Steak','2 Chicken Fingers','1 Chicken Goulash','2 Chicken Bottems']::text[]),
('L','Delivery date: Tuesday
Type food: Raw
Household: 4+',array['2 Beef Mock Minute Steak','2 Chicken Fingers','2 Chicken Goulash','2 Chicken Bottems']::text[]),
('Sc','',array['1 ch finger','1 ch goulash','1 ch bodem','1 Cold Cuts']::text[]),
('Mc','',array['2 ch finger','1 ch goulash','1 ch bodem','1 Cold Cuts']::text[]),
('Lc','',array['3 ch finger','2 ch goulash','2 ch bodem','1 Cold Cuts']::text[])
on conflict (code) do nothing;

-- 2) Agencies and prices (box = billed once per box; meal = per meal, x21 x household size)
insert into agencies (code, name) values ('UJO','UJO'),('PT','PT'),('CCS','CCS'),('LH','LH'),('LT','LT'),('RY','RY'),('OR','OR')
on conflict (code) do nothing;
insert into agency_prices (agency, box_price, meal_price) values
 ('UJO',125,13),('PT',100,11.5),('CCS',100,13.5),('LH',100,9),('LT',100,9),('RY',100,10),('OR',null,null)
on conflict (agency) do nothing;

-- 3) Menu page for office secretaries, Billing page for billing staff (already-invited people)
update profiles set pages = array_append(pages,'menu') where role = 'secretary' and not ('menu' = any(pages));
update profiles set pages = array_append(pages,'billing') where role = 'billing' and not ('billing' = any(pages));

-- 4) Billing reads delivered orders through this function: only name, ID, type, receipt and picture links.
create or replace function billing_rows()
returns table(order_id text, delivered_at timestamptz, agency text, agency_ref text, name text, base text, food text,
              hh int, boxes int, letters text, receipt_url text, photo_urls text[])
language sql stable security definer set search_path = public as $$
  select d.order_id, d.delivered_at, c.agency, c.agency_ref, c.name,
         coalesce(nullif(d.snap->>'base',''), c.base::text),
         coalesce(nullif(d.snap->>'food',''), c.food::text),
         coalesce(round(nullif(d.snap->>'hh','')::numeric)::int, c.hh),
         coalesce(round(nullif(d.snap->>'boxes','')::numeric)::int, 0),
         coalesce(d.snap->>'letters',''), d.receipt_url, d.photo_urls
  from deliveries d join customers c on c.id = d.customer_id
  where d.delivered_at is not null and (app_has_page('billing') or app_is_owner())
  order by d.delivered_at desc
$$;
grant execute on function billing_rows() to authenticated;
