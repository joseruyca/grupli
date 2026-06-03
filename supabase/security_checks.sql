-- Grupli security checks: diagnostics only. It does not modify data.

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
union all select 'create_group_atomic exists', to_regprocedure('public.create_group_atomic(text)') is not null
union all select 'join_group_with_code exists', to_regprocedure('public.join_group_with_code(text)') is not null
union all select 'get_my_groups exists', to_regprocedure('public.get_my_groups()') is not null;

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
