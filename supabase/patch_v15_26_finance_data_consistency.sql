-- Grupli v15.26 — Finanzas y datos consistentes
-- No resetea nada. Añade reversión segura de liquidaciones y refuerza el modelo de balance neto.

begin;

create table if not exists public.settlement_payments (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  from_user uuid not null references public.profiles(id) on delete cascade,
  to_user uuid not null references public.profiles(id) on delete cascade,
  amount numeric(12,2) not null check (amount > 0),
  status text not null default 'paid',
  note text,
  created_by uuid references public.profiles(id) on delete set null,
  paid_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (from_user <> to_user)
);

alter table public.settlement_payments add column if not exists status text not null default 'paid';
alter table public.settlement_payments add column if not exists note text;
alter table public.settlement_payments add column if not exists updated_at timestamptz not null default now();

-- Asegura valores conocidos aunque venga de versiones antiguas.
update public.settlement_payments
set status = 'paid'
where status is null or status not in ('paid', 'cancelled');

alter table public.settlement_payments drop constraint if exists settlement_payments_status_check;
alter table public.settlement_payments add constraint settlement_payments_status_check check (status in ('paid', 'cancelled'));

create index if not exists idx_settlement_payments_group_status_paid
on public.settlement_payments(group_id, status, paid_at desc);

create or replace function public.cancel_settlement_payment_atomic(p_payment_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment public.settlement_payments%rowtype;
begin
  select * into v_payment
  from public.settlement_payments
  where id = p_payment_id
  for update;

  if not found then
    raise exception 'settlement_not_found';
  end if;

  if not public.is_group_member(v_payment.group_id) then
    raise exception 'not_group_member';
  end if;

  if not (
    public.is_group_admin(v_payment.group_id)
    or v_payment.created_by = auth.uid()
    or v_payment.from_user = auth.uid()
    or v_payment.to_user = auth.uid()
  ) then
    raise exception 'not_allowed';
  end if;

  update public.settlement_payments
  set status = 'cancelled', updated_at = now()
  where id = p_payment_id;

  return true;
end;
$$;

revoke all on function public.cancel_settlement_payment_atomic(uuid) from public;
grant execute on function public.cancel_settlement_payment_atomic(uuid) to authenticated;

-- Realtime para que las cancelaciones de liquidaciones lleguen al resto de móviles.
do $$
begin
  begin
    alter publication supabase_realtime add table public.settlement_payments;
  exception
    when duplicate_object then null;
    when undefined_object then null;
  end;
end $$;

commit;
