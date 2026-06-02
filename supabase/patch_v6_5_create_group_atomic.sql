
-- Grupli v6.5 - Fix creación de grupos con RLS
-- Ejecutar en Supabase SQL Editor.

CREATE OR REPLACE FUNCTION public.create_group_atomic(
  p_name text,
  p_type text DEFAULT 'otro',
  p_privacy text DEFAULT 'privado',
  p_default_days text DEFAULT NULL,
  p_default_time text DEFAULT NULL,
  p_default_location text DEFAULT NULL,
  p_min_people int DEFAULT 2
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
  clean_privacy text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  clean_name := trim(coalesce(p_name, ''));
  IF char_length(clean_name) < 2 THEN
    RAISE EXCEPTION 'El nombre del grupo es demasiado corto';
  END IF;

  clean_type := lower(trim(coalesce(p_type, 'otro')));
  IF clean_type NOT IN ('deporte', 'cartas', 'otro') THEN
    clean_type := 'otro';
  END IF;

  clean_privacy := lower(trim(coalesce(p_privacy, 'privado')));
  IF clean_privacy NOT IN ('privado', 'público', 'publico') THEN
    clean_privacy := 'privado';
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
    clean_privacy,
    NULLIF(trim(coalesce(p_default_days, '')), ''),
    NULLIF(trim(coalesce(p_default_time, '')), ''),
    NULLIF(trim(coalesce(p_default_location, '')), ''),
    greatest(coalesce(p_min_people, 2), 1)
  )
  RETURNING id INTO new_group_id;

  INSERT INTO public.group_members (group_id, user_id, role)
  VALUES (new_group_id, auth.uid(), 'owner')
  ON CONFLICT (group_id, user_id) DO NOTHING;

  RETURN new_group_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_group_atomic(
  text, text, text, text, text, text, int
) TO authenticated;
