with u as (update billing_snap set agency_ref='FAM-3942' where agency='CCS' and agency_ref='FAM-3762' and not exists(select 1 from billing_snap b where b.agency='CCS' and b.agency_ref='FAM-3942') returning 1)
select (select count(*) from u) snap_updated, (select count(*) from billing_import where ref='FAM-3762') import_old, (select count(*) from billing_import where ref='FAM-3942') import_new;
