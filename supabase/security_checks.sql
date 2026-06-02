select 'profiles RLS enabled' as check_name, rowsecurity as ok from pg_tables where schemaname='public' and tablename='profiles'
union all select 'groups RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='groups'
union all select 'group_members RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='group_members'
union all select 'events RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='events'
union all select 'expenses RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='expenses'
union all select 'tournaments RLS enabled', rowsecurity from pg_tables where schemaname='public' and tablename='tournaments'
union all select 'create_group_atomic exists', to_regprocedure('public.create_group_atomic(text)') is not null
union all select 'join_group_with_code exists', to_regprocedure('public.join_group_with_code(text)') is not null
union all select 'get_my_groups exists', to_regprocedure('public.get_my_groups()') is not null;
