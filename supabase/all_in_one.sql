-- Grupli v14 clean rebuild
-- Ejecutar en Supabase SQL Editor para resetear la base de datos de Grupli.
-- Borra SOLO las tablas propias de Grupli y las recrea con RLS.

create extension if not exists "pgcrypto";

begin;

-- Drop any old overloaded RPC signatures that may exist from previous versions.
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

-- Drop policies/functions/tables safely
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.random_invite_code() CASCADE;
DROP FUNCTION IF EXISTS public.ensure_current_profile() CASCADE;
DROP FUNCTION IF EXISTS public.is_group_member(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_admin(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_owner(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.create_group_atomic(text) CASCADE;
DROP FUNCTION IF EXISTS public.join_group_with_code(text) CASCADE;
DROP FUNCTION IF EXISTS public.get_my_groups() CASCADE;
DROP FUNCTION IF EXISTS public.protect_owner_role() CASCADE;
DROP FUNCTION IF EXISTS public.create_group_notifications(uuid, uuid, text, text, text, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.notify_event_insert() CASCADE;
DROP FUNCTION IF EXISTS public.notify_event_update() CASCADE;
DROP FUNCTION IF EXISTS public.notify_expense_insert() CASCADE;
DROP FUNCTION IF EXISTS public.notify_tournament_insert() CASCADE;
DROP FUNCTION IF EXISTS public.notify_match_played() CASCADE;
DROP FUNCTION IF EXISTS public.notify_member_join() CASCADE;
DROP FUNCTION IF EXISTS public.delete_my_account(text) CASCADE;

DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.user_devices CASCADE;
DROP TABLE IF EXISTS public.matches CASCADE;
DROP TABLE IF EXISTS public.tournament_teams CASCADE;
DROP TABLE IF EXISTS public.tournaments CASCADE;
DROP TABLE IF EXISTS public.settlement_payments CASCADE;
DROP TABLE IF EXISTS public.expense_participants CASCADE;
DROP TABLE IF EXISTS public.expenses CASCADE;
DROP TABLE IF EXISTS public.event_attendance CASCADE;
DROP TABLE IF EXISTS public.events CASCADE;
DROP TABLE IF EXISTS public.group_members CASCADE;
DROP TABLE IF EXISTS public.groups CASCADE;
DROP TABLE IF EXISTS public.user_settings CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

CREATE OR REPLACE FUNCTION public.random_invite_code()
RETURNS text
LANGUAGE sql
AS $$
  SELECT upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
$$;

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  full_name text NOT NULL DEFAULT 'Usuario',
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.user_settings (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  notify_events boolean NOT NULL DEFAULT true,
  notify_expenses boolean NOT NULL DEFAULT true,
  notify_tournaments boolean NOT NULL DEFAULT true,
  notify_members boolean NOT NULL DEFAULT true,
  push_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(trim(name)) BETWEEN 2 AND 80),
  type text NOT NULL DEFAULT 'otro' CHECK (type IN ('deporte','cartas','otro')),
  privacy text NOT NULL DEFAULT 'privado' CHECK (privacy = 'privado'),
  invite_code text NOT NULL UNIQUE DEFAULT public.random_invite_code(),
  cover_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.group_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('owner','admin','member')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(group_id, user_id)
);

CREATE TABLE public.events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  title text NOT NULL CHECK (char_length(trim(title)) >= 2),
  starts_at timestamptz NOT NULL,
  location text,
  notes text,
  min_people int NOT NULL DEFAULT 2 CHECK (min_people > 0),
  event_series_id uuid,
  recurrence_frequency text CHECK (recurrence_frequency IS NULL OR recurrence_frequency IN ('weekly','biweekly','monthly')),
  recurrence_index int,
  recurrence_count int,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','cancelled')),
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.event_attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('yes','maybe','no','pending')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(event_id, user_id)
);

CREATE TABLE public.expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  concept text NOT NULL CHECK (char_length(trim(concept)) >= 2),
  amount numeric(12,2) NOT NULL CHECK (amount > 0),
  paid_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  note text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','paid','cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.expense_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id uuid NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  share_amount numeric(12,2) NOT NULL CHECK (share_amount >= 0),
  paid boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(expense_id, user_id)
);

CREATE TABLE public.settlement_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  from_user uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  to_user uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount numeric(12,2) NOT NULL CHECK (amount > 0),
  status text NOT NULL DEFAULT 'paid' CHECK (status IN ('paid','cancelled')),
  note text,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  paid_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (from_user <> to_user)
);

