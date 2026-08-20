-- ============================================================
-- 002: Tables
-- Refers to DATABASE_SCHEMA.md sections 2.1 - 2.14
-- Created in dependency order. gathering_events <-> gathering_poll_options
-- has a circular reference, resolved with an ALTER TABLE after both exist.
-- ============================================================

-- 2.1 profiles ---------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone_number text,
  address text,
  photo_url text,
  role text not null default 'member' check (role in ('admin', 'member')),
  is_active boolean not null default true,
  has_won_before boolean not null default false,
  created_at timestamptz not null default now()
);

-- 2.2 arisan_periods ----------------------------------------------
create table if not exists public.arisan_periods (
  id uuid primary key default gen_random_uuid(),
  period_number integer not null,
  event_date date not null,
  host_id uuid references public.profiles(id),
  host_address text,
  contribution_amount numeric,
  status text not null default 'upcoming' check (status in ('upcoming', 'ongoing', 'completed')),
  winner_id uuid references public.profiles(id),
  total_collected numeric,
  created_at timestamptz not null default now()
);

-- 2.3 payments ------------------------------------------------------
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  period_id uuid not null references public.arisan_periods(id) on delete cascade,
  member_id uuid not null references public.profiles(id),
  amount numeric not null,
  payment_method text check (payment_method in ('cash', 'transfer')),
  status text not null default 'unpaid' check (status in ('unpaid', 'paid')),
  paid_at timestamptz,
  recorded_by uuid references public.profiles(id),
  allocated_to_fund numeric not null default 0,
  unique (period_id, member_id)
);

-- 2.4 donations -------------------------------------------------------
create table if not exists public.donations (
  id uuid primary key default gen_random_uuid(),
  period_id uuid not null references public.arisan_periods(id) on delete cascade,
  member_id uuid not null references public.profiles(id),
  amount numeric not null,
  note text,
  created_at timestamptz not null default now()
);

-- 2.5 draws -----------------------------------------------------------
create table if not exists public.draws (
  id uuid primary key default gen_random_uuid(),
  period_id uuid not null unique references public.arisan_periods(id) on delete cascade,
  eligible_member_ids uuid[] not null,
  winner_id uuid not null references public.profiles(id),
  draw_method text not null default 'random',
  conducted_by uuid not null references public.profiles(id),
  conducted_at timestamptz not null default now()
);

-- 2.6 event_checklist ---------------------------------------------------
create table if not exists public.event_checklist (
  id uuid primary key default gen_random_uuid(),
  period_id uuid not null references public.arisan_periods(id) on delete cascade,
  step_name text not null,
  step_order integer not null,
  is_completed boolean not null default false,
  completed_at timestamptz
);

-- 2.7 event_photos ---------------------------------------------------
create table if not exists public.event_photos (
  id uuid primary key default gen_random_uuid(),
  period_id uuid not null references public.arisan_periods(id) on delete cascade,
  photo_url text not null,
  uploaded_by uuid not null references public.profiles(id),
  uploaded_at timestamptz not null default now()
);

-- 2.8 notifications (optional, phase 2) --------------------------------
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  period_id uuid references public.arisan_periods(id) on delete set null,
  title text not null,
  body text not null,
  sent_at timestamptz,
  type text not null check (type in ('reminder_h7', 'reminder_h1', 'announcement'))
);

-- 2.9 app_settings ------------------------------------------------------
create table if not exists public.app_settings (
  key text primary key,
  value text not null,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);

-- 2.11 gathering_events ---------------------------------------------------
-- winning_option_id FK added later (circular dependency with poll_options)
create table if not exists public.gathering_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  status text not null default 'voting' check (status in ('voting', 'decided', 'completed', 'cancelled')),
  winning_option_id uuid,
  event_date date,
  fund_used numeric,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  closed_at timestamptz
);

-- 2.12 gathering_poll_options ---------------------------------------------
create table if not exists public.gathering_poll_options (
  id uuid primary key default gen_random_uuid(),
  gathering_event_id uuid not null references public.gathering_events(id) on delete cascade,
  option_label text not null,
  created_at timestamptz not null default now()
);

-- Resolve circular FK: gathering_events.winning_option_id -> gathering_poll_options.id
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'gathering_events_winning_option_fk'
  ) then
    alter table public.gathering_events
      add constraint gathering_events_winning_option_fk
      foreign key (winning_option_id) references public.gathering_poll_options(id);
  end if;
end $$;

-- 2.13 gathering_votes ------------------------------------------------------
create table if not exists public.gathering_votes (
  id uuid primary key default gen_random_uuid(),
  gathering_event_id uuid not null references public.gathering_events(id) on delete cascade,
  option_id uuid not null references public.gathering_poll_options(id) on delete cascade,
  member_id uuid not null references public.profiles(id),
  voted_at timestamptz not null default now(),
  unique (gathering_event_id, member_id)
);

-- 2.10 fund_ledger (created after gathering_events for FK) ------------------
create table if not exists public.fund_ledger (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('contribution_allocation', 'gathering_expense', 'adjustment')),
  amount numeric not null,
  period_id uuid references public.arisan_periods(id),
  gathering_event_id uuid references public.gathering_events(id),
  description text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

-- 2.14 invite_codes ------------------------------------------------------
create table if not exists public.invite_codes (
  id uuid primary key default gen_random_uuid(),
  code_hash text not null,
  created_by uuid not null references public.profiles(id),
  expires_at timestamptz not null,
  max_uses integer not null default 1,
  used_count integer not null default 0,
  is_revoked boolean not null default false,
  revoked_by uuid references public.profiles(id),
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
