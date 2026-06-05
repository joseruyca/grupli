-- v15.22.5 — SQL idempotente de liquidaciones + realtime del grupo
-- Ejecutar en Supabase SQL Editor. Es seguro repetirlo si ya estaba aplicado.
-- No resetea datos. Solo asegura tablas, función segura y realtime.

BEGIN;

CREATE TABLE IF NOT EXISTS public.settlement_payments (
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

ALTER TABLE public.settlement_payments ADD COLUMN IF NOT EXISTS note text;
ALTER TABLE public.settlement_payments ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'paid';
ALTER TABLE public.settlement_payments ADD COLUMN IF NOT EXISTS paid_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE public.settlement_payments ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_settlement_payments_group_paid
ON public.settlement_payments(group_id, paid_at DESC);

ALTER TABLE public.settlement_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS settlement_payments_select_member ON public.settlement_payments;
DROP POLICY IF EXISTS settlement_payments_insert_member ON public.settlement_payments;
DROP POLICY IF EXISTS settlement_payments_update_admin_or_creator ON public.settlement_payments;
DROP POLICY IF EXISTS settlement_payments_delete_admin_or_creator ON public.settlement_payments;

CREATE POLICY settlement_payments_select_member
ON public.settlement_payments
FOR SELECT TO authenticated
USING (public.is_group_member(group_id));

CREATE POLICY settlement_payments_insert_member
ON public.settlement_payments
FOR INSERT TO authenticated
WITH CHECK (
  public.is_group_member(group_id)
  AND created_by = auth.uid()
  AND EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = settlement_payments.group_id AND gm.user_id = settlement_payments.from_user)
  AND EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = settlement_payments.group_id AND gm.user_id = settlement_payments.to_user)
);

CREATE POLICY settlement_payments_update_admin_or_creator
ON public.settlement_payments
FOR UPDATE TO authenticated
USING (public.is_group_admin(group_id) OR created_by = auth.uid())
WITH CHECK (public.is_group_member(group_id));

CREATE POLICY settlement_payments_delete_admin_or_creator
ON public.settlement_payments
FOR DELETE TO authenticated
USING (public.is_group_admin(group_id) OR created_by = auth.uid());

CREATE OR REPLACE FUNCTION public.create_settlement_payment_atomic(
  p_group_id uuid,
  p_from_user uuid,
  p_to_user uuid,
  p_amount numeric
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
  v_uid uuid := auth.uid();
  v_amount numeric(12,2) := round(p_amount::numeric, 2);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  IF v_amount <= 0 THEN
    RAISE EXCEPTION 'invalid_amount';
  END IF;

  IF p_from_user = p_to_user THEN
    RAISE EXCEPTION 'same_user';
  END IF;

  IF NOT public.is_group_member(p_group_id) THEN
    RAISE EXCEPTION 'not_group_member';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.group_members WHERE group_id = p_group_id AND user_id = p_from_user) THEN
    RAISE EXCEPTION 'from_user_not_in_group';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.group_members WHERE group_id = p_group_id AND user_id = p_to_user) THEN
    RAISE EXCEPTION 'to_user_not_in_group';
  END IF;

  INSERT INTO public.settlement_payments (
    group_id,
    from_user,
    to_user,
    amount,
    status,
    created_by,
    paid_at
  ) VALUES (
    p_group_id,
    p_from_user,
    p_to_user,
    v_amount,
    'paid',
    v_uid,
    now()
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_settlement_payment_atomic(uuid, uuid, uuid, numeric) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_settlement_payment_atomic(uuid, uuid, uuid, numeric) TO authenticated;

-- Realtime: permite que otros móviles vean cambios sin refrescar manualmente.
DO $$
DECLARE
  table_name text;
  tables text[] := ARRAY[
    'groups',
    'group_members',
    'events',
    'event_attendance',
    'expenses',
    'expense_participants',
    'settlement_payments',
    'tournaments',
    'tournament_teams',
    'matches',
    'notifications'
  ];
BEGIN
  FOREACH table_name IN ARRAY tables LOOP
    IF to_regclass('public.' || table_name) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.%I REPLICA IDENTITY FULL', table_name);
      BEGIN
        EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', table_name);
      EXCEPTION WHEN duplicate_object OR undefined_object THEN
        NULL;
      END;
    END IF;
  END LOOP;
END $$;

COMMIT;