CREATE TABLE public.tournaments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(trim(name)) >= 2),
  format text NOT NULL DEFAULT 'liga' CHECK (format IN ('liga','eliminatoria','americano')),
  team_type text NOT NULL DEFAULT 'equipo' CHECK (team_type IN ('individual','pareja','equipo')),
  scoring_type text NOT NULL DEFAULT 'general' CHECK (scoring_type IN ('general','football','tennis_padel','basketball','cards_mus','custom')),
  scoring_config jsonb NOT NULL DEFAULT '{"win":3,"draw":1,"loss":0,"unit":"puntos","allowDraw":true}'::jsonb,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','finished')),
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.tournament_teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id uuid NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(trim(name)) >= 2),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.matches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id uuid NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  team_a uuid REFERENCES public.tournament_teams(id) ON DELETE SET NULL,
  team_b uuid REFERENCES public.tournament_teams(id) ON DELETE SET NULL,
  score_a int,
  score_b int,
  result_details jsonb,
  round int NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','played')),
  played_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_group_members_group ON public.group_members(group_id);
CREATE INDEX idx_group_members_user ON public.group_members(user_id);
CREATE INDEX idx_events_group_start ON public.events(group_id, starts_at);
CREATE INDEX idx_events_series ON public.events(event_series_id, starts_at);
CREATE INDEX idx_expenses_group_created ON public.expenses(group_id, created_at DESC);
CREATE INDEX idx_settlement_payments_group_paid ON public.settlement_payments(group_id, paid_at DESC);
CREATE INDEX idx_tournaments_group_created ON public.tournaments(group_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.ensure_current_profile()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  clean_email text;
  clean_name text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  clean_email := NULLIF(auth.jwt()->>'email', '');
  clean_name := COALESCE(
    NULLIF(auth.jwt()->'user_metadata'->>'full_name', ''),
    NULLIF(auth.jwt()->'user_metadata'->>'name', ''),
    NULLIF(split_part(COALESCE(clean_email, 'Usuario'), '@', 1), ''),
    'Usuario'
  );

  INSERT INTO public.profiles (id, email, full_name)
  VALUES (auth.uid(), clean_email, clean_name)
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(EXCLUDED.email, profiles.email),
    full_name = COALESCE(NULLIF(profiles.full_name, ''), EXCLUDED.full_name, 'Usuario'),
    updated_at = now();

  INSERT INTO public.user_settings (user_id)
  VALUES (auth.uid())
  ON CONFLICT (user_id) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1), 'Usuario')
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.is_group_member(target_group_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = target_group_id AND gm.user_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_group_admin(target_group_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = target_group_id AND gm.user_id = auth.uid() AND gm.role IN ('owner','admin')
  );
$$;

CREATE OR REPLACE FUNCTION public.is_group_owner(target_group_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = target_group_id AND gm.user_id = auth.uid() AND gm.role = 'owner'
  );
$$;

CREATE OR REPLACE FUNCTION public.create_group_atomic(p_name text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_group_id uuid;
  clean_name text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  PERFORM public.ensure_current_profile();
  clean_name := trim(coalesce(p_name, ''));

  IF char_length(clean_name) < 2 THEN
    RAISE EXCEPTION 'El nombre del grupo es demasiado corto';
  END IF;

  INSERT INTO public.groups (owner_id, name, type, privacy)
  VALUES (auth.uid(), clean_name, 'otro', 'privado')
  RETURNING id INTO new_group_id;

  INSERT INTO public.group_members (group_id, user_id, role)
  VALUES (new_group_id, auth.uid(), 'owner')
  ON CONFLICT (group_id, user_id) DO NOTHING;

  RETURN new_group_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.join_group_with_code(code text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  gid uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  PERFORM public.ensure_current_profile();

  SELECT id INTO gid FROM public.groups WHERE invite_code = upper(trim(code));
  IF gid IS NULL THEN
    RAISE EXCEPTION 'Código de invitación no válido';
  END IF;

  INSERT INTO public.group_members(group_id, user_id, role)
  VALUES (gid, auth.uid(), 'member')
  ON CONFLICT (group_id, user_id) DO NOTHING;

  RETURN gid;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_my_groups()
RETURNS TABLE (
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
  created_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    g.id,
    g.name,
    g.type,
    g.privacy,
    g.invite_code,
    g.cover_url,
    gm.role,
    (SELECT count(*)::int FROM public.group_members x WHERE x.group_id = g.id) AS members_count,
    (SELECT count(*)::int FROM public.events e WHERE e.group_id = g.id AND e.status = 'active' AND e.starts_at >= now() - interval '2 hours') AS events_count,
    0::numeric AS balance,
    g.created_at
  FROM public.groups g
  JOIN public.group_members gm ON gm.group_id = g.id
  WHERE gm.user_id = auth.uid()
  ORDER BY g.created_at DESC;
$$;

CREATE OR REPLACE FUNCTION public.protect_owner_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.role = 'owner' AND OLD.role <> 'owner' THEN
    RAISE EXCEPTION 'Solo puede existir el owner original del grupo';
  END IF;

  IF OLD.role = 'owner' AND (TG_OP = 'DELETE' OR NEW.role <> 'owner') THEN
    RAISE EXCEPTION 'No se puede expulsar ni degradar al creador del grupo';
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER protect_owner_role_trigger
BEFORE UPDATE OR DELETE ON public.group_members
FOR EACH ROW EXECUTE FUNCTION public.protect_owner_role();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlement_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_select_related ON public.profiles FOR SELECT TO authenticated USING (
  id = auth.uid() OR EXISTS (
    SELECT 1 FROM public.group_members a JOIN public.group_members b ON b.group_id = a.group_id
    WHERE a.user_id = auth.uid() AND b.user_id = profiles.id
  )
);
CREATE POLICY profiles_insert_self ON public.profiles FOR INSERT TO authenticated WITH CHECK (id = auth.uid());
CREATE POLICY profiles_update_self ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY settings_self ON public.user_settings FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY groups_select_member ON public.groups FOR SELECT TO authenticated USING (public.is_group_member(id));
CREATE POLICY groups_insert_owner ON public.groups FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid() AND privacy = 'privado');
CREATE POLICY groups_update_admin ON public.groups FOR UPDATE TO authenticated USING (public.is_group_admin(id)) WITH CHECK (public.is_group_admin(id) AND privacy = 'privado');
CREATE POLICY groups_delete_owner ON public.groups FOR DELETE TO authenticated USING (owner_id = auth.uid());

CREATE POLICY group_members_select_member ON public.group_members FOR SELECT TO authenticated USING (public.is_group_member(group_id));
CREATE POLICY group_members_insert_admin ON public.group_members FOR INSERT TO authenticated WITH CHECK (
  public.is_group_admin(group_id) OR (user_id = auth.uid() AND role = 'owner' AND EXISTS (SELECT 1 FROM public.groups g WHERE g.id = group_id AND g.owner_id = auth.uid()))
);
CREATE POLICY group_members_update_admin ON public.group_members FOR UPDATE TO authenticated USING (public.is_group_admin(group_id)) WITH CHECK (public.is_group_admin(group_id));
CREATE POLICY group_members_delete_admin_or_self ON public.group_members FOR DELETE TO authenticated USING (public.is_group_admin(group_id) OR user_id = auth.uid());

CREATE POLICY events_select_member ON public.events FOR SELECT TO authenticated USING (public.is_group_member(group_id));
CREATE POLICY events_insert_member ON public.events FOR INSERT TO authenticated WITH CHECK (public.is_group_member(group_id));
CREATE POLICY events_update_admin_or_creator ON public.events FOR UPDATE TO authenticated USING (public.is_group_admin(group_id) OR created_by = auth.uid()) WITH CHECK (public.is_group_member(group_id));
CREATE POLICY events_delete_admin_or_creator ON public.events FOR DELETE TO authenticated USING (public.is_group_admin(group_id) OR created_by = auth.uid());

CREATE POLICY attendance_select_member ON public.event_attendance FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.events e WHERE e.id = event_id AND public.is_group_member(e.group_id)));
CREATE POLICY attendance_insert_self ON public.event_attendance FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid() AND EXISTS (SELECT 1 FROM public.events e WHERE e.id = event_id AND public.is_group_member(e.group_id)));
CREATE POLICY attendance_update_self ON public.event_attendance FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY attendance_delete_self ON public.event_attendance FOR DELETE TO authenticated USING (user_id = auth.uid());

