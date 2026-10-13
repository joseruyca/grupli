begin;
-- A direct member/admin update must never change group ownership.
create or replace function grupli_private.guard_group_owner()
returns trigger language plpgsql security invoker set search_path='' as $$ begin
 if current_user in ('anon','authenticated') and new.owner_id is distinct from old.owner_id then raise exception 'ownership_transfer_required'; end if;
 return new;
end $$;
revoke all on function grupli_private.guard_group_owner() from public,anon,authenticated;
drop trigger if exists guard_group_owner on public.groups;
create trigger guard_group_owner before update of owner_id on public.groups for each row execute function grupli_private.guard_group_owner();
create or replace function grupli_private.transfer_group(p_group_id uuid,p_new_owner uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_old uuid; v_setting text;
begin
 if auth.uid() is null then raise exception 'not_authenticated'; end if;
 select owner_id into v_old from public.groups where id=p_group_id for update;
 if not found or v_old<>auth.uid() then raise exception 'permission_denied'; end if;
 if p_new_owner is null or p_new_owner=v_old then raise exception 'invalid_new_owner'; end if;
 perform 1 from public.group_members where group_id=p_group_id and user_id=p_new_owner for update;
 if not found then raise exception 'new_owner_not_in_group'; end if;
 v_setting:=current_setting('grupli.allow_owner_delete',true);
 perform set_config('grupli.allow_owner_delete','on',true);
 update public.group_members set role='admin' where group_id=p_group_id and user_id=v_old;
 update public.group_members set role='owner' where group_id=p_group_id and user_id=p_new_owner;
 update public.groups set owner_id=p_new_owner,updated_at=now() where id=p_group_id;
 perform set_config('grupli.allow_owner_delete',coalesce(v_setting,''),true);
end $$;
revoke all on function grupli_private.transfer_group(uuid,uuid) from public,anon;
grant execute on function grupli_private.transfer_group(uuid,uuid) to authenticated;
create or replace function public.grupli_transfer_group(p_group_id uuid,p_new_owner uuid)
returns void language sql security invoker set search_path='' as $$ select grupli_private.transfer_group(p_group_id,p_new_owner); $$;
revoke all on function public.grupli_transfer_group(uuid,uuid) from public,anon;
grant execute on function public.grupli_transfer_group(uuid,uuid) to authenticated;
commit;
