-- READ ONLY. IDs of active customers with Type Box and a non-box food (ids only).
select coalesce(json_agg(json_build_object('agency',agency,'ref',agency_ref,'food',food,'hh',hh) order by agency,agency_ref),'[]'::json) ids
from customers where base='box' and food not in ('raw','rawnb') and active;
