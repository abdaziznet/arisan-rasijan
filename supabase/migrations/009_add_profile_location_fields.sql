-- ============================================================
-- 009: Add location metadata to profiles
-- Aligns with DATABASE_SCHEMA.md: profiles.address + location details
-- for home address, current location, and route navigation.
-- ============================================================

alter table public.profiles
  add column if not exists city text,
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists updated_at timestamptz;

-- Backfill existing rows to keep updated_at meaningful
update public.profiles
set updated_at = coalesce(updated_at, created_at, now())
where updated_at is null;

alter table public.profiles
  alter column updated_at set default now(),
  alter column updated_at set not null;

-- Optional validation for GPS coordinates
alter table public.profiles
  drop constraint if exists profiles_latitude_range,
  drop constraint if exists profiles_longitude_range;

alter table public.profiles
  add constraint profiles_latitude_range
    check (latitude is null or (latitude between -90 and 90)),
  add constraint profiles_longitude_range
    check (longitude is null or (longitude between -180 and 180));

-- Trigger to auto-update timestamp when profile is edited
create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;

create trigger trg_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_profiles_updated_at();
