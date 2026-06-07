-- Grupli v15.31.1 security checks: diagnóstico, no modifica datos.

select 'profiles RLS enabled' as check_name, rowsecurity as ok from pg_tables where schemaname='public' and tablename='profiles'
union all select 'user_settings RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='user_settings'
union all select 'groups RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='groups'
union all select 'group_members RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='group_members'
union all select 'events RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='events'
union all select 'event_attendance RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='event_attendance'
union all select 'expenses RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='expenses'
union all select 'expense_participants RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='expense_participants'
union all select 'settlement_payments RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='settlement_payments'
union all select 'tournaments RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='tournaments'
union all select 'tournament_teams RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='tournament_teams'
union all select 'matches RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='matches'
union all select 'notifications RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='notifications'
union all select 'user_devices RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='user_devices'
union all select 'app_admins RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='app_admins'
union all select 'support_tickets RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='support_tickets'
union all select 'app_quality_events RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='app_quality_events'
union all select 'app_user_flags RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='app_user_flags'
union all select 'ensure_current_profile exists', to_regprocedure('public.ensure_current_profile()') is not null
union all select 'create_group_atomic exists', to_regprocedure('public.create_group_atomic(text)') is not null
union all select 'join_group_with_code exists', to_regprocedure('public.join_group_with_code(text)') is not null
union all select 'get_my_groups exists', to_regprocedure('public.get_my_groups()') is not null
union all select 'group_events_with_attendance exists', to_regprocedure('public.group_events_with_attendance(uuid)') is not null
union all select 'create_settlement_payment_atomic exists', to_regprocedure('public.create_settlement_payment_atomic(uuid,uuid,uuid,numeric)') is not null
union all select 'cancel_settlement_payment_atomic exists', to_regprocedure('public.cancel_settlement_payment_atomic(uuid)') is not null
union all select 'app_admin_role exists', to_regprocedure('public.app_admin_role()') is not null
union all select 'admin_overview exists', to_regprocedure('public.admin_overview()') is not null
union all select 'delete_my_account exists', to_regprocedure('public.delete_my_account(text)') is not null;

select 'duplicated create_group_atomic overloads' as check_name, count(*) = 1 as ok
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public' and p.proname='create_group_atomic';

select 'duplicated join_group_with_code overloads' as check_name, count(*) = 1 as ok
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public' and p.proname='join_group_with_code';

select 'realtime enabled for operational tables' as check_name,
  count(*) >= 12 as ok,
  array_agg(tablename order by tablename) as tables_found
from pg_publication_tables
where pubname = 'supabase_realtime'
  and schemaname = 'public'
  and tablename in (
    'profiles',
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
    'notifications',
    'support_tickets',
    'app_quality_events'
  );

select 'storage buckets exist' as check_name,
  count(*) = 2 as ok,
  array_agg(id order by id) as buckets
from storage.buckets
where id in ('avatars','group-covers');