CREATE POLICY expenses_select_member ON public.expenses FOR SELECT TO authenticated USING (public.is_group_member(group_id));
CREATE POLICY expenses_insert_member ON public.expenses FOR INSERT TO authenticated WITH CHECK (public.is_group_member(group_id));
CREATE POLICY expenses_update_admin_or_creator ON public.expenses FOR UPDATE TO authenticated USING (public.is_group_admin(group_id) OR created_by = auth.uid()) WITH CHECK (public.is_group_member(group_id));
CREATE POLICY expenses_delete_admin_or_creator ON public.expenses FOR DELETE TO authenticated USING (public.is_group_admin(group_id) OR created_by = auth.uid());

CREATE POLICY expense_participants_select_member ON public.expense_participants FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = expense_id AND public.is_group_member(e.group_id)));
CREATE POLICY expense_participants_insert_member ON public.expense_participants FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = expense_id AND public.is_group_member(e.group_id)));
CREATE POLICY expense_participants_update_member ON public.expense_participants FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = expense_id AND public.is_group_member(e.group_id))) WITH CHECK (EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = expense_id AND public.is_group_member(e.group_id)));
CREATE POLICY expense_participants_delete_member ON public.expense_participants FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = expense_id AND public.is_group_member(e.group_id)));

CREATE POLICY settlement_payments_select_member ON public.settlement_payments FOR SELECT TO authenticated USING (public.is_group_member(group_id));
CREATE POLICY settlement_payments_insert_member ON public.settlement_payments FOR INSERT TO authenticated WITH CHECK (public.is_group_member(group_id) AND created_by = auth.uid());
CREATE POLICY settlement_payments_update_admin_or_creator ON public.settlement_payments FOR UPDATE TO authenticated USING (public.is_group_admin(group_id) OR created_by = auth.uid()) WITH CHECK (public.is_group_member(group_id));
CREATE POLICY settlement_payments_delete_admin_or_creator ON public.settlement_payments FOR DELETE TO authenticated USING (public.is_group_admin(group_id) OR created_by = auth.uid());

