-- Migration 062: Shape support for game zones (zones table)
-- Adds CIRCLE / RECT shape types to the `zones` table,
-- reusing the spawn_zone_shape ENUM created in migration 061.

-- Add geometry columns (RECT is the default to keep existing rows valid)
ALTER TABLE public.zones
    ADD COLUMN IF NOT EXISTS shape_type  public.spawn_zone_shape NOT NULL DEFAULT 'RECT',
    ADD COLUMN IF NOT EXISTS center_x    double precision,
    ADD COLUMN IF NOT EXISTS center_y    double precision,
    ADD COLUMN IF NOT EXISTS inner_radius double precision NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS outer_radius double precision NOT NULL DEFAULT 0;

-- Back-fill center_x/y from AABB midpoints for all existing RECT zones
UPDATE public.zones
SET    center_x = (min_x + max_x) / 2.0,
       center_y = (min_y + max_y) / 2.0
WHERE  center_x IS NULL OR center_y IS NULL;

-- Make center columns non-nullable now that they are populated
ALTER TABLE public.zones
    ALTER COLUMN center_x SET NOT NULL,
    ALTER COLUMN center_y SET NOT NULL;

-- Column documentation
COMMENT ON COLUMN public.zones.shape_type    IS 'Zone boundary shape: RECT (AABB), CIRCLE (center + outer_radius), ANNULUS (center + inner_radius + outer_radius)';
COMMENT ON COLUMN public.zones.center_x      IS 'World-space X of zone centre. For RECT this equals (min_x+max_x)/2';
COMMENT ON COLUMN public.zones.center_y      IS 'World-space Y of zone centre. For RECT this equals (min_y+max_y)/2';
COMMENT ON COLUMN public.zones.inner_radius  IS 'Inner exclusion radius (ANNULUS only). Zero for RECT/CIRCLE';
COMMENT ON COLUMN public.zones.outer_radius  IS 'Outer boundary radius for CIRCLE/ANNULUS. Zero for RECT (use AABB instead)';
