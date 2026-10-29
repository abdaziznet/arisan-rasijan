create table if not exists public.backup_jobs (
  id uuid primary key default gen_random_uuid(),
  status text not null default 'pending'
    check (status in ('pending', 'running', 'success', 'failed')),
  trigger_type text not null default 'scheduled'
    check (trigger_type in ('scheduled', 'manual')),
  scope text not null default 'full'
    check (scope in ('full', 'db_only')),
  note text check (note is null or char_length(note) <= 200),
  requested_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  started_at timestamptz,
  finished_at timestamptz,
  size_bytes bigint check (size_bytes is null or size_bytes >= 0),
  location text,
  error text
);

create unique index if not exists backup_jobs_one_active
  on public.backup_jobs ((true))
  where status in ('pending', 'running');

create index if not exists backup_jobs_created_at_desc
  on public.backup_jobs (created_at desc);

alter table public.backup_jobs enable row level security;

drop policy if exists backup_jobs_admin_select on public.backup_jobs;
create policy backup_jobs_admin_select
  on public.backup_jobs for select to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

revoke all on public.backup_jobs from anon, authenticated;
grant select on public.backup_jobs to authenticated;
grant all on public.backup_jobs to service_role;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'backup_jobs'
  ) then
    alter publication supabase_realtime add table public.backup_jobs;
  end if;
end;
$$;

create extension if not exists pg_cron with schema pg_catalog;

do $$
declare
  existing_job_id bigint;
begin
  select jobid into existing_job_id
  from cron.job
  where jobname = 'monthly-backup';

  if existing_job_id is not null then
    perform cron.unschedule(existing_job_id);
  end if;

  perform cron.schedule(
    'monthly-backup',
    '0 19 * * *',
    $job$
      insert into public.backup_jobs (trigger_type, scope)
      select 'scheduled', 'full'
      where extract(day from (now() at time zone 'Asia/Jakarta')) = 1
      on conflict do nothing
    $job$
  );
end;
$$;
