-- Grupli v15.28 — Realtime escalable por grupo
-- Ejecutar en Supabase SQL Editor. No resetea datos y es seguro repetirlo.
-- Objetivo: que las tablas hijas tengan group_id directo para poder filtrar Realtime
-- por grupo y evitar refrescos globales cuando otros grupos cambian.

begin;

-- 1) Añadir group_id directo a tablas hijas.
alter table public.event_attendance
  add column if not exists group_id uuid references public.groups(id) on delete cascade;

alter table public.expense_participants
  add column if not exists group_id uuid references public.groups(id) on delete cascade;

alter table public.tournament_teams
  add column if not exists group_id uuid references public.groups(id) on delete cascade;

alter table public.matches
  add column if not exists group_id uuid references public.groups(id) on delete cascade;

-- 2) Backfill de datos existentes.
update public.event_attendance ea
set group_id = e.group_id
from public.events e
where ea.event_id = e.id
  and (ea.group_id is null or ea.group_id <> e.group_id);

update public.expense_participants ep
set group_id = e.group_id
from public.expenses e
where ep.expense_id = e.id
  and (ep.group_id is null or ep.group_id <> e.group_id);

update public.tournament_teams tt
set group_id = t.group_id
from public.tournaments t
where tt.tournament_id = t.id
  and (tt.group_id is null or tt.group_id <> t.group_id);

update public.matches m
set group_id = t.group_id
from public.tournaments t
where m.tournament_id = t.id
  and (m.group_id is null or m.group_id <> t.group_id);

-- 3) Triggers para mantener group_id sincronizado en nuevas filas.
create or replace function public.set_event_attendance_group_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select e.group_id into new.group_id
  from public.events e
  where e.id = new.event_id;
  return new;
end;
$$;

drop trigger if exists set_event_attendance_group_id_trigger on public.event_attendance;
create trigger set_event_attendance_group_id_trigger
before insert or update of event_id on public.event_attendance
for each row execute function public.set_event_attendance_group_id();

create or replace function public.set_expense_participant_group_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select e.group_id into new.group_id
  from public.expenses e
  where e.id = new.expense_id;
  return new;
end;
$$;

drop trigger if exists set_expense_participant_group_id_trigger on public.expense_participants;
create trigger set_expense_participant_group_id_trigger
before insert or update of expense_id on public.expense_participants
for each row execute function public.set_expense_participant_group_id();

create or replace function public.set_tournament_team_group_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select t.group_id into new.group_id
  from public.tournaments t
  where t.id = new.tournament_id;
  return new;
end;
$$;

drop trigger if exists set_tournament_team_group_id_trigger on public.tournament_teams;
create trigger set_tournament_team_group_id_trigger
before insert or update of tournament_id on public.tournament_teams
for each row execute function public.set_tournament_team_group_id();

create or replace function public.set_match_group_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select t.group_id into new.group_id
  from public.tournaments t
  where t.id = new.tournament_id;
  return new;
end;
$$;

drop trigger if exists set_match_group_id_trigger on public.matches;
create trigger set_match_group_id_trigger
before insert or update of tournament_id on public.matches
for each row execute function public.set_match_group_id();

-- 4) Índices para filtros por grupo.
create index if not exists idx_event_attendance_group_event on public.event_attendance(group_id, event_id);
create index if not exists idx_expense_participants_group_expense on public.expense_participants(group_id, expense_id);
create index if not exists idx_tournament_teams_group_tournament on public.tournament_teams(group_id, tournament_id);
create index if not exists idx_matches_group_tournament on public.matches(group_id, tournament_id);

-- 5) Realtime: identidad completa y publicación.
do $$
declare
  t text;
begin
  foreach t in array array[
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
    'support_tickets'
  ] loop
    begin
      execute format('alter table public.%I replica identity full', t);
    exception when undefined_table then
      null;
    end;

    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception
      when duplicate_object then null;
      when undefined_table then null;
      when undefined_object then null;
    end;
  end loop;
end $$;

commit;
