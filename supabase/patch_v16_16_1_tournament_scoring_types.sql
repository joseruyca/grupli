-- Grupli v16.16.1 — ampliar deportes permitidos en torneos
-- Ejecutar en Supabase SQL Editor si ya tenías la base creada antes de esta versión.

ALTER TABLE public.tournaments
DROP CONSTRAINT IF EXISTS tournaments_scoring_type_check;

ALTER TABLE public.tournaments
ADD CONSTRAINT tournaments_scoring_type_check
CHECK (
  scoring_type IN (
    'general',
    'football',
    'tennis_padel',
    'basketball',
    'volleyball',
    'ping_pong',
    'cards_mus',
    'darts',
    'billiards',
    'esports',
    'custom'
  )
);
