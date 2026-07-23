-- Backend Phase 1: Notification Logs — distinct from `reminder_log` (which
-- only dedupes "did we already remind about ref X on date Y").
-- notification_logs is a per-channel delivery record (push/email/sms/
-- whatsapp), written by the future Email/SMS/WhatsApp edge functions and
-- the existing push path, readable by the user for an in-app history.
-- No client UI is wired to this yet (UI is frozen for this phase) — this
-- is backend infrastructure only.

create table if not exists public.notification_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  channel text not null check (channel in ('push', 'email', 'sms', 'whatsapp')),
  title text,
  body text,
  status text not null default 'sent' check (status in ('sent', 'delivered', 'failed', 'opened')),
  error text,
  related_type text,     -- 'expense' | 'income' | 'personal_event' | 'loan' | 'subscription' | ...
  related_id uuid,
  sent_at timestamptz not null default now()
);

create index if not exists idx_notification_logs_user on public.notification_logs(user_id, sent_at desc);

alter table public.notification_logs enable row level security;

-- Users can read their own notification history.
drop policy if exists "Users can view their own notification logs" on public.notification_logs;
create policy "Users can view their own notification logs"
  on public.notification_logs for select
  to authenticated
  using (auth.uid() = user_id);

-- Client-side (e.g. logging a local push notification that fired) may also
-- insert its own rows; server-side edge functions use the service_role key,
-- which bypasses RLS entirely, so no separate policy is needed for them.
drop policy if exists "Users can create their own notification logs" on public.notification_logs;
create policy "Users can create their own notification logs"
  on public.notification_logs for insert
  to authenticated
  with check (auth.uid() = user_id);

grant select, insert on public.notification_logs to authenticated;
grant all on public.notification_logs to service_role;
