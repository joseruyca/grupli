-- Grupli v15.21 — Admin + soporte + calidad
-- Ejecutar en Supabase SQL Editor después de instalar el ZIP.
-- Añade panel admin, reportes de usuarios y eventos básicos de calidad.

create extension if not exists "pgcrypto";

begin;

create table if not exists public.app_admins (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner','support','viewer')),
  created_at timestamptz not null default now()
);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  group_id uuid references public.groups(id) on delete set null,
  type text not null default 'bug' check (type in ('bug','cuenta','grupo','evento','finanzas','torneo','notificaciones','sugerencia','otro')),
  title text not null check (char_length(trim(title)) >= 3),
  description text not null check (char_length(trim(description)) >= 8),
  status text not null default 'open' check (status in ('open','reviewing','resolved','closed')),
  priority text not null default 'normal' check (priority in ('low','normal','high','critical')),
  screen text,
  app_version text,
  device_info text,
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists public.app_quality_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  group_id uuid references public.groups(id) on delete set null,
  event_type text not null,
  screen text,
  message text,
  app_version text,
  platform text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.app_admins enable row level security;
alter table public.support_tickets enable row level security;
alter table public.app_quality_events enable row level security;

create or replace function public.is_app_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.app_admins a
    where a.user_id = auth.uid()
  );
$$;

create or replace function public.ensure_owner_admin()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  jwt_email text;
begin
  jwt_email := coalesce(auth.jwt() ->> 'email', '');

  if lower(jwt_email) = 'joseruyca@gmail.com' then
    insert into public.app_admins(user_id, role)
    values (auth.uid(), 'owner')
    on conflict (user_id) do nothing;
  end if;
end;
$$;

-- También intenta asignar admin si el perfil ya existe al ejecutar el SQL.
insert into public.app_admins(user_id, role)
select id, 'owner'
from public.profiles
where lower(coalesce(email, '')) = 'joseruyca@gmail.com'
on conflict (user_id) do nothing;

create or replace function public.admin_overview()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when not public.is_app_admin() then '{}'::jsonb
    else jsonb_build_object(
      'users', (select count(*) from public.profiles),
      'groups', (select count(*) from public.groups),
      'events', (select count(*) from public.events),
      'expenses', (select count(*) from public.expenses),
      'tournaments', (select count(*) from public.tournaments),
      'open_tickets', (select count(*) from public.support_tickets where status in ('open','reviewing')),
      'critical_tickets', (select count(*) from public.support_tickets where status in ('open','reviewing') and priority = 'critical'),
      'quality_events', (select count(*) from public.app_quality_events)
    )
  end;
$$;

-- Políticas idempotentes.
drop policy if exists app_admins_select_self_or_admin on public.app_admins;
drop policy if exists support_tickets_insert_own on public.support_tickets;
drop policy if exists support_tickets_select_own_or_admin on public.support_tickets;
drop policy if exists support_tickets_update_admin on public.support_tickets;
drop policy if exists app_quality_events_insert_own on public.app_quality_events;
drop policy if exists app_quality_events_select_admin on public.app_quality_events;

create policy app_admins_select_self_or_admin
on public.app_admins for select to authenticated
using (user_id = auth.uid() or public.is_app_admin());

create policy support_tickets_insert_own
on public.support_tickets for insert to authenticated
with check (user_id = auth.uid());

create policy support_tickets_select_own_or_admin
on public.support_tickets for select to authenticated
using (user_id = auth.uid() or public.is_app_admin());

create policy support_tickets_update_admin
on public.support_tickets for update to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

create policy app_quality_events_insert_own
on public.app_quality_events for insert to authenticated
with check (user_id = auth.uid());

create policy app_quality_events_select_admin
on public.app_quality_events for select to authenticated
using (public.is_app_admin());

-- Permitir que el owner de la app vea perfiles y grupos desde el panel admin.
drop policy if exists profiles_select_app_admin on public.profiles;
drop policy if exists groups_select_app_admin on public.groups;

create policy profiles_select_app_admin
on public.profiles for select to authenticated
using (public.is_app_admin());

create policy groups_select_app_admin
on public.groups for select to authenticated
using (public.is_app_admin());

create index if not exists support_tickets_status_created_idx on public.support_tickets(status, created_at desc);
create index if not exists support_tickets_user_created_idx on public.support_tickets(user_id, created_at desc);
create index if not exists support_tickets_group_idx on public.support_tickets(group_id);
create index if not exists app_quality_events_created_idx on public.app_quality_events(created_at desc);
create index if not exists app_quality_events_user_idx on public.app_quality_events(user_id);

revoke all on function public.is_app_admin() from public;
revoke all on function public.ensure_owner_admin() from public;
revoke all on function public.admin_overview() from public;
grant execute on function public.is_app_admin() to authenticated;
grant execute on function public.ensure_owner_admin() to authenticated;
grant execute on function public.admin_overview() to authenticated;

commit;
