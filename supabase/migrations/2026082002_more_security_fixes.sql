-- Migration: Fix additional security advisor warnings and set search_path
-- Date: 2026-08-20

-- 1. Fix search_path for notify_gathering_vote_opened
CREATE OR REPLACE FUNCTION public.notify_gathering_vote_opened()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, net
AS $$
BEGIN
  IF NEW.status = 'voting' AND OLD.status IS DISTINCT FROM NEW.status THEN
    SELECT net.http_post(
      'https://iggwgsuvdtcowlypnglj.supabase.co/functions/v1/send-gathering-notification',
      jsonb_build_object(
        'event_id', NEW.id,
        'title', NEW.title,
        'message', 'Pemungutan suara untuk acara gathering telah dibuka!'
      ),
      '{"Content-Type": "application/json"}'::jsonb
    );
    RAISE NOTICE 'Notification sent for gathering event %', NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

-- 2. Fix search_path for check_and_close_gathering_voting
CREATE OR REPLACE FUNCTION public.check_and_close_gathering_voting()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    event_id uuid;
    total_active_members int;
    current_votes_count int;
    winning_option uuid;
BEGIN
    event_id := NEW.gathering_event_id;

    -- Get total active members
    SELECT COUNT(*) INTO total_active_members
    FROM public.profiles
    WHERE is_active = TRUE;

    -- Get current votes count for this event
    SELECT COUNT(*) INTO current_votes_count
    FROM public.gathering_votes
    WHERE gathering_event_id = event_id;

    -- Check if all active members have voted
    IF current_votes_count >= total_active_members THEN
        -- Find the winning option (most votes, tie-break by option ID)
        SELECT gp.id INTO winning_option
        FROM public.gathering_poll_options gp
        LEFT JOIN public.gathering_votes gv ON gp.id = gv.option_id
        WHERE gp.gathering_event_id = event_id
        GROUP BY gp.id
        ORDER BY COUNT(gv.id) DESC, gp.created_at ASC, gp.id ASC -- Tie-break by creation date, then ID
        LIMIT 1;

        -- Update gathering_events status
        UPDATE public.gathering_events
        SET
            status = 'decided',
            winning_option_id = winning_option,
            closed_at = NOW()
        WHERE id = event_id AND status = 'voting'; -- Only close if still in voting status
    END IF;

    RETURN NEW;
END;
$$;

-- 3. Fix search_path for handle_gathering_expense_ledger
CREATE OR REPLACE FUNCTION public.handle_gathering_expense_ledger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check if fund_used was updated and is greater than 0
    IF (TG_OP = 'UPDATE') AND (NEW.fund_used IS DISTINCT FROM OLD.fund_used) AND (NEW.fund_used > 0) THEN
        -- Insert into fund_ledger
        INSERT INTO public.fund_ledger (
            id,
            type,
            amount,
            gathering_event_id,
            description,
            created_by,
            created_at
        ) VALUES (
            gen_random_uuid(),
            'gathering_expense',
            -NEW.fund_used, -- Amount is negative for expenses
            NEW.id,
            'Pengeluaran untuk event: ' || NEW.title,
            NEW.created_by, -- Assuming admin who created event or who updated it
            NOW()
        );
    END IF;
    RETURN NEW;
END;
$$;

-- 4. Revoke EXECUTE from anon explicitly on all SECURITY DEFINER / critical functions
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_admin() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_gathering_vote_tally(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.fn_allocate_payment_to_fund() FROM anon;
REVOKE EXECUTE ON FUNCTION public.fn_check_gathering_voting_complete() FROM anon;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM anon;
REVOKE EXECUTE ON FUNCTION public.notify_gathering_vote_opened() FROM anon;
REVOKE EXECUTE ON FUNCTION public.check_and_close_gathering_voting() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_gathering_expense_ledger() FROM anon;

-- Revoke from PUBLIC just in case
REVOKE EXECUTE ON FUNCTION public.notify_gathering_vote_opened() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.check_and_close_gathering_voting() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_gathering_expense_ledger() FROM PUBLIC;

-- 5. Grant to authenticated where necessary
GRANT EXECUTE ON FUNCTION public.notify_gathering_vote_opened() TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_and_close_gathering_voting() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_gathering_expense_ledger() TO authenticated;
