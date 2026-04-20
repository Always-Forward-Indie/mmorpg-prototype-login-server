-- Migration 068: Class Starter Items
-- Таблица стартовых предметов, выдаваемых персонажу при создании в зависимости от класса.
-- Скилы по умолчанию при создании уже управляются через class_skill_tree.is_default = true.

CREATE TABLE public.class_starter_items (
    id            SERIAL PRIMARY KEY,
    class_id      integer NOT NULL REFERENCES public.character_class(id) ON DELETE CASCADE,
    item_id       integer NOT NULL REFERENCES public.items(id) ON DELETE CASCADE,
    quantity      integer NOT NULL DEFAULT 1,
    slot_index    smallint,          -- NULL = автоприсвоение следующего свободного слота
    durability_current integer       -- NULL = взять durability_max из items
);

COMMENT ON TABLE public.class_starter_items IS 'Предметы, автоматически выдаваемые персонажу при создании в зависимости от класса. Количество и слот настраиваются. Durability = NULL означает полную прочность по умолчанию.';
COMMENT ON COLUMN public.class_starter_items.class_id        IS 'FK → character_class.id. Класс которому выдаётся предмет.';
COMMENT ON COLUMN public.class_starter_items.item_id         IS 'FK → items.id. Шаблон предмета для выдачи.';
COMMENT ON COLUMN public.class_starter_items.quantity        IS 'Количество предметов в стаке.';
COMMENT ON COLUMN public.class_starter_items.slot_index      IS 'Позиция в инвентаре. NULL = сервер назначает автоматически.';
COMMENT ON COLUMN public.class_starter_items.durability_current IS 'Начальная прочность. NULL = использовать durability_max из таблицы items.';

CREATE INDEX idx_class_starter_items_class ON public.class_starter_items(class_id);

-- Стартовые предметы для Mage (class_id = 1): деревянный посох + 50 золота
INSERT INTO public.class_starter_items (class_id, item_id, quantity, slot_index, durability_current)
SELECT 1, id, 1, 0, NULL::integer FROM public.items WHERE slug = 'wooden_staff'
UNION ALL
SELECT 1, id, 50, 1, NULL::integer FROM public.items WHERE slug = 'gold_coin';

-- Стартовые предметы для Warrior (class_id = 2): железный меч + щит + 50 золота
INSERT INTO public.class_starter_items (class_id, item_id, quantity, slot_index, durability_current)
SELECT 2, id, 1, 0, NULL::integer FROM public.items WHERE slug = 'iron_sworld'
UNION ALL
SELECT 2, id, 1, 1, NULL::integer FROM public.items WHERE slug = 'wooden_shield'
UNION ALL
SELECT 2, id, 50, 2, NULL::integer FROM public.items WHERE slug = 'gold_coin';
