-- =============================================================
-- Migration 001: Schema improvements
-- Date: 2026-03-03
-- Changes:
--   1. DROP users.session_key (дублирование с user_sessions)
--   2. spawn_zones: surrogate PK id, UNIQUE(zone_id, mob_id)
--   3. mob_position / npc_position: добавить zone_id FK → zones
--   4. character_current_state: вынести hot-state из characters
--   5. mob_attributes.mob_id / npc_attributes.npc_id: bigint → integer
--   6. Composite UNIQUE индексы на attribute-таблицах
-- =============================================================

BEGIN;

-- -------------------------------------------------------------
-- 1. Remove legacy session_key from users
--    (полноценная сессионная таблица user_sessions заменяет это)
-- -------------------------------------------------------------
ALTER TABLE public.users DROP COLUMN session_key;


-- -------------------------------------------------------------
-- 2. spawn_zones: surrogate PK + UNIQUE(zone_id, mob_id)
--    Текущая проблема: PK = zone_id → один тип моба на зону.
--    После: zone_id — просто идентификатор зоны спавна,
--    можно иметь N мобов в одной зоне.
-- -------------------------------------------------------------
ALTER TABLE public.spawn_zones DROP CONSTRAINT spawn_zones_pkey;

ALTER TABLE public.spawn_zones
    ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;

ALTER TABLE public.spawn_zones
    ADD CONSTRAINT spawn_zones_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX uq_spawn_zone_mob
    ON public.spawn_zones (zone_id, mob_id);

COMMENT ON COLUMN public.spawn_zones.zone_id IS
    'Идентификатор зоны спавна (группирующий ключ). В будущем — FK → zones(id)';
COMMENT ON COLUMN public.spawn_zones.id IS
    'Surrogate PK. Позволяет несколько mob_id на один zone_id';


-- -------------------------------------------------------------
-- 3. mob_position / npc_position: добавить zone_id → zones
--    NULL = позиция не привязана к zone (легаси/оффлайн)
-- -------------------------------------------------------------
ALTER TABLE public.mob_position
    ADD COLUMN zone_id integer;

ALTER TABLE public.mob_position
    ADD CONSTRAINT fk_mob_position_zone
        FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;

CREATE INDEX ix_mob_position_zone ON public.mob_position (zone_id);

COMMENT ON COLUMN public.mob_position.zone_id IS
    'Зона, в которой размещён моб. NULL = не привязан к зоне';


ALTER TABLE public.npc_position
    ADD COLUMN zone_id integer;

ALTER TABLE public.npc_position
    ADD CONSTRAINT fk_npc_position_zone
        FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;

CREATE INDEX ix_npc_position_zone ON public.npc_position (zone_id);

COMMENT ON COLUMN public.npc_position.zone_id IS
    'Зона, в которой размещён NPC. NULL = не привязан к зоне';


-- -------------------------------------------------------------
-- 4. character_current_state
--    Выносим горячее боевое состояние из characters.
--    characters обновляется редко (level up, bind, logout).
--    character_current_state пишется каждый тик боя — отдельная
--    строка, мало весит, минимальный lock contention.
-- -------------------------------------------------------------
CREATE TABLE public.character_current_state (
    character_id  bigint  NOT NULL,
    current_health integer NOT NULL DEFAULT 1,
    current_mana   integer NOT NULL DEFAULT 1,
    is_dead        boolean NOT NULL DEFAULT false,
    updated_at     timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT character_current_state_pkey
        PRIMARY KEY (character_id),
    CONSTRAINT fk_char_current_state
        FOREIGN KEY (character_id) REFERENCES public.characters(id)
        ON DELETE CASCADE
);

COMMENT ON TABLE public.character_current_state IS
    'Горячее состояние персонажа (HP/MP/смерть). Пишется часто (каждый тик боя). Хранить отдельно от персистентных данных characters';
COMMENT ON COLUMN public.character_current_state.current_health IS
    'Текущие HP. Меняются в бою каждые N мс';
COMMENT ON COLUMN public.character_current_state.current_mana IS
    'Текущая мана. Меняется при кастах и регене';
COMMENT ON COLUMN public.character_current_state.is_dead IS
    'Флаг смерти. TRUE пока персонаж не воскрешён';
COMMENT ON COLUMN public.character_current_state.updated_at IS
    'Время последнего обновления состояния (для staleness-проверок)';

-- Мигрируем существующие данные
INSERT INTO public.character_current_state
    (character_id, current_health, current_mana, is_dead)
SELECT id, current_health, current_mana, is_dead
FROM public.characters;

-- Удаляем колонки из characters
ALTER TABLE public.characters DROP COLUMN current_health;
ALTER TABLE public.characters DROP COLUMN current_mana;
ALTER TABLE public.characters DROP COLUMN is_dead;


-- -------------------------------------------------------------
-- 5. Приводим типы FK к типу PK
--    mob.id = integer, но mob_attributes.mob_id = bigint → integer
--    npc.id = integer, но npc_attributes.npc_id = bigint → integer
-- -------------------------------------------------------------

-- mob_attributes
ALTER TABLE public.mob_attributes
    DROP CONSTRAINT mob_attributes_mob_id_fkey;
ALTER TABLE public.mob_attributes
    ALTER COLUMN mob_id TYPE integer;
ALTER TABLE public.mob_attributes
    ADD CONSTRAINT mob_attributes_mob_id_fkey
        FOREIGN KEY (mob_id) REFERENCES public.mob(id);

-- npc_attributes
ALTER TABLE public.npc_attributes
    DROP CONSTRAINT npc_attributes_npc_id_fkey;
ALTER TABLE public.npc_attributes
    ALTER COLUMN npc_id TYPE integer;
ALTER TABLE public.npc_attributes
    ADD CONSTRAINT npc_attributes_npc_id_fkey
        FOREIGN KEY (npc_id) REFERENCES public.npc(id);


-- -------------------------------------------------------------
-- 6. Composite UNIQUE индексы на attribute-таблицах
--    Самый частый запрос: "все атрибуты персонажа/моба/NPC"
--    SELECT * WHERE character_id = X — сейчас seq scan!
--    UNIQUE гарантирует что дублей атрибутов не будет.
-- -------------------------------------------------------------
CREATE UNIQUE INDEX ix_character_attributes_char_attr
    ON public.character_attributes (character_id, attribute_id);

CREATE UNIQUE INDEX ix_mob_attributes_mob_attr
    ON public.mob_attributes (mob_id, attribute_id);

CREATE UNIQUE INDEX ix_npc_attributes_npc_attr
    ON public.npc_attributes (npc_id, attribute_id);


COMMIT;
