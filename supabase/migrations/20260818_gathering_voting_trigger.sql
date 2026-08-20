-- Function to check and close gathering voting
CREATE OR REPLACE FUNCTION public.check_and_close_gathering_voting()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function after a new vote is inserted
DROP TRIGGER IF EXISTS on_gathering_vote_insert ON public.gathering_votes;
CREATE TRIGGER on_gathering_vote_insert
AFTER INSERT ON public.gathering_votes
FOR EACH ROW EXECUTE FUNCTION public.check_and_close_gathering_voting();

-- Grant execute on RPC function for tally
GRANT EXECUTE ON FUNCTION public.get_gathering_vote_tally(uuid) TO authenticated;

-- Function to handle gathering expense in ledger
CREATE OR REPLACE FUNCTION public.handle_gathering_expense_ledger()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for gathering expense
DROP TRIGGER IF EXISTS on_gathering_expense_update ON public.gathering_events;
CREATE TRIGGER on_gathering_expense_update
AFTER UPDATE ON public.gathering_events
FOR EACH ROW EXECUTE FUNCTION public.handle_gathering_expense_ledger();