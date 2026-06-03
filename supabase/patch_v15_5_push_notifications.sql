-- Grupli v15.5 — notificaciones internas + base push FCM
-- No resetea datos. Ejecutar en Supabase SQL Editor.

begin;

alter table public.user_settings
  add column if not exists push_enabled boolean not null default true,
  add column if not exists notify_members boolean not null default true;

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null default 'unknown',
  device_label text,
  enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  group_id uuid references public.groups(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  type text not null default 'general' check (type in ('event','finance','tournament','member','general')),
  title text not null,
  body text not null,
  route_type text,
  route_id uuid,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user_created on public.notifications(user_id, created_at desc);
create index if not exists idx_notifications_user_unread on public.notifications(user_id, read_at) where read_at is null;
create index if not exists idx_user_devices_user on public.user_devices(user_id);

alter table public.notifications enable row level security;
alter table public.user_devices enable row level security;

-- Policies: notifications
DROP POLICY IF EXISTS "notifications select own" ON public.notifications;
CREATE POLICY "notifications select own" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications update own" ON public.notifications;
CREATE POLICY "notifications update own" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications delete own" ON public.notifications;
CREATE POLICY "notifications delete own" ON public.notifications
  FOR DELETE USING (user_id = auth.uid());

-- Policies: devices
DROP POLICY IF EXISTS "devices select own" ON public.user_devices;
CREATE POLICY "devices select own" ON public.user_devices
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "devices insert own" ON public.user_devices;
CREATE POLICY "devices insert own" ON public.user_devices
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "devices update own" ON public.user_devices;
CREATE POLICY "devices update own" ON public.user_devices
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "devices delete own" ON public.user_devices;
CREATE POLICY "devices delete own" ON public.user_devices
  FOR DELETE USING (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.create_group_notifications(
  p_group_id uuid,
  p_actor_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_route_type text,
  p_route_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  group_name text;
BEGIN
  SELECT name INTO group_name FROM public.groups WHERE id = p_group_id;
  IF group_name IS NULL THEN
    RETURN;
  END IF;

  INSERT INTO public.notifications (user_id, group_id, actor_id, type, title, body, route_type, route_id)
  SELECT
    gm.user_id,
    p_group_id,
    p_actor_id,
    CASE WHEN p_type IN ('event','finance','tournament','member','general') THEN p_type ELSE 'general' END,
    p_title,
    group_name || ' · ' || p_body,
    p_route_type,
    p_route_id
  FROM public.group_members gm
  LEFT JOIN public.user_settings us ON us.user_id = gm.user_id
  WHERE gm.group_id = p_group_id
    AND (p_actor_id IS NULL OR gm.user_id <> p_actor_id)
    AND CASE
      WHEN p_type = 'event' THEN coalesce(us.notify_events, true)
      WHEN p_type = 'finance' THEN coalesce(us.notify_expenses, true)
      WHEN p_type = 'tournament' THEN coalesce(us.notify_tournaments, true)
      WHEN p_type = 'member' THEN coalesce(us.notify_members, true)
      ELSE true
    END;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_event_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.create_group_notifications(
    NEW.group_id,
    NEW.created_by,
    'event',
    'Nueva quedada',
    NEW.title,
    'event',
    NEW.id
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_event_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'cancelled' AND OLD.status <> 'cancelled' THEN
    PERFORM public.create_group_notifications(NEW.group_id, NEW.created_by, 'event', 'Quedada cancelada', NEW.title, 'event', NEW.id);
  ELSIF NEW.title IS DISTINCT FROM OLD.title OR NEW.starts_at IS DISTINCT FROM OLD.starts_at OR NEW.location IS DISTINCT FROM OLD.location THEN
    PERFORM public.create_group_notifications(NEW.group_id, NEW.created_by, 'event', 'Quedada actualizada', NEW.title, 'event', NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_expense_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.create_group_notifications(
    NEW.group_id,
    NEW.created_by,
    'finance',
    'Nuevo gasto',
    NEW.concept || ' · ' || to_char(NEW.amount, 'FM999999990D00') || ' €',
    'finance',
    NEW.id
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_tournament_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.create_group_notifications(NEW.group_id, NEW.created_by, 'tournament', 'Nuevo torneo', NEW.name, 'tournament', NEW.id);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_match_played()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  g_id uuid;
  t_name text;
BEGIN
  IF NEW.status = 'played' AND OLD.status IS DISTINCT FROM 'played' THEN
    SELECT t.group_id, t.name INTO g_id, t_name FROM public.tournaments t WHERE t.id = NEW.tournament_id;
    IF g_id IS NOT NULL THEN
      PERFORM public.create_group_notifications(g_id, NULL, 'tournament', 'Resultado registrado', coalesce(t_name, 'Torneo'), 'tournament', NEW.tournament_id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_member_join()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  person_name text;
BEGIN
  SELECT coalesce(full_name, email, 'Nuevo miembro') INTO person_name FROM public.profiles WHERE id = NEW.user_id;
  PERFORM public.create_group_notifications(NEW.group_id, NEW.user_id, 'member', 'Nuevo miembro', person_name || ' se ha unido al grupo', 'members', NEW.group_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_event_insert ON public.events;
CREATE TRIGGER trg_notify_event_insert
AFTER INSERT ON public.events
FOR EACH ROW EXECUTE FUNCTION public.notify_event_insert();

DROP TRIGGER IF EXISTS trg_notify_event_update ON public.events;
CREATE TRIGGER trg_notify_event_update
AFTER UPDATE ON public.events
FOR EACH ROW EXECUTE FUNCTION public.notify_event_update();

DROP TRIGGER IF EXISTS trg_notify_expense_insert ON public.expenses;
CREATE TRIGGER trg_notify_expense_insert
AFTER INSERT ON public.expenses
FOR EACH ROW EXECUTE FUNCTION public.notify_expense_insert();

DROP TRIGGER IF EXISTS trg_notify_tournament_insert ON public.tournaments;
CREATE TRIGGER trg_notify_tournament_insert
AFTER INSERT ON public.tournaments
FOR EACH ROW EXECUTE FUNCTION public.notify_tournament_insert();

DROP TRIGGER IF EXISTS trg_notify_match_played ON public.matches;
CREATE TRIGGER trg_notify_match_played
AFTER UPDATE ON public.matches
FOR EACH ROW EXECUTE FUNCTION public.notify_match_played();

DROP TRIGGER IF EXISTS trg_notify_member_join ON public.group_members;
CREATE TRIGGER trg_notify_member_join
AFTER INSERT ON public.group_members
FOR EACH ROW EXECUTE FUNCTION public.notify_member_join();

commit;
