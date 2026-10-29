-- Use the application's profiles.role as the source of truth for Backup access.
-- Prevent members from granting themselves admin through profiles updates.
create or replace function public.prevent_unauthorized_profile_role_change()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.role is distinct from old.role and not public.is_admin() then
    raise exception 'Only an admin can change a profile role'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_unauthorized_role_change
  on public.profiles;
create trigger profiles_prevent_unauthorized_role_change
  before update of role on public.profiles
  for each row
  execute function public.prevent_unauthorized_profile_role_change();

drop policy if exists backup_jobs_admin_select on public.backup_jobs;
create policy backup_jobs_admin_select
  on public.backup_jobs for select to authenticated
  using ((select public.is_admin()));
