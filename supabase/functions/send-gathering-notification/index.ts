import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const payload = await req.json()
  console.log('Gathering voting opened notification triggered:', payload)

  // TODO: Send push notifications to all members
  // e.g. via FCM, OneSignal, etc.

  return new Response(JSON.stringify({ message: 'Notification sent successfully' }), {
    headers: { 'Content-Type': 'application/json' },
    status: 200,
  })
})
