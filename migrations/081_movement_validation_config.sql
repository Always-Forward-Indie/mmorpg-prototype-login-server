-- 081_movement_validation_config.sql
-- Add movement speed buffer multiplier to game_config.
-- Controls strictness of server-authoritative movement validation.
-- Increase (e.g. 1.6–2.0) for VPN / high-jitter players.

INSERT INTO public.game_config (key, value, value_type, description) VALUES
('movement.speed_buffer_multiplier', '1.3', 'float', 'Multiplier for movement speed validation (maxDist = speed x delta x multiplier). Increase for VPN/high-jitter clients. Default 1.3 = 30 percent buffer.');
