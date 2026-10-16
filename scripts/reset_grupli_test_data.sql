-- One-time cleanup explicitly authorized on 2026-10-16.
-- Storage objects are deliberately not deleted through SQL: that would orphan files.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
lock table auth.users in share row exclusive mode;
lock table public.groups in share row exclusive mode;
do $$
declare fingerprint text;
begin
 select md5(string_agg(id::text,',' order by id)) into fingerprint from auth.users;
 if fingerprint is null and not exists(select 1 from public.groups) then return; end if;
 if fingerprint is distinct from '9323f2ee2d74e2d936b5e5dd015ff622'
 or (select count(*) from auth.users)<>5
 or (select count(*) from public.groups)<>2
 then raise exception 'Reset cancelled: account set changed'; end if;
 perform set_config('grupli.allow_owner_delete','on',true);
 delete from auth.sessions where user_id in (select id from auth.users);
 delete from public.support_tickets;
 delete from public.app_quality_events;
 delete from public.app_user_flags;
 delete from public.notifications;
 delete from public.settlements;
 delete from public.groups;
 delete from auth.users;
 if exists(select 1 from auth.users) or exists(select 1 from public.profiles)
 or exists(select 1 from public.groups) or exists(select 1 from public.events)
 or exists(select 1 from public.expenses) or exists(select 1 from public.tournaments)
 then raise exception 'Reset verification failed'; end if;
end $$;
commit;
