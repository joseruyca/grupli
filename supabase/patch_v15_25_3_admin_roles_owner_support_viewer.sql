-- Grupli v15.25.3 — Roles de administración de app
-- No resetea datos. Define los roles owner / support / viewer y deja ruyca58@gmail.com como owner.

begin;

create table if not exists public.app_admins (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  role text not null default 'viewer' check (role in ('owner','support','viewer')),
  created_at timestamptz not null default now()
);

alter table public.app_admins enable row level security;

-- Rol actual del usuario autenticado dentro de la app.
create or replace function public.app_admin_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select a.role
    from public.app_admins a
    where a.user_id = auth.uid()
    limit 1
  ), '');
$$;

create or replace function public.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.app_admin_role() in ('owner','support','viewer');
$$;

create or replace function public.is_app_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.app_admin_role() = 'owner';
$$;

create or replace function public.can_handle_support()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.app_admin_role() in ('owner','support');
$$;

-- Cuentas tuyas: al iniciar sesión se aseguran como owner.
create or replace function public.ensure_owner_admin()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  jwt_email text;
begin
  jwt_email := lower(coalesce(auth.jwt() ->> 'email', ''));

  if jwt_email in ('joseruyca@gmail.com', 'ruyca58@gmail.com') then
    insert into public.app_admins(user_id, role)
    values (auth.uid(), 'owner')
    on conflict (user_id) do update set role = 'owner';
  end if;
end;
$$;

-- Si las cuentas ya existen en Auth, asegura perfil y rol owner.
insert into public.profiles (id, email, full_name)
select
  u.id,
  u.email,
  coalesce(nullif(u.raw_user_meta_data ->> 'full_name', ''), split_part(u.email, '@', 1), 'Usuario')
from auth.users u
where lower(coalesce(u.email, '')) in ('joseruyca@gmail.com', 'ruyca58@gmail.com')
on conflict (id) do update
set email = excluded.email;

insert into public.app_admins(user_id, role)
select p.id, 'owner'
from public.profiles p
where lower(coalesce(p.email, '')) in ('joseruyca@gmail.com', 'ruyca58@gmail.com')
on conflict (user_id) do update set role = 'owner';

