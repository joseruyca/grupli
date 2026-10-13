-- Incremental patch. Never run the destructive all_in_one.sql on a populated project.
begin;
create schema if not exists grupli_private;
revoke all on schema grupli_private from public,anon;
grant usage on schema grupli_private to authenticated;
create or replace function grupli_private.save_expense(p_group_id uuid,p_expense_id uuid,p_concept text,p_amount numeric,p_paid_by uuid,p_shares jsonb,p_note text)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=auth.uid(); v_id uuid; e public.expenses%rowtype; v_total numeric; v_count int;
begin
 if v_uid is null then raise exception 'not_authenticated'; end if;
 if p_group_id is null or not public.is_group_member(p_group_id) then raise exception 'not_group_member'; end if;
 if p_amount is null or p_amount::text in ('NaN','Infinity','-Infinity') or p_amount<=0 or p_amount>9999999999.99 or p_amount<>round(p_amount,2) then raise exception 'invalid_amount'; end if;
 if char_length(trim(coalesce(p_concept,''))) not between 2 and 160 then raise exception 'invalid_concept'; end if;
 if char_length(coalesce(p_note,''))>2000 then raise exception 'invalid_note'; end if;
 if not exists(select 1 from public.group_members where group_id=p_group_id and user_id=p_paid_by) then raise exception 'payer_not_in_group'; end if;
 if p_shares is null or jsonb_typeof(p_shares)<>'object' then raise exception 'invalid_shares'; end if;
 select count(*) into v_count from jsonb_each(p_shares);
 if v_count not between 1 and 500 then raise exception 'invalid_shares'; end if;
 if exists(select 1 from jsonb_each(p_shares) where jsonb_typeof(value)<>'number') then raise exception 'invalid_shares'; end if;
 if exists(select 1 from jsonb_each_text(p_shares) where value::numeric<0 or value::numeric>p_amount or value::numeric<>round(value::numeric,2)) then raise exception 'invalid_shares'; end if;
 if exists(select 1 from jsonb_each_text(p_shares) s where not exists(select 1 from public.group_members m where m.group_id=p_group_id and m.user_id::text=s.key)) then raise exception 'participant_not_in_group'; end if;
 select sum(value::numeric) into v_total from jsonb_each_text(p_shares);
 if v_total<>p_amount then raise exception 'shares_total_mismatch'; end if;
 if p_expense_id is not null then
  select * into e from public.expenses where id=p_expense_id for update;
  if not found then raise exception 'expense_not_found'; end if;
  if e.group_id<>p_group_id or not (coalesce(e.created_by=v_uid,false) or public.is_group_admin(e.group_id)) then raise exception 'permission_denied'; end if;
  if exists(select 1 from public.expense_participants where expense_id=e.id and paid and user_id<>e.paid_by) then raise exception 'expense_has_payments'; end if;
  update public.expenses set concept=trim(p_concept),amount=p_amount,paid_by=p_paid_by,note=nullif(trim(p_note),''),status='pending',updated_at=now() where id=e.id;
  delete from public.expense_participants where expense_id=e.id;
  v_id:=e.id;
 else
  insert into public.expenses(group_id,concept,amount,paid_by,created_by,note,status) values(p_group_id,trim(p_concept),p_amount,p_paid_by,v_uid,nullif(trim(p_note),''),'pending') returning id into v_id;
 end if;
 insert into public.expense_participants(expense_id,user_id,share_amount,paid) select v_id,key::uuid,value::numeric,key::uuid=p_paid_by from jsonb_each_text(p_shares);
 return v_id;
end $$;
revoke all on function grupli_private.save_expense(uuid,uuid,text,numeric,uuid,jsonb,text) from public,anon;
grant execute on function grupli_private.save_expense(uuid,uuid,text,numeric,uuid,jsonb,text) to authenticated;
create or replace function public.grupli_save_expense(p_group_id uuid,p_expense_id uuid,p_concept text,p_amount numeric,p_paid_by uuid,p_shares jsonb,p_note text)
returns uuid language sql security invoker set search_path='' as $$ select grupli_private.save_expense(p_group_id,p_expense_id,p_concept,p_amount,p_paid_by,p_shares,p_note); $$;
revoke all on function public.grupli_save_expense(uuid,uuid,text,numeric,uuid,jsonb,text) from public,anon;
grant execute on function public.grupli_save_expense(uuid,uuid,text,numeric,uuid,jsonb,text) to authenticated;
create or replace function grupli_private.expense_action(p_expense_id uuid,p_action text,p_user_id uuid,p_paid boolean)
returns void language plpgsql security definer set search_path='' as $$
declare e public.expenses%rowtype; v_uid uuid:=auth.uid();
begin
 if v_uid is null then raise exception 'not_authenticated'; end if;
 select * into e from public.expenses where id=p_expense_id for update;
 if not found then raise exception 'expense_not_found'; end if;
 if not public.is_group_member(e.group_id) or not (coalesce(e.created_by=v_uid,false) or coalesce(e.paid_by=v_uid,false) or public.is_group_admin(e.group_id)) then raise exception 'permission_denied'; end if;
 if p_action='participant' then
  if p_paid is null then raise exception 'invalid_paid'; end if;
  update public.expense_participants set paid=case when user_id=e.paid_by then true else p_paid end where expense_id=e.id and user_id=p_user_id;
  if not found then raise exception 'participant_not_found'; end if;
  update public.expenses set status='pending',updated_at=now() where id=e.id;
 elsif p_action='settle' then
  update public.expense_participants set paid=true where expense_id=e.id;
  update public.expenses set status='paid',updated_at=now() where id=e.id;
 elsif p_action='reopen' then
  update public.expense_participants set paid=(user_id=e.paid_by) where expense_id=e.id;
  update public.expenses set status='pending',updated_at=now() where id=e.id;
 elsif p_action='delete' then delete from public.expenses where id=e.id;
 else raise exception 'invalid_action'; end if;
