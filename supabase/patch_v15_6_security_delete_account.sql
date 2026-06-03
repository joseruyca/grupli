-- Grupli v15.6 — Revisión SQL/RLS + errores humanos + borrar cuenta
-- NO resetea datos. Ejecutar en Supabase SQL Editor.

begin;

-- Permite que una operación controlada pueda borrar grupos owned sin que
-- el trigger de protección del owner bloquee los cascades internos.
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

  if old.role = 'owner' and (tg_op = 'DELETE' or new.role <> 'owner') then
    raise exception 'owner_protected';
  end if;

  return coalesce(new, old);
end;
$$;

-- RPC segura para eliminar la cuenta desde la app.
-- Requiere confirmación explícita: ELIMINAR.
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

  -- Datos personales / dispositivos / avisos.
  delete from public.notifications where user_id = v_uid or actor_id = v_uid;
  delete from public.user_devices where user_id = v_uid;
  delete from public.user_settings where user_id = v_uid;

  -- Participaciones personales.
  delete from public.event_attendance where user_id = v_uid;

  -- Los gastos pagados o creados por el usuario se eliminan para no dejar
  -- datos personales ni bloquear la eliminación por FK paid_by.
  delete from public.expenses where paid_by = v_uid or created_by = v_uid;

  -- Grupos owned: se borran completamente con eventos, gastos, torneos y miembros.
  delete from public.groups where owner_id = v_uid;

  -- Salida del resto de grupos donde era miembro/admin.
  delete from public.group_members where user_id = v_uid;

  -- Avatar en Storage. Se borra por ruta propia del usuario.
  delete from storage.objects
   where bucket_id = 'avatars'
     and name like (v_uid::text || '/%');

  -- Borrado de Auth. Esto cascada el perfil por FK profiles.id -> auth.users.id.
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_my_account(text) from public;
grant execute on function public.delete_my_account(text) to authenticated;

commit;
