-- Grupli v15.31 — Estado, notificaciones, agenda y finanzas
-- No resetea nada.
-- Refuerza Realtime para cambios de perfil/avatar y deja la estructura lista para navegación real de notificaciones.

begin;

alter table public.notifications add column if not exists route_type text;
alter table public.notifications add column if not exists route_id uuid;

create index if not exists idx_notifications_group_created on public.notifications(group_id, created_at desc);
create index if not exists idx_notifications_route on public.notifications(route_type, route_id);

-- Realtime: necesario para que cambios de foto/avatar/perfil se reflejen sin cerrar y abrir.
do $$
begin
  alter publication supabase_realtime add table public.profiles;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

commit;
