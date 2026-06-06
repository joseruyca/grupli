-- Grupli v15.29.4 — Reparación definitiva de Agenda
-- No resetea nada.
-- Añade una RPC segura para cargar eventos + asistencias sin depender del embed de PostgREST.

begin;

create or replace function public.group_events_with_attendance(p_group_id uuid)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when not public.is_group_member(p_group_id) then '[]'::jsonb
    else coalesce((
      select jsonb_agg(
        to_jsonb(e)
        || jsonb_build_object(
          'event_attendance',
          coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'status', ea.status,
                'user_id', ea.user_id
              )
              order by ea.created_at
            )
            from public.event_attendance ea
            where ea.event_id = e.id
          ), '[]'::jsonb)
        )
        order by e.starts_at
      )
      from public.events e
      where e.group_id = p_group_id
    ), '[]'::jsonb)
  end;
$$;

revoke all on function public.group_events_with_attendance(uuid) from public;
grant execute on function public.group_events_with_attendance(uuid) to authenticated;

commit;