end $$;
revoke all on function grupli_private.expense_action(uuid,text,uuid,boolean) from public,anon;
grant execute on function grupli_private.expense_action(uuid,text,uuid,boolean) to authenticated;
create or replace function public.grupli_expense_action(p_expense_id uuid,p_action text,p_user_id uuid default null,p_paid boolean default null)
returns void language sql security invoker set search_path='' as $$ select grupli_private.expense_action(p_expense_id,p_action,p_user_id,p_paid); $$;
revoke all on function public.grupli_expense_action(uuid,text,uuid,boolean) from public,anon;
grant execute on function public.grupli_expense_action(uuid,text,uuid,boolean) to authenticated;
revoke insert,update,delete on public.expenses,public.expense_participants from anon,authenticated;
grant select on public.expenses,public.expense_participants to authenticated;

-- Protect the existing destructive administrative RPC behind an owner-only wrapper.
do $$ begin
 if to_regprocedure('grupli_private.admin_delete_user_impl(text,text)') is null then
  alter function public.admin_delete_user_by_email(text,text) set schema grupli_private;
  alter function grupli_private.admin_delete_user_by_email(text,text) rename to admin_delete_user_impl;
 end if;
end $$;
revoke all on function grupli_private.admin_delete_user_impl(text,text) from public,anon,authenticated;
create or replace function grupli_private.admin_delete_user(p_email text,p_confirm text)
returns jsonb language plpgsql security definer set search_path='' as $$ begin
 if auth.uid() is null or not public.is_app_owner() then raise exception 'permission_denied'; end if;
 return grupli_private.admin_delete_user_impl(p_email,p_confirm);
end $$;
revoke all on function grupli_private.admin_delete_user(text,text) from public,anon;
grant execute on function grupli_private.admin_delete_user(text,text) to authenticated;
create or replace function public.admin_delete_user_by_email(target_email text,confirm_text text)
returns jsonb language sql security invoker set search_path='' as $$ select grupli_private.admin_delete_user(target_email,confirm_text); $$;
revoke all on function public.admin_delete_user_by_email(text,text) from public,anon;
grant execute on function public.admin_delete_user_by_email(text,text) to authenticated;

-- Read access is separate from management. Members cannot bypass the UI flags.
drop policy if exists tournaments_member_all on public.tournaments;
drop policy if exists tournaments_read_member on public.tournaments;
drop policy if exists tournaments_write_admin on public.tournaments;
create policy tournaments_read_member on public.tournaments for select to authenticated using(public.is_group_member(group_id));
create policy tournaments_write_admin on public.tournaments for all to authenticated using(public.is_group_admin(group_id)) with check(public.is_group_admin(group_id));
drop policy if exists tournament_teams_member_all on public.tournament_teams;
drop policy if exists tournament_teams_read_member on public.tournament_teams;
drop policy if exists tournament_teams_write_admin on public.tournament_teams;
create policy tournament_teams_read_member on public.tournament_teams for select to authenticated using(public.is_group_member(group_id));
create policy tournament_teams_write_admin on public.tournament_teams for all to authenticated using(public.is_group_admin(group_id)) with check(exists(select 1 from public.tournaments t where t.id=tournament_id and public.is_group_admin(t.group_id)));
drop policy if exists tournament_team_members_member_all on public.tournament_team_members;
drop policy if exists tournament_team_members_read_member on public.tournament_team_members;
drop policy if exists tournament_team_members_write_admin on public.tournament_team_members;
create policy tournament_team_members_read_member on public.tournament_team_members for select to authenticated using(exists(select 1 from public.tournament_teams t where t.id=tournament_team_id and public.is_group_member(t.group_id)));
create policy tournament_team_members_write_admin on public.tournament_team_members for all to authenticated using(exists(select 1 from public.tournament_teams t where t.id=tournament_team_id and public.is_group_admin(t.group_id))) with check(exists(select 1 from public.tournament_teams t where t.id=tournament_team_id and public.is_group_admin(t.group_id)));
drop policy if exists matches_member_all on public.matches;
drop policy if exists matches_read_member on public.matches;
drop policy if exists matches_write_admin on public.matches;
create policy matches_read_member on public.matches for select to authenticated using(public.is_group_member(group_id));
create policy matches_write_admin on public.matches for all to authenticated using(public.is_group_admin(group_id)) with check(exists(select 1 from public.tournaments t where t.id=tournament_id and public.is_group_admin(t.group_id)));
commit;
