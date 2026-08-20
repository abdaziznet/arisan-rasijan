-- ============================================================
-- 005: Gathering Vote Tally
--
-- NOTE — correction vs. the plain SQL VIEW originally sketched in
-- DATABASE_SCHEMA.md (2.15): a plain view does NOT bypass the RLS
-- policy on gathering_votes. When gathering_votes_visible_to_members
-- = 'false', a member querying the view would still only see their
-- own row, making the aggregate wrong for everyone else.
--
-- Implemented instead as a SECURITY DEFINER function, which runs
-- with the privileges of its owner (bypassing gathering_votes RLS
-- safely) and only ever returns aggregate counts — never who voted
-- for what. This is the correct way to expose an aggregate without
-- exposing the underlying rows.
-- ============================================================

create or replace function public.get_gathering_vote_tally(p_gathering_event_id uuid)
returns table (option_id uuid, vote_count bigint)
language sql
security definer
set search_path = public
as $$
  select option_id, count(*) as vote_count
  from public.gathering_votes
  where gathering_event_id = p_gathering_event_id
  group by option_id;
$$;

grant execute on function public.get_gathering_vote_tally(uuid) to authenticated;