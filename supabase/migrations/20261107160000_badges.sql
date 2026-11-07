create table if not exists public.badge_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.badge_people (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  template_id uuid not null references public.badge_templates (id) on delete cascade,
  name text not null default '',
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create index if not exists badge_templates_user on public.badge_templates (user_id);
create index if not exists badge_people_user on public.badge_people (user_id);
create index if not exists badge_people_template on public.badge_people (template_id);

alter table public.badge_templates enable row level security;
alter table public.badge_people enable row level security;

revoke all on public.badge_templates from anon;
revoke all on public.badge_people from anon;
grant select, insert, update, delete on public.badge_templates to authenticated;
grant select, insert, update, delete on public.badge_people to authenticated;

create policy "own templates read" on public.badge_templates for select to authenticated using (user_id = auth.uid());
create policy "own templates add" on public.badge_templates for insert to authenticated with check (user_id = auth.uid());
create policy "own templates change" on public.badge_templates for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own templates remove" on public.badge_templates for delete to authenticated using (user_id = auth.uid());

create policy "own people read" on public.badge_people for select to authenticated using (user_id = auth.uid());
create policy "own people add" on public.badge_people for insert to authenticated with check (
  user_id = auth.uid() and exists (select 1 from public.badge_templates t where t.id = template_id and t.user_id = auth.uid())
);
create policy "own people change" on public.badge_people for update to authenticated using (user_id = auth.uid()) with check (
  user_id = auth.uid() and exists (select 1 from public.badge_templates t where t.id = template_id and t.user_id = auth.uid())
);
create policy "own people remove" on public.badge_people for delete to authenticated using (user_id = auth.uid());
