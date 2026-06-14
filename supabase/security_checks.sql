-- Grupli v15.32 — security_checks.sql
-- Ejecutar después de supabase/all_in_one.sql para revisar que el reset global quedó coherente.
-- No modifica datos.

select 'profiles' as table_name, count(*) as rows from public.profiles
union all select 'groups', count(*) from public.groups
union all select 'group_members', count(*) from public.group_members
union all select 'events', count(*) from public.events
union all select 'event_attendance', count(*) from public.event_attendance
union all select 'event_contributions', count(*) from public.event_contributions
union all select 'expenses', count(*) from public.expenses
union all select 'expense_participants', count(*) from public.expense_participants
union all select 'settlement_payments', count(*) from public.settlement_payments
union all select 'tournaments', count(*) from public.tournaments
union all select 'tournament_teams', count(*) from public.tournament_teams
union all select 'matches', count(*) from public.matches
union all select 'notifications', count(*) from public.notifications
union all select 'support_tickets', count(*) from public.support_tickets
union all select 'app_admins', count(*) from public.app_admins
union all select 'app_quality_events', count(*) from public.app_quality_events
union all select 'app_user_flags', count(*) from public.app_user_flags;

select
  'functions_ok' as check_name,
  exists(select 1 from pg_proc where proname = 'ensure_current_profile') as ensure_current_profile,
  exists(select 1 from pg_proc where proname = 'create_group_atomic') as create_group_atomic,
  exists(select 1 from pg_proc where proname = 'join_group_with_code') as join_group_with_code,
  exists(select 1 from pg_proc where proname = 'group_events_with_attendance') as group_events_with_attendance,
  exists(select 1 from pg_proc where proname = 'admin_overview') as admin_overview;

select
  'rls_enabled' as check_name,
  relname,
  relrowsecurity
from pg_class
where relnamespace = 'public'::regnamespace
  and relkind = 'r'
  and relname in (
    'profiles','groups','group_members','events','event_attendance','event_contributions','expenses',
    'expense_participants','settlement_payments','tournaments','tournament_teams',
    'matches','notifications','support_tickets','app_admins','app_quality_events','app_user_flags'
  )
order by relname;

select
  'single_global_reset_file' as check_name,
  'Use only supabase/all_in_one.sql. No patch SQL files should be needed for a clean reset.' as note;
