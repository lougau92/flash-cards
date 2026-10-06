create table if not exists public.app_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  category text not null check (
    category in ('Bug report', 'Research question', 'Idea', 'Other')
  ),
  message text not null check (char_length(message) between 5 and 4000),
  contact_email text
);

alter table public.app_feedback enable row level security;

revoke all on table public.app_feedback from anon, authenticated;
grant insert on table public.app_feedback to authenticated;

create policy "users can submit their own feedback"
  on public.app_feedback
  for insert
  to authenticated
  with check (auth.uid() = user_id);
