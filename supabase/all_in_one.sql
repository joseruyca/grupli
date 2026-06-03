-- Grupli v12 clean rebuild
-- Ejecutar en Supabase SQL Editor para resetear la base de datos de Grupli.
-- Borra SOLO las tablas propias de Grupli y las recrea con RLS.

create extension if not exists "pgcrypto";

begin;

-- Drop policies/functions/tables safely
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.random_invite_code() CASCADE;
DROP FUNCTION IF EXISTS public.ensure_current_profile() CASCADE;
DROP FUNCTION IF EXISTS public.is_group_member(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_admin(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.create_group_atomic(text) CASCADE;
DROP FUNCTION IF EXISTS public.join_group_with_code(text) CASCADE;
DROP FUNCTION IF EXISTS public.get_my_groups() CASCADE;
DROP FUNCTION IF EXISTS public.protect_owner_role() CASCADE;

DROP TABLE IF EXISTS public.matches CASCADE;
DROP TABLE IF EXISTS public.tournament_teams CASCADE;
DROP TABLE IF EXISTS public.tournaments CASCADE;
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

CREATE TABLE public.tournaments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(trim(name)) >= 2),
  format text NOT NULL DEFAULT 'liga' CHECK (format IN ('liga','eliminatoria','americano')),
  team_type text NOT NULL DEFAULT 'equipo' CHECK (team_type IN ('individual','pareja','equipo')),
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
  round int NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','played')),
  played_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_group_members_group ON public.group_members(group_id);
CREATE INDEX idx_group_members_user ON public.group_members(user_id);
CREATE INDEX idx_events_group_start ON public.events(group_id, starts_at);
CREATE INDEX idx_expenses_group_created ON public.expenses(group_id, created_at DESC);
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

commit;
