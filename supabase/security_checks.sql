-- Grupli security_checks.sql
-- Ejecutar en Supabase SQL Editor después de all_in_one.sql + patches.
-- Objetivo: detectar tablas sin RLS, políticas ausentes y funciones críticas.

-- 1) Todas estas tablas deben tener rowsecurity = true.
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'profiles','user_settings','groups','group_members','events','event_attendance',
    'expenses','expense_participants','settlements','tournaments',
    'tournament_teams','tournament_team_members','matches'
  )
ORDER BY tablename;

-- 2) Si devuelve filas, hay tablas propias sin RLS.
SELECT tablename AS table_without_rls
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'profiles','user_settings','groups','group_members','events','event_attendance',
    'expenses','expense_participants','settlements','tournaments',
    'tournament_teams','tournament_team_members','matches'
  )
  AND rowsecurity IS DISTINCT FROM true;

-- 3) Deben existir políticas por tabla.
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 4) Funciones críticas: todas deben existir.
SELECT 'create_group_atomic' AS function_name, to_regprocedure('public.create_group_atomic(text,text,text,text,text,text,int)') IS NOT NULL AS ok
UNION ALL SELECT 'join_group_with_code', to_regprocedure('public.join_group_with_code(text)') IS NOT NULL
UNION ALL SELECT 'regenerate_group_invite_code', to_regprocedure('public.regenerate_group_invite_code(uuid)') IS NOT NULL
UNION ALL SELECT 'get_my_groups', to_regprocedure('public.get_my_groups()') IS NOT NULL
UNION ALL SELECT 'get_group_balances', to_regprocedure('public.get_group_balances(uuid)') IS NOT NULL
UNION ALL SELECT 'is_group_member', to_regprocedure('public.is_group_member(uuid)') IS NOT NULL
UNION ALL SELECT 'is_group_admin', to_regprocedure('public.is_group_admin(uuid)') IS NOT NULL
UNION ALL SELECT 'is_group_owner', to_regprocedure('public.is_group_owner(uuid)') IS NOT NULL;

-- 5) Buckets esperados.
SELECT id, name, public
FROM storage.buckets
WHERE id IN ('avatars', 'group-assets');

-- 6) Diagnóstico v9: todas las filas deben tener ok = true.
SELECT * FROM public.v_grupli_security_diagnostics ORDER BY check_name;

-- 7) Comprobación manual con sesión autenticada desde SQL no siempre aplica.
-- Desde la app debe comprobarse:
-- - B no ve grupos ajenos.
-- - B no abre URL directa de grupo ajeno.
-- - B no modifica miembros si no es admin.
-- - Nadie degrada/expulsa al owner.


-- v9.1 private groups checks
SELECT
  'ensure_current_profile exists' AS check_name,
  to_regprocedure('public.ensure_current_profile()') IS NOT NULL AS ok;

SELECT
  'all groups are private' AS check_name,
  NOT EXISTS(SELECT 1 FROM public.groups WHERE privacy <> 'privado') AS ok;

SELECT
  'groups private-only constraint exists' AS check_name,
  EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname = 'groups'
      AND c.conname = 'groups_privacy_private_only'
  ) AS ok;
