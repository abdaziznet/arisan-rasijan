import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

console.log('Hello from run-draw function!');

// Handle CORS preflight requests
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Create Supabase client with service role (bypasses RLS)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 2. Verify the caller is an admin using the Authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Authorization header required');
    }

    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(
      authHeader.replace('Bearer ', '')
    );

    if (userError || !user) {
      throw new Error('Invalid authentication');
    }

    // Check if user is admin
    const { data: member, error: memberError } = await supabaseAdmin
      .from('members')
      .select('role')
      .eq('id', user.id)
      .single();

    if (memberError || !member || member.role !== 'admin') {
      throw new Error('Admin access required');
    }

    // 3. Get periodId from the request body
    const { periodId } = await req.json();
    if (!periodId) {
      throw new Error('periodId is required.');
    }

    // 4. Call the database function to run the draw (idempotent)
    const { data: draw, error: drawError } = await supabaseAdmin
      .rpc('run_draw', { p_period_id: periodId });

    if (drawError) {
      throw new Error(drawError.message);
    }

    // 5. Return the draw result
    return new Response(JSON.stringify(draw), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    console.error('run-draw error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});