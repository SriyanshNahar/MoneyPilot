-- Persists Pro plan activation server-side. Before this migration, "Pro"
-- only ever lived in the Flutter app's local SharedPreferences (mp_plan) —
-- reinstalling the app or switching devices silently lost Pro status, and
-- profiles.plan (referenced by the reminder cron) was never actually
-- written to by anything. This fixes both.

alter table public.profiles
  add column if not exists plan_expires_at timestamptz;

create table if not exists public.plan_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan text not null,
  amount_paise integer not null,
  razorpay_order_id text not null,
  razorpay_payment_id text,
  status text not null default 'created' check (status in ('created', 'active', 'expired', 'cancelled')),
  started_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_plan_subscriptions_user on public.plan_subscriptions(user_id);
create unique index if not exists idx_plan_subscriptions_order on public.plan_subscriptions(razorpay_order_id);

alter table public.plan_subscriptions enable row level security;

create policy "Users can read their own subscriptions"
  on public.plan_subscriptions for select
  to authenticated
  using (auth.uid() = user_id);

-- Inserts/updates come only from the razorpay-create-order /
-- razorpay-verify-payment / razorpay-webhook edge functions (the first two
-- run as the authenticated user via their own RLS-scoped client and need an
-- insert/update policy; the webhook runs as service_role, which bypasses
-- RLS entirely and needs no policy).
create policy "Users can create their own pending subscription"
  on public.plan_subscriptions for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own subscription on verify"
  on public.plan_subscriptions for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, update on public.plan_subscriptions to authenticated;
grant all on public.plan_subscriptions to service_role;

create trigger trg_plan_subscriptions_updated_at
  before update on public.plan_subscriptions
  for each row execute function public.tg_set_updated_at();
