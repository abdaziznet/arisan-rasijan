-- Expose a period-level verified total to authenticated members without
-- exposing other members' donation rows, which remain protected by RLS.
create or replace function public.get_verified_donation_total(p_period_id uuid)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum(coalesce(d.received_amount, d.amount)), 0)::numeric
  from public.donations as d
  where d.period_id = p_period_id
    and d.status = 'verified'
    and (select auth.uid()) is not null;
$$;

revoke all on function public.get_verified_donation_total(uuid)
  from public, anon, authenticated;
grant execute on function public.get_verified_donation_total(uuid)
  to authenticated;
