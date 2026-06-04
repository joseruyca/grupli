-- v15.16 — Finanzas final tipo Tricount
-- Permite registrar liquidaciones reales entre miembros para que desaparezcan de los saldos.

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
WITH CHECK (public.is_group_member(group_id) AND created_by = auth.uid());

CREATE POLICY settlement_payments_update_admin_or_creator
ON public.settlement_payments
FOR UPDATE TO authenticated
USING (public.is_group_admin(group_id) OR created_by = auth.uid())
WITH CHECK (public.is_group_member(group_id));

CREATE POLICY settlement_payments_delete_admin_or_creator
ON public.settlement_payments
FOR DELETE TO authenticated
USING (public.is_group_admin(group_id) OR created_by = auth.uid());
