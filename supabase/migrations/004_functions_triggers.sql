-- ============================================================
-- 004: Functions & Triggers
-- Implements the two pieces of "server-side only" logic called
-- out in ARCHITECTURE.md: fund allocation on payment, and
-- automatic voting close when all active members have voted.
-- ============================================================

-- --------------------------------------------------------------
-- Trigger: auto-allocate a cut of each paid contribution into
-- fund_ledger, based on app_settings.gathering_fund_percentage.
-- Fires on INSERT (payment created already 'paid') or UPDATE
-- (status flips from something else to 'paid').
-- --------------------------------------------------------------
create or replace function public.fn_allocate_payment_to_fund()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_percentage numeric;
  v_allocation numeric;
begin
  if new.status = 'paid' and (tg_op = 'INSERT' or old.status is distinct from 'paid') then
    select coalesce(value::numeric, 0) into v_percentage
    from public.app_settings
    where key = 'gathering_fund_percentage';

    v_allocation := round(new.amount * (coalesce(v_percentage, 0) / 100), 2);
    new.allocated_to_fund := v_allocation;

    insert into public.fund_ledger (type, amount, period_id, description, created_by)
    values (
      'contribution_allocation',
      v_allocation,
      new.period_id,
      'Alokasi otomatis dari iuran anggota',
      coalesce(new.recorded_by, new.member_id)
    );
  end if;
  return new;
end;
$$;

create trigger trg_allocate_payment_to_fund
before insert or update on public.payments
for each row
execute function public.fn_allocate_payment_to_fund();

-- --------------------------------------------------------------
-- Trigger: after each vote, check if every active member has
-- voted. If so, tally the winning option and close the event.
-- --------------------------------------------------------------
create or replace function public.fn_check_gathering_voting_complete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total_votes integer;
  v_active_members integer;
  v_winning_option uuid;
begin
  select count(*) into v_total_votes
  from public.gathering_votes
  where gathering_event_id = new.gathering_event_id;

  select count(*) into v_active_members
  from public.profiles
  where is_active = true;

  if v_total_votes >= v_active_members then
    select option_id into v_winning_option
    from public.gathering_votes
    where gathering_event_id = new.gathering_event_id
    group by option_id
    order by count(*) desc
    limit 1;

    update public.gathering_events
    set status = 'decided',
        winning_option_id = v_winning_option,
        closed_at = now()
    where id = new.gathering_event_id
      and status = 'voting';
  end if;

  return new;
end;
$$;

create trigger trg_check_gathering_voting_complete
after insert on public.gathering_votes
for each row
execute function public.fn_check_gathering_voting_complete();