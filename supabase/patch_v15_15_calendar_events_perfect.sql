-- v15.15
-- Calendario y eventos: rutinas conectadas, edición/cancelación por alcance y agenda más clara.

ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS event_series_id uuid;

ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS recurrence_frequency text;

ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS recurrence_index int;

ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS recurrence_count int;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'events_recurrence_frequency_check'
  ) THEN
    ALTER TABLE public.events
    ADD CONSTRAINT events_recurrence_frequency_check
    CHECK (recurrence_frequency IS NULL OR recurrence_frequency IN ('weekly','biweekly','monthly'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_events_series
ON public.events(event_series_id, starts_at);
