-- 084_admin_rpc_config.sql
-- Admin-RPC test hook knobs (chunk defense layers 1+2).
-- `admin.enabled` defaults to false (closed); enable on DEV by hand only,
-- then restart game+chunk (knobs propagate via the boot handshake only).
-- `admin.gm_client_ids` is the DEV GM allowlist (CSV of clientIds); bot
-- accounts are never listed — only the separate gm_bot (users.role=1).
-- Prod deploy: flag off + zero role>=1 accounts (asserted by Preflight).

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('admin.enabled', 'false', 'bool', 'DEV-only admin-RPC test hook master switch')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('admin.gm_client_ids', '', 'string', 'DEV-only admin-RPC GM allowlist (CSV clientIds, gm_bot only)')
ON CONFLICT (key) DO NOTHING;

-- Verification (expect 2 rows).
-- SELECT key, value FROM public.game_config WHERE key LIKE 'admin.%';
