-- Grupli v9 - RLS hardening + security diagnostics
-- Ejecutar después del SQL principal y después de patch_v8_profile_settings.sql.
-- Objetivo: cerrar funciones SECURITY DEFINER y evitar lecturas/modificaciones cruzadas.

-- 1) get_group_balances debe comprobar que el usuario autenticado pertenece al grupo.
CREATE OR REPLACE FUNCTION public.get_group_balances(target_group_id uuid)
RETURNS TABLE (
  debtor_id uuid,
  debtor_name text,
  creditor_id uuid,
  creditor_name text,
  amount numeric
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    ep.user_id AS debtor_id,
    COALESCE(dp.full_name, dp.email, 'Usuario') AS debtor_name,
    e.paid_by AS creditor_id,
    COALESCE(cp.full_name, cp.email, 'Usuario') AS creditor_name,
    round(sum(ep.share_amount), 2) AS amount
  FROM public.expense_participants ep
  JOIN public.expenses e ON e.id = ep.expense_id
  LEFT JOIN public.profiles dp ON dp.id = ep.user_id
  LEFT JOIN public.profiles cp ON cp.id = e.paid_by
  WHERE public.is_group_member(target_group_id)
    AND e.group_id = target_group_id
    AND ep.user_id <> e.paid_by
    AND e.status <> 'cancelled'
  GROUP BY ep.user_id, dp.full_name, dp.email, e.paid_by, cp.full_name, cp.email
  HAVING round(sum(ep.share_amount), 2) > 0
  ORDER BY amount DESC;
$$;

REVOKE ALL ON FUNCTION public.get_group_balances(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_group_balances(uuid) TO authenticated;

-- 2) Restringir ejecución pública de funciones SECURITY DEFINER críticas.
REVOKE ALL ON FUNCTION public.create_group_atomic(text,text,text,text,text,text,int) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.join_group_with_code(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.regenerate_group_invite_code(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_groups() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.create_group_atomic(text,text,text,text,text,text,int) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_group_with_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.regenerate_group_invite_code(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_groups() TO authenticated;

-- 3) Endurecer expense_participants: solo admin o creador del gasto puede crear/editar participantes.
DROP POLICY IF EXISTS expense_participants_insert_member ON public.expense_participants;
DROP POLICY IF EXISTS expense_participants_update_member ON public.expense_participants;
DROP POLICY IF EXISTS expense_participants_delete_member ON public.expense_participants;

CREATE POLICY expense_participants_insert_admin_or_expense_creator
ON public.expense_participants
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.expenses e
    WHERE e.id = expense_id
      AND public.is_group_member(e.group_id)
      AND (public.is_group_admin(e.group_id) OR e.created_by = auth.uid())
  )
);

CREATE POLICY expense_participants_update_admin_or_expense_creator
ON public.expense_participants
FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.expenses e
    WHERE e.id = expense_id
      AND public.is_group_member(e.group_id)
      AND (public.is_group_admin(e.group_id) OR e.created_by = auth.uid())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.expenses e
    WHERE e.id = expense_id
      AND public.is_group_member(e.group_id)
      AND (public.is_group_admin(e.group_id) OR e.created_by = auth.uid())
  )
);

CREATE POLICY expense_participants_delete_admin_or_expense_creator
ON public.expense_participants
FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.expenses e
    WHERE e.id = expense_id
      AND public.is_group_member(e.group_id)
      AND (public.is_group_admin(e.group_id) OR e.created_by = auth.uid())
  )
);

-- 4) Diagnóstico rápido: debe devolver solo filas con ok = true.
CREATE OR REPLACE VIEW public.v_grupli_security_diagnostics AS
SELECT 'profiles RLS enabled' AS check_name, rowsecurity AS ok FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles'
UNION ALL SELECT 'groups RLS enabled', rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'groups'
UNION ALL SELECT 'group_members RLS enabled', rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'group_members'
UNION ALL SELECT 'events RLS enabled', rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'events'
UNION ALL SELECT 'event_attendance RLS enabled', rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'event_attendance'
UNION ALL SELECT 'expenses RLS enabled', rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'expenses'
UNION ALL SELECT 'expense_participants RLS enabled', rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'expense_participants'
UNION ALL SELECT 'settlements RLS enabled', rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'settlements'
UNION ALL SELECT 'tournaments RLS enabled', rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'tournaments'
UNION ALL SELECT 'tournament_teams RLS enabled', rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'tournament_teams'
UNION ALL SELECT 'matches RLS enabled', rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'matches'
UNION ALL SELECT 'avatars bucket exists', EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'avatars')
UNION ALL SELECT 'group-assets bucket exists', EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'group-assets')
UNION ALL SELECT 'create_group_atomic exists', to_regprocedure('public.create_group_atomic(text,text,text,text,text,text,int)') IS NOT NULL
UNION ALL SELECT 'get_group_balances exists', to_regprocedure('public.get_group_balances(uuid)') IS NOT NULL;

GRANT SELECT ON public.v_grupli_security_diagnostics TO authenticated;
