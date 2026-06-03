-- Grupli v12.10
-- Fix: create_group_atomic tenía varias versiones antiguas en Supabase.
-- Eso provoca PGRST203: "Could not choose the best candidate function".
-- Este parche elimina TODAS las versiones sobrecargadas y deja una sola función oficial.

begin;

do $$
declare
  f record;
begin
  for f in
    select
      n.nspname as schema_name,
      p.proname as function_name,
      pg_get_function_identity_arguments(p.oid) as args
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('create_group_atomic', 'join_group_with_code')
  loop
    execute format(
      'drop function if exists %I.%I(%s) cascade',
      f.schema_name,
      f.function_name,
      f.args
    );
  end loop;
end $$;

create or replace function public.ensure_current_profile()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_email text;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  select email into current_email
  from auth.users
  where id = auth.uid();

  insert into public.profiles (id, email, full_name)
  values (
    auth.uid(),
    current_email,
    coalesce(nullif(split_part(current_email, '@', 1), ''), 'Usuario')
  )
  on conflict (id) do update set
    email = excluded.email,
    updated_at = now();

  insert into public.user_settings (user_id)
  values (auth.uid())
  on conflict (user_id) do nothing;
end;
$$;

create or replace function public.create_group_atomic(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_group_id uuid;
  clean_name text;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  perform public.ensure_current_profile();

  clean_name := trim(coalesce(p_name, ''));

  if char_length(clean_name) < 2 then
    raise exception 'El nombre del grupo es demasiado corto';
  end if;

  insert into public.groups (owner_id, name, type, privacy)
  values (auth.uid(), clean_name, 'otro', 'privado')
  returning id into new_group_id;

  insert into public.group_members (group_id, user_id, role)
  values (new_group_id, auth.uid(), 'owner')
  on conflict (group_id, user_id) do update set role = 'owner';

  return new_group_id;
end;
$$;

create or replace function public.join_group_with_code(code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  gid uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  perform public.ensure_current_profile();

  select id into gid
  from public.groups
  where invite_code = upper(trim(code));

  if gid is null then
    raise exception 'Código de invitación no válido';
  end if;

  insert into public.group_members(group_id, user_id, role)
  values (gid, auth.uid(), 'member')
  on conflict (group_id, user_id) do nothing;

  return gid;
end;
$$;

revoke all on function public.ensure_current_profile() from public;
revoke all on function public.create_group_atomic(text) from public;
revoke all on function public.join_group_with_code(text) from public;

grant execute on function public.ensure_current_profile() to authenticated;
grant execute on function public.create_group_atomic(text) to authenticated;
grant execute on function public.join_group_with_code(text) to authenticated;

commit;
