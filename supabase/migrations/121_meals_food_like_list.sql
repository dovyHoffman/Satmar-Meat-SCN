-- Owner: food must be like the new list. 5 customers moved Box -> Meals by Friday's list and 8 CCS Meals customers had a raw food: food = meals (type and household untouched).
update customers set food='meals'
where active and base='meals' and food::text in ('raw','rawnb')
  and (agency, agency_ref) in (('PT','4012'),('PT','5013'),('RY','Grunwald - 8453236440'),('RY','Stern - 8456597251'),('RY','Walter - 8456596220'),
    ('CCS','FAM-3791'),('CCS','FAM-1421'),('CCS','FAM-2151'),('CCS','FAM-3801'),('CCS','FAM-3809'),('CCS','FAM-3770'),('CCS','FAM-3790'),('CCS','FAM-3814'));
select (select count(*) from customers where active and agency='CCS' and base='meals' and food::text in ('raw','rawnb')) ccs_meals_raw_left,
       (select count(*) from customers where active and base='box' and food::text not in ('raw','rawnb')) box_other_food_left;
