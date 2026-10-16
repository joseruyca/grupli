begin;
do $$ begin
 if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.prosecdef and has_function_privilege('anon',p.oid,'execute'))
 then raise exception 'Anonymous caller still has privileged RPC access'; end if;
 if has_table_privilege('anon','public.v_grupli_security_diagnostics','select')
 or has_table_privilege('authenticated','public.v_grupli_security_diagnostics','select')
 then raise exception 'Internal diagnostic view is exposed'; end if;
 if not exists(select 1 from pg_class where oid='public.v_grupli_security_diagnostics'::regclass
 and 'security_invoker=true'=any(reloptions)) then raise exception 'Diagnostic view bypasses caller permissions'; end if;
end $$;
insert into auth.users(id,email) values
('30000000-0000-0000-0000-000000000001','qa-hardening-owner@example.test'),
('30000000-0000-0000-0000-000000000002','qa-hardening-admin@example.test'),
('30000000-0000-0000-0000-000000000003','qa-hardening-member@example.test');
insert into public.groups(id,name,owner_id) values('40000000-0000-0000-0000-000000000001','QA roles','30000000-0000-0000-0000-000000000001');
insert into public.group_members(group_id,user_id,role) values
('40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000002','admin');
select set_config('request.jwt.claim.sub','30000000-0000-0000-0000-000000000002',true);
set local role authenticated;
do $$ begin
 begin insert into public.group_members(group_id,user_id,role) values('40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000003','owner'); raise exception 'Admin created extra owner'; exception when insufficient_privilege then null; end;
 insert into public.group_members(group_id,user_id,role) values('40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000003','member');
 begin update public.group_members set role='owner' where group_id='40000000-0000-0000-0000-000000000001' and user_id='30000000-0000-0000-0000-000000000003'; raise exception 'Admin escalated member to owner'; exception when insufficient_privilege then null; end;
 raise notice 'PASS privileged RPC grants, diagnostic view and membership role escalation';
end $$;
reset role;
rollback;
