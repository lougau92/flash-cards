create table if not exists public.summary_runs (
  user_id uuid not null references auth.users (id) on delete cascade,
  id text not null,
  created_at timestamptz not null,
  run_data jsonb not null check (jsonb_typeof(run_data) = 'object'),
  primary key (user_id, id)
);

create index if not exists summary_runs_user_created_at_idx
  on public.summary_runs (user_id, created_at desc);

alter table public.summary_runs enable row level security;

grant select, insert, update, delete on public.summary_runs to authenticated;
revoke all on public.summary_runs from anon;

create policy "users can read their own summary runs"
  on public.summary_runs for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "users can insert their own summary runs"
  on public.summary_runs for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "users can update their own summary runs"
  on public.summary_runs for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "users can delete their own summary runs"
  on public.summary_runs for delete to authenticated
  using ((select auth.uid()) = user_id);
