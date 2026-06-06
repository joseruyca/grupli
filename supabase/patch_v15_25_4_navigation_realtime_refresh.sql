-- Grupli v15.25.4 — navegación y refresco realtime
-- Ejecutar en Supabase SQL Editor. No resetea datos y es seguro repetirlo.

begin;

-- Asegura que las tablas principales emiten cambios por Realtime.
-- Si alguna ya estaba añadida, se ignora el error y continúa.
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
