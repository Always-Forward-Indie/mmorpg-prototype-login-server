-- Migration 069: Class Spawn Zones + Respawn Zone Bounds
-- Таблица стартовых спавн-зон для каждого класса (при первом входе персонажа в игру).
-- Расширение respawn_zones: добавление геометрических bounds для случайной точки респавна.

-- ============================================================================
-- 1. Class Spawn Zones — стартовые зоны спавна для классов
-- ============================================================================
CREATE TABLE public.class_spawn_zones (
    id          SERIAL PRIMARY KEY,
    class_id    integer NOT NULL UNIQUE REFERENCES public.character_class(id) ON DELETE CASCADE,
    zone_id     integer REFERENCES public.zones(id),
    min_x       real NOT NULL DEFAULT 0,
    max_x       real NOT NULL DEFAULT 0,
    min_y       real NOT NULL DEFAULT 0,
    max_y       real NOT NULL DEFAULT 0,
    min_z       real NOT NULL DEFAULT 0,
    max_z       real NOT NULL DEFAULT 0,
    shape_type  varchar(10) NOT NULL DEFAULT 'RECT',
    center_x    real NOT NULL DEFAULT 0,
    center_y    real NOT NULL DEFAULT 0,
    inner_radius real NOT NULL DEFAULT 0,
    outer_radius real NOT NULL DEFAULT 0
);

COMMENT ON TABLE public.class_spawn_zones IS 'Стартовые спавн-зоны для классов. Когда персонаж создаётся и впервые входит в игру, он появляется в случайной точке внутри зоны своего класса.';
COMMENT ON COLUMN public.class_spawn_zones.class_id     IS 'FK → character_class.id. Класс которому принадлежит зона спавна.';
COMMENT ON COLUMN public.class_spawn_zones.zone_id      IS 'FK → zones.id. Игровая зона, в которой находится спавн.';
COMMENT ON COLUMN public.class_spawn_zones.shape_type   IS 'Форма зоны: RECT (прямоугольник), CIRCLE (круг), ANNULUS (кольцо).';

CREATE INDEX idx_class_spawn_zones_class ON public.class_spawn_zones(class_id);

-- ============================================================================
-- 2. Respawn Zones — добавляем геометрические bounds
-- ============================================================================
ALTER TABLE public.respawn_zones
    ADD COLUMN min_x       real NOT NULL DEFAULT 0,
    ADD COLUMN max_x       real NOT NULL DEFAULT 0,
    ADD COLUMN min_y       real NOT NULL DEFAULT 0,
    ADD COLUMN max_y       real NOT NULL DEFAULT 0,
    ADD COLUMN min_z       real NOT NULL DEFAULT 0,
    ADD COLUMN max_z       real NOT NULL DEFAULT 0,
    ADD COLUMN shape_type  varchar(10) NOT NULL DEFAULT 'RECT',
    ADD COLUMN center_x    real NOT NULL DEFAULT 0,
    ADD COLUMN center_y    real NOT NULL DEFAULT 0,
    ADD COLUMN inner_radius real NOT NULL DEFAULT 0,
    ADD COLUMN outer_radius real NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.respawn_zones.min_x IS 'Минимальная X-координата для случайной точки респавна (0 = bounds не заданы, используется фиксированная точка x).';
COMMENT ON COLUMN public.respawn_zones.max_x IS 'Максимальная X-координата для случайной точки респавна.';
COMMENT ON COLUMN public.respawn_zones.min_y IS 'Минимальная Y-координата для случайной точки респавна.';
COMMENT ON COLUMN public.respawn_zones.max_y IS 'Максимальная Y-координата для случайной точки респавна.';
COMMENT ON COLUMN public.respawn_zones.min_z IS 'Минимальная Z-координата для случайной точки респавна.';
COMMENT ON COLUMN public.respawn_zones.max_z IS 'Максимальная Z-координата для случайной точки респавна.';
COMMENT ON COLUMN public.respawn_zones.shape_type IS 'Форма зоны: RECT (прямоугольник), CIRCLE (круг), ANNULUS (кольцо). По умолчанию RECT.';
COMMENT ON COLUMN public.respawn_zones.center_x IS 'X-центр для круглых/кольцевых зон.';
COMMENT ON COLUMN public.respawn_zones.center_y IS 'Y-центр для круглых/кольцевых зон.';
COMMENT ON COLUMN public.respawn_zones.inner_radius IS 'Внутренний радиус для ANNULUS (0 для CIRCLE).';
COMMENT ON COLUMN public.respawn_zones.outer_radius IS 'Внешний радиус для CIRCLE/ANNULUS.';
