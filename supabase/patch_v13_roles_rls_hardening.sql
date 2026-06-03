-- Grupli v13 - RLS and role hardening.
-- This patch does not reset data. It only prevents duplicate owners and keeps role rules clear.

create or replace function public.is_group_owner(target_group_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.group_members gm
    where gm.group_id = target_group_id
      and gm.user_id = auth.uid()
      and gm.role = 'owner'
  );
$$;

drop trigger if exists protect_owner_role_trigger on public.group_members;
drop function if exists public.protect_owner_role() cascade;

create or replace function public.protect_owner_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and new.role = 'owner' and old.role <> 'owner' then
    raise exception 'Solo puede existir el owner original del grupo';
  end if;

  if old.role = 'owner' and (tg_op = 'DELETE' or new.role <> 'owner') then
    raise exception 'No se puede expulsar ni degradar al creador del grupo';
  end if;

  return coalesce(new, old);
end;
$$;

create trigger protect_owner_role_trigger
before update or delete on public.group_members
for each row execute function public.protect_owner_role();

-- Make sure old overloaded create_group_atomic functions are gone.
do $$
declare
  f record;
begin
  for f in
    select n.nspname as schema_name, p.proname as function_name, pg_get_function_identity_arguments(p.oid) as args
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'create_group_atomic'
      and pg_get_function_identity_arguments(p.oid) <> 'p_name text'
  loop
    execute format('drop function if exists %I.%I(%s) cascade', f.schema_name, f.function_name, f.args);
  end loop;
end $$;
