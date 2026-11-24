-- Two-case families: the customer list keeps ONE row (total family); billing keeps each case on its own line.
create table if not exists bk_20261124_billing_snap_1121 as select * from billing_snap where week='2026-11-21';
with v(agency,ref,h1,e1,h2,e2) as (values
('PT','1002',1,0,1,0),
('PT','1017',1,0,1,0),
('PT','1049',1,0,1,0),
('PT','1056',1,0,1,0),
('PT','2015',2,0,2,0),
('PT','3006',2,0,1,0),
('PT','3016',2,0,1,0),
('PT','3024',1,0,1,0),
('PT','3046',1,0,1,0),
('PT','3062',3,0,1,0),
('PT','3511',1,0,1,0),
('PT','4004',2,0,1,0),
('PT','4022',1,0,1,0),
('PT','4025',2,0,4,0),
('PT','5006',1,0,1,0),
('PT','6033',1,0,1,0),
('PT','7003',5,0,1,0),
('PT','8000',1,0,2,0),
('LH','TR10924K',1,0,3,0),
('LT','LT00001',5,3,1,1),
('LT','LT00050',1,1,5,2),
('RY','Gamoran - 3057134224',1,0,1,0),
('RY','Lebovits - 7185067708',1,0,2,0),
('RY','Rosenblum - 8453623241',1,0,2,0),
('RY','Schwartz - 3472329997',3,0,1,0),
('RY','Schwartz - 6317799018',3,0,1,0),
('RY','Weber - 5166475748',1,0,1,0)),
ins as (insert into billing_snap(week,agency,agency_ref,name,base,food,hh,enh)
  select s.week,s.agency,s.agency_ref||' (2)',s.name,'box','raw',v.h2,v.e2 from billing_snap s join v on s.agency=v.agency and s.agency_ref=v.ref where s.week='2026-11-21' on conflict do nothing returning 1),
upd as (update billing_snap s set base='meals',hh=v.h1,enh=v.e1 from v where s.week='2026-11-21' and s.agency=v.agency and s.agency_ref=v.ref returning 1)
select (select count(*) from ins) inserted,(select count(*) from upd) updated;
