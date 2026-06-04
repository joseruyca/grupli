-- v15.12
-- Refuerza sistema de puntuación y guarda detalles por sets en partidos.

ALTER TABLE public.tournaments
ADD COLUMN IF NOT EXISTS scoring_type text NOT NULL DEFAULT 'general';

ALTER TABLE public.tournaments
ADD COLUMN IF NOT EXISTS scoring_config jsonb NOT NULL DEFAULT '{"win":3,"draw":1,"loss":0,"unit":"puntos","allowDraw":true}'::jsonb;

ALTER TABLE public.matches
ADD COLUMN IF NOT EXISTS result_details jsonb;
