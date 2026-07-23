-- Backend Phase 1: RLS hardening pass over every pre-existing table that
-- predates this migration history (created directly in the Supabase
-- dashboard before this repo tracked schema changes, so their RLS status
-- was never independently confirmed the way investments/loans/subscriptions
-- were in 20260722000003). Idempotent (drop-then-create) so re-running is
-- always safe. Policies are scoped to each table's *actual* client usage
-- (checked against the Flutter repositories that read/write them) rather
-- than a blanket full-CRUD grant everywhere:
--   - alert_prefs, security_settings: select/insert/update (no delete — the
--     app only ever fetches and upserts these single-row-per-user configs).
--   - profiles: select/update only, keyed on id (not user_id — profiles.id
--     *is* the auth.users id). No insert/delete policy: nothing in the
--     Flutter app inserts a profile row directly, meaning that row is
--     created server-side (trigger on auth.users, or dashboard-managed) —
--     granting client insert here would be a needless privilege widening.
--   - Every other table: full owner CRUD (select/insert/update/delete).

do $$
declare
  t text;
  full_crud_tables text[] := array[
    'budgets', 'device_tokens', 'emi_payments', 'expenses',
    'networth_items', 'networth_snapshots', 'personal_events'
  ];
begin
  foreach t in array full_crud_tables loop
    execute format('alter table public.%I enable row level security', t);

    execute format('drop policy if exists "phase1: select own" on public.%I', t);
    execute format(
      'create policy "phase1: select own" on public.%I for select to authenticated using (auth.uid() = user_id)', t
    );

    execute format('drop policy if exists "phase1: insert own" on public.%I', t);
    execute format(
      'create policy "phase1: insert own" on public.%I for insert to authenticated with check (auth.uid() = user_id)', t
    );

    execute format('drop policy if exists "phase1: update own" on public.%I', t);
    execute format(
      'create policy "phase1: update own" on public.%I for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)', t
    );

    execute format('drop policy if exists "phase1: delete own" on public.%I', t);
    execute format(
      'create policy "phase1: delete own" on public.%I for delete to authenticated using (auth.uid() = user_id)', t
    );

    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- alert_prefs / security_settings: select + insert + update only, no delete.
do $$
declare
  t text;
  config_tables text[] := array['alert_prefs', 'security_settings'];
begin
  foreach t in array config_tables loop
    execute format('alter table public.%I enable row level security', t);

    execute format('drop policy if exists "phase1: select own" on public.%I', t);
    execute format(
      'create policy "phase1: select own" on public.%I for select to authenticated using (auth.uid() = user_id)', t
    );

    execute format('drop policy if exists "phase1: insert own" on public.%I', t);
    execute format(
      'create policy "phase1: insert own" on public.%I for insert to authenticated with check (auth.uid() = user_id)', t
    );

    execute format('drop policy if exists "phase1: update own" on public.%I', t);
    execute format(
      'create policy "phase1: update own" on public.%I for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)', t
    );

    execute format('grant select, insert, update on public.%I to authenticated', t);
  end loop;
end $$;

-- profiles: keyed on id (= auth.users.id), select/update only.
alter table public.profiles enable row level security;

drop policy if exists "phase1: select own profile" on public.profiles;
create policy "phase1: select own profile"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "phase1: update own profile" on public.profiles;
create policy "phase1: update own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

grant select, update on public.profiles to authenticated;

-- reminder_log: read-only for the owning user; written by the server-side
-- reminders cron under service_role, which bypasses RLS entirely.
alter table public.reminder_log enable row level security;

drop policy if exists "phase1: select own reminder log" on public.reminder_log;
create policy "phase1: select own reminder log"
  on public.reminder_log for select
  to authenticated
  using (auth.uid() = user_id);

grant select on public.reminder_log to authenticated;
grant all on public.reminder_log to service_role;
