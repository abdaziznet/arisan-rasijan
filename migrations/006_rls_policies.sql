-- ============================================================
-- 006: Row Level Security
-- Every table: authenticated-only reads (mostly), admin-only
-- writes for financial/draw/voting data. See DATABASE_SCHEMA.md
-- section 4 for the overall principles.
-- ============================================================

-- 2.1 profiles ---------------------------------------------------
alter table public.profiles enable row level security;

create policy "profiles_select_authenticated"
  on public.profiles for select
  using (auth.uid() is not null);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (id = auth.uid());

create policy "profiles_update_own_or_admin"
  on public.profiles for update
  using (id = auth.uid() or public.is_admin());

-- 2.2 arisan_periods -----------------------------------------------
alter table public.arisan_periods enable row level security;

create policy "arisan_periods_select_all"
  on public.arisan_periods for select
  using (auth.uid() is not null);

create policy "arisan_periods_admin_insert"
  on public.arisan_periods for insert
  with check (public.is_admin());

create policy "arisan_periods_admin_update"
  on public.arisan_periods for update
  using (public.is_admin());

-- 2.3 payments --------------------------------------------------------
alter table public.payments enable row level security;

create policy "payments_select_all"
  on public.payments for select
  using (auth.uid() is not null);

create policy "payments_admin_insert"
  on public.payments for insert
  with check (public.is_admin());

create policy "payments_admin_update"
  on public.payments for update
  using (public.is_admin());

-- 2.4 donations ----------------------------------------------------------
alter table public.donations enable row level security;

create policy "donations_select_all"
  on public.donations for select
  using (auth.uid() is not null);

create policy "donations_admin_insert"
  on public.donations for insert
  with check (public.is_admin());

create policy "donations_admin_update"
  on public.donations for update
  using (public.is_admin());

-- 2.5 draws -------------------------------------------------------------
-- No update/delete policy at all: draw history is immutable once written.
alter table public.draws enable row level security;

create policy "draws_select_all"
  on public.draws for select
  using (auth.uid() is not null);

create policy "draws_admin_insert"
  on public.draws for insert
  with check (public.is_admin());

-- 2.6 event_checklist -----------------------------------------------------
alter table public.event_checklist enable row level security;

create policy "event_checklist_select_all"
  on public.event_checklist for select
  using (auth.uid() is not null);

create policy "event_checklist_admin_insert"
  on public.event_checklist for insert
  with check (public.is_admin());

create policy "event_checklist_admin_update"
  on public.event_checklist for update
  using (public.is_admin());

-- 2.7 event_photos -----------------------------------------------------
-- Anyone in the group can upload photos, not just admin.
alter table public.event_photos enable row level security;

create policy "event_photos_select_all"
  on public.event_photos for select
  using (auth.uid() is not null);

create policy "event_photos_insert_any_member"
  on public.event_photos for insert
  with check (auth.uid() is not null and uploaded_by = auth.uid());

-- 2.8 notifications -----------------------------------------------------
-- Read-only from the client; rows are written by Edge Function/cron
-- using the service_role key, so no insert policy is defined here.
alter table public.notifications enable row level security;

create policy "notifications_select_all"
  on public.notifications for select
  using (auth.uid() is not null);

-- 2.9 app_settings -----------------------------------------------------
alter table public.app_settings enable row level security;

create policy "app_settings_select_all"
  on public.app_settings for select
  using (auth.uid() is not null);

create policy "app_settings_admin_insert"
  on public.app_settings for insert
  with check (public.is_admin());

create policy "app_settings_admin_update"
  on public.app_settings for update
  using (public.is_admin());

-- 2.10 fund_ledger -----------------------------------------------------
-- Client never inserts directly in practice (trigger + Edge Function
-- do it), but the policy exists as a safety net for admin tooling.
alter table public.fund_ledger enable row level security;

create policy "fund_ledger_select_all"
  on public.fund_ledger for select
  using (auth.uid() is not null);

create policy "fund_ledger_admin_insert"
  on public.fund_ledger for insert
  with check (public.is_admin());

-- 2.11 gathering_events -----------------------------------------------
alter table public.gathering_events enable row level security;

create policy "gathering_events_select_all"
  on public.gathering_events for select
  using (auth.uid() is not null);

create policy "gathering_events_admin_insert"
  on public.gathering_events for insert
  with check (public.is_admin());

create policy "gathering_events_admin_update"
  on public.gathering_events for update
  using (public.is_admin());

-- 2.12 gathering_poll_options -------------------------------------------
alter table public.gathering_poll_options enable row level security;

create policy "gathering_poll_options_select_all"
  on public.gathering_poll_options for select
  using (auth.uid() is not null);

create policy "gathering_poll_options_admin_insert"
  on public.gathering_poll_options for insert
  with check (
    public.is_admin()
    and exists (
      select 1 from public.gathering_events e
      where e.id = gathering_event_id and e.status = 'voting'
    )
  );

-- 2.13 gathering_votes ---------------------------------------------------
-- SELECT is conditional on the app_settings toggle for vote visibility.
-- No update/delete policy: a vote is final once submitted.
alter table public.gathering_votes enable row level security;

create policy "gathering_votes_select"
  on public.gathering_votes for select
  using (
    member_id = auth.uid()
    or public.is_admin()
    or (select value from public.app_settings where key = 'gathering_votes_visible_to_members') = 'true'
  );

create policy "gathering_votes_insert_own"
  on public.gathering_votes for insert
  with check (
    member_id = auth.uid()
    and exists (
      select 1 from public.gathering_events e
      where e.id = gathering_event_id and e.status = 'voting'
    )
  );

-- 2.14 invite_codes --------------------------------------------------
-- Admin-only, and even admin writes for revoke/used_count should go
-- through the Edge Function contract in ARCHITECTURE.md (service_role),
-- not directly from the client. No policy is defined for anonymous
-- access — invite redemption always goes through redeem-invite-code.
alter table public.invite_codes enable row level security;

create policy "invite_codes_select_admin"
  on public.invite_codes for select
  using (public.is_admin());

create policy "invite_codes_admin_insert"
  on public.invite_codes for insert
  with check (public.is_admin());