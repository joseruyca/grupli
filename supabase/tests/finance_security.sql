-- Synthetic data and authorization assertions. Transaction always rolls back.
begin;
insert into auth.users(id,email) values
('10000000-0000-0000-0000-000000000001','qa-owner@example.test'),
('10000000-0000-0000-0000-000000000002','qa-creator@example.test'),
('10000000-0000-0000-0000-000000000003','qa-viewer@example.test'),
('10000000-0000-0000-0000-000000000004','qa-outsider@example.test');
insert into public.groups(id,name,owner_id) values('20000000-0000-0000-0000-000000000001','QA','10000000-0000-0000-0000-000000000001');
insert into public.group_members(group_id,user_id,role) values
('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','owner'),
('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','member'),
('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000003','member');
insert into public.app_admins(user_id,role) values('10000000-0000-0000-0000-000000000003','viewer'),('10000000-0000-0000-0000-000000000004','support');
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
set local role authenticated;
do $$ declare v_id uuid; v_sum numeric; begin
 v_id:=public.grupli_save_expense('20000000-0000-0000-0000-000000000001',null,'Pista',10,'10000000-0000-0000-0000-000000000001','{"10000000-0000-0000-0000-000000000001":3.34,"10000000-0000-0000-0000-000000000002":3.33,"10000000-0000-0000-0000-000000000003":3.33}','');
 select sum(share_amount) into v_sum from public.expense_participants where expense_id=v_id;
 if v_sum<>10 then raise exception 'QA total not preserved'; end if;
 begin perform public.grupli_save_expense('20000000-0000-0000-0000-000000000001',v_id,'Pista',10,'10000000-0000-0000-0000-000000000001','{"10000000-0000-0000-0000-000000000001":9}',''); raise exception 'QA invalid split allowed'; exception when others then if sqlerrm<>'shares_total_mismatch' then raise; end if; end;
 select sum(share_amount) into v_sum from public.expense_participants where expense_id=v_id;
 if v_sum<>10 then raise exception 'QA edit lost shares'; end if;
 begin update public.expenses set amount=1 where id=v_id; raise exception 'QA direct update allowed'; exception when insufficient_privilege then null; end;
 begin delete from public.expense_participants where expense_id=v_id; raise exception 'QA direct deletion allowed'; exception when insufficient_privilege then null; end;
 begin perform public.grupli_save_expense('20000000-0000-0000-0000-000000000001',null,'Pista',10,'10000000-0000-0000-0000-000000000001','{"10000000-0000-0000-0000-000000000004":10}',''); raise exception 'QA foreign participant allowed'; exception when others then if sqlerrm<>'participant_not_in_group' then raise; end if; end;
 begin insert into public.tournaments(group_id,name) values('20000000-0000-0000-0000-000000000001','Illegal'); raise exception 'QA member created tournament'; exception when insufficient_privilege then null; end;
 perform public.grupli_expense_action(v_id,'settle');
 begin perform public.grupli_save_expense('20000000-0000-0000-0000-000000000001',v_id,'Pista',10,'10000000-0000-0000-0000-000000000001','{"10000000-0000-0000-0000-000000000001":10}',''); raise exception 'QA editing paid expense allowed'; exception when others then if sqlerrm<>'expense_has_payments' then raise; end if; end;
 perform public.grupli_expense_action(v_id,'reopen');
 raise notice 'PASS finance atomicity, exact cents, permission checks and explicit reopen';
end $$;
reset role;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
set local role authenticated;
do $$ begin
 begin perform public.admin_delete_user_by_email('qa-creator@example.test','ELIMINAR USUARIO'); raise exception 'QA viewer deletion allowed'; exception when others then if sqlerrm<>'permission_denied' then raise; end if; end;
 begin perform grupli_private.admin_delete_user_impl('qa-creator@example.test','ELIMINAR USUARIO'); raise exception 'QA private implementation accessible'; exception when insufficient_privilege then null; end;
 raise notice 'PASS viewer cannot delete accounts';
end $$;
reset role;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',true);
set local role authenticated;
do $$ begin
 begin perform public.admin_delete_user_by_email('qa-creator@example.test','ELIMINAR USUARIO'); raise exception 'QA support deletion allowed'; exception when others then if sqlerrm<>'permission_denied' then raise; end if; end;
 raise notice 'PASS support cannot delete accounts';
end $$;
reset role;
set local role anon;
do $$ begin
 begin perform public.grupli_save_expense(null,null,'Pista',10,null,'{}',''); raise exception 'QA anonymous RPC allowed'; exception when insufficient_privilege then null; end;
 raise notice 'PASS signed-out caller cannot write expenses';
end $$;
reset role;
rollback;
