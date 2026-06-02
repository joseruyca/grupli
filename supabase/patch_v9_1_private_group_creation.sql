-- Grupli v9.1 - grupos privados simples + fix perfil ausente
-- Ejecutar en Supabase SQL Editor si vienes de una versión anterior.
-- Soluciona:
-- 1) foreign key groups_owner_id_fkey cuando el usuario autenticado no existe en profiles
-- 2) creación de grupos siempre privados/cerrados
-- 3) acceso por código creando antes el perfil del usuario invitado

BEGIN;

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
    email = COALESCE(profiles.email, EXCLUDED.email),
    full_name = COALESCE(NULLIF(profiles.full_name, ''), EXCLUDED.full_name),
    updated_at = now();

  INSERT INTO public.user_settings (user_id)
  VALUES (auth.uid())
  ON CONFLICT (user_id) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_current_profile() TO authenticated;

-- Pasar cualquier grupo antiguo a la nueva regla: cerrado, sin planificación global.
UPDATE public.groups
SET
  privacy = 'privado',
  default_days = NULL,
  default_time = NULL,
  default_location = NULL,
  min_people = 1,
  updated_at = now()
WHERE privacy <> 'privado'
   OR default_days IS NOT NULL
   OR default_time IS NOT NULL
   OR default_location IS NOT NULL
   OR min_people <> 1;

ALTER TABLE public.groups ALTER COLUMN min_people SET DEFAULT 1;

ALTER TABLE public.groups DROP CONSTRAINT IF EXISTS groups_privacy_check;
ALTER TABLE public.groups DROP CONSTRAINT IF EXISTS groups_privacy_private_only;
ALTER TABLE public.groups
  ADD CONSTRAINT groups_privacy_private_only CHECK (privacy = 'privado');

CREATE OR REPLACE FUNCTION public.create_group_atomic(
  p_name text,
  p_type text DEFAULT 'otro',
  p_privacy text DEFAULT 'privado',
  p_default_days text DEFAULT NULL,
  p_default_time text DEFAULT NULL,
  p_default_location text DEFAULT NULL,
  p_min_people int DEFAULT 1
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_group_id uuid;
  clean_name text;
  clean_type text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  PERFORM public.ensure_current_profile();

  clean_name := trim(coalesce(p_name, ''));
  IF char_length(clean_name) < 2 THEN
    RAISE EXCEPTION 'El nombre del grupo es demasiado corto';
  END IF;

  clean_type := lower(trim(coalesce(p_type, 'otro')));
  IF clean_type NOT IN ('deporte', 'cartas', 'otro') THEN
    clean_type := 'otro';
  END IF;

  INSERT INTO public.groups (
    owner_id,
    name,
    type,
    privacy,
    default_days,
    default_time,
    default_location,
    min_people
  ) VALUES (
    auth.uid(),
    clean_name,
    clean_type,
    'privado',
    NULL,
    NULL,
    NULL,
    1
  )
  RETURNING id INTO new_group_id;

  INSERT INTO public.group_members (group_id, user_id, role)
  VALUES (new_group_id, auth.uid(), 'owner')
  ON CONFLICT (group_id, user_id) DO NOTHING;

  RETURN new_group_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_group_atomic(text,text,text,text,text,text,int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_group_atomic(text,text,text,text,text,text,int) TO authenticated;

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

  SELECT id INTO gid
  FROM public.groups
  WHERE invite_code = upper(trim(code))
    AND privacy = 'privado';

  IF gid IS NULL THEN
    RAISE EXCEPTION 'Código de invitación no válido.';
  END IF;

  INSERT INTO public.group_members(group_id, user_id, role)
  VALUES (gid, auth.uid(), 'member')
  ON CONFLICT (group_id, user_id) DO NOTHING;

  RETURN gid;
END;
$$;

REVOKE ALL ON FUNCTION public.join_group_with_code(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_group_with_code(text) TO authenticated;

COMMIT;
