
-- Grupli v10 - reset de contrato de producto y fix robusto de perfiles
-- Ejecutar si vienes de versiones anteriores y quieres conservar datos.

BEGIN;

-- Los grupos son siempre cerrados/privados. La planificación vive en events.
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

ALTER TABLE public.groups ALTER COLUMN privacy SET DEFAULT 'privado';
ALTER TABLE public.groups ALTER COLUMN min_people SET DEFAULT 1;
ALTER TABLE public.groups DROP CONSTRAINT IF EXISTS groups_privacy_check;
ALTER TABLE public.groups DROP CONSTRAINT IF EXISTS groups_privacy_private_only;
ALTER TABLE public.groups ADD CONSTRAINT groups_privacy_private_only CHECK (privacy = 'privado');

-- Crea perfiles para usuarios existentes y evita el error owner_id -> profiles.
INSERT INTO public.profiles (id, email, full_name)
SELECT
  u.id,
  u.email,
  COALESCE(
    NULLIF(u.raw_user_meta_data->>'full_name', ''),
    NULLIF(u.raw_user_meta_data->>'name', ''),
    NULLIF(split_part(COALESCE(u.email, 'Usuario'), '@', 1), ''),
    'Usuario'
  ) AS full_name
FROM auth.users u
ON CONFLICT (id) DO UPDATE SET
  email = COALESCE(public.profiles.email, EXCLUDED.email),
  full_name = COALESCE(NULLIF(public.profiles.full_name, ''), EXCLUDED.full_name),
  updated_at = now();

INSERT INTO public.user_settings (user_id)
SELECT p.id FROM public.profiles p
ON CONFLICT (user_id) DO NOTHING;

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
    email = COALESCE(public.profiles.email, EXCLUDED.email),
    full_name = COALESCE(NULLIF(public.profiles.full_name, ''), EXCLUDED.full_name),
    updated_at = now();

  INSERT INTO public.user_settings (user_id)
  VALUES (auth.uid())
  ON CONFLICT (user_id) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_current_profile() TO authenticated;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
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
    COALESCE(
      NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
      NULLIF(NEW.raw_user_meta_data->>'name', ''),
      NULLIF(split_part(COALESCE(NEW.email, 'Usuario'), '@', 1), ''),
      'Usuario'
    )
  )
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(public.profiles.email, EXCLUDED.email),
    full_name = COALESCE(NULLIF(public.profiles.full_name, ''), EXCLUDED.full_name),
    updated_at = now();

  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_grupli ON auth.users;
CREATE TRIGGER on_auth_user_created_grupli
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

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
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  PERFORM public.ensure_current_profile();

  clean_name := trim(coalesce(p_name, ''));
  IF char_length(clean_name) < 2 THEN
    RAISE EXCEPTION 'El nombre del grupo es demasiado corto';
  END IF;

  INSERT INTO public.groups (owner_id, name, type, privacy, default_days, default_time, default_location, min_people)
  VALUES (auth.uid(), clean_name, 'otro', 'privado', NULL, NULL, NULL, 1)
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
