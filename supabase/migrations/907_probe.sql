select 'imp_max' k, max(tab_date)::text v from billing_import
union all select 'imp_LT_'||tab_date::text, count(*)::text from billing_import where company='LT' group by tab_date
union all select 'snap_'||week::text||'_'||agency, count(*)::text from billing_snap where agency='LT' group by week, agency
union all select 'snapLT_'||agency_ref, base||' hh'||hh||' enh'||coalesce(enh,0) from billing_snap where week='2026-11-07' and agency='LT' and base='box';
