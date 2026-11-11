-- Preserve older flash-cards builds that omit app_id while labeling all existing rows.
begin;

alter table public.app_feedback
  add column if not exists app_id text not null default 'flash-cards';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.app_feedback'::regclass
      and conname = 'app_feedback_app_id_check'
  ) then
    alter table public.app_feedback add constraint app_feedback_app_id_check
      check (app_id ~ '^[a-z][a-z0-9-]{0,63}$');
  end if;
end;
$$;

create index if not exists app_feedback_app_created_idx
  on public.app_feedback (app_id, created_at desc, id desc);

commit;
