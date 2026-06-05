-- Grupli v15.22.4 — Fix borrado de usuarios Auth/Admin
-- NO resetea datos. NO borra usuarios por sí solo.
-- Soluciona el error "Database error deleting user" al borrar usuarios con datos relacionados.

begin;

-- 1) El gasto pagado por un usuario no debe bloquear el borrado de su cuenta.
--    Si se borra una cuenta, los gastos pagados por esa cuenta se eliminan en cascada.
do $$
declare
  v_constraint text;
begin
  select c.conname
  into v_constraint
  from pg_constraint c
  join pg_attribute a
    on a.attrelid = c.conrelid
   and a.attnum = any(c.conkey)
  where c.conrelid = 'public.expenses'::regclass
    and c.contype = 'f'
    and a.attname = 'paid_by'
  limit 1;

  if v_constraint is not null then
    execute format('alter table public.expenses drop constraint %I', v_constraint);
  end if;

  alter table public.expenses
    add constraint expenses_paid_by_fkey
    foreign key (paid_by)
    references public.profiles(id)
    on delete cascade;
end $$;

-- 2) El trigger sigue protegiendo al owner dentro de la app, pero ya no bloquea
--    borrados administrativos desde Auth/SQL ni borrados controlados de cuenta.
create or replace function public.protect_owner_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_setting('grupli.allow_owner_delete', true) = 'on' then
    return coalesce(new, old);
  end if;

  if tg_op = 'UPDATE' and new.role = 'owner' and old.role <> 'owner' then
    raise exception 'owner_protected';
  end if;

  if tg_op = 'UPDATE' and old.role = 'owner' and new.role <> 'owner' then
    raise exception 'owner_protected';
  end if;

  -- Si auth.uid() existe, la petición viene de la app: protegemos el owner.
  -- Si auth.uid() es null, normalmente viene de SQL/Auth admin: permitimos
  -- el cascade para que Supabase pueda borrar usuarios correctamente.
  if tg_op = 'DELETE' and old.role = 'owner' and auth.uid() is not null then
    raise exception 'owner_protected';
  end if;

  return coalesce(new, old);
end;
$$;

-- 3) Endurece la política normal: desde la app nadie puede expulsar al owner.
drop policy if exists group_members_delete_admin_or_self on public.group_members;
create policy group_members_delete_admin_or_self
on public.group_members
for delete
to authenticated
using (
  role <> 'owner'
  and (
    public.is_group_admin(group_id)
    or user_id = auth.uid()
  )
);

-- 4) RPC administrativa para borrar un usuario de forma limpia por email.
--    Úsala si el botón de Supabase Auth sigue fallando o quieres hacerlo controlado.
create or replace function public.admin_delete_user_by_email(target_email text, confirm_text text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, storage
as $$
declare
  v_user_id uuid;
  v_email text;
  v_deleted_expenses int := 0;
  v_deleted_groups int := 0;
  v_deleted_memberships int := 0;
begin
  if upper(trim(coalesce(confirm_text, ''))) <> 'ELIMINAR USUARIO' then
    raise exception 'confirmation_required';
  end if;

  -- Desde la app solo puede usarlo un app admin. Desde SQL Editor auth.uid() suele ser null.
  if auth.uid() is not null and not public.is_app_admin() then
    raise exception 'not_app_admin';
  end if;

  select p.id, p.email
  into v_user_id, v_email
  from public.profiles p
  where lower(coalesce(p.email, '')) = lower(trim(target_email))
  limit 1;

  if v_user_id is null then
    select u.id, u.email
    into v_user_id, v_email
    from auth.users u
    where lower(coalesce(u.email, '')) = lower(trim(target_email))
    limit 1;
  end if;

  if v_user_id is null then
    return jsonb_build_object(
      'deleted', false,
      'reason', 'user_not_found',
      'email', target_email
    );
  end if;

  perform set_config('grupli.allow_owner_delete', 'on', true);

  -- Datos personales y soporte.
  delete from public.notifications where user_id = v_user_id or actor_id = v_user_id;
  delete from public.user_devices where user_id = v_user_id;
  delete from public.user_settings where user_id = v_user_id;
  delete from public.app_admins where user_id = v_user_id;
  delete from public.support_tickets where user_id = v_user_id;
  update public.app_quality_events set user_id = null where user_id = v_user_id;

  -- Eventos/asistencia.
  delete from public.event_attendance where user_id = v_user_id;

  -- Finanzas.
  delete from public.settlement_payments
   where from_user = v_user_id
      or to_user = v_user_id
      or created_by = v_user_id;

  delete from public.expense_participants where user_id = v_user_id;

  delete from public.expenses
   where paid_by = v_user_id
      or created_by = v_user_id;
  get diagnostics v_deleted_expenses = row_count;

  -- Grupos owned: se eliminan completos con todo lo que cuelga de ellos.
  delete from public.groups where owner_id = v_user_id;
  get diagnostics v_deleted_groups = row_count;

  -- Salida de otros grupos.
  delete from public.group_members where user_id = v_user_id;
  get diagnostics v_deleted_memberships = row_count;

  -- Storage de avatar propio.
  delete from storage.objects
   where bucket_id = 'avatars'
     and name like (v_user_id::text || '/%');

  -- Borra el perfil público si aún existe.
  delete from public.profiles where id = v_user_id;

  -- Borra Auth. Esto elimina sesiones/tokens del usuario.
  delete from auth.users where id = v_user_id;

  return jsonb_build_object(
    'deleted', true,
    'user_id', v_user_id,
    'email', coalesce(v_email, target_email),
    'deleted_groups', v_deleted_groups,
    'deleted_expenses', v_deleted_expenses,
    'deleted_memberships', v_deleted_memberships
  );
end;
$$;

revoke all on function public.admin_delete_user_by_email(text, text) from public;
grant execute on function public.admin_delete_user_by_email(text, text) to authenticated;

-- 5) Mejora delete_my_account para cubrir las tablas añadidas después de v15.6.
create or replace function public.delete_my_account(confirm_text text)
returns void
language plpgsql
security definer
set search_path = public, auth, storage
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  if upper(trim(coalesce(confirm_text, ''))) <> 'ELIMINAR' then
    raise exception 'confirmation_required';
  end if;

  perform set_config('grupli.allow_owner_delete', 'on', true);

  delete from public.notifications where user_id = v_uid or actor_id = v_uid;
  delete from public.user_devices where user_id = v_uid;
  delete from public.user_settings where user_id = v_uid;
  delete from public.app_admins where user_id = v_uid;
  delete from public.support_tickets where user_id = v_uid;
  update public.app_quality_events set user_id = null where user_id = v_uid;

  delete from public.event_attendance where user_id = v_uid;
  delete from public.settlement_payments where from_user = v_uid or to_user = v_uid or created_by = v_uid;
  delete from public.expense_participants where user_id = v_uid;
  delete from public.expenses where paid_by = v_uid or created_by = v_uid;
  delete from public.groups where owner_id = v_uid;
  delete from public.group_members where user_id = v_uid;

  delete from storage.objects
   where bucket_id = 'avatars'
     and name like (v_uid::text || '/%');

  delete from public.profiles where id = v_uid;
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_my_account(text) from public;
grant execute on function public.delete_my_account(text) to authenticated;

commit;

-- USO MANUAL SI EL BOTÓN DE AUTH UI FALLA:
-- select public.admin_delete_user_by_email('email-del-usuario@dominio.com', 'ELIMINAR USUARIO');
