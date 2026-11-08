-- Menu page: upload the weekly menu files (PDF, picture, Excel, Word) until the menu is made from the website.
-- Nothing is ever deleted; changes go to History.
create table if not exists menu_files (
  id bigserial primary key,
  name text not null,
  path text not null,
  size bigint not null default 0,
  ctype text not null default '',
  week text not null default '',
  note text not null default '',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);
alter table menu_files enable row level security;
drop policy if exists p_mf_read on menu_files;
drop policy if exists p_mf_ins on menu_files;
create policy p_mf_read on menu_files for select using (app_has_page('menu'));
create policy p_mf_ins on menu_files for insert with check (app_has_page('menu'));
drop trigger if exists audit_menu_files on menu_files;
drop trigger if exists nd_menu_files on menu_files;
create trigger audit_menu_files after insert or update on menu_files for each row execute function audit_row();
create trigger nd_menu_files before delete on menu_files for each row execute function no_delete();

insert into storage.buckets (id, name, public) values ('menu-files','menu-files',false) on conflict (id) do nothing;
drop policy if exists p_mf_obj_read on storage.objects;
drop policy if exists p_mf_obj_ins on storage.objects;
create policy p_mf_obj_read on storage.objects for select to authenticated using (bucket_id = 'menu-files' and app_has_page('menu'));
create policy p_mf_obj_ins on storage.objects for insert to authenticated with check (bucket_id = 'menu-files' and app_has_page('menu'));
