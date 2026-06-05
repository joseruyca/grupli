-- Grupli v15.22 — Push notifications reales con Firebase Cloud Messaging
-- Ejecutar en Supabase SQL Editor después de v15.21.
-- No borra datos.

begin;

alter table public.user_devices
  add column if not exists app_version text,
  add column if not exists last_error text,
  add column if not exists disabled_at timestamptz;

alter table public.notifications
  add column if not exists push_status text not null default 'pending' check (push_status in ('pending','sent','partial','failed','skipped')),
  add column if not exists push_attempts integer not null default 0,
  add column if not exists push_sent_at timestamptz,
  add column if not exists push_error text;

create index if not exists idx_notifications_push_pending
  on public.notifications(push_status, created_at)
  where push_status in ('pending','failed','partial');

create index if not exists idx_user_devices_enabled
  on public.user_devices(user_id, enabled, last_seen_at desc);

create or replace function public.create_test_notification()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  insert into public.notifications (
    user_id,
    actor_id,
    type,
    title,
    body,
    route_type,
    push_status
  ) values (
    v_uid,
    v_uid,
    'general',
    'Prueba de Grupli',
    'Si ves este aviso fuera de la app, las push ya funcionan en este móvil.',
    'notifications',
    'pending'
  ) returning id into v_id;

  return v_id;
end;
$$;

grant execute on function public.create_test_notification() to authenticated;

-- Refresca la función de avisos por si venías de una versión antigua.
create or replace function public.create_group_notifications(
  p_group_id uuid,
  p_actor_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_route_type text,
  p_route_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  group_name text;
begin
  select name into group_name from public.groups where id = p_group_id;
  if group_name is null then
    return;
  end if;

  insert into public.notifications (user_id, group_id, actor_id, type, title, body, route_type, route_id, push_status)
  select
    gm.user_id,
    p_group_id,
    p_actor_id,
    case when p_type in ('event','finance','tournament','member','general') then p_type else 'general' end,
    p_title,
    group_name || ' · ' || p_body,
    p_route_type,
    p_route_id,
    'pending'
  from public.group_members gm
  left join public.user_settings us on us.user_id = gm.user_id
  where gm.group_id = p_group_id
    and (p_actor_id is null or gm.user_id <> p_actor_id)
    and coalesce(us.push_enabled, true) is not false
    and case
      when p_type = 'event' then coalesce(us.notify_events, true)
      when p_type = 'finance' then coalesce(us.notify_expenses, true)
      when p_type = 'tournament' then coalesce(us.notify_tournaments, true)
      when p_type = 'member' then coalesce(us.notify_members, true)
      else true
    end;
end;
$$;

commit;
