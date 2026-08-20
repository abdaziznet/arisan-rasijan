import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    { global: { headers: { 'x-my-example-header': 'my-example-value' } } }
  )

  // TODO: Implement logic to query for upcoming events and send notifications
  console.log('Running send-reminders Edge Function')

  return new Response(JSON.stringify({ message: 'Reminders function executed' }), {
    headers: { 'Content-Type': 'application/json' },
    status: 200,
  })
})