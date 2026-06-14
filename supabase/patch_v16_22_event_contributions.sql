-- Grupli v16.22 — Qué llevamos en eventos
-- Ejecutar en Supabase SQL Editor si NO haces reset completo con all_in_one.sql.
-- Añade una tabla segura para que cada miembro indique qué va a llevar a un evento.

begin;

create table if not exists public.event_contributions (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references public.groups(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  items_text text not null check (char_length(trim(items_text)) between 2 and 240),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(event_id, user_id)
);

create index if not exists idx_event_contributions_group_event on public.event_contributions(group_id, event_id);
create index if not exists idx_event_contributions_user on public.event_contributions(user_id);

create or replace function public.set_event_contribution_group_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
begin
  select e.group_id into v_group_id
  from public.events e
  where e.id = new.event_id
    and e.status <> 'cancelled';

  if v_group_id is null then
    raise exception 'Evento no válido.';
  end if;

  new.group_id := v_group_id;
  if new.user_id is null then
    new.user_id := auth.uid();
  end if;
  new.items_text := trim(new.items_text);
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists set_event_contribution_group_id_trigger on public.event_contributions;
create trigger set_event_contribution_group_id_trigger
before insert or update of event_id, items_text on public.event_contributions
for each row execute function public.set_event_contribution_group_id();

alter table public.event_contributions enable row level security;

drop policy if exists event_contributions_select_member on public.event_contributions;
create policy event_contributions_select_member
on public.event_contributions
for select
to authenticated
using (public.is_group_member(group_id));

drop policy if exists event_contributions_insert_self on public.event_contributions;
create policy event_contributions_insert_self
on public.event_contributions
for insert
to authenticated
with check (
  user_id = auth.uid()
  and public.is_group_member(group_id)
  and exists (
    select 1 from public.events e
    where e.id = event_id
      and e.group_id = group_id
      and e.status <> 'cancelled'
  )
);

drop policy if exists event_contributions_update_self on public.event_contributions;
create policy event_contributions_update_self
on public.event_contributions
for update
to authenticated
using (user_id = auth.uid() and public.is_group_member(group_id))
with check (
  user_id = auth.uid()
  and public.is_group_member(group_id)
  and exists (
    select 1 from public.events e
    where e.id = event_id
      and e.group_id = group_id
      and e.status <> 'cancelled'
  )
);

drop policy if exists event_contributions_delete_self_or_admin on public.event_contributions;
create policy event_contributions_delete_self_or_admin
on public.event_contributions
for delete
to authenticated
using (user_id = auth.uid() or public.is_group_admin(group_id));

do $$
begin
  alter publication supabase_realtime add table public.event_contributions;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

commit;
