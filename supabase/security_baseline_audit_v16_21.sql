-- Grupli v16.21 Security Baseline Audit
-- Ejecutar en Supabase SQL Editor para revisar estado de seguridad.
-- No modifica datos.

-- 1) Tablas públicas sin RLS habilitado.
select
  schemaname,
  tablename,
  rowsecurity
from pg_tables
where schemaname = 'public'
  and rowsecurity = false
order by tablename;

-- 2) Tablas públicas sin ninguna policy.
select
  t.schemaname,
  t.tablename,
  count(p.policyname) as policies_count
from pg_tables t
left join pg_policies p
  on p.schemaname = t.schemaname
 and p.tablename = t.tablename
where t.schemaname = 'public'
group by t.schemaname, t.tablename
having count(p.policyname) = 0
order by t.tablename;

-- 3) Policies demasiado permisivas para usuarios anónimos.
select
  schemaname,
  tablename,
  policyname,
  cmd,
  roles,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and (
    roles::text ilike '%anon%'
    or qual::text = 'true'
    or with_check::text = 'true'
  )
order by tablename, policyname;

-- 4) Buckets de Storage públicos.
select
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
from storage.buckets
order by name;

-- 5) Funciones security definer para revisar manualmente.
select
  n.nspname as schema,
  p.proname as function_name,
  pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and pg_get_functiondef(p.oid) ilike '%security definer%'
order by p.proname;
