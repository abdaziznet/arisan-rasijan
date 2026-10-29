import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json({ error: "unauthorized" }, 401);
  }

  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !anonKey || !serviceRoleKey) {
    return json({ error: "server_configuration_error" }, 500);
  }

  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return json({ error: "unauthorized" }, 401);
  const adminClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: profile, error: profileError } = await adminClient
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .maybeSingle();
  if (profileError) return json({ error: "authorization_check_failed" }, 500);
  if (profile?.role !== "admin") {
    return json({ error: "forbidden" }, 403);
  }

  let body: Record<string, unknown>;
  try {
    const parsed: unknown = await req.json();
    if (
      parsed === null || typeof parsed !== "object" || Array.isArray(parsed)
    ) {
      return json({ error: "invalid_body" }, 400);
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return json({ error: "invalid_body" }, 400);
  }

  const scope = body.scope ?? "full";
  if (scope !== "full" && scope !== "db_only") {
    return json({ error: "invalid_scope" }, 400);
  }
  const rawNote = body.note;
  if (rawNote != null && typeof rawNote !== "string") {
    return json({ error: "invalid_note" }, 400);
  }
  const note = typeof rawNote === "string" ? rawNote.trim() : "";
  if (note.length > 200) return json({ error: "note_too_long" }, 400);

  const { data, error } = await adminClient
    .from("backup_jobs")
    .insert({
      requested_by: user.id,
      trigger_type: "manual",
      scope,
      note: note || null,
    })
    .select()
    .single();

  if (error?.code === "23505") {
    return json({ error: "Masih ada backup yang berjalan" }, 409);
  }
  if (error || !data) return json({ error: "request_failed" }, 500);
  return json(data, 201);
});
