-- Grupli v14.7 — miembros, invitaciones y permisos
-- Este parche NO resetea datos. Añade RPCs seguras para roles y miembros.

create or replace function public._grupli_current_member_role(p_group_id uuid)
returns text
language sql
security definer
set search_path = public
as $$
  select gm.role::text
  from public.group_members gm
  where gm.group_id = p_group_id
    and gm.user_id = auth.uid()
  limit 1;
$$;

create or replace function public.set_group_member_role(p_member_row_id uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
  v_target_role text;
  v_actor_role text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_role not in ('admin', 'member') then
    raise exception 'invalid_role';
  end if;

  select gm.group_id, gm.role::text
    into v_group_id, v_target_role
  from public.group_members gm
  where gm.id = p_member_row_id;

  if v_group_id is null then
    raise exception 'member_not_found';
  end if;

  v_actor_role := public._grupli_current_member_role(v_group_id);

  if v_actor_role not in ('owner', 'admin') then
    raise exception 'permission_denied';
  end if;

  if v_target_role = 'owner' then
    raise exception 'owner_protected';
  end if;

  update public.group_members
     set role = p_role
   where id = p_member_row_id;
end;
$$;

create or replace function public.remove_group_member(p_member_row_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
  v_target_role text;
  v_actor_role text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select gm.group_id, gm.role::text
    into v_group_id, v_target_role
  from public.group_members gm
  where gm.id = p_member_row_id;

  if v_group_id is null then
    raise exception 'member_not_found';
  end if;

  v_actor_role := public._grupli_current_member_role(v_group_id);

  if v_actor_role not in ('owner', 'admin') then
    raise exception 'permission_denied';
  end if;

  if v_target_role = 'owner' then
    raise exception 'owner_protected';
  end if;

  delete from public.group_members
   where id = p_member_row_id;
end;
$$;

create or replace function public.leave_group_safe(p_group_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_role text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  v_actor_role := public._grupli_current_member_role(p_group_id);

  if v_actor_role is null then
    raise exception 'not_member';
  end if;

  if v_actor_role = 'owner' then
    raise exception 'owner_protected';
  end if;

  delete from public.group_members
   where group_id = p_group_id
     and user_id = auth.uid();
end;
$$;

revoke all on function public._grupli_current_member_role(uuid) from public;
revoke all on function public.set_group_member_role(uuid, text) from public;
revoke all on function public.remove_group_member(uuid) from public;
revoke all on function public.leave_group_safe(uuid) from public;

grant execute on function public.set_group_member_role(uuid, text) to authenticated;
grant execute on function public.remove_group_member(uuid) to authenticated;
grant execute on function public.leave_group_safe(uuid) to authenticated;
