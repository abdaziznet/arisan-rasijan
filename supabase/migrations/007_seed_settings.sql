-- ============================================================
-- 007: Seed default app_settings
-- Sensible defaults so the app doesn't break before an admin
-- visits the settings screen for the first time.
-- ============================================================

insert into public.app_settings (key, value) values
  ('gathering_fund_percentage', '10'),
  ('gathering_votes_visible_to_members', 'false')
on conflict (key) do nothing;