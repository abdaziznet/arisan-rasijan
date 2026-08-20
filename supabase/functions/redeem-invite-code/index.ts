import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { code, email } = await req.json();

    if (!code || !email) {
      return new Response(
        JSON.stringify({ success: false, message: "Kode undangan tidak valid" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Hash kode dengan SHA-256 (atau bcrypt)
    const encoder = new TextEncoder();
    const data = encoder.encode(code.trim());
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const codeHash = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

    // Query invite_codes
    const { data: invite, error } = await supabaseAdmin
      .from("invite_codes")
      .select("*")
      .eq("code_hash", codeHash)
      .eq("is_revoked", false)
      .gt("expires_at", new Date().toISOString())
      .single();

    if (error || !invite || invite.used_count >= invite.max_uses) {
      return new Response(
        JSON.stringify({ success: false, message: "Kode undangan tidak valid" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Increment used_count
    await supabaseAdmin
      .from("invite_codes")
      .update({ used_count: invite.used_count + 1 })
      .eq("id", invite.id);

    // Kirim Magic Link via Admin Auth API
    const { error: authError } = await supabaseAdmin.auth.signInWithOtp({
      email: email.trim(),
    });

    if (authError) {
      return new Response(
        JSON.stringify({ success: false, message: "Kode undangan tidak valid" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, message: "Magic link telah dikirim" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (_e) {
    return new Response(
      JSON.stringify({ success: false, message: "Kode undangan tidak valid" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
