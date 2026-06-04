-- Grupli v15.11
-- Añade sistema de puntuación configurable para torneos/ligas.
-- Es seguro ejecutarlo varias veces.

ALTER TABLE public.tournaments
  ADD COLUMN IF NOT EXISTS scoring_type text NOT NULL DEFAULT 'general';

ALTER TABLE public.tournaments
  ADD COLUMN IF NOT EXISTS scoring_config jsonb NOT NULL DEFAULT '{"win":3,"draw":1,"loss":0,"unit":"puntos","allowDraw":true}'::jsonb;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'tournaments_scoring_type_check'
      AND conrelid = 'public.tournaments'::regclass
  ) THEN
    ALTER TABLE public.tournaments
      ADD CONSTRAINT tournaments_scoring_type_check
      CHECK (scoring_type IN ('general','football','tennis_padel','basketball','cards_mus','custom'));
  END IF;
END $$;

UPDATE public.tournaments
SET
  scoring_type = COALESCE(NULLIF(scoring_type, ''), 'general'),
  scoring_config = COALESCE(scoring_config, '{"win":3,"draw":1,"loss":0,"unit":"puntos","allowDraw":true}'::jsonb);
