-- 088_outbox_seq_watermark.sql
-- High-water of chunk->game fact seq per character (outbox phases B-D).
-- Written atomically with each applied fact inside outboxClaimFactKey's txn;
-- read once per NEW chunk link (never on heartbeat) and returned in the
-- setChunkData ack so chunk can fast-forward its global seq_. bootId is
-- RETAINED (keys stay 4-part {characterId}:{factType}:{bootId}:{seq}), so a
-- stale/low watermark is always harmless: seq reuse across boots cannot
-- collide thanks to differing bootIds.
-- fact_keys_applied stays the dedup source of truth; this table is only
-- sequencing/observability. One row per character => tiny forever.
-- NOTE for load-safe: this table rides dumps with data (resume state, like
-- game_config, not content). After load-safe the watermark may be stale-low,
-- which is safe per above (forward-only resume, bootId retained).
CREATE TABLE IF NOT EXISTS public.outbox_seq_watermark (
    chunk_id     SMALLINT NOT NULL DEFAULT 1,
    character_id INTEGER NOT NULL,
    last_seq     BIGINT NOT NULL DEFAULT 0,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_outbox_seq_watermark PRIMARY KEY (chunk_id, character_id),
    CONSTRAINT ck_outbox_seq_watermark_seq CHECK (last_seq >= 0)
);
COMMENT ON TABLE public.outbox_seq_watermark IS
  'Max applied chunk fact seq per character. GREATEST-wins; never moves backward.';

-- Retention support for fact_keys_applied (dedup window only needs to cover
-- the 1h DLQ/retry horizon; without this the PK btree grows forever at
-- units/sec). Batched deletes from the game sweep.
CREATE INDEX IF NOT EXISTS ix_fact_keys_applied_applied_at
    ON public.fact_keys_applied (applied_at);
