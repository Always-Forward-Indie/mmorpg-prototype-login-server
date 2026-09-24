-- 089_drop_corpse_ttl.sql
-- Seed TTL knobs the chunk already reads live with compiled fallbacks
-- (drop.ttl_sec=300 in dropped-item cleanup, corpse.ttl_ms=60000 in
-- dead-mob cleanup). Seeding changes nothing at runtime; it only makes
-- the values visible and tunable via game_config like the other ~30 keys.
INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('drop.ttl_sec', '300', 'int', 'Chunk expired ground-item cleanup: drop age threshold in seconds')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('corpse.ttl_ms', '60000', 'int', 'Chunk dead-mob cleanup: corpse visibility window in milliseconds')
ON CONFLICT (key) DO NOTHING;
