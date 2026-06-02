-- Grupli v8 - Perfil, avatar y ajustes reales
-- Ejecutar en Supabase SQL Editor si ya tienes una base anterior.
-- No borra datos existentes.

create extension if not exists "pgcrypto";

-- Ajustes persistentes por usuario
create table if not exists public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  notify_events boolean not null default true,
  notify_expenses boolean not null default true,
  notify_tournaments boolean not null default true,
  theme text not null default 'light' check (theme in ('light')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_settings enable row level security;

drop policy if exists user_settings_select_self on public.user_settings;
drop policy if exists user_settings_insert_self on public.user_settings;
drop policy if exists user_settings_update_self on public.user_settings;
drop policy if exists user_settings_delete_self on public.user_settings;

create policy user_settings_select_self
on public.user_settings for select
to authenticated
using (user_id = auth.uid());

create policy user_settings_insert_self
on public.user_settings for insert
to authenticated
with check (user_id = auth.uid());

create policy user_settings_update_self
on public.user_settings for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy user_settings_delete_self
on public.user_settings for delete
to authenticated
using (user_id = auth.uid());

-- Bucket y políticas de avatar
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

drop policy if exists avatars_select_public on storage.objects;
drop policy if exists avatars_insert_own on storage.objects;
drop policy if exists avatars_update_own on storage.objects;
drop policy if exists avatars_delete_own on storage.objects;

create policy avatars_select_public
on storage.objects for select
using (bucket_id = 'avatars');

create policy avatars_insert_own
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy avatars_update_own
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy avatars_delete_own
on storage.objects for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Asegura fila de settings para usuarios existentes con perfil
insert into public.user_settings (user_id)
select id
from public.profiles
on conflict (user_id) do nothing;
