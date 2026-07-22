-- The original React app only ever read investments/loans/subscriptions
-- (dashboard reminders) — it never wrote to them, so there's no existing
-- proof these tables carry insert/update/delete RLS policies. The new
-- Flutter CRUD screens (Goals/Investments/Loans/Subscriptions, v2.1) need
-- full owner CRUD on all three. Safe to re-run: policies are dropped and
-- recreated, so this is a no-op if they already matched.

-- investments
alter table public.investments enable row level security;

drop policy if exists "Users can view their own investments" on public.investments;
create policy "Users can view their own investments"
  on public.investments for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can create their own investments" on public.investments;
create policy "Users can create their own investments"
  on public.investments for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own investments" on public.investments;
create policy "Users can update their own investments"
  on public.investments for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own investments" on public.investments;
create policy "Users can delete their own investments"
  on public.investments for delete
  to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete on public.investments to authenticated;

-- loans
alter table public.loans enable row level security;

drop policy if exists "Users can view their own loans" on public.loans;
create policy "Users can view their own loans"
  on public.loans for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can create their own loans" on public.loans;
create policy "Users can create their own loans"
  on public.loans for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own loans" on public.loans;
create policy "Users can update their own loans"
  on public.loans for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own loans" on public.loans;
create policy "Users can delete their own loans"
  on public.loans for delete
  to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete on public.loans to authenticated;

-- subscriptions
alter table public.subscriptions enable row level security;

drop policy if exists "Users can view their own subscriptions" on public.subscriptions;
create policy "Users can view their own subscriptions"
  on public.subscriptions for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can create their own subscriptions" on public.subscriptions;
create policy "Users can create their own subscriptions"
  on public.subscriptions for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own subscriptions" on public.subscriptions;
create policy "Users can update their own subscriptions"
  on public.subscriptions for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own subscriptions" on public.subscriptions;
create policy "Users can delete their own subscriptions"
  on public.subscriptions for delete
  to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete on public.subscriptions to authenticated;

-- Keep `updated_at` accurate on manual edits from the new CRUD screens
-- (harmless no-op if these triggers already existed from the base schema).
drop trigger if exists trg_investments_updated_at on public.investments;
create trigger trg_investments_updated_at
  before update on public.investments
  for each row execute function public.tg_set_updated_at();

drop trigger if exists trg_loans_updated_at on public.loans;
create trigger trg_loans_updated_at
  before update on public.loans
  for each row execute function public.tg_set_updated_at();

drop trigger if exists trg_subscriptions_updated_at on public.subscriptions;
create trigger trg_subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.tg_set_updated_at();
