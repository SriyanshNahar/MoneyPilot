-- Chat history for the AI Coach (Money Lab). Each row is one message in the
-- user's ongoing conversation with Claude — lets the chat reload prior
-- messages instead of starting over every time the screen is reopened.
--
-- Run with `supabase db push` or paste into the Dashboard SQL Editor.

create table if not exists public.ai_chat_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_ai_chat_messages_user_created on public.ai_chat_messages(user_id, created_at);

alter table public.ai_chat_messages enable row level security;

create policy "Users manage their own chat history"
  on public.ai_chat_messages for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, delete on public.ai_chat_messages to authenticated;
