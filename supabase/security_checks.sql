-- Grupli security_checks.sql
-- Consultas rápidas para revisar que RLS y políticas existen.

SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'profiles','groups','group_members','events','event_attendance',
    'expenses','expense_participants','settlements','tournaments',
    'tournament_teams','tournament_team_members','matches'
  )
ORDER BY tablename;

SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

SELECT id, name, public
FROM storage.buckets
WHERE id IN ('avatars', 'group-assets');

-- Debe devolver true solo para grupos donde el usuario autenticado sea miembro.
-- SELECT public.is_group_member('UUID_DEL_GRUPO');
-- SELECT public.is_group_admin('UUID_DEL_GRUPO');
-- SELECT public.is_group_owner('UUID_DEL_GRUPO');
