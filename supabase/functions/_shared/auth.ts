import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * Verifies the caller's Supabase session JWT (forwarded automatically by
 * supabase_flutter's `functions.invoke`) and returns the authenticated user.
 * Mirrors requireSupabaseAuth in src/integrations/supabase/auth-middleware.ts.
 */
export async function requireUser(req: Request) {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) throw new Error("Missing Authorization header");

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const token = authHeader.replace("Bearer ", "");
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) throw new Error("Unauthorized");
  return data.user;
}
