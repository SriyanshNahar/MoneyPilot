import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

/**
 * Verifies the caller's Supabase session JWT (forwarded automatically by
 * supabase_flutter's `functions.invoke`) and returns the authenticated user
 * plus a Supabase client bound to that same JWT (so any query it makes is
 * subject to the user's own RLS policies — never bypasses row-level security).
 * Mirrors requireSupabaseAuth in src/integrations/supabase/auth-middleware.ts.
 */
export async function requireUserWithClient(req: Request): Promise<{ user: { id: string; email?: string }; supabase: SupabaseClient }> {
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
  return { user: data.user, supabase };
}

/** Convenience wrapper for functions that only need the user, not the client. */
export async function requireUser(req: Request) {
  const { user } = await requireUserWithClient(req);
  return user;
}
