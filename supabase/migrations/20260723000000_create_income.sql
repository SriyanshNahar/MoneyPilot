-- Backend Phase 1: Income tracking. No equivalent table exists in the
-- original React app's schema (it only ever tracked expenses) — this is a
-- new table for the backend phase, mirroring `expenses`' shape/RLS style
-- since it's conceptually the counterpart to it.

create table if not exists public.income (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric not null check (amount >= 0),
  source text not null,                 -- 'Salary' | 'Freelance' | 'Business' | 'Rental' | 'Interest' | 'Other' | ...
  category text,                        -- optional free-form sub-classification
  income_date date not null,
  note text,
  is_recurring boolean not null default false,
  recurring_day int,                    -- day-of-month for recurring income (salary credit date, etc.)
  payment_method text,
  bank_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_income_user on public.income(user_id);
create index if not exists idx_income_date on public.income(user_id, income_date desc);

alter table public.income enable row level security;

drop policy if exists "Users can view their own income" on public.income;
create policy "Users can view their own income"
  on public.income for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can create their own income" on public.income;
create policy "Users can create their own income"
  on public.income for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own income" on public.income;
create policy "Users can update their own income"
  on public.income for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own income" on public.income;
create policy "Users can delete their own income"
  on public.income for delete
  to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete on public.income to authenticated;

drop trigger if exists trg_income_updated_at on public.income;
create trigger trg_income_updated_at
  before update on public.income
  for each row execute function public.tg_set_updated_at();
