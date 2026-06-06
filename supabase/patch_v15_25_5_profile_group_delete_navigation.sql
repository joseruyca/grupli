-- Grupli v15.25.5 — perfil, eliminar grupos y navegación
-- No resetea datos. Ejecutar en Supabase SQL Editor.

begin;

-- Permite que el borrado de grupo controlado por RPC pueda eliminar también la fila owner
-- sin romper la protección normal contra expulsar/degradar al creador.
create or replace function public.protect_owner_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_setting('app.grupli_deleting_group', true) = 'on' then
    return coalesce(new, old);
  end if;

  if tg_op = 'UPDATE' and new.role = 'owner' and old.role <> 'owner' then
    raise exception 'Solo puede existir el owner original del grupo';
  end if;

  if old.role = 'owner' and (tg_op = 'DELETE' or new.role <> 'owner') then
    raise exception 'No se puede expulsar ni degradar al creador del grupo';
  end if;

  return coalesce(new, old);
end;
$$;

create or replace function public.delete_group_safe(p_group_id uuid, p_confirm text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if upper(trim(coalesce(p_confirm, ''))) <> 'ELIMINAR GRUPO' then
    raise exception 'confirmation_required';
  end if;

  select owner_id into v_owner
  from public.groups
  where id = p_group_id;

  if v_owner is null then
    raise exception 'group_not_found';
  end if;

  if v_owner <> auth.uid() then
    raise exception 'only_owner_can_delete_group';
  end if;

  perform set_config('app.grupli_deleting_group', 'on', true);

  -- Limpieza explícita de tablas relacionadas para evitar bloqueos por triggers/RLS/cascadas antiguas.
  delete from public.notifications where group_id = p_group_id;
  delete from public.support_tickets where group_id = p_group_id;
  delete from public.settlement_payments where group_id = p_group_id;
  delete from public.expense_participants
   where expense_id in (select id from public.expenses where group_id = p_group_id);
  delete from public.expenses where group_id = p_group_id;
  delete from public.event_attendance
   where event_id in (select id from public.events where group_id = p_group_id);
  delete from public.events where group_id = p_group_id;
  delete from public.matches
   where tournament_id in (select id from public.tournaments where group_id = p_group_id);
  delete from public.tournament_teams
   where tournament_id in (select id from public.tournaments where group_id = p_group_id);
  delete from public.tournaments where group_id = p_group_id;
  delete from public.group_members where group_id = p_group_id;
  delete from public.groups where id = p_group_id;

  perform set_config('app.grupli_deleting_group', 'off', true);
exception
  when others then
    perform set_config('app.grupli_deleting_group', 'off', true);
    raise;
end;
$$;

revoke all on function public.delete_group_safe(uuid, text) from public;
grant execute on function public.delete_group_safe(uuid, text) to authenticated;

commit;
