-- New in v2.1: Goals is a brand-new module with no equivalent table in the
-- original React app. Mirrors the shape/RLS style of investments/loans so
-- it behaves consistently with the rest of the money-tracking schema.

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  target_amount numeric not null,
  current_amount numeric not null default 0,
  target_date date,
  icon text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_goals_user on public.goals(user_id);

alter table public.goals enable row level security;

create policy "Users can view their own goals"
  on public.goals for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can create their own goals"
  on public.goals for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own goals"
  on public.goals for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own goals"
  on public.goals for delete
  to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete on public.goals to authenticated;

create trigger trg_goals_updated_at
  before update on public.goals
  for each row execute function public.tg_set_updated_at();
