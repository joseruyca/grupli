-- Grupli v14 security checks: diagnostics only. It does not modify data.

select 'profiles RLS enabled' as check_name, rowsecurity as ok from pg_tables where schemaname='public' and tablename='profiles'
union all select 'groups RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='groups'
union all select 'group_members RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='group_members'
union all select 'events RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='events'
union all select 'event_attendance RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='event_attendance'
union all select 'expenses RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='expenses'
union all select 'expense_participants RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='expense_participants'
union all select 'tournaments RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='tournaments'
union all select 'tournament_teams RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='tournament_teams'
union all select 'matches RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='matches'
union all select 'ensure_current_profile exists', to_regprocedure('public.ensure_current_profile()') is not null
union all select 'create_group_atomic only text exists', to_regprocedure('public.create_group_atomic(text)') is not null
union all select 'join_group_with_code exists', to_regprocedure('public.join_group_with_code(text)') is not null
union all select 'get_my_groups exists', to_regprocedure('public.get_my_groups()') is not null
union all select 'is_group_owner exists', to_regprocedure('public.is_group_owner(uuid)') is not null;

select 'duplicated create_group_atomic overloads' as check_name, count(*) = 1 as ok
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'create_group_atomic';

select 'groups are private only' as check_name, not exists(select 1 from public.groups where privacy <> 'privado') as ok;

select 'owners per group exactly one' as check_name, not exists(
  select group_id
  from public.group_members
  where role = 'owner'
  group by group_id
  having count(*) <> 1
) as ok;

select schemaname, tablename, policyname, permissive, roles, cmd
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

select 'avatars bucket exists' as check_name, exists(select 1 from storage.buckets where id = 'avatars') as ok
union all select 'profiles avatar_url column exists', exists(select 1 from information_schema.columns where table_schema='public' and table_name='profiles' and column_name='avatar_url');

select 'avatar storage policies' as section, policyname, cmd
from pg_policies
where schemaname = 'storage' and tablename = 'objects' and policyname like 'avatars_%'
order by policyname;


select 'avatar bucket exists' as check_name, exists (
  select 1 from storage.buckets where id = 'avatars'
) as ok;

select 'public RPC overload count' as check_name, count(*) as value
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('create_group_atomic', 'join_group_with_code');

select 'admin policies summary' as check_name, tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename in ('groups','group_members','events','expenses','tournaments','matches')
order by tablename, policyname;


-- v14.7 role/member RPC check
select
  p.proname as function,
  pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('set_group_member_role','remove_group_member','leave_group_safe')
order by p.proname;


-- v15.5 notification checks
select 'notifications_rls' as check_name, relrowsecurity as rls_enabled from pg_class where relname = 'notifications';
select 'user_devices_rls' as check_name, relrowsecurity as rls_enabled from pg_class where relname = 'user_devices';
select 'notification_triggers' as check_name, tgname from pg_trigger where tgname like 'trg_notify_%' order by tgname;
select 'unread_notifications' as check_name, count(*) from public.notifications where user_id = auth.uid() and read_at is null;
