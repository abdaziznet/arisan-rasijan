-- ============================================================
-- 003: Indexes
-- Speeds up the lookups the app does constantly (by period,
-- by member, by gathering event).
-- ============================================================

create index if not exists idx_arisan_periods_host on public.arisan_periods(host_id);
create index if not exists idx_arisan_periods_winner on public.arisan_periods(winner_id);

create index if not exists idx_payments_period on public.payments(period_id);
create index if not exists idx_payments_member on public.payments(member_id);

create index if not exists idx_donations_period on public.donations(period_id);
create index if not exists idx_donations_member on public.donations(member_id);

create index if not exists idx_event_checklist_period on public.event_checklist(period_id);
create index if not exists idx_event_photos_period on public.event_photos(period_id);

create index if not exists idx_fund_ledger_period on public.fund_ledger(period_id);
create index if not exists idx_fund_ledger_gathering_event on public.fund_ledger(gathering_event_id);

create index if not exists idx_gathering_poll_options_event on public.gathering_poll_options(gathering_event_id);
create index if not exists idx_gathering_votes_event on public.gathering_votes(gathering_event_id);
create index if not exists idx_gathering_votes_option on public.gathering_votes(option_id);

create index if not exists idx_invite_codes_hash on public.invite_codes(code_hash);