-- Gestión manual segura de roles: solo owner puede conceder/cambiar roles.
create or replace function public.admin_set_app_admin_by_email(target_email text, target_role text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_email text := lower(trim(coalesce(target_email, '')));
  v_role text := lower(trim(coalesce(target_role, '')));
  v_uid uuid;
begin
  if not public.is_app_owner() then
    raise exception 'Solo un owner puede cambiar roles de administración.';
  end if;

  if v_role not in ('owner','support','viewer') then
    raise exception 'Rol no válido. Usa owner, support o viewer.';
  end if;

  select id into v_uid from auth.users where lower(email) = v_email limit 1;
  if v_uid is null then
    raise exception 'No existe ningún usuario Auth con ese email.';
  end if;

  insert into public.profiles(id, email, full_name)
  select u.id, u.email, coalesce(nullif(u.raw_user_meta_data ->> 'full_name', ''), split_part(u.email, '@', 1), 'Usuario')
  from auth.users u
  where u.id = v_uid
  on conflict (id) do update set email = excluded.email;

  insert into public.app_admins(user_id, role)
  values (v_uid, v_role)
  on conflict (user_id) do update set role = excluded.role;

  return jsonb_build_object('email', v_email, 'role', v_role, 'user_id', v_uid);
end;
$$;

create or replace function public.admin_remove_app_admin_by_email(target_email text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_email text := lower(trim(coalesce(target_email, '')));
  v_uid uuid;
begin
  if not public.is_app_owner() then
    raise exception 'Solo un owner puede quitar roles de administración.';
  end if;

  select id into v_uid from auth.users where lower(email) = v_email limit 1;
  if v_uid is null then
    raise exception 'No existe ningún usuario Auth con ese email.';
  end if;

  if v_uid = auth.uid() then
    raise exception 'No puedes quitarte tu propio rol owner desde aquí.';
  end if;

  delete from public.app_admins where user_id = v_uid;
  return jsonb_build_object('email', v_email, 'removed', true);
end;
$$;

-- Overview disponible para owner/support/viewer, sin exponer datos sensibles de reportes al viewer.
create or replace function public.admin_overview()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case
    when not public.is_app_admin() then '{}'::jsonb
    else jsonb_build_object(
      'role', public.app_admin_role(),
      'users', (select count(*) from public.profiles),
      'groups', (select count(*) from public.groups),
      'events', (select count(*) from public.events),
      'expenses', (select count(*) from public.expenses),
      'tournaments', (select count(*) from public.tournaments),
      'open_tickets', (select count(*) from public.support_tickets where status in ('open','reviewing')),
      'critical_tickets', (select count(*) from public.support_tickets where status in ('open','reviewing') and priority = 'critical'),
      'quality_events', (select count(*) from public.app_quality_events),
      'owners', (select count(*) from public.app_admins where role = 'owner'),
      'support', (select count(*) from public.app_admins where role = 'support'),
      'viewers', (select count(*) from public.app_admins where role = 'viewer')
    )
  end;
$$;

-- RLS de roles/admin/support.
drop policy if exists app_admins_select_self_or_admin on public.app_admins;
drop policy if exists app_admins_select_self_or_owner on public.app_admins;
drop policy if exists app_admins_insert_owner on public.app_admins;
drop policy if exists app_admins_update_owner on public.app_admins;
drop policy if exists app_admins_delete_owner on public.app_admins;
drop policy if exists support_tickets_select_own_or_admin on public.support_tickets;
drop policy if exists support_tickets_update_admin on public.support_tickets;
drop policy if exists support_tickets_select_own_or_support on public.support_tickets;
drop policy if exists support_tickets_update_support on public.support_tickets;
drop policy if exists app_quality_events_select_admin on public.app_quality_events;
drop policy if exists app_quality_events_select_app_admin on public.app_quality_events;

create policy app_admins_select_self_or_owner
on public.app_admins for select to authenticated
using (user_id = auth.uid() or public.is_app_owner());

create policy app_admins_insert_owner
on public.app_admins for insert to authenticated
with check (public.is_app_owner());

create policy app_admins_update_owner
on public.app_admins for update to authenticated
using (public.is_app_owner())
with check (public.is_app_owner());

create policy app_admins_delete_owner
on public.app_admins for delete to authenticated
using (public.is_app_owner() and user_id <> auth.uid());

create policy support_tickets_select_own_or_support
on public.support_tickets for select to authenticated
using (user_id = auth.uid() or public.can_handle_support());

create policy support_tickets_update_support
on public.support_tickets for update to authenticated
using (public.can_handle_support())
with check (public.can_handle_support());

create policy app_quality_events_select_app_admin
on public.app_quality_events for select to authenticated
using (public.is_app_admin());

revoke all on function public.app_admin_role() from public;
revoke all on function public.is_app_admin() from public;
revoke all on function public.is_app_owner() from public;
revoke all on function public.can_handle_support() from public;
revoke all on function public.ensure_owner_admin() from public;
revoke all on function public.admin_set_app_admin_by_email(text, text) from public;
revoke all on function public.admin_remove_app_admin_by_email(text) from public;
revoke all on function public.admin_overview() from public;

grant execute on function public.app_admin_role() to authenticated;
grant execute on function public.is_app_admin() to authenticated;
grant execute on function public.is_app_owner() to authenticated;
grant execute on function public.can_handle_support() to authenticated;
grant execute on function public.ensure_owner_admin() to authenticated;
grant execute on function public.admin_set_app_admin_by_email(text, text) to authenticated;
grant execute on function public.admin_remove_app_admin_by_email(text) to authenticated;
grant execute on function public.admin_overview() to authenticated;

commit;

-- USO MANUAL:
-- select public.admin_set_app_admin_by_email('email@dominio.com', 'support');
-- select public.admin_set_app_admin_by_email('email@dominio.com', 'viewer');
-- select public.admin_set_app_admin_by_email('email@dominio.com', 'owner');
-- select public.admin_remove_app_admin_by_email('email@dominio.com');
