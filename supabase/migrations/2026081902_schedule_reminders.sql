-- Schedule to run everyday at 08:00 AM
-- Note: Replace <PROJECT_URL> with the actual Supabase project URL
SELECT cron.schedule(
  'send-daily-reminders',
  '0 8 * * *',
  'SELECT net.http_post(
     ''<PROJECT_URL>/functions/v1/send-reminders'',
     ''{"secret": "'' || current_setting(''app.settings.cron_secret'') || ''''}'',
     ''application/json''
   )'
);
