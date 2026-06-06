-- Grupli v15.29 — Admin/soporte más real
-- No resetea nada. Añade panel admin más útil, usuarios, grupos, dispositivos y bloqueo lógico.

create extension if not exists "pgcrypto";

begin;

create table if not exists public.app_user_flags (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  status text not null default 'active' check (status in ('active','blocked')),
  note text,
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.app_user_flags enable row level security;
alter table public.user_devices add column if not exists app_version text;

create or replace function public.app_admin_role()
returns text
language sql
security definer
set search_path = public
as $$
  select coalesce(
    (select a.role from public.app_admins a where a.user_id = auth.uid()),
    ''
  );
$$;

create or replace function public.is_app_owner()
returns boolean
language sql
security definer
set search_path = public
as $$
  select public.app_admin_role() = 'owner';
$$;

create or replace function public.is_app_support_or_owner()
returns boolean
language sql
security definer
set search_path = public
as $$
  select public.app_admin_role() in ('owner','support');
$$;

create or replace function public.admin_set_user_status_by_email(target_email text, new_status text, note text default '')
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  target_id uuid;
begin
  if public.app_admin_role() <> 'owner' then
    raise exception 'Solo owner puede modificar el estado de usuarios.';
  end if;

  if new_status not in ('active','blocked') then
    raise exception 'Estado inválido.';
  end if;

  select p.id into target_id
  from public.profiles p
  where lower(p.email) = lower(trim(target_email))
  limit 1;

  if target_id is null then
    raise exception 'Usuario no encontrado.';
  end if;

  insert into public.app_user_flags(user_id, status, note, updated_by, updated_at)
  values (target_id, new_status, nullif(trim(note), ''), auth.uid(), now())
  on conflict (user_id) do update
  set status = excluded.status,
      note = excluded.note,
      updated_by = auth.uid(),
      updated_at = now();

  insert into public.app_quality_events(user_id, event_type, screen, message, metadata)
  values (
    auth.uid(),
    'admin_user_status_changed',
    'admin',
    target_email,
    jsonb_build_object('target_user_id', target_id, 'status', new_status)
  );

  return true;
end;
$$;

create or replace function public.admin_users_overview()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when public.app_admin_role() <> 'owner' then '[]'::jsonb
    else coalesce((
      select jsonb_agg(row_to_json(x)::jsonb order by x.created_at desc)
      from (
        select
          p.id,
          p.email,
          p.full_name,
          p.avatar_url,
          p.created_at,
          p.updated_at,
          coalesce(f.status, 'active') as status,
          f.note as status_note,
          f.updated_at as status_updated_at,
          coalesce(a.role, '') as admin_role,
          (select count(*) from public.group_members gm where gm.user_id = p.id) as groups_count,
          (select count(*) from public.user_devices d where d.user_id = p.id) as devices_count,
          (select max(d.last_seen_at) from public.user_devices d where d.user_id = p.id) as last_seen_at
        from public.profiles p
        left join public.app_user_flags f on f.user_id = p.id
        left join public.app_admins a on a.user_id = p.id
        order by p.created_at desc
        limit 150
      ) x
    ), '[]'::jsonb)
  end;
$$;

create or replace function public.admin_groups_overview()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when public.app_admin_role() <> 'owner' then '[]'::jsonb
    else coalesce((
      select jsonb_agg(row_to_json(x)::jsonb order by x.created_at desc)
      from (
        select
          g.id,
          g.name,
          g.created_at,
          g.owner_id,
          coalesce(owner.email, '') as owner_email,
          (select count(*) from public.group_members gm where gm.group_id = g.id) as members_count,
          (select count(*) from public.events e where e.group_id = g.id) as events_count,
          (select count(*) from public.expenses ex where ex.group_id = g.id) as expenses_count,
          (select count(*) from public.tournaments t where t.group_id = g.id) as tournaments_count
        from public.groups g
        left join public.profiles owner on owner.id = g.owner_id
        order by g.created_at desc
        limit 150
      ) x
    ), '[]'::jsonb)
  end;
$$;

create or replace function public.admin_devices_overview()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when public.app_admin_role() <> 'owner' then '[]'::jsonb
    else coalesce((
      select jsonb_agg(row_to_json(x)::jsonb order by x.last_seen_at desc)
      from (
        select
          d.id,
          d.user_id,
          p.email,
          p.full_name,
          d.platform,
          d.device_label,
          d.enabled,
          d.last_seen_at,
          d.created_at,
          coalesce(d.app_version, '') as app_version
        from public.user_devices d
        left join public.profiles p on p.id = d.user_id
        order by d.last_seen_at desc
        limit 150
      ) x
    ), '[]'::jsonb)
  end;
$$;

create or replace function public.admin_overview()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when public.app_admin_role() = '' then '{}'::jsonb
    else jsonb_build_object(
      'users', (select count(*) from public.profiles),
      'blocked_users', (select count(*) from public.app_user_flags where status = 'blocked'),
      'groups', (select count(*) from public.groups),
      'events', (select count(*) from public.events),
      'expenses', (select count(*) from public.expenses),
      'tournaments', (select count(*) from public.tournaments),
      'devices', (select count(*) from public.user_devices),
      'push_enabled_devices', (select count(*) from public.user_devices where enabled is true),
      'open_tickets', (select count(*) from public.support_tickets where status in ('open','reviewing')),
      'critical_tickets', (select count(*) from public.support_tickets where status in ('open','reviewing') and priority = 'critical'),
      'quality_events', (select count(*) from public.app_quality_events)
    )
  end;
$$;

drop policy if exists app_user_flags_owner_select on public.app_user_flags;
drop policy if exists app_user_flags_owner_all on public.app_user_flags;
create policy app_user_flags_owner_select
on public.app_user_flags for select to authenticated
using (public.app_admin_role() = 'owner');

create policy app_user_flags_owner_all
on public.app_user_flags for all to authenticated
using (public.app_admin_role() = 'owner')
with check (public.app_admin_role() = 'owner');

drop policy if exists user_devices_select_app_owner on public.user_devices;
create policy user_devices_select_app_owner
on public.user_devices for select to authenticated
using (public.app_admin_role() = 'owner');

revoke all on function public.app_admin_role() from public;
revoke all on function public.is_app_owner() from public;
revoke all on function public.is_app_support_or_owner() from public;
revoke all on function public.admin_set_user_status_by_email(text,text,text) from public;
revoke all on function public.admin_users_overview() from public;
revoke all on function public.admin_groups_overview() from public;
revoke all on function public.admin_devices_overview() from public;
revoke all on function public.admin_overview() from public;

grant execute on function public.app_admin_role() to authenticated;
grant execute on function public.is_app_owner() to authenticated;
grant execute on function public.is_app_support_or_owner() to authenticated;
grant execute on function public.admin_set_user_status_by_email(text,text,text) to authenticated;
grant execute on function public.admin_users_overview() to authenticated;
grant execute on function public.admin_groups_overview() to authenticated;
grant execute on function public.admin_devices_overview() to authenticated;
grant execute on function public.admin_overview() to authenticated;

commit;
