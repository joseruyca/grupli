begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
-- Compatibility RPC: account email must never grant application ownership.
create or replace function public.ensure_owner_admin()
returns void language plpgsql security invoker set search_path=pg_catalog,public as $$
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
end $$;
revoke execute on function public.ensure_owner_admin() from public,anon;
grant execute on function public.ensure_owner_admin() to authenticated,service_role;
do $$ declare f record; sig text; begin
 for f in select p.oid::regprocedure::text as signature,p.prorettype='trigger'::regtype as is_trigger
 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.prosecdef loop
   execute format('revoke execute on function %s from public, anon',f.signature);
   if f.is_trigger then
     execute format('revoke execute on function %s from authenticated',f.signature);
   else
     execute format('grant execute on function %s to authenticated, service_role',f.signature);
   end if;
 end loop;
 -- Notification fanout is internal to owner-executed triggers, never a client RPC.
 for f in select p.oid::regprocedure::text as signature from pg_proc p
 join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.proname='create_group_notifications' loop
   execute format('revoke execute on function %s from authenticated',f.signature);
 end loop;
 foreach sig in array array['public.touch_updated_at()','public.keep_group_owner()',
 'public.uuid_or_null(text)','public.random_invite_code()'] loop
   if to_regprocedure(sig) is not null then
     execute format('alter function %s set search_path = pg_catalog, public',sig);
   end if;
 end loop;
 if to_regclass('public.v_grupli_security_diagnostics') is not null then
   execute 'alter view public.v_grupli_security_diagnostics set (security_invoker=true)';
   execute 'revoke all on public.v_grupli_security_diagnostics from public,anon,authenticated';
 end if;
end $$;
-- Owners are created with the group or transferred by the guarded RPC only.
drop policy if exists group_members_insert_admin on public.group_members;
create policy group_members_insert_admin on public.group_members for insert to authenticated
with check ((public.is_group_admin(group_id) and role in ('admin','member'))
 or (user_id=auth.uid() and role='owner' and exists(select 1 from public.groups g where g.id=group_id and g.owner_id=auth.uid())));
drop policy if exists group_members_update_admin on public.group_members;
create policy group_members_update_admin on public.group_members for update to authenticated
using (public.is_group_admin(group_id) and role<>'owner')
with check (public.is_group_admin(group_id) and role in ('admin','member'));
do $$ begin
 if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.prosecdef and has_function_privilege('anon',p.oid,'execute'))
 then raise exception 'Anonymous function permissions verification failed'; end if;
end $$;
commit;