CREATE POLICY tournaments_member_all ON public.tournaments FOR ALL TO authenticated USING (public.is_group_member(group_id)) WITH CHECK (public.is_group_member(group_id));
CREATE POLICY tournament_teams_member_all ON public.tournament_teams FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.tournaments t WHERE t.id = tournament_id AND public.is_group_member(t.group_id))) WITH CHECK (EXISTS (SELECT 1 FROM public.tournaments t WHERE t.id = tournament_id AND public.is_group_member(t.group_id)));
CREATE POLICY matches_member_all ON public.matches FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.tournaments t WHERE t.id = tournament_id AND public.is_group_member(t.group_id))) WITH CHECK (EXISTS (SELECT 1 FROM public.tournaments t WHERE t.id = tournament_id AND public.is_group_member(t.group_id)));

REVOKE ALL ON FUNCTION public.ensure_current_profile() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_group_atomic(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.join_group_with_code(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_groups() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ensure_current_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_group_atomic(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_group_with_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_groups() TO authenticated;


-- Grupli v12.9 profile avatars storage
-- Ejecutar una vez si quieres permitir subida de foto de perfil.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update set
  public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists avatars_public_read on storage.objects;
drop policy if exists avatars_insert_own on storage.objects;
drop policy if exists avatars_update_own on storage.objects;
drop policy if exists avatars_delete_own on storage.objects;

create policy avatars_public_read
on storage.objects for select
using (bucket_id = 'avatars');

create policy avatars_insert_own
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy avatars_update_own
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy avatars_delete_own
on storage.objects for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);


-- Grupli v15.7 group cover images storage
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('group-covers', 'group-covers', true, 5242880, array['image/jpeg','image/png','image/webp']::text[])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists group_covers_public_read on storage.objects;
drop policy if exists group_covers_insert_admin on storage.objects;
drop policy if exists group_covers_update_admin on storage.objects;
drop policy if exists group_covers_delete_admin on storage.objects;

create policy group_covers_public_read
on storage.objects for select
to public
using (bucket_id = 'group-covers');

create policy group_covers_insert_admin
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'group-covers'
  and public.is_group_admin(((storage.foldername(name))[1])::uuid)
);

create policy group_covers_update_admin
on storage.objects for update
to authenticated
using (
  bucket_id = 'group-covers'
  and public.is_group_admin(((storage.foldername(name))[1])::uuid)
)
with check (
  bucket_id = 'group-covers'
  and public.is_group_admin(((storage.foldername(name))[1])::uuid)
);

create policy group_covers_delete_admin
on storage.objects for delete
to authenticated
using (
  bucket_id = 'group-covers'
  and public.is_group_admin(((storage.foldername(name))[1])::uuid)
);

commit;
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


-- Grupli v15.5 — notificaciones internas + base push FCM
-- No resetea datos. Ejecutar en Supabase SQL Editor.

-- v15.5 notification schema patch included in all_in_one

alter table public.user_settings
  add column if not exists push_enabled boolean not null default true,
  add column if not exists notify_members boolean not null default true;

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null default 'unknown',
  device_label text,
  enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  group_id uuid references public.groups(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  type text not null default 'general' check (type in ('event','finance','tournament','member','general')),
  title text not null,
  body text not null,
  route_type text,
  route_id uuid,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user_created on public.notifications(user_id, created_at desc);
create index if not exists idx_notifications_user_unread on public.notifications(user_id, read_at) where read_at is null;
create index if not exists idx_user_devices_user on public.user_devices(user_id);

alter table public.notifications enable row level security;
alter table public.user_devices enable row level security;

-- Policies: notifications
DROP POLICY IF EXISTS "notifications select own" ON public.notifications;
CREATE POLICY "notifications select own" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications update own" ON public.notifications;
CREATE POLICY "notifications update own" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications delete own" ON public.notifications;
CREATE POLICY "notifications delete own" ON public.notifications
  FOR DELETE USING (user_id = auth.uid());

-- Policies: devices
DROP POLICY IF EXISTS "devices select own" ON public.user_devices;
CREATE POLICY "devices select own" ON public.user_devices
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "devices insert own" ON public.user_devices;
CREATE POLICY "devices insert own" ON public.user_devices
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "devices update own" ON public.user_devices;
CREATE POLICY "devices update own" ON public.user_devices
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "devices delete own" ON public.user_devices;
CREATE POLICY "devices delete own" ON public.user_devices
  FOR DELETE USING (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.create_group_notifications(
  p_group_id uuid,
  p_actor_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_route_type text,
  p_route_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  group_name text;
BEGIN
  SELECT name INTO group_name FROM public.groups WHERE id = p_group_id;
  IF group_name IS NULL THEN
    RETURN;
  END IF;

  INSERT INTO public.notifications (user_id, group_id, actor_id, type, title, body, route_type, route_id)
  SELECT
    gm.user_id,
    p_group_id,
    p_actor_id,
    CASE WHEN p_type IN ('event','finance','tournament','member','general') THEN p_type ELSE 'general' END,
    p_title,
    group_name || ' · ' || p_body,
    p_route_type,
    p_route_id
  FROM public.group_members gm
  LEFT JOIN public.user_settings us ON us.user_id = gm.user_id
  WHERE gm.group_id = p_group_id
    AND (p_actor_id IS NULL OR gm.user_id <> p_actor_id)
    AND CASE
      WHEN p_type = 'event' THEN coalesce(us.notify_events, true)
      WHEN p_type = 'finance' THEN coalesce(us.notify_expenses, true)
      WHEN p_type = 'tournament' THEN coalesce(us.notify_tournaments, true)
      WHEN p_type = 'member' THEN coalesce(us.notify_members, true)
      ELSE true
    END;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_event_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.create_group_notifications(
    NEW.group_id,
    NEW.created_by,
    'event',
    'Nueva quedada',
    NEW.title,
    'event',
    NEW.id
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_event_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'cancelled' AND OLD.status <> 'cancelled' THEN
    PERFORM public.create_group_notifications(NEW.group_id, NEW.created_by, 'event', 'Quedada cancelada', NEW.title, 'event', NEW.id);
  ELSIF NEW.title IS DISTINCT FROM OLD.title OR NEW.starts_at IS DISTINCT FROM OLD.starts_at OR NEW.location IS DISTINCT FROM OLD.location THEN
    PERFORM public.create_group_notifications(NEW.group_id, NEW.created_by, 'event', 'Quedada actualizada', NEW.title, 'event', NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_expense_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.create_group_notifications(
    NEW.group_id,
    NEW.created_by,
    'finance',
    'Nuevo gasto',
    NEW.concept || ' · ' || to_char(NEW.amount, 'FM999999990D00') || ' €',
    'finance',
    NEW.id
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_tournament_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.create_group_notifications(NEW.group_id, NEW.created_by, 'tournament', 'Nuevo torneo', NEW.name, 'tournament', NEW.id);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_match_played()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  g_id uuid;
  t_name text;
BEGIN
  IF NEW.status = 'played' AND OLD.status IS DISTINCT FROM 'played' THEN
    SELECT t.group_id, t.name INTO g_id, t_name FROM public.tournaments t WHERE t.id = NEW.tournament_id;
    IF g_id IS NOT NULL THEN
      PERFORM public.create_group_notifications(g_id, NULL, 'tournament', 'Resultado registrado', coalesce(t_name, 'Torneo'), 'tournament', NEW.tournament_id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_member_join()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  person_name text;
BEGIN
  SELECT coalesce(full_name, email, 'Nuevo miembro') INTO person_name FROM public.profiles WHERE id = NEW.user_id;
  PERFORM public.create_group_notifications(NEW.group_id, NEW.user_id, 'member', 'Nuevo miembro', person_name || ' se ha unido al grupo', 'members', NEW.group_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_event_insert ON public.events;
CREATE TRIGGER trg_notify_event_insert
AFTER INSERT ON public.events
FOR EACH ROW EXECUTE FUNCTION public.notify_event_insert();

DROP TRIGGER IF EXISTS trg_notify_event_update ON public.events;
CREATE TRIGGER trg_notify_event_update
AFTER UPDATE ON public.events
FOR EACH ROW EXECUTE FUNCTION public.notify_event_update();

DROP TRIGGER IF EXISTS trg_notify_expense_insert ON public.expenses;
CREATE TRIGGER trg_notify_expense_insert
AFTER INSERT ON public.expenses
FOR EACH ROW EXECUTE FUNCTION public.notify_expense_insert();

DROP TRIGGER IF EXISTS trg_notify_tournament_insert ON public.tournaments;
CREATE TRIGGER trg_notify_tournament_insert
AFTER INSERT ON public.tournaments
FOR EACH ROW EXECUTE FUNCTION public.notify_tournament_insert();

DROP TRIGGER IF EXISTS trg_notify_match_played ON public.matches;
CREATE TRIGGER trg_notify_match_played
AFTER UPDATE ON public.matches
FOR EACH ROW EXECUTE FUNCTION public.notify_match_played();

DROP TRIGGER IF EXISTS trg_notify_member_join ON public.group_members;
CREATE TRIGGER trg_notify_member_join
AFTER INSERT ON public.group_members
FOR EACH ROW EXECUTE FUNCTION public.notify_member_join();

-- end v15.5 notification schema patch



-- Grupli v15.6 — Revisión SQL/RLS + errores humanos + borrar cuenta
-- NO resetea datos. Ejecutar en Supabase SQL Editor.

begin;

-- Permite que una operación controlada pueda borrar grupos owned sin que
-- el trigger de protección del owner bloquee los cascades internos.
create or replace function public.protect_owner_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_setting('grupli.allow_owner_delete', true) = 'on' then
    return coalesce(new, old);
  end if;

  if tg_op = 'UPDATE' and new.role = 'owner' and old.role <> 'owner' then
    raise exception 'owner_protected';
  end if;

  if old.role = 'owner' and (tg_op = 'DELETE' or new.role <> 'owner') then
    raise exception 'owner_protected';
  end if;

  return coalesce(new, old);
end;
$$;

-- RPC segura para eliminar la cuenta desde la app.
-- Requiere confirmación explícita: ELIMINAR.
create or replace function public.delete_my_account(confirm_text text)
returns void
language plpgsql
security definer
set search_path = public, auth, storage
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  if upper(trim(coalesce(confirm_text, ''))) <> 'ELIMINAR' then
    raise exception 'confirmation_required';
  end if;

  perform set_config('grupli.allow_owner_delete', 'on', true);

  -- Datos personales / dispositivos / avisos.
  delete from public.notifications where user_id = v_uid or actor_id = v_uid;
  delete from public.user_devices where user_id = v_uid;
  delete from public.user_settings where user_id = v_uid;

  -- Participaciones personales.
  delete from public.event_attendance where user_id = v_uid;

  -- Los gastos pagados o creados por el usuario se eliminan para no dejar
  -- datos personales ni bloquear la eliminación por FK paid_by.
  delete from public.expenses where paid_by = v_uid or created_by = v_uid;

  -- Grupos owned: se borran completamente con eventos, gastos, torneos y miembros.
  delete from public.groups where owner_id = v_uid;

  -- Salida del resto de grupos donde era miembro/admin.
  delete from public.group_members where user_id = v_uid;

  -- Avatar en Storage. Se borra por ruta propia del usuario.
  delete from storage.objects
   where bucket_id = 'avatars'
     and name like (v_uid::text || '/%');

  -- Borrado de Auth. Esto cascada el perfil por FK profiles.id -> auth.users.id.
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_my_account(text) from public;
grant execute on function public.delete_my_account(text) to authenticated;

commit;

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


-- Grupli v15.21 admin visibility fix

-- Permitir que el owner de la app vea perfiles y grupos desde el panel admin.
drop policy if exists profiles_select_app_admin on public.profiles;
drop policy if exists groups_select_app_admin on public.groups;

create policy profiles_select_app_admin
on public.profiles for select to authenticated
using (public.is_app_admin());

create policy groups_select_app_admin
on public.groups for select to authenticated
using (public.is_app_admin());

