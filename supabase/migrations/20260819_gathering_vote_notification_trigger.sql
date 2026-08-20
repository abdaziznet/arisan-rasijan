-- Create a function that triggers the Edge Function when gathering event status becomes 'voting'
CREATE OR REPLACE FUNCTION notify_gathering_vote_opened()
RETURNS trigger AS $$
BEGIN
  IF NEW.status = 'voting' AND OLD.status IS DISTINCT FROM NEW.status THEN
    SELECT net.http_post(
      'https://<PROJECT_REF>.supabase.co/functions/v1/send-gathering-notification',
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
$$ LANGUAGE plpgsql;

-- Attach the trigger to gathering_events table
DROP TRIGGER IF EXISTS trigger_notify_gathering_vote_opened ON gathering_events;
CREATE TRIGGER trigger_notify_gathering_vote_opened
AFTER UPDATE OF status ON gathering_events
FOR EACH ROW
WHEN (NEW.status = 'voting' AND OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION notify_gathering_vote_opened();