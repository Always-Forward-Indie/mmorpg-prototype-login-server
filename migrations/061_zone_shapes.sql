-- Migration 061: Zone shapes — RECT / CIRCLE / ANNULUS + geometry field cleanup
-- Adds support for non-rectangular spawn zones and an optional exclusion zone per spawn zone.
--
-- Design rationale:
--   RECT    — existing AABB behaviour, stored as (min_spawn_x/y, max_spawn_x/y)
--   CIRCLE  — filled disc: center_x/y + outer_radius
--   ANNULUS — ring/donut: center_x/y + inner_radius + outer_radius
--             Classic use-case: ring mobs around a village while keeping the center safe.
--   exclusion_game_zone_id — any spawn candidate that falls inside this game zone is rejected
--             at runtime (e.g. the village safe zone).  Complements ANNULUS for irregular shapes.

BEGIN;

-- -----------------------------------------------------------------
-- 1.  Zone shape enum
-- -----------------------------------------------------------------
CREATE TYPE public.spawn_zone_shape AS ENUM ('RECT', 'CIRCLE', 'ANNULUS');

-- -----------------------------------------------------------------
-- 2.  New geometry columns on spawn_zones
-- -----------------------------------------------------------------
ALTER TABLE public.spawn_zones
    ADD COLUMN shape_type            public.spawn_zone_shape NOT NULL DEFAULT 'RECT',
    ADD COLUMN center_x              double precision        NOT NULL DEFAULT 0,
    ADD COLUMN center_y              double precision        NOT NULL DEFAULT 0,
    ADD COLUMN inner_radius          double precision        NOT NULL DEFAULT 0,
    ADD COLUMN outer_radius          double precision        NOT NULL DEFAULT 0,
    ADD COLUMN exclusion_game_zone_id integer
        REFERENCES public.zones(id) ON DELETE SET NULL;

-- -----------------------------------------------------------------
-- 3.  Back-fill center_x / center_y from existing AABB bounds
--     (useful as a computed default even for RECT zones, e.g. champion spawn)
-- -----------------------------------------------------------------
UPDATE public.spawn_zones
SET center_x = (min_spawn_x + max_spawn_x) / 2.0,
    center_y = (min_spawn_y + max_spawn_y) / 2.0
WHERE shape_type = 'RECT';

-- -----------------------------------------------------------------
-- 4.  Column comments
-- -----------------------------------------------------------------
COMMENT ON COLUMN public.spawn_zones.shape_type IS
    'Geometry variant for this spawn zone.  '
    'RECT = AABB prism defined by (min_spawn_x/y, max_spawn_x/y).  '
    'CIRCLE = filled disc defined by (center_x/y, outer_radius).  '
    'ANNULUS = ring/donut defined by (center_x/y, inner_radius, outer_radius).  '
    'Use ANNULUS to surround a village or landmark with mobs while leaving the centre empty.';

COMMENT ON COLUMN public.spawn_zones.center_x IS
    'World X coordinate of zone centre.  Required for CIRCLE and ANNULUS.  '
    'For RECT zones this is auto-derived as (min_spawn_x + max_spawn_x) / 2 and used for '
    'champion spawn-point resolution.';

COMMENT ON COLUMN public.spawn_zones.center_y IS
    'World Y coordinate of zone centre.  Mirror of center_x for the Y axis.';

COMMENT ON COLUMN public.spawn_zones.inner_radius IS
    'ANNULUS only.  Spawn candidates whose distance to center is less than inner_radius are '
    'rejected.  Set to 0 for RECT and CIRCLE.';

COMMENT ON COLUMN public.spawn_zones.outer_radius IS
    'CIRCLE / ANNULUS.  Maximum distance from center at which mobs may spawn.  '
    'Set to 0 for RECT zones (AABB boundary is used instead).';

COMMENT ON COLUMN public.spawn_zones.exclusion_game_zone_id IS
    'Optional FK → zones.id.  Spawn candidates whose position falls inside this game zone are '
    'rejected at runtime regardless of the primary shape.  '
    'Typical use: prevent mobs spawning inside is_safe_zone=true areas when using RECT.';

COMMENT ON TABLE public.spawn_zones IS
    'Defines where mobs may spawn in the world.  Three geometry variants are supported: '
    'RECT (AABB), CIRCLE (disc), and ANNULUS (ring).  '
    'Mob quotas and respawn timers are configured in spawn_zone_mobs.';

COMMIT;
