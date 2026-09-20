-- 084_fact_keys_applied.sql
-- Idempotency guard for chunk→game facts (outbox plan): every applied fact
-- key is recorded once; retried deliveries hit the conflict branch and are
-- ACKed as duplicates without re-applying business effects.
-- Pure append + point lookups; aged rows are deletable (see retention note).

CREATE TABLE IF NOT EXISTS public.fact_keys_applied (
    key TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Verification (expect 1 row, then 0).
-- INSERT INTO public.fact_keys_applied(key) VALUES('probe')
-- ON CONFLICT DO NOTHING RETURNING key;
-- DELETE FROM public.fact_keys_applied WHERE key = 'probe';
