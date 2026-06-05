-- Grupli v15.23 — Core hardening: grupos, invitaciones, finanzas y realtime
-- Ejecutar en Supabase SQL Editor. No resetea datos.

begin;

-- 1) Grupos más completos sin romper los existentes.
alter table public.groups add column if not exists description text;
alter table public.groups add column if not exists currency text not null default 'EUR';
alter table public.groups add column if not exists timezone text not null default 'Europe/Madrid';
alter table public.groups add column if not exists language text not null default 'es';
alter table public.groups add column if not exists rules text;
alter table public.groups add column if not exists invite_updated_at timestamptz not null default now();

alter table public.groups drop constraint if exists groups_type_check;
alter table public.groups add constraint groups_type_check check (type in ('deporte','amigos','viaje','cartas','otro'));

alter table public.groups drop constraint if exists groups_currency_check;
alter table public.groups add constraint groups_currency_check check (currency in ('EUR','USD','GBP'));

alter table public.groups drop constraint if exists groups_language_check;
alter table public.groups add constraint groups_language_check check (language in ('es','en'));

-- 2) Crear grupo con tipo, descripción y ajustes básicos.
create or replace function public.create_group_atomic_v2(
  p_name text,
  p_type text default 'otro',
  p_description text default null,
  p_currency text default 'EUR',
  p_timezone text default 'Europe/Madrid',
  p_language text default 'es'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_group_id uuid;
  clean_name text;
  clean_type text;
  clean_currency text;
  clean_language text;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  perform public.ensure_current_profile();
  clean_name := trim(coalesce(p_name, ''));
  clean_type := lower(trim(coalesce(p_type, 'otro')));
  clean_currency := upper(trim(coalesce(p_currency, 'EUR')));
  clean_language := lower(trim(coalesce(p_language, 'es')));

  if char_length(clean_name) < 2 then
    raise exception 'El nombre del grupo es demasiado corto';
  end if;

  if clean_type not in ('deporte','amigos','viaje','cartas','otro') then
    clean_type := 'otro';
  end if;
  if clean_currency not in ('EUR','USD','GBP') then
    clean_currency := 'EUR';
  end if;
  if clean_language not in ('es','en') then
    clean_language := 'es';
  end if;

  insert into public.groups (owner_id, name, type, privacy, description, currency, timezone, language)
  values (
    auth.uid(),
    clean_name,
    clean_type,
    'privado',
    nullif(trim(coalesce(p_description, '')), ''),
    clean_currency,
    nullif(trim(coalesce(p_timezone, 'Europe/Madrid')), ''),
    clean_language
  )
  returning id into new_group_id;

  insert into public.group_members (group_id, user_id, role)
  values (new_group_id, auth.uid(), 'owner')
  on conflict (group_id, user_id) do nothing;

  return new_group_id;
end;
$$;

revoke all on function public.create_group_atomic_v2(text,text,text,text,text,text) from public;
grant execute on function public.create_group_atomic_v2(text,text,text,text,text,text) to authenticated;

-- 3) Regenerar código de invitación, solo owner/admin.
create or replace function public.regenerate_group_invite_code(p_group_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  new_code text;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;
  if not public.is_group_admin(p_group_id) then
    raise exception 'No tienes permiso para regenerar este código';
  end if;

  loop
    new_code := public.random_invite_code();
    exit when not exists (select 1 from public.groups where invite_code = new_code);
  end loop;

  update public.groups
  set invite_code = new_code,
      invite_updated_at = now(),
      updated_at = now()
  where id = p_group_id;

  return new_code;
end;
$$;

revoke all on function public.regenerate_group_invite_code(uuid) from public;
grant execute on function public.regenerate_group_invite_code(uuid) to authenticated;

-- 4) get_my_groups expone nuevos campos para UI futura, sin cambiar compatibilidad.
drop function if exists public.get_my_groups();
create or replace function public.get_my_groups()
returns table (
  id uuid,
  name text,
  type text,
  privacy text,
  invite_code text,
  cover_url text,
  role text,
  members_count int,
  events_count int,
  balance numeric,
  created_at timestamptz,
  description text,
  currency text,
  timezone text,
  language text
)
language sql
security definer
set search_path = public
as $$
  select
    g.id,
    g.name,
    g.type,
    g.privacy,
    g.invite_code,
    g.cover_url,
    gm.role,
    (select count(*)::int from public.group_members x where x.group_id = g.id) as members_count,
    (select count(*)::int from public.events e where e.group_id = g.id and e.status = 'active' and e.starts_at >= now() - interval '2 hours') as events_count,
    0::numeric as balance,
    g.created_at,
    g.description,
    g.currency,
    g.timezone,
    g.language
  from public.groups g
  join public.group_members gm on gm.group_id = g.id
  where gm.user_id = auth.uid()
  order by g.created_at desc;
$$;

grant execute on function public.get_my_groups() to authenticated;

commit;
