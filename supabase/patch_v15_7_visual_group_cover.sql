-- Grupli v15.7 — visual premium azul + foto de grupo
-- No resetea datos.

begin;

alter table public.groups
  add column if not exists cover_url text;

create or replace function public.get_my_groups()
returns table (
  id uuid,
  name text,
  type text,
  privacy text,
  invite_code text,
  cover_url text,
  role text,
  members_count int,
  events_count int,
  balance numeric,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    g.id,
    g.name,
    g.type,
    g.privacy,
    g.invite_code,
    g.cover_url,
    gm.role,
    (select count(*)::int from public.group_members x where x.group_id = g.id) as members_count,
    (select count(*)::int from public.events e where e.group_id = g.id and e.status = 'active' and e.starts_at >= now() - interval '2 hours') as events_count,
    0::numeric as balance,
    g.created_at
  from public.groups g
  join public.group_members gm on gm.group_id = g.id
  where gm.user_id = auth.uid()
  order by g.created_at desc;
$$;

grant execute on function public.get_my_groups() to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('group-covers', 'group-covers', true, 5242880, array['image/jpeg','image/png','image/webp']::text[])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists group_covers_public_read on storage.objects;
drop policy if exists group_covers_insert_admin on storage.objects;
drop policy if exists group_covers_update_admin on storage.objects;
drop policy if exists group_covers_delete_admin on storage.objects;

create policy group_covers_public_read
on storage.objects for select
to public
using (bucket_id = 'group-covers');

create policy group_covers_insert_admin
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'group-covers'
  and public.is_group_admin(((storage.foldername(name))[1])::uuid)
);

create policy group_covers_update_admin
on storage.objects for update
to authenticated
using (
  bucket_id = 'group-covers'
  and public.is_group_admin(((storage.foldername(name))[1])::uuid)
)
with check (
  bucket_id = 'group-covers'
  and public.is_group_admin(((storage.foldername(name))[1])::uuid)
);

create policy group_covers_delete_admin
on storage.objects for delete
to authenticated
using (
  bucket_id = 'group-covers'
  and public.is_group_admin(((storage.foldername(name))[1])::uuid)
);

commit;
