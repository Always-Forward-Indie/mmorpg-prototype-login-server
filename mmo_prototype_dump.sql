--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5 (Debian 15.5-1.pgdg120+1)
-- Dumped by pg_dump version 15.5 (Debian 15.5-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: node_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.node_type AS ENUM (
    'line',
    'choice_hub',
    'action',
    'jump',
    'end'
);


--
-- Name: TYPE node_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.node_type IS 'Тип узла диалога: line/choice_hub/action/jump/end';


--
-- Name: quest_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.quest_state AS ENUM (
    'offered',
    'active',
    'completed',
    'turned_in',
    'failed'
);


--
-- Name: TYPE quest_state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.quest_state IS 'Состояние квеста у игрока';


--
-- Name: quest_step_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.quest_step_type AS ENUM (
    'collect',
    'kill',
    'talk',
    'reach',
    'custom'
);


--
-- Name: TYPE quest_step_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.quest_step_type IS 'Тип шага квеста (структура в params JSON)';


--
-- Name: game_config_set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.game_config_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: character_permanent_modifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_permanent_modifiers (
    id bigint NOT NULL,
    character_id bigint DEFAULT 0 NOT NULL,
    attribute_id integer DEFAULT 0 NOT NULL,
    value numeric DEFAULT 0 NOT NULL,
    source_type character varying(30) DEFAULT 'gm'::character varying NOT NULL,
    source_id integer,
    CONSTRAINT character_permanent_modifiers_source_type_check CHECK (((source_type)::text = ANY ((ARRAY['gm'::character varying, 'quest'::character varying, 'achievement'::character varying, 'event'::character varying, 'admin'::character varying])::text[])))
);


--
-- Name: TABLE character_permanent_modifiers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_permanent_modifiers IS 'Постоянные модификаторы характеристик персонажа из внешних источников. Источники: квест, достижение, GM-правка, событие. НЕ является кешем — это источник правды для перманентных бонусов. Базовые статы класса хранятся в class_stat_formula, бонусы шмота — в character_equipment.';


--
-- Name: COLUMN character_permanent_modifiers.attribute_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_permanent_modifiers.attribute_id IS 'Характеристика из entity_attributes';


--
-- Name: COLUMN character_permanent_modifiers.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_permanent_modifiers.value IS 'Значение бонуса (может быть отрицательным для штрафов)';


--
-- Name: COLUMN character_permanent_modifiers.source_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_permanent_modifiers.source_type IS 'Источник: gm | quest | achievement | event | admin';


--
-- Name: COLUMN character_permanent_modifiers.source_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_permanent_modifiers.source_id IS 'ID источника (quest.id / achievement.id / NULL для GM)';


--
-- Name: character_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.character_permanent_modifiers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.character_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: entity_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entity_attributes (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL
);


--
-- Name: TABLE entity_attributes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.entity_attributes IS 'Справочник всех атрибутов игровых сущностей (сила, ловкость, физический урон и т.д.). Единый для персонажей, мобов, NPC и предметов. Использовать slug как стабильный ключ — id может меняться между окружениями.';


--
-- Name: COLUMN entity_attributes.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.entity_attributes.id IS 'Суррогатный PK. В коде ссылаться по slug, не по числу.';


--
-- Name: COLUMN entity_attributes.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.entity_attributes.name IS 'Отображаемое название атрибута (EN), например "Physical Attack".';


--
-- Name: COLUMN entity_attributes.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.entity_attributes.slug IS 'Машиночитаемый ключ атрибута, уникален. Примеры: strength, agility, physical_attack, physical_defense, crit_chance, evasion, heal_on_use, hunger_restore. Использовать в коде вместо числового id.';


--
-- Name: character_attributes_id_seq1; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.entity_attributes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.character_attributes_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: character_class; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_class (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50),
    description text
);


--
-- Name: TABLE character_class; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_class IS 'Классы персонажей (воин, маг и т.д.)';


--
-- Name: character_class_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.character_class ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.character_class_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: character_current_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_current_state (
    character_id bigint NOT NULL,
    current_health integer DEFAULT 1 NOT NULL,
    current_mana integer DEFAULT 1 NOT NULL,
    is_dead boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE character_current_state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_current_state IS 'Горячее состояние персонажа (HP/MP/смерть). Пишется часто (каждый тик боя). Хранить отдельно от персистентных данных characters';


--
-- Name: COLUMN character_current_state.current_health; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_current_state.current_health IS 'Текущие HP. Меняются в бою каждые N мс';


--
-- Name: COLUMN character_current_state.current_mana; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_current_state.current_mana IS 'Текущая мана. Меняется при кастах и регене';


--
-- Name: COLUMN character_current_state.is_dead; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_current_state.is_dead IS 'Флаг смерти. TRUE пока персонаж не воскрешён';


--
-- Name: COLUMN character_current_state.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_current_state.updated_at IS 'Время последнего обновления состояния (для staleness-проверок)';


--
-- Name: character_equipment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_equipment (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    equip_slot_id integer NOT NULL,
    inventory_item_id bigint NOT NULL,
    equipped_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE character_equipment; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_equipment IS 'Экипированные предметы персонажа. Ссылается на player_inventory, а не на items напрямую — чтобы учитывать состояние конкретного инстанса (прочность). Один персонаж не может занять один слот дважды (UNIQUE на character_id + equip_slot_id).';


--
-- Name: COLUMN character_equipment.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_equipment.id IS 'Суррогатный PK.';


--
-- Name: COLUMN character_equipment.character_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_equipment.character_id IS 'FK → characters.id.';


--
-- Name: COLUMN character_equipment.equip_slot_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_equipment.equip_slot_id IS 'FK → equip_slots.id. Слот экипировки (голова, грудь, оружие и т.д.).';


--
-- Name: COLUMN character_equipment.inventory_item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_equipment.inventory_item_id IS 'FK → player_inventory.id. Конкретный инстанс предмета из инвентаря персонажа.';


--
-- Name: COLUMN character_equipment.equipped_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_equipment.equipped_at IS 'Метка времени надевания. DEFAULT now().';


--
-- Name: character_equipment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.character_equipment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: character_equipment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.character_equipment_id_seq OWNED BY public.character_equipment.id;


--
-- Name: character_genders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_genders (
    id smallint NOT NULL,
    name character varying(20) NOT NULL,
    label character varying(30) NOT NULL
);


--
-- Name: TABLE character_genders; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_genders IS 'Справочник полов персонажей: 0=мужской, 1=женский, 2=не задан';


--
-- Name: character_position; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_position (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    x numeric(11,2) NOT NULL,
    y numeric(11,2) NOT NULL,
    z numeric(11,2) NOT NULL,
    zone_id integer,
    rot_z double precision DEFAULT 0 NOT NULL
);


--
-- Name: TABLE character_position; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_position IS 'Текущая позиция персонажа в мире. Одна запись на персонажа';


--
-- Name: COLUMN character_position.zone_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_position.zone_id IS 'Зона, в которой находится персонаж. NULL = не в зоне/оффлайн';


--
-- Name: COLUMN character_position.rot_z; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_position.rot_z IS 'Угол поворота персонажа по оси Z (направление взгляда, в радианах)';


--
-- Name: character_position_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.character_position ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.character_position_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: character_skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_skills (
    id integer NOT NULL,
    character_id bigint NOT NULL,
    skill_id integer NOT NULL,
    current_level integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE character_skills; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_skills IS 'Скиллы, изученные персонажем, с их текущим уровнем';


--
-- Name: COLUMN character_skills.current_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_skills.current_level IS 'Текущий уровень изученного скилла';


--
-- Name: character_skills_id_seq1; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.character_skills_id_seq1
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: character_skills_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.character_skills_id_seq1 OWNED BY public.character_skills.id;


--
-- Name: characters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.characters (
    id bigint NOT NULL,
    name character varying(20) NOT NULL,
    owner_id bigint NOT NULL,
    class_id integer DEFAULT 1 NOT NULL,
    race_id integer DEFAULT 1 NOT NULL,
    experience_points bigint DEFAULT 0 NOT NULL,
    level integer DEFAULT 0 NOT NULL,
    radius integer DEFAULT 100 NOT NULL,
    free_skill_points smallint DEFAULT 0 NOT NULL,
    gender smallint DEFAULT 0 NOT NULL,
    account_slot smallint DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_online_at timestamp with time zone,
    deleted_at timestamp with time zone,
    play_time_sec bigint DEFAULT 0 NOT NULL,
    bind_zone_id integer,
    bind_x double precision,
    bind_y double precision,
    bind_z double precision,
    appearance jsonb
);


--
-- Name: TABLE characters; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.characters IS 'Персонажи игроков. Привязаны к аккаунту через owner_id';


--
-- Name: COLUMN characters.radius; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.radius IS 'Радиус коллизии/взаимодействия в игровых единицах';


--
-- Name: COLUMN characters.free_skill_points; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.free_skill_points IS 'Очки скиллов, ожидающие распределения игроком';


--
-- Name: COLUMN characters.gender; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.gender IS '0=male, 1=female';


--
-- Name: COLUMN characters.account_slot; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.account_slot IS 'Порядок на экране выбора персонажей';


--
-- Name: COLUMN characters.last_online_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.last_online_at IS 'Время последнего выхода из игры';


--
-- Name: COLUMN characters.deleted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.deleted_at IS 'Soft delete — персонаж удалён, но восстановим';


--
-- Name: COLUMN characters.play_time_sec; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.play_time_sec IS 'Суммарное время игры в секундах';


--
-- Name: COLUMN characters.bind_zone_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.bind_zone_id IS 'Зона точки воскрешения/возврата';


--
-- Name: COLUMN characters.bind_x; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.bind_x IS 'X-координата точки привязки воскрешения';


--
-- Name: COLUMN characters.bind_y; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.bind_y IS 'Y-координата точки привязки воскрешения';


--
-- Name: COLUMN characters.bind_z; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.bind_z IS 'Z-координата точки привязки воскрешения';


--
-- Name: COLUMN characters.appearance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.characters.appearance IS 'Кастомизация внешности: цвет волос/глаз, рост и т.д. (JSONB)';


--
-- Name: characters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.characters ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.characters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: class_skill_tree; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.class_skill_tree (
    id integer NOT NULL,
    class_id integer NOT NULL,
    skill_id integer NOT NULL,
    required_level integer DEFAULT 1 NOT NULL,
    is_default boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE class_skill_tree; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.class_skill_tree IS 'Шаблон доступных скилов для класса. is_default=true — скил выдаётся автоматически при создании персонажа. required_level — минимальный уровень персонажа для изучения скила. Факт выученных скилов хранится в character_skills.';


--
-- Name: COLUMN class_skill_tree.is_default; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_skill_tree.is_default IS 'TRUE = скилл выдаётся автоматически при создании персонажа данного класса';


--
-- Name: class_skill_tree_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.class_skill_tree_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: class_skill_tree_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.class_skill_tree_id_seq OWNED BY public.class_skill_tree.id;


--
-- Name: class_stat_formula; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.class_stat_formula (
    class_id integer NOT NULL,
    attribute_id integer NOT NULL,
    base_value numeric(10,2) DEFAULT 0 NOT NULL,
    multiplier numeric(10,4) DEFAULT 0 NOT NULL,
    exponent numeric(6,4) DEFAULT 1.0000 NOT NULL,
    CONSTRAINT class_stat_formula_exponent_check CHECK ((exponent > (0)::numeric))
);


--
-- Name: TABLE class_stat_formula; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.class_stat_formula IS 'Формула роста базовых характеристик класса по уровням. Итоговый стат = base_value + multiplier * level^exponent. Заменяет class_base_stats. Используется game server при логине и левел-апе для пересчёта character_permanent_modifiers.';


--
-- Name: COLUMN class_stat_formula.class_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_stat_formula.class_id IS 'Класс персонажа';


--
-- Name: COLUMN class_stat_formula.attribute_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_stat_formula.attribute_id IS 'Характеристика из entity_attributes';


--
-- Name: COLUMN class_stat_formula.base_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_stat_formula.base_value IS 'Значение характеристики на 1 уровне';


--
-- Name: COLUMN class_stat_formula.multiplier; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_stat_formula.multiplier IS 'Множитель роста: ROUND(base_value + multiplier * level^exponent)';


--
-- Name: COLUMN class_stat_formula.exponent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_stat_formula.exponent IS 'Степень кривой: 1.0 = линейный, >1.0 = ускоряется, <1.0 = замедляется';


--
-- Name: currency_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currency_transactions (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    amount bigint NOT NULL,
    reason_type character varying(50) NOT NULL,
    source_id bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE currency_transactions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.currency_transactions IS 'Полный журнал всех денежных операций персонажей (ledger-подход)';


--
-- Name: COLUMN currency_transactions.amount; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.currency_transactions.amount IS 'Положительное = доход, отрицательное = расход';


--
-- Name: COLUMN currency_transactions.reason_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.currency_transactions.reason_type IS 'quest_reward, vendor_buy, vendor_sell, drop, gm_grant, trade';


--
-- Name: COLUMN currency_transactions.source_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.currency_transactions.source_id IS 'ID источника (quest_id, vendor_npc_id и т.д.) в зависимости от reason_type';


--
-- Name: COLUMN currency_transactions.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.currency_transactions.created_at IS 'Время транзакции';


--
-- Name: currency_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.currency_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currency_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.currency_transactions_id_seq OWNED BY public.currency_transactions.id;


--
-- Name: dialogue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dialogue (
    id bigint NOT NULL,
    slug text NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    start_node_id bigint
);


--
-- Name: TABLE dialogue; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.dialogue IS 'Диалог как граф. У NPC может быть несколько диалогов.';


--
-- Name: COLUMN dialogue.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue.slug IS 'Уникальный ключ диалога для поиска/линковки';


--
-- Name: COLUMN dialogue.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue.version IS 'Версия контента (для редактора/каталогизации)';


--
-- Name: COLUMN dialogue.start_node_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue.start_node_id IS 'ID стартового узла (dialogue_node.id)';


--
-- Name: dialogue_edge; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dialogue_edge (
    id bigint NOT NULL,
    from_node_id bigint NOT NULL,
    to_node_id bigint NOT NULL,
    order_index integer DEFAULT 0 NOT NULL,
    client_choice_key text,
    condition_group jsonb,
    action_group jsonb,
    hide_if_locked boolean DEFAULT false NOT NULL,
    CONSTRAINT dialogue_edge_order_ck CHECK ((order_index >= 0))
);


--
-- Name: TABLE dialogue_edge; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.dialogue_edge IS 'Варианты выбора (рёбра графа) из узла в узел';


--
-- Name: COLUMN dialogue_edge.from_node_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_edge.from_node_id IS 'Исходный узел (кнопка показывается на нём)';


--
-- Name: COLUMN dialogue_edge.to_node_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_edge.to_node_id IS 'Узел-назначение при выборе';


--
-- Name: COLUMN dialogue_edge.order_index; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_edge.order_index IS 'Порядок отображения кнопок на клиенте';


--
-- Name: COLUMN dialogue_edge.client_choice_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_edge.client_choice_key IS 'Ключ текста варианта для клиента';


--
-- Name: COLUMN dialogue_edge.condition_group; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_edge.condition_group IS 'JSON-условия доступности варианта';


--
-- Name: COLUMN dialogue_edge.action_group; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_edge.action_group IS 'JSON-действия, применяемые по клику';


--
-- Name: COLUMN dialogue_edge.hide_if_locked; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_edge.hide_if_locked IS 'Если TRUE — скрыть вариант при невыполненных условиях';


--
-- Name: dialogue_edge_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dialogue_edge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dialogue_edge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dialogue_edge_id_seq OWNED BY public.dialogue_edge.id;


--
-- Name: dialogue_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dialogue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dialogue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dialogue_id_seq OWNED BY public.dialogue.id;


--
-- Name: dialogue_node; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dialogue_node (
    id bigint NOT NULL,
    dialogue_id bigint NOT NULL,
    type public.node_type NOT NULL,
    speaker_npc_id bigint,
    client_node_key text,
    condition_group jsonb,
    action_group jsonb,
    jump_target_node_id bigint,
    CONSTRAINT dialogue_node_jump_target_ck CHECK (((type <> 'jump'::public.node_type) OR (jump_target_node_id IS NOT NULL)))
);


--
-- Name: TABLE dialogue_node; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.dialogue_node IS 'Узел графа диалога (реплика, выбор, действие, прыжок, конец)';


--
-- Name: COLUMN dialogue_node.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_node.type IS 'Тип узла: line/choice_hub/action/jump/end';


--
-- Name: COLUMN dialogue_node.speaker_npc_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_node.speaker_npc_id IS 'Идентификатор говорящего NPC (для клиента)';


--
-- Name: COLUMN dialogue_node.client_node_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_node.client_node_key IS 'Ключ строки/контента на клиенте';


--
-- Name: COLUMN dialogue_node.condition_group; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_node.condition_group IS 'JSON-условия: когда узел актуален (иначе пропуск)';


--
-- Name: COLUMN dialogue_node.action_group; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_node.action_group IS 'JSON-действия, исполняемые при входе в action-узел';


--
-- Name: COLUMN dialogue_node.jump_target_node_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dialogue_node.jump_target_node_id IS 'Целевой узел для прыжка (type=jump)';


--
-- Name: dialogue_node_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dialogue_node_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dialogue_node_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dialogue_node_id_seq OWNED BY public.dialogue_node.id;


--
-- Name: equip_slot; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equip_slot (
    id smallint NOT NULL,
    slug character varying(30) NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: TABLE equip_slot; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.equip_slot IS 'Справочник слотов экипировки (голова, грудь, главная рука и т.д.)';


--
-- Name: exp_for_level; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exp_for_level (
    id integer NOT NULL,
    level integer NOT NULL,
    experience_points bigint NOT NULL
);


--
-- Name: TABLE exp_for_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.exp_for_level IS 'Таблица порогов опыта: сколько XP нужно для достижения каждого уровня';


--
-- Name: COLUMN exp_for_level.experience_points; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.exp_for_level.experience_points IS 'Суммарный опыт, необходимый для достижения данного уровня';


--
-- Name: exp_for_level_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.exp_for_level ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.exp_for_level_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: game_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_config (
    key text NOT NULL,
    value text NOT NULL,
    value_type text DEFAULT 'float'::text NOT NULL,
    description text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT game_config_value_type_ck CHECK ((value_type = ANY (ARRAY['int'::text, 'float'::text, 'bool'::text, 'string'::text])))
);


--
-- Name: TABLE game_config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.game_config IS 'Геймплейные константы и параметры баланса. Читаются при старте game-server и отправляются в chunk-server. Изменения применяются без перезапуска через GM-команду reload.';


--
-- Name: COLUMN game_config.key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_config.key IS 'Уникальный ключ параметра. Формат: namespace.param_name. Примеры: combat.defense_formula_k, aggro.base_radius.';


--
-- Name: COLUMN game_config.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_config.value IS 'Значение в виде строки. Интерпретируется согласно value_type.';


--
-- Name: COLUMN game_config.value_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_config.value_type IS 'Тип значения: int | float | bool | string. Используется GameConfigService для корректного приведения типа.';


--
-- Name: COLUMN game_config.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_config.description IS 'Описание параметра и его влияния на геймплей. Для GM-UI и документации.';


--
-- Name: COLUMN game_config.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_config.updated_at IS 'Автообновляется при изменении строки (через триггер ниже).';


--
-- Name: gm_action_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gm_action_log (
    id bigint NOT NULL,
    gm_user_id bigint,
    action_type character varying(100) NOT NULL,
    target_type character varying(50) NOT NULL,
    target_id bigint,
    old_value jsonb,
    new_value jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE gm_action_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.gm_action_log IS 'Полный аудит-лог действий GM и администраторов';


--
-- Name: COLUMN gm_action_log.old_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.gm_action_log.old_value IS 'Состояние до изменения (JSONB)';


--
-- Name: COLUMN gm_action_log.new_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.gm_action_log.new_value IS 'Состояние после изменения (JSONB)';


--
-- Name: gm_action_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gm_action_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gm_action_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gm_action_log_id_seq OWNED BY public.gm_action_log.id;


--
-- Name: item_attributes_mapping; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_attributes_mapping (
    id bigint NOT NULL,
    item_id bigint NOT NULL,
    attribute_id integer NOT NULL,
    value integer NOT NULL,
    apply_on text DEFAULT 'equip'::text NOT NULL,
    CONSTRAINT item_attributes_mapping_apply_on_ck CHECK ((apply_on = ANY (ARRAY['equip'::text, 'use'::text])))
);


--
-- Name: TABLE item_attributes_mapping; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.item_attributes_mapping IS 'Атрибуты предметов с их значениями и режимом применения. apply_on=equip → бонус суммируется в стат персонажа при надевании. apply_on=use   → создаётся player_active_effect при использовании предмета. FK attribute_id → entity_attributes (единый справочник атрибутов).';


--
-- Name: COLUMN item_attributes_mapping.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_attributes_mapping.id IS 'Суррогатный PK.';


--
-- Name: COLUMN item_attributes_mapping.item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_attributes_mapping.item_id IS 'FK → items.id. Предмет-шаблон, к которому привязан атрибут.';


--
-- Name: COLUMN item_attributes_mapping.attribute_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_attributes_mapping.attribute_id IS 'Атрибут из entity_attributes (единый справочник для персонажей, мобов и предметов). Экипируемые предметы (apply_on=equip): physical_attack, strength, crit_chance и т.д. Используемые предметы (apply_on=use): heal_on_use, hunger_restore, hp_regen_per_s и т.д.';


--
-- Name: COLUMN item_attributes_mapping.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_attributes_mapping.value IS 'Числовое значение атрибута. Интерпретируется по slug: physical_attack=10 → +10 к атаке; heal_on_use=50 → восстановить 50 HP.';


--
-- Name: COLUMN item_attributes_mapping.apply_on; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_attributes_mapping.apply_on IS 'equip = суммируется в стат персонажа при надевании (броня, оружие). use   = создаёт player_active_effect при использовании предмета (зелья, еда).';


--
-- Name: item_attributes_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.item_attributes_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.item_attributes_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: item_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL
);


--
-- Name: TABLE item_types; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.item_types IS 'Справочник типов предметов: weapon, armor, accessory, potion, food, quest_item, resource, currency, container.';


--
-- Name: COLUMN item_types.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_types.id IS 'Суррогатный PK.';


--
-- Name: COLUMN item_types.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_types.name IS 'Отображаемое название типа предмета.';


--
-- Name: COLUMN item_types.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_types.slug IS 'Машиночитаемый ключ типа, уникален. Примеры: weapon, armor, potion, food, quest_item, resource.';


--
-- Name: item_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.item_types ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.item_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL,
    description text,
    is_quest_item boolean DEFAULT false NOT NULL,
    item_type bigint NOT NULL,
    weight double precision DEFAULT 0.0 NOT NULL,
    rarity_id bigint DEFAULT 1 NOT NULL,
    stack_max bigint DEFAULT 64 NOT NULL,
    is_container boolean DEFAULT false NOT NULL,
    is_durable boolean DEFAULT false NOT NULL,
    is_tradable boolean DEFAULT true NOT NULL,
    durability_max bigint DEFAULT 100 NOT NULL,
    vendor_price_buy bigint DEFAULT 1 NOT NULL,
    vendor_price_sell bigint DEFAULT 1 NOT NULL,
    equip_slot bigint,
    level_requirement bigint DEFAULT 0 NOT NULL,
    is_equippable boolean DEFAULT false NOT NULL,
    is_harvest boolean DEFAULT false NOT NULL,
    is_usable boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE items; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.items IS 'Каталог предметов игры — шаблоны, не инстансы. Инстансы (конкретные предметы персонажа) хранятся в player_inventory. Поля is_equippable / is_usable / is_quest_item определяют поведение предмета.';


--
-- Name: COLUMN items.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.id IS 'Суррогатный PK шаблона предмета.';


--
-- Name: COLUMN items.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.name IS 'Отображаемое название предмета.';


--
-- Name: COLUMN items.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.slug IS 'Машиночитаемый уникальный ключ. Используется в коде и конфигах.';


--
-- Name: COLUMN items.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.description IS 'Текстовое описание предмета для UI-тултипа. NULL допустим.';


--
-- Name: COLUMN items.is_quest_item; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.is_quest_item IS 'TRUE = квестовый предмет, не выпадает из инвентаря';


--
-- Name: COLUMN items.item_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.item_type IS 'FK → item_types.id. Тип предмета (оружие, броня, зелье и т.д.).';


--
-- Name: COLUMN items.weight; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.weight IS 'Вес предмета в килограммах. Используется если включена система веса инвентаря.';


--
-- Name: COLUMN items.rarity_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.rarity_id IS 'FK → item_rarity.id. Редкость: обычный, необычный, редкий и т.д. DEFAULT 1 = обычный.';


--
-- Name: COLUMN items.stack_max; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.stack_max IS 'Максимальное количество предметов в одном стаке инвентаря';


--
-- Name: COLUMN items.is_container; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.is_container IS 'TRUE = предмет является сумкой/контейнером';


--
-- Name: COLUMN items.is_durable; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.is_durable IS 'TRUE = предмет имеет прочность и изнашивается';


--
-- Name: COLUMN items.is_tradable; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.is_tradable IS 'TRUE = предмет можно передать другому игроку или продать';


--
-- Name: COLUMN items.durability_max; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.durability_max IS 'Максимальная прочность (relevantно если is_durable = true)';


--
-- Name: COLUMN items.vendor_price_buy; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.vendor_price_buy IS 'Цена покупки у NPC-торговца (медь)';


--
-- Name: COLUMN items.vendor_price_sell; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.vendor_price_sell IS 'Цена продажи NPC-торговцу (медь). Обычно ниже buy';


--
-- Name: COLUMN items.equip_slot; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.equip_slot IS 'Слот экипировки (FK → equip_slot). NULL = неэкипируемый предмет';


--
-- Name: COLUMN items.level_requirement; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.level_requirement IS 'Минимальный уровень персонажа для экипировки/использования';


--
-- Name: COLUMN items.is_equippable; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.is_equippable IS 'TRUE = предмет можно надеть в слот экипировки';


--
-- Name: COLUMN items.is_harvest; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.is_harvest IS 'TRUE = добываемый ресурс (трава, руда и т.д.)';


--
-- Name: COLUMN items.is_usable; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.is_usable IS 'TRUE = предмет можно использовать из инвентаря (зелья, свитки, еда). При использовании атрибуты (apply_on=''use'') из item_attributes_mapping создают запись в player_active_effect с таймером expires_at.';


--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: items_rarity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items_rarity (
    id smallint NOT NULL,
    name character varying(30) NOT NULL,
    color_hex character(7) NOT NULL,
    slug character varying(30)
);


--
-- Name: TABLE items_rarity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.items_rarity IS 'Редкости предметов с цветовым кодом для UI';


--
-- Name: COLUMN items_rarity.color_hex; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items_rarity.color_hex IS 'Hex-цвет для подсветки предмета в UI (например #00ff00 для необычного)';


--
-- Name: mob; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mob (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    race_id integer DEFAULT 1 NOT NULL,
    level integer NOT NULL,
    spawn_health integer DEFAULT 1 NOT NULL,
    spawn_mana integer DEFAULT 1 NOT NULL,
    is_aggressive boolean DEFAULT false NOT NULL,
    is_dead boolean DEFAULT false NOT NULL,
    slug character varying(50),
    radius integer DEFAULT 100 NOT NULL,
    base_xp integer DEFAULT 1 NOT NULL,
    rank_id integer DEFAULT 1 NOT NULL,
    aggro_range double precision DEFAULT 400.0 NOT NULL,
    attack_range double precision DEFAULT 150.0 NOT NULL,
    attack_cooldown double precision DEFAULT 2.0 NOT NULL,
    chase_multiplier double precision DEFAULT 2.0 NOT NULL,
    patrol_speed double precision DEFAULT 1.0 NOT NULL,
    is_social boolean DEFAULT false NOT NULL,
    chase_duration double precision DEFAULT 30.0 NOT NULL,
    flee_hp_threshold double precision DEFAULT 0.0 NOT NULL,
    ai_archetype character varying(20) DEFAULT 'melee'::character varying NOT NULL,
    CONSTRAINT mob_ai_archetype_check CHECK (((ai_archetype)::text = ANY ((ARRAY['melee'::character varying, 'caster'::character varying, 'ranged'::character varying, 'support'::character varying, 'summoner'::character varying, 'lurker'::character varying])::text[]))),
    CONSTRAINT mob_flee_hp_threshold_check CHECK (((flee_hp_threshold >= (0.0)::double precision) AND (flee_hp_threshold < (1.0)::double precision)))
);


--
-- Name: TABLE mob; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mob IS 'Шаблоны мобов. Это не игровые инстансы, а определения спавна';


--
-- Name: COLUMN mob.spawn_health; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.spawn_health IS 'Стартовое здоровье экземпляра при спавне. НЕ текущее состояние — runtime-хп моба хранится в памяти chunk-server.';


--
-- Name: COLUMN mob.spawn_mana; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.spawn_mana IS 'Стартовая мана экземпляра при спавне. НЕ текущее состояние — runtime-мана моба хранится в памяти chunk-server.';


--
-- Name: COLUMN mob.is_aggressive; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.is_aggressive IS 'TRUE = атакует игроков приближающихся в радиус агра';


--
-- Name: COLUMN mob.is_dead; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.is_dead IS 'TRUE = шаблон моба отмечен как "мёртвый" (для дизайна, не инстанс)';


--
-- Name: COLUMN mob.radius; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.radius IS 'Радиус коллизии и зоны агра в игровых единицах';


--
-- Name: COLUMN mob.base_xp; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.base_xp IS 'Базовый опыт за убийство. Итоговый = base_xp × mob_ranks.mult';


--
-- Name: COLUMN mob.rank_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.rank_id IS 'Ранг моба (FK → mob_ranks). Влияет на множитель характеристик и XP';


--
-- Name: COLUMN mob.aggro_range; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.aggro_range IS 'Radius at which mob detects and begins chasing a player (world units)';


--
-- Name: COLUMN mob.attack_range; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.attack_range IS 'Distance at which mob can attack a player (world units)';


--
-- Name: COLUMN mob.attack_cooldown; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.attack_cooldown IS 'Seconds between consecutive mob attacks';


--
-- Name: COLUMN mob.chase_multiplier; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.chase_multiplier IS 'aggro_range * chase_multiplier = max chase distance before giving up';


--
-- Name: COLUMN mob.patrol_speed; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.patrol_speed IS 'Speed multiplier for patrol movement (1.0 = normal)';


--
-- Name: COLUMN mob.is_social; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.is_social IS 'TRUE = mob participates in group-aggro and passive-social mechanics.';


--
-- Name: COLUMN mob.chase_duration; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.chase_duration IS 'Max seconds a mob will chase before leashing (replaces hard-coded 30 s). Per-mob override; larger values = more persistent pursuit.';


--
-- Name: COLUMN mob.flee_hp_threshold; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.flee_hp_threshold IS '0.0 = не убегает. 0.25 = убегает при HP <= 25%. Используется, когда реализован FLEEING state в MobAIController.';


--
-- Name: COLUMN mob.ai_archetype; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob.ai_archetype IS 'Архетип ИИ: melee (ближний бой, дефолт) | caster (kiting+заклинания) | ranged | support | summoner | lurker (засада). Используется, когда реализован выбор поведения по архетипу.';


--
-- Name: mob_active_effect; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mob_active_effect (
    id bigint NOT NULL,
    mob_uid integer NOT NULL,
    effect_id integer NOT NULL,
    attribute_id integer,
    value numeric(10,4) DEFAULT 0 NOT NULL,
    source_type text DEFAULT 'skill'::text NOT NULL,
    source_player_id bigint,
    applied_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    tick_ms integer DEFAULT 0 NOT NULL,
    CONSTRAINT mob_active_effect_source_type_ck CHECK ((source_type = ANY (ARRAY['skill'::text, 'zone'::text, 'quest'::text, 'admin'::text])))
);


--
-- Name: TABLE mob_active_effect; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mob_active_effect IS 'Активные баффы/дебаффы runtime-экземпляров мобов. mob_uid = MobDataStruct::uid из памяти chunk-server (не mob.id). Записи создаются при применении скила игрока на моба и удаляются при смерти моба или истечении таймера.';


--
-- Name: COLUMN mob_active_effect.mob_uid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_active_effect.mob_uid IS 'Runtime UID экземпляра моба (MobDataStruct::uid)';


--
-- Name: COLUMN mob_active_effect.effect_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_active_effect.effect_id IS 'Ссылка на skill_effects';


--
-- Name: COLUMN mob_active_effect.attribute_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_active_effect.attribute_id IS 'Модифицируемый атрибут (NULL для non-stat эффектов)';


--
-- Name: COLUMN mob_active_effect.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_active_effect.value IS 'Величина изменения атрибута';


--
-- Name: COLUMN mob_active_effect.source_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_active_effect.source_type IS 'Источник активного эффекта: skill | zone | quest | admin';


--
-- Name: COLUMN mob_active_effect.source_player_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_active_effect.source_player_id IS 'ID персонажа, применившего эффект';


--
-- Name: COLUMN mob_active_effect.expires_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_active_effect.expires_at IS 'NULL = постоянный (до смерти моба)';


--
-- Name: mob_active_effect_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.mob_active_effect ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_active_effect_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: mob_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.mob ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: mob_loot_info; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mob_loot_info (
    id bigint NOT NULL,
    mob_id integer NOT NULL,
    item_id bigint NOT NULL,
    drop_chance numeric(5,2) DEFAULT 0.00 NOT NULL,
    is_harvest_only boolean DEFAULT false NOT NULL,
    min_quantity smallint DEFAULT 1 NOT NULL,
    max_quantity smallint DEFAULT 1 NOT NULL,
    CONSTRAINT mob_loot_quantity_check CHECK (((max_quantity >= min_quantity) AND (min_quantity >= 1)))
);


--
-- Name: TABLE mob_loot_info; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mob_loot_info IS 'Таблица дропа моба: какие предметы и с какой вероятностью';


--
-- Name: COLUMN mob_loot_info.drop_chance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_loot_info.drop_chance IS 'Вероятность выпадения: 0.0 = никогда, 1.0 = всегда';


--
-- Name: COLUMN mob_loot_info.is_harvest_only; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_loot_info.is_harvest_only IS 'TRUE = предмет доступен только через harvest (взаимодействие с трупом), не выпадает при обычном убийстве.';


--
-- Name: COLUMN mob_loot_info.min_quantity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_loot_info.min_quantity IS 'Минимальное количество выпадающего предмета (>= 1)';


--
-- Name: COLUMN mob_loot_info.max_quantity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_loot_info.max_quantity IS 'Максимальное количество выпадающего предмета (>= min_quantity)';


--
-- Name: mob_loot_info_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.mob_loot_info ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_loot_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: mob_position; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mob_position (
    id bigint NOT NULL,
    mob_id integer NOT NULL,
    x numeric(11,2) NOT NULL,
    y numeric(11,2) NOT NULL,
    z numeric(11,2) NOT NULL,
    rot_z double precision DEFAULT 0 NOT NULL,
    zone_id integer
);


--
-- Name: TABLE mob_position; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mob_position IS 'Статические позиции спавна шаблонов мобов в зонах. FK: mob_id → mob';


--
-- Name: COLUMN mob_position.rot_z; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_position.rot_z IS 'Начальный угол поворота моба в точке спавна (в радианах)';


--
-- Name: COLUMN mob_position.zone_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_position.zone_id IS 'Зона, в которой размещён моб. NULL = не привязан к зоне';


--
-- Name: mob_position_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.mob_position ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_position_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: mob_race; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mob_race (
    id integer NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: TABLE mob_race; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mob_race IS 'Расы мобов (нежить, зверь, демон и т.д.)';


--
-- Name: mob_race_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.mob_race ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_race_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: mob_ranks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mob_ranks (
    rank_id smallint NOT NULL,
    code text NOT NULL,
    mult numeric(4,2) NOT NULL
);


--
-- Name: TABLE mob_ranks; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mob_ranks IS 'Ранги мобов (normal/elite/boss) с множителем характеристик';


--
-- Name: COLUMN mob_ranks.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_ranks.code IS 'Код ранга: normal / elite / boss / world_boss';


--
-- Name: COLUMN mob_ranks.mult; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_ranks.mult IS 'Множитель характеристик относительно нормального моба (1.0 = норма)';


--
-- Name: mob_skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mob_skills (
    id integer NOT NULL,
    mob_id integer NOT NULL,
    skill_id integer NOT NULL,
    current_level integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE mob_skills; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mob_skills IS 'Скиллы шаблона моба с уровнем';


--
-- Name: COLUMN mob_skills.current_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_skills.current_level IS 'Уровень скилла у данного шаблона моба';


--
-- Name: mob_skills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mob_skills_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mob_skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mob_skills_id_seq OWNED BY public.mob_skills.id;


--
-- Name: mob_stat; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mob_stat (
    id integer NOT NULL,
    mob_id integer NOT NULL,
    attribute_id integer NOT NULL,
    flat_value numeric(10,2) NOT NULL,
    multiplier numeric(10,4),
    exponent numeric(6,4),
    CONSTRAINT mob_stat_exponent_check CHECK (((exponent IS NULL) OR (exponent > (0)::numeric)))
);


--
-- Name: TABLE mob_stat; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mob_stat IS 'Единая таблица статов шаблона моба. multiplier IS NULL → использовать flat_value как есть. multiplier IS NOT NULL → ROUND(flat_value + multiplier * level^exponent).';


--
-- Name: COLUMN mob_stat.flat_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_stat.flat_value IS 'Базовое значение (или константа L1 при multiplier IS NULL)';


--
-- Name: COLUMN mob_stat.multiplier; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_stat.multiplier IS 'NULL = нет формулы; иначе — коэффициент масштабирования';


--
-- Name: COLUMN mob_stat.exponent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_stat.exponent IS 'Показатель степени для level (только при multiplier IS NOT NULL)';


--
-- Name: mob_stat_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.mob_stat ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_stat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: npc; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.npc (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    race_id integer DEFAULT 1 NOT NULL,
    level integer NOT NULL,
    current_health integer DEFAULT 1 NOT NULL,
    current_mana integer DEFAULT 1 NOT NULL,
    is_dead boolean DEFAULT false NOT NULL,
    slug character varying(50) NOT NULL,
    radius integer DEFAULT 100 NOT NULL,
    is_interactable boolean DEFAULT true NOT NULL,
    npc_type integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE npc; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.npc IS 'Шаблоны NPC. Содержат торговцев, квестодателей, диалоговых персонажей';


--
-- Name: COLUMN npc.radius; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc.radius IS 'Радиус коллизии, используемый клиентом';


--
-- Name: COLUMN npc.is_interactable; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc.is_interactable IS 'TRUE = игрок может начать диалог / взаимодействие с этим NPC';


--
-- Name: COLUMN npc.npc_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc.npc_type IS 'Тип NPC (FK → npc_type): торговец, квестодатель и т.д.';


--
-- Name: npc_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.npc_attributes (
    id bigint NOT NULL,
    npc_id integer NOT NULL,
    attribute_id integer NOT NULL,
    value integer NOT NULL
);


--
-- Name: TABLE npc_attributes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.npc_attributes IS 'Значения атрибутов NPC';


--
-- Name: COLUMN npc_attributes.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_attributes.value IS 'Значение атрибута для данного NPC';


--
-- Name: npc_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.npc_attributes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.npc_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: npc_dialogue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.npc_dialogue (
    npc_id bigint NOT NULL,
    dialogue_id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    condition_group jsonb
);


--
-- Name: TABLE npc_dialogue; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.npc_dialogue IS 'Связка NPC → Диалог с приоритетом выбора';


--
-- Name: COLUMN npc_dialogue.priority; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_dialogue.priority IS 'Чем выше число, тем раньше выбирается диалог для NPC';


--
-- Name: COLUMN npc_dialogue.condition_group; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_dialogue.condition_group IS 'JSON-условия активации диалога (те же правила что в dialogue_edge.condition_group)';


--
-- Name: npc_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.npc ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.npc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: npc_placements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.npc_placements (
    id bigint NOT NULL,
    npc_id bigint NOT NULL,
    zone_id integer,
    x double precision DEFAULT 0 NOT NULL,
    y double precision DEFAULT 0 NOT NULL,
    z double precision DEFAULT 0 NOT NULL,
    rot_z double precision DEFAULT 0 NOT NULL
);


--
-- Name: TABLE npc_placements; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.npc_placements IS 'Статичное размещение NPC в игровом мире. Используется gameserver при инициализации локации.';


--
-- Name: npc_placements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.npc_placements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: npc_placements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.npc_placements_id_seq OWNED BY public.npc_placements.id;


--
-- Name: npc_position; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.npc_position (
    id bigint NOT NULL,
    npc_id integer NOT NULL,
    x numeric(11,2) NOT NULL,
    y numeric(11,2) NOT NULL,
    z numeric(11,2) NOT NULL,
    rot_z numeric(11,2) DEFAULT 0 NOT NULL,
    zone_id integer
);


--
-- Name: TABLE npc_position; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.npc_position IS 'Статические позиции размещения NPC в зонах. FK: npc_id → npc';


--
-- Name: COLUMN npc_position.rot_z; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_position.rot_z IS 'Начальный угол поворота NPC (в радианах)';


--
-- Name: COLUMN npc_position.zone_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_position.zone_id IS 'Зона, в которой размещён NPC. NULL = не привязан к зоне';


--
-- Name: npc_position_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.npc_position ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.npc_position_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: npc_skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.npc_skills (
    id integer NOT NULL,
    npc_id integer NOT NULL,
    skill_id integer NOT NULL,
    current_level integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE npc_skills; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.npc_skills IS 'Скиллы NPC с уровнем';


--
-- Name: COLUMN npc_skills.current_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_skills.current_level IS 'Уровень скилла у данного NPC';


--
-- Name: npc_skills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.npc_skills_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: npc_skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.npc_skills_id_seq OWNED BY public.npc_skills.id;


--
-- Name: npc_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.npc_type (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL
);


--
-- Name: TABLE npc_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.npc_type IS 'Типы NPC: торговец, квестодатель, страж и т.д.';


--
-- Name: npc_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.npc_type ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.npc_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: player_active_effect; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player_active_effect (
    id bigint NOT NULL,
    player_id bigint NOT NULL,
    effect_id integer NOT NULL,
    source_type text NOT NULL,
    source_id bigint,
    value numeric DEFAULT 0 NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    attribute_id integer,
    tick_ms integer DEFAULT 0 NOT NULL,
    CONSTRAINT player_active_effect_source_type_ck CHECK ((source_type = ANY (ARRAY['quest'::text, 'dialogue'::text, 'skill'::text, 'item'::text])))
);


--
-- Name: TABLE player_active_effect; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.player_active_effect IS 'Активные эффекты персонажа: баффы/дебаффы с таймером или постоянные. Постоянные (квестовые награды, GM-модификаторы) хранятся в character_permanent_modifiers. Здесь — временые эффекты с expires_at и on-use эффекты от предметов (зелья, еда).';


--
-- Name: COLUMN player_active_effect.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_active_effect.id IS 'Суррогатный PK.';


--
-- Name: COLUMN player_active_effect.player_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_active_effect.player_id IS 'FK → characters.id. Персонаж, на которого наложен эффект.';


--
-- Name: COLUMN player_active_effect.effect_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_active_effect.effect_id IS 'FK → effects.id. Шаблон эффекта (тип, иконка, описание).';


--
-- Name: COLUMN player_active_effect.source_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_active_effect.source_type IS 'Источник эффекта: quest / dialogue / skill / item';


--
-- Name: COLUMN player_active_effect.source_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_active_effect.source_id IS 'ID источника (quest_id, dialogue_node_id, skill_id, item_id)';


--
-- Name: COLUMN player_active_effect.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_active_effect.value IS 'Величина эффекта (например, +50 к макс. HP)';


--
-- Name: COLUMN player_active_effect.applied_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_active_effect.applied_at IS 'Время наложения эффекта. DEFAULT now().';


--
-- Name: COLUMN player_active_effect.expires_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_active_effect.expires_at IS 'Время истечения. NULL = бессрочный эффект';


--
-- Name: COLUMN player_active_effect.attribute_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_active_effect.attribute_id IS 'Какой атрибут модифицирует эффект (FK → entity_attributes). NULL допустим для не-стат эффектов (stun, silence, root).';


--
-- Name: player_active_effect_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.player_active_effect_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_active_effect_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.player_active_effect_id_seq OWNED BY public.player_active_effect.id;


--
-- Name: player_flag; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player_flag (
    player_id bigint NOT NULL,
    flag_key text NOT NULL,
    int_value integer,
    bool_value boolean,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE player_flag; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.player_flag IS 'Флаги/счётчики игрока для условной логики диалогов и квестов';


--
-- Name: COLUMN player_flag.flag_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_flag.flag_key IS 'Имя флага (например, "mila_thanked")';


--
-- Name: player_inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player_inventory (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    item_id bigint NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    slot_index smallint,
    durability_current integer
);


--
-- Name: TABLE player_inventory; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.player_inventory IS 'Инвентарь персонажа: инстансы предметов с количеством и состоянием. Один ряд = один стак. Экипированные предметы дополнительно присутствуют в character_equipment.';


--
-- Name: COLUMN player_inventory.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_inventory.id IS 'Суррогатный PK инстанса предмета в инвентаре.';


--
-- Name: COLUMN player_inventory.character_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_inventory.character_id IS 'FK → characters.id. Владелец предмета.';


--
-- Name: COLUMN player_inventory.item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_inventory.item_id IS 'FK → items.id. Шаблон предмета.';


--
-- Name: COLUMN player_inventory.quantity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_inventory.quantity IS 'Количество предметов в стаке. DEFAULT 1.';


--
-- Name: COLUMN player_inventory.slot_index; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_inventory.slot_index IS 'Позиция предмета в сумке (NULL = не назначена)';


--
-- Name: COLUMN player_inventory.durability_current; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_inventory.durability_current IS 'Текущая прочность (NULL если item.is_durable = false)';


--
-- Name: player_inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.player_inventory ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.player_inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: player_quest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player_quest (
    player_id bigint NOT NULL,
    quest_id bigint NOT NULL,
    state public.quest_state NOT NULL,
    current_step integer DEFAULT 0 NOT NULL,
    progress jsonb,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT player_quest_step_ck CHECK ((current_step >= 0))
);


--
-- Name: TABLE player_quest; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.player_quest IS 'Текущее состояние квестов конкретного игрока';


--
-- Name: COLUMN player_quest.state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_quest.state IS 'offered/active/completed/turned_in/failed';


--
-- Name: COLUMN player_quest.current_step; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_quest.current_step IS 'Индекс текущего шага квеста (0-based). Соответствует quest_step.step_index';


--
-- Name: COLUMN player_quest.progress; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_quest.progress IS 'JSON прогресса текущего шага (например, {"have":3})';


--
-- Name: COLUMN player_quest.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_quest.updated_at IS 'Время последнего изменения состояния квеста';


--
-- Name: quest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quest (
    id bigint NOT NULL,
    slug text NOT NULL,
    min_level integer DEFAULT 1 NOT NULL,
    repeatable boolean DEFAULT false NOT NULL,
    cooldown_sec integer DEFAULT 0 NOT NULL,
    giver_npc_id bigint,
    turnin_npc_id bigint,
    client_quest_key text
);


--
-- Name: TABLE quest; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.quest IS 'Карточка квеста (без текстов), базовые правила/валидаторы';


--
-- Name: COLUMN quest.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest.slug IS 'Уникальный ключ квеста';


--
-- Name: COLUMN quest.min_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest.min_level IS 'Мин. уровень для взятия квеста';


--
-- Name: COLUMN quest.repeatable; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest.repeatable IS 'Можно ли повторять квест';


--
-- Name: COLUMN quest.cooldown_sec; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest.cooldown_sec IS 'Кулдаун перед повторным взятием (если repeatable)';


--
-- Name: COLUMN quest.giver_npc_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest.giver_npc_id IS 'NPC, выдающий квест';


--
-- Name: COLUMN quest.turnin_npc_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest.turnin_npc_id IS 'NPC, принимающий квест';


--
-- Name: COLUMN quest.client_quest_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest.client_quest_key IS 'Ключ для клиентского UI (название/описание)';


--
-- Name: quest_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quest_id_seq OWNED BY public.quest.id;


--
-- Name: quest_reward; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quest_reward (
    id bigint NOT NULL,
    quest_id bigint NOT NULL,
    reward_type text NOT NULL,
    item_id bigint,
    quantity integer DEFAULT 1 NOT NULL,
    amount bigint DEFAULT 0 NOT NULL,
    CONSTRAINT quest_reward_type_ck CHECK ((reward_type = ANY (ARRAY['item'::text, 'exp'::text, 'gold'::text])))
);


--
-- Name: TABLE quest_reward; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.quest_reward IS 'Награды за сдачу квеста (предметы, опыт, золото)';


--
-- Name: COLUMN quest_reward.reward_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest_reward.reward_type IS 'Тип награды: item / exp / gold';


--
-- Name: COLUMN quest_reward.item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest_reward.item_id IS 'ID предмета (только если reward_type = item)';


--
-- Name: COLUMN quest_reward.quantity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest_reward.quantity IS 'Количество предметов (только если reward_type = item)';


--
-- Name: COLUMN quest_reward.amount; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest_reward.amount IS 'Количество опыта или золота (только если reward_type = exp / gold)';


--
-- Name: quest_reward_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quest_reward_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quest_reward_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quest_reward_id_seq OWNED BY public.quest_reward.id;


--
-- Name: quest_step; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quest_step (
    id bigint NOT NULL,
    quest_id bigint NOT NULL,
    step_index integer NOT NULL,
    step_type public.quest_step_type NOT NULL,
    params jsonb NOT NULL,
    client_step_key text,
    CONSTRAINT quest_step_index_ck CHECK ((step_index >= 0))
);


--
-- Name: TABLE quest_step; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.quest_step IS 'Шаги квеста с параметрами в JSON';


--
-- Name: COLUMN quest_step.params; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest_step.params IS 'JSON параметров шага (item/count, npcId, зона и т.п.)';


--
-- Name: COLUMN quest_step.client_step_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest_step.client_step_key IS 'Ключ строки цели на клиенте';


--
-- Name: quest_step_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quest_step_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quest_step_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quest_step_id_seq OWNED BY public.quest_step.id;


--
-- Name: race; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.race (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying NOT NULL
);


--
-- Name: TABLE race; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.race IS 'Играбельные расы персонажей';


--
-- Name: race_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.race ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.race_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: skill_effect_instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_effect_instances (
    id integer NOT NULL,
    skill_id integer NOT NULL,
    order_idx smallint DEFAULT 1 NOT NULL,
    target_type_id integer NOT NULL
);


--
-- Name: TABLE skill_effect_instances; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skill_effect_instances IS 'Привязка эффектов к конкретным скиллам с порядком применения';


--
-- Name: COLUMN skill_effect_instances.order_idx; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skill_effect_instances.order_idx IS 'Порядок выполнения эффектов внутри одного скилла (меньше = раньше)';


--
-- Name: COLUMN skill_effect_instances.target_type_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skill_effect_instances.target_type_id IS 'На кого направлен эффект: self / enemy / ally / area';


--
-- Name: skill_effect_instances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.skill_effect_instances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: skill_effect_instances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.skill_effect_instances_id_seq OWNED BY public.skill_effect_instances.id;


--
-- Name: skill_effects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_effects (
    id integer NOT NULL,
    slug text NOT NULL,
    effect_type_id integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE skill_effects; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skill_effects IS 'Определения конкретных эффектов с типом и базовыми параметрами';


--
-- Name: skill_effects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.skill_effects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: skill_effects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.skill_effects_id_seq OWNED BY public.skill_effects.id;


--
-- Name: skill_effects_mapping; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_effects_mapping (
    id integer NOT NULL,
    effect_instance_id integer NOT NULL,
    effect_id integer NOT NULL,
    value numeric NOT NULL,
    level integer DEFAULT 1 NOT NULL,
    tick_ms integer DEFAULT 0 NOT NULL,
    duration_ms integer DEFAULT 0 NOT NULL,
    attribute_id integer
);


--
-- Name: TABLE skill_effects_mapping; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skill_effects_mapping IS 'Значения эффектов на каждом уровне скилла';


--
-- Name: COLUMN skill_effects_mapping.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skill_effects_mapping.value IS 'Числовое значение эффекта на данном уровне скилла';


--
-- Name: COLUMN skill_effects_mapping.level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skill_effects_mapping.level IS 'Уровень скилла, которому соответствует эта строка';


--
-- Name: COLUMN skill_effects_mapping.tick_ms; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skill_effects_mapping.tick_ms IS 'Интервал тика DoT/HoT в миллисекундах. 0 = мгновенный эффект (не тиковый).';


--
-- Name: COLUMN skill_effects_mapping.duration_ms; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skill_effects_mapping.duration_ms IS 'Полная продолжительность эффекта в миллисекундах. 0 = мгновенное применение.';


--
-- Name: COLUMN skill_effects_mapping.attribute_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skill_effects_mapping.attribute_id IS 'Атрибут-цель эффекта (например hp_regen_per_s для HoT). NULL = стандартный damage/heal без привязки к конкретному атрибуту.';


--
-- Name: skill_effects_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.skill_effects_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: skill_effects_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.skill_effects_mapping_id_seq OWNED BY public.skill_effects_mapping.id;


--
-- Name: skill_effects_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_effects_type (
    id integer NOT NULL,
    slug text NOT NULL
);


--
-- Name: TABLE skill_effects_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skill_effects_type IS 'Категории эффектов скиллов (урон, исцеление, дебафф и т.д.)';


--
-- Name: skill_effects_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.skill_effects_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: skill_effects_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.skill_effects_type_id_seq OWNED BY public.skill_effects_type.id;


--
-- Name: skill_properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_properties (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying NOT NULL
);


--
-- Name: TABLE skill_properties; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skill_properties IS 'Справочник свойств скиллов (кулдаун, дальность, стоимость маны и т.д.)';


--
-- Name: skill_properties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.skill_properties ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.skill_properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: skill_properties_mapping; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_properties_mapping (
    id integer NOT NULL,
    skill_id integer NOT NULL,
    skill_level integer NOT NULL,
    property_id integer NOT NULL,
    property_value numeric NOT NULL
);


--
-- Name: TABLE skill_properties_mapping; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skill_properties_mapping IS 'Значения свойств скилла на каждом уровне';


--
-- Name: COLUMN skill_properties_mapping.skill_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skill_properties_mapping.skill_level IS 'Уровень скилла, для которого задано значение свойства';


--
-- Name: COLUMN skill_properties_mapping.property_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skill_properties_mapping.property_value IS 'Конкретное значение свойства (например, cooldown=3.0)';


--
-- Name: skill_scale_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_scale_type (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL
);


--
-- Name: TABLE skill_scale_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skill_scale_type IS 'Типы масштабирования урона скилла (от силы, от интеллекта и т.д.)';


--
-- Name: skill_scale_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.skill_scale_type ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.skill_scale_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: skill_school; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_school (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL
);


--
-- Name: TABLE skill_school; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skill_school IS 'Магические/боевые школы скиллов (огонь, тьма, физика и т.д.)';


--
-- Name: skill_school_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.skill_school ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.skill_school_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skills (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL,
    scale_stat_id integer DEFAULT 1 NOT NULL,
    school_id integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE skills; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skills IS 'Каталог скиллов игры (шаблоны, не привязанные к персонажу)';


--
-- Name: COLUMN skills.scale_stat_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.scale_stat_id IS 'Атрибут, от которого масштабируется скилл (FK → skill_scale_type). NULL = без скейла';


--
-- Name: COLUMN skills.school_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.school_id IS 'Школа скилла (FK → skill_school). NULL = универсальный';


--
-- Name: skills_attributes_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.skill_properties_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.skills_attributes_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: skills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.skills ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: spawn_zone_mobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spawn_zone_mobs (
    id bigint NOT NULL,
    spawn_zone_id integer NOT NULL,
    mob_id integer NOT NULL,
    spawn_count integer DEFAULT 1 NOT NULL,
    respawn_time text DEFAULT '00:05:00'::text NOT NULL,
    CONSTRAINT spawn_zone_mobs_respawn_time_check CHECK ((respawn_time ~ '^\d{2}:\d{2}:\d{2}$'::text)),
    CONSTRAINT spawn_zone_mobs_spawn_count_check CHECK ((spawn_count > 0))
);


--
-- Name: TABLE spawn_zone_mobs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.spawn_zone_mobs IS 'Какие мобы спавнятся в зоне, в каком количестве и с каким интервалом. Одна зона может содержать несколько разных мобов.';


--
-- Name: COLUMN spawn_zone_mobs.respawn_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.spawn_zone_mobs.respawn_time IS 'Интервал до следующего спавна в формате HH:MM:SS';


--
-- Name: spawn_zone_mobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.spawn_zone_mobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: spawn_zone_mobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.spawn_zone_mobs_id_seq OWNED BY public.spawn_zone_mobs.id;


--
-- Name: spawn_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spawn_zones (
    zone_id integer NOT NULL,
    zone_name character varying(100) NOT NULL,
    min_spawn_x double precision DEFAULT 0 NOT NULL,
    min_spawn_y double precision DEFAULT 0 NOT NULL,
    min_spawn_z double precision DEFAULT 0 NOT NULL,
    max_spawn_x double precision DEFAULT 0 NOT NULL,
    max_spawn_y double precision DEFAULT 0 NOT NULL,
    max_spawn_z double precision DEFAULT 0 NOT NULL,
    game_zone_id integer
);


--
-- Name: TABLE spawn_zones; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.spawn_zones IS 'Геометрия зоны спавна (прямоугольник координат). Принадлежит игровому региону (zones). Мобы настраиваются в spawn_zone_mobs.';


--
-- Name: COLUMN spawn_zones.game_zone_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.spawn_zones.game_zone_id IS 'Игровой регион (zones), которому принадлежит точка спавна';


--
-- Name: spawn_zones_zone_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.spawn_zones_zone_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: spawn_zones_zone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.spawn_zones_zone_id_seq OWNED BY public.spawn_zones.zone_id;


--
-- Name: target_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.target_type (
    id integer NOT NULL,
    slug text NOT NULL
);


--
-- Name: TABLE target_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.target_type IS 'Типы целей скиллов: self, enemy, ally, area и т.д.';


--
-- Name: target_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.target_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: target_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.target_type_id_seq OWNED BY public.target_type.id;


--
-- Name: user_bans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_bans (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    banned_by_user_id bigint,
    reason text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL
);


--
-- Name: TABLE user_bans; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_bans IS 'Записи блокировок аккаунтов. expires_at = NULL означает перманентный бан';


--
-- Name: COLUMN user_bans.expires_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_bans.expires_at IS 'NULL = перманентный бан';


--
-- Name: user_bans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_bans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_bans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_bans_id_seq OWNED BY public.user_bans.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id smallint NOT NULL,
    name character varying(30) NOT NULL,
    label character varying(50) NOT NULL,
    is_staff boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE user_roles; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_roles IS 'Справочник ролей аккаунтов: 0=player, 1=gm, 2=admin';


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_hash character varying(255) NOT NULL,
    ip inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone
);


--
-- Name: TABLE user_sessions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_sessions IS 'Сессии пользователей — позволяет мультисессионность и точечный отзыв токена';


--
-- Name: user_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    login character varying(50) NOT NULL,
    password character varying(100) NOT NULL,
    last_login timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    email character varying(255),
    role smallint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    failed_login_attempts smallint DEFAULT 0 NOT NULL,
    locked_until timestamp with time zone,
    last_login_ip inet,
    registration_ip inet,
    is_email_verified boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.users IS 'Аккаунты игроков и персонала. Один аккаунт — до неск. персонажей';


--
-- Name: COLUMN users.login; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.login IS 'Уникальный логин для входа';


--
-- Name: COLUMN users.password; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.password IS 'Пароль (в реальном проекте — хэш bcrypt)';


--
-- Name: COLUMN users.last_login; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.last_login IS 'Время последнего входа в аккаунт';


--
-- Name: COLUMN users.role; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.role IS '0=player, 1=GM, 2=администратор. FK → user_roles';


--
-- Name: COLUMN users.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.created_at IS 'Дата регистрации аккаунта';


--
-- Name: COLUMN users.is_active; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.is_active IS 'FALSE = аккаунт заблокирован/отключён администратором';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: vendor_inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_inventory (
    id bigint NOT NULL,
    vendor_npc_id integer NOT NULL,
    item_id bigint NOT NULL,
    stock_count integer DEFAULT '-1'::integer NOT NULL,
    price_override bigint
);


--
-- Name: TABLE vendor_inventory; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.vendor_inventory IS 'Ассортимент конкретного торговца с остатком и ценой';


--
-- Name: COLUMN vendor_inventory.stock_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vendor_inventory.stock_count IS 'Остаток товара. -1 = бесконечный запас';


--
-- Name: COLUMN vendor_inventory.price_override; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vendor_inventory.price_override IS 'Ценовое исключение для этого товара у этого торговца. NULL = стандартная цена';


--
-- Name: vendor_inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendor_inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendor_inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendor_inventory_id_seq OWNED BY public.vendor_inventory.id;


--
-- Name: vendor_npc; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_npc (
    id integer NOT NULL,
    npc_id integer NOT NULL,
    markup_pct smallint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE vendor_npc; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.vendor_npc IS 'Торговая конфигурация NPC: базовая наценка';


--
-- Name: COLUMN vendor_npc.markup_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vendor_npc.markup_pct IS 'Наценка в % поверх vendor_price_buy предмета. 0 = без наценки';


--
-- Name: vendor_npc_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendor_npc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendor_npc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendor_npc_id_seq OWNED BY public.vendor_npc.id;


--
-- Name: zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zones (
    id integer NOT NULL,
    slug character varying(100) NOT NULL,
    name character varying(100) NOT NULL,
    min_level integer DEFAULT 1 NOT NULL,
    max_level integer DEFAULT 999 NOT NULL,
    is_pvp boolean DEFAULT false NOT NULL,
    is_safe_zone boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE zones; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.zones IS 'Игровые зоны/карты. Без zone_id координаты позиций теряют смысл';


--
-- Name: zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zones_id_seq OWNED BY public.zones.id;


--
-- Name: character_equipment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_equipment ALTER COLUMN id SET DEFAULT nextval('public.character_equipment_id_seq'::regclass);


--
-- Name: character_skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_skills ALTER COLUMN id SET DEFAULT nextval('public.character_skills_id_seq1'::regclass);


--
-- Name: class_skill_tree id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_skill_tree ALTER COLUMN id SET DEFAULT nextval('public.class_skill_tree_id_seq'::regclass);


--
-- Name: currency_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_transactions ALTER COLUMN id SET DEFAULT nextval('public.currency_transactions_id_seq'::regclass);


--
-- Name: dialogue id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue ALTER COLUMN id SET DEFAULT nextval('public.dialogue_id_seq'::regclass);


--
-- Name: dialogue_edge id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_edge ALTER COLUMN id SET DEFAULT nextval('public.dialogue_edge_id_seq'::regclass);


--
-- Name: dialogue_node id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_node ALTER COLUMN id SET DEFAULT nextval('public.dialogue_node_id_seq'::regclass);


--
-- Name: gm_action_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gm_action_log ALTER COLUMN id SET DEFAULT nextval('public.gm_action_log_id_seq'::regclass);


--
-- Name: mob_skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_skills ALTER COLUMN id SET DEFAULT nextval('public.mob_skills_id_seq'::regclass);


--
-- Name: npc_placements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_placements ALTER COLUMN id SET DEFAULT nextval('public.npc_placements_id_seq'::regclass);


--
-- Name: npc_skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_skills ALTER COLUMN id SET DEFAULT nextval('public.npc_skills_id_seq'::regclass);


--
-- Name: player_active_effect id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_active_effect ALTER COLUMN id SET DEFAULT nextval('public.player_active_effect_id_seq'::regclass);


--
-- Name: quest id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest ALTER COLUMN id SET DEFAULT nextval('public.quest_id_seq'::regclass);


--
-- Name: quest_reward id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest_reward ALTER COLUMN id SET DEFAULT nextval('public.quest_reward_id_seq'::regclass);


--
-- Name: quest_step id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest_step ALTER COLUMN id SET DEFAULT nextval('public.quest_step_id_seq'::regclass);


--
-- Name: skill_effect_instances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effect_instances ALTER COLUMN id SET DEFAULT nextval('public.skill_effect_instances_id_seq'::regclass);


--
-- Name: skill_effects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_id_seq'::regclass);


--
-- Name: skill_effects_mapping id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects_mapping ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_mapping_id_seq'::regclass);


--
-- Name: skill_effects_type id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects_type ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_type_id_seq'::regclass);


--
-- Name: spawn_zone_mobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_zone_mobs ALTER COLUMN id SET DEFAULT nextval('public.spawn_zone_mobs_id_seq'::regclass);


--
-- Name: spawn_zones zone_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_zones ALTER COLUMN zone_id SET DEFAULT nextval('public.spawn_zones_zone_id_seq'::regclass);


--
-- Name: target_type id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_type ALTER COLUMN id SET DEFAULT nextval('public.target_type_id_seq'::regclass);


--
-- Name: user_bans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_bans ALTER COLUMN id SET DEFAULT nextval('public.user_bans_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.user_sessions_id_seq'::regclass);


--
-- Name: vendor_inventory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_inventory ALTER COLUMN id SET DEFAULT nextval('public.vendor_inventory_id_seq'::regclass);


--
-- Name: vendor_npc id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_npc ALTER COLUMN id SET DEFAULT nextval('public.vendor_npc_id_seq'::regclass);


--
-- Name: zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones ALTER COLUMN id SET DEFAULT nextval('public.zones_id_seq'::regclass);


--
-- Data for Name: character_class; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.character_class (id, name, slug, description) FROM stdin;
1	Mage	\N	\N
2	Warrior	\N	\N
\.


--
-- Data for Name: character_current_state; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.character_current_state (character_id, current_health, current_mana, is_dead, updated_at) FROM stdin;
1	999	999	f	2026-03-03 18:20:23.253769+00
2	999	999	f	2026-03-06 17:08:51.867517+00
3	968	999	f	2026-03-07 12:16:59.747582+00
\.


--
-- Data for Name: character_equipment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.character_equipment (id, character_id, equip_slot_id, inventory_item_id, equipped_at) FROM stdin;
\.


--
-- Data for Name: character_genders; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.character_genders (id, name, label) FROM stdin;
0	male	Male
1	female	Female
2	unknown	Unknown
\.


--
-- Data for Name: character_permanent_modifiers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.character_permanent_modifiers (id, character_id, attribute_id, value, source_type, source_id) FROM stdin;
4	1	1	100	gm	\N
5	1	2	200	gm	\N
6	1	3	5	gm	\N
7	1	4	15	gm	\N
8	1	5	3	gm	\N
16	1	6	5	gm	\N
17	1	7	5	gm	\N
18	1	10	1	gm	\N
19	1	11	1	gm	\N
20	1	12	3	gm	\N
21	1	13	5	gm	\N
22	1	8	15	gm	\N
23	1	9	2	gm	\N
24	1	14	5	gm	\N
25	1	15	5	gm	\N
28	1	18	5	gm	\N
29	1	19	5	gm	\N
30	1	20	7	gm	\N
32	2	2	200	gm	\N
33	2	3	5	gm	\N
34	2	4	15	gm	\N
35	2	5	3	gm	\N
36	2	6	5	gm	\N
37	2	7	5	gm	\N
38	2	10	1	gm	\N
39	2	11	1	gm	\N
40	2	12	3	gm	\N
41	2	13	5	gm	\N
42	2	8	15	gm	\N
43	2	9	2	gm	\N
44	2	14	5	gm	\N
45	2	15	5	gm	\N
48	2	18	5	gm	\N
49	2	19	5	gm	\N
50	2	20	7	gm	\N
52	3	2	200	gm	\N
53	3	3	5	gm	\N
54	3	4	15	gm	\N
55	3	5	3	gm	\N
56	3	6	5	gm	\N
57	3	7	5	gm	\N
58	3	10	1	gm	\N
59	3	11	1	gm	\N
60	3	12	3	gm	\N
61	3	13	5	gm	\N
62	3	8	15	gm	\N
63	3	9	2	gm	\N
64	3	14	5	gm	\N
65	3	15	5	gm	\N
66	3	16	15	gm	\N
67	3	17	3	gm	\N
68	3	18	5	gm	\N
69	3	19	5	gm	\N
70	3	20	7	gm	\N
31	2	1	100	gm	\N
51	3	1	100	gm	\N
\.


--
-- Data for Name: character_position; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.character_position (id, character_id, x, y, z, zone_id, rot_z) FROM stdin;
1	1	-2000.00	4000.00	300.00	2	0
2	2	-3770.10	4258.45	187.15	2	0
3	3	-2091.67	3941.16	186.94	1	0
\.


--
-- Data for Name: character_skills; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.character_skills (id, character_id, skill_id, current_level) FROM stdin;
1	1	1	1
4	2	1	1
5	3	1	1
\.


--
-- Data for Name: characters; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.characters (id, name, owner_id, class_id, race_id, experience_points, level, radius, free_skill_points, gender, account_slot, created_at, last_online_at, deleted_at, play_time_sec, bind_zone_id, bind_x, bind_y, bind_z, appearance) FROM stdin;
3	TetsWarrior1Player	3	2	1	919	2	100	0	0	1	2026-03-03 16:16:54.741947+00	\N	\N	0	1	0	0	200	\N
1	TetsMage1Player	5	1	1	57	2	100	0	0	1	2026-03-03 16:16:54.741947+00	\N	\N	0	1	0	0	200	\N
2	TetsMage2Player	4	1	1	130	1	100	0	0	1	2026-03-03 16:16:54.741947+00	\N	\N	0	1	0	0	200	\N
\.


--
-- Data for Name: class_skill_tree; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.class_skill_tree (id, class_id, skill_id, required_level, is_default) FROM stdin;
1	1	1	1	t
2	1	3	5	f
3	2	1	1	t
4	2	2	5	f
\.


--
-- Data for Name: class_stat_formula; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.class_stat_formula (class_id, attribute_id, base_value, multiplier, exponent) FROM stdin;
1	1	80.00	8.0000	1.1000
1	2	200.00	25.0000	1.1200
1	3	5.00	0.8000	1.0000
1	4	15.00	2.5000	1.0500
1	5	3.00	0.5000	1.0000
1	6	5.00	1.2000	1.0500
1	7	8.00	2.0000	1.0800
1	8	15.00	0.8000	1.0200
1	9	2.00	0.0500	1.0000
1	10	1.00	0.3000	1.0500
1	11	1.00	0.8000	1.0800
1	12	2.00	0.5000	1.0000
1	13	5.00	1.8000	1.0800
1	14	5.00	0.5000	1.0000
1	15	5.00	0.5000	1.0000
1	16	0.00	0.0000	1.0000
1	17	0.00	0.0000	1.0000
1	18	5.00	0.0000	1.0000
1	19	5.00	0.2000	1.0000
1	20	7.00	0.3000	1.0000
2	1	150.00	18.0000	1.1500
2	2	50.00	5.0000	1.0500
2	3	12.00	2.0000	1.0800
2	4	5.00	0.5000	1.0000
2	5	3.00	0.3000	1.0000
2	6	15.00	4.0000	1.1200
2	7	5.00	1.5000	1.0500
2	8	15.00	0.5000	1.0000
2	9	2.00	0.0500	1.0000
2	10	1.00	0.5000	1.0800
2	11	1.00	0.2000	1.0000
2	12	10.00	3.5000	1.1000
2	13	2.00	0.5000	1.0000
2	14	5.00	0.5000	1.0000
2	15	3.00	0.3000	1.0000
2	16	15.00	0.5000	1.0000
2	17	3.00	1.0000	1.0500
2	18	5.00	0.0000	1.0000
2	19	5.00	0.3000	1.0000
2	20	3.00	0.1000	1.0000
\.


--
-- Data for Name: currency_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.currency_transactions (id, character_id, amount, reason_type, source_id, created_at) FROM stdin;
\.


--
-- Data for Name: dialogue; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dialogue (id, slug, version, start_node_id) FROM stdin;
1	milaya_base	1	1
\.


--
-- Data for Name: dialogue_edge; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dialogue_edge (id, from_node_id, to_node_id, order_index, client_choice_key, condition_group, action_group, hide_if_locked) FROM stdin;
1	1	2	0	milaya.about_village	\N	\N	f
3	3	5	1	milaya.choice.kill_wolfes_decline	\N	\N	f
4	4	6	0	milaya.choice.end	\N	\N	f
5	5	6	0	milaya.choice.end	\N	\N	f
6	2	3	0	milaya.need_help	\N	\N	f
2	3	4	0	milaya.choice.kill_wolfes_accept	{"slug": "wolf_hunt_intro", "type": "quest", "state": "not_started"}	{"actions": [{"slug": "wolf_hunt_intro", "type": "offer_quest"}]}	t
\.


--
-- Data for Name: dialogue_node; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dialogue_node (id, dialogue_id, type, speaker_npc_id, client_node_key, condition_group, action_group, jump_target_node_id) FROM stdin;
1	1	line	2	milaya.dialogue.wellcome	\N	\N	\N
2	1	line	2	milaya.dialogue.about_village	\N	\N	\N
4	1	line	2	milaya.dialogue.kill_wolfes_accept	\N	\N	\N
5	1	line	2	milaya.dialogue.kill_wolfes_decline	\N	\N	\N
3	1	choice_hub	2	milaya.dialogue.choice.kill_wolfes	\N	\N	\N
6	1	end	2	milaya.dialogue.end	\N	\N	\N
\.


--
-- Data for Name: entity_attributes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.entity_attributes (id, name, slug) FROM stdin;
1	Maximum Health	max_health
2	Maximum Mana	max_mana
3	Strength	strength
4	Intelligence	intelligence
5	Luck	luck
6	Physical Defense	physical_defense
7	Magical Defense	magical_defense
8	Crit Chance	crit_chance
9	Crit Multiplier	crit_multiplier
10	HP Regen /s	hp_regen_per_s
11	MP Regen /s	mp_regen_per_s
12	Physical Attack	physical_attack
13	Magical Attack	magical_attack
14	Accuracy	accuracy
15	Evasion	evasion
16	Block Chance	block_chance
17	Block Value	block_value
18	Move Speed	move_speed
19	Attack Speed	attack_speed
20	Cast Speed	cast_speed
21	Heal On Use	heal_on_use
22	Hunger Restore	hunger_restore
23	Physical Resistance	physical_resistance
24	Magical Resistance	magical_resistance
\.


--
-- Data for Name: equip_slot; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.equip_slot (id, slug, name) FROM stdin;
1	head	Head
2	chest	Chest
3	legs	Legs
4	feet	Feet
5	hands	Hands
6	main_hand	Main Hand
7	off_hand	Off Hand
8	two_hand	Two-Handed
9	ring	Ring
10	neck	Neck
11	trinket	Trinket
\.


--
-- Data for Name: exp_for_level; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exp_for_level (id, level, experience_points) FROM stdin;
1	1	100
2	2	500
3	3	1000
4	4	2000
5	5	4000
6	6	8000
7	7	15000
8	8	25000
9	9	40000
10	10	60000
\.


--
-- Data for Name: game_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.game_config (key, value, value_type, description, updated_at) FROM stdin;
combat.defense_formula_k	7.5	float	Коэффициент K в формуле убывающей доходности брони: DR = armor / (armor + K * targetLevel). Чем выше K, тем больше брони нужно для одного и того же % снижения урона. Значение 7.5: на lvl10 нужно 75 брони для 50% DR.	2026-03-05 14:27:26.320486+00
combat.defense_cap	0.85	float	Максимальный процент снижения урона от физической/магической брони (0–1). Значение 0.85 = максимум 85% снижения. Не позволяет броне даровать полный иммунитет.	2026-03-05 14:27:26.320486+00
combat.damage_variance	0.12	float	Симметричный разброс базового урона ±N (0–1). Значение 0.12 = каждый удар ±12% от расчётного. Предотвращает предсказуемость одиночного тика и монотонность DPS.	2026-03-05 14:27:26.320486+00
combat.level_diff_damage_per_level	0.04	float	Бонус/штраф к урону за каждый уровень разницы (0–1). Значение 0.04 = ±4% урона за каждый уровень. Атака по цели выше уровнем = штраф; ниже уровнем = бонус.	2026-03-05 14:27:26.320486+00
combat.level_diff_hit_per_level	0.02	float	Бонус/штраф к шансу попадания за каждый уровень разницы (0–1). Значение 0.02 = ±2% к hitChance за уровень.	2026-03-05 14:27:26.320486+00
combat.level_diff_cap	10	int	Максимальная учитываемая разница уровней для штрафов/бонусов. Разница > cap трактуется как cap (не уходит в бесконечность).	2026-03-05 14:27:26.320486+00
combat.base_hit_chance	0.95	float	Базовый шанс попадания до учёта accuracy/evasion (0–1). Финальный hitChance = base_hit_chance + (accuracy - evasion) * 0.01.	2026-03-05 14:27:26.320486+00
combat.hit_chance_min	0.05	float	Минимальный возможный шанс попадания (0–1). Даже при огромном уклонении противника не менее N% ударов попадут.	2026-03-05 14:27:26.320486+00
combat.hit_chance_max	0.95	float	Максимальный возможный шанс попадания (0–1). Даже при огромной точности не более N% ударов попадут.	2026-03-05 14:27:26.320486+00
combat.default_crit_multiplier	2.0	float	Дефолтный множитель крита, если у атакующего нет атрибута crit_multiplier. Значение 2.0 = удвоенный урон при крите.	2026-03-05 14:27:26.320486+00
aggro.base_radius	500	int	Базовый радиус обнаружения игрока мобом (игровые единицы). Конкретный моб может иметь свой radius из таблицы mobs.	2026-03-05 14:27:26.320486+00
aggro.leash_distance	2000	int	Дистанция от точки спавна, при превышении которой моб сбрасывает агро и возвращается назад (игровые единицы).	2026-03-05 14:27:26.320486+00
combat.max_resistance_cap	75	float	Maximum resistance % a target can have for any school (0-100)	2026-03-05 18:09:52.304703+00
combat.dot_min_tick_ms	500	float	Minimum allowed tick interval for DoT/HoT effects (ms)	2026-03-05 18:29:09.000283+00
combat.dot_max_ticks	20	float	Maximum number of ticks a single DoT/HoT effect can have	2026-03-05 18:29:09.000283+00
combat.aoe_target_cap	10	float	Maximum number of targets hit by a single AoE skill cast	2026-03-05 18:49:40.6975+00
\.


--
-- Data for Name: gm_action_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.gm_action_log (id, gm_user_id, action_type, target_type, target_id, old_value, new_value, created_at) FROM stdin;
\.


--
-- Data for Name: item_attributes_mapping; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.item_attributes_mapping (id, item_id, attribute_id, value, apply_on) FROM stdin;
1	1	12	10	equip
2	2	6	5	equip
3	3	21	50	use
7	15	13	8	equip
4	4	21	15	use
\.


--
-- Data for Name: item_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.item_types (id, name, slug) FROM stdin;
1	Weapon	weapon
2	Armor	armor
3	Potion	potion
4	Food	food
5	Quest Item	quest_item
6	Resource	resource
7	Accessory	accessory
8	Currency	currency
9	Container	container
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.items (id, name, slug, description, is_quest_item, item_type, weight, rarity_id, stack_max, is_container, is_durable, is_tradable, durability_max, vendor_price_buy, vendor_price_sell, equip_slot, level_requirement, is_equippable, is_harvest, is_usable) FROM stdin;
5	Ancient Artifact	ancient_artifact	A mysterious artifact for quests.	t	5	0.5	1	64	f	f	t	100	1	1	\N	0	f	f	f
1	Iron Sword	iron_sworld	A sturdy iron sword.	f	1	5	1	64	f	t	t	100	50	20	6	1	t	f	f
2	Wooden Shield	wooden_shield	A basic wooden shield.	f	2	3	1	64	f	t	t	100	40	15	7	1	t	f	f
3	Health Potion	health_potion	Restores 50 health points.	f	3	0.5	1	64	f	f	t	100	10	4	\N	0	f	f	t
4	Bread	bread	A loaf of bread to restore hunger.	f	4	0.1	1	64	f	f	t	100	3	1	\N	0	f	f	t
6	Iron Ore	iron_ore	A piece of iron ore, useful for crafting.	f	6	2	1	64	f	f	t	100	5	2	\N	0	f	f	f
9	Small Animal Skin	small_animal_skin	A basic skin of small animal.	f	6	0.3	1	64	f	f	t	100	8	3	\N	0	f	t	f
10	Animal Fat	animal_fat	Fat extracted from animal.	f	6	0.2	1	64	f	f	t	100	4	2	\N	0	f	t	f
11	Animal Blood	animal_blood	Blood extracted from animal.	f	6	0.5	1	64	f	f	t	100	4	1	\N	0	f	t	f
12	Animal Meat	animal_meet	Meat extracted from animal.	f	6	1	1	64	f	f	t	100	5	2	\N	0	f	t	f
13	Animal Fang	animal_fang	Fang extracted from animal.	f	6	0.2	1	64	f	f	t	100	6	3	\N	0	f	t	f
14	Animal Eye	animal_eye	Eye extracted from animal.	f	6	0.1	1	64	f	f	t	100	5	2	\N	0	f	t	f
7	Small Animal Bone	small_animal_bone	A small bones of small animal.	f	6	0.5	1	64	f	f	t	100	3	1	\N	0	f	t	f
15	Wooden Staff	wooden_staff	A simple wooden staff for apprentice mages.	f	1	2	1	64	f	t	t	80	30	12	8	1	t	f	f
\.


--
-- Data for Name: items_rarity; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.items_rarity (id, name, color_hex, slug) FROM stdin;
1	Common	#FFFFFF	common
2	Uncommon	#1EFF00	uncommon
3	Rare	#0070DD	rare
4	Epic	#A335EE	epic
5	Legendary	#FF8000	legendary
\.


--
-- Data for Name: mob; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mob (id, name, race_id, level, spawn_health, spawn_mana, is_aggressive, is_dead, slug, radius, base_xp, rank_id, aggro_range, attack_range, attack_cooldown, chase_multiplier, patrol_speed, is_social, chase_duration, flee_hp_threshold, ai_archetype) FROM stdin;
1	Small Fox	2	1	80	50	f	f	SmallFox	100	15	1	500	120	2.5	1.8	0.9	t	30	0	melee
2	Grey Wolf	2	1	150	50	t	f	GreyWolf	100	20	1	450	120	2	2.2	1.1	f	30	0	melee
6	Wolf Pack Leader	2	3	200	60	t	f	WolfPackLeader	120	35	2	420	140	2.2	2.5	1.2	t	45	0	melee
7	Old Grey Wolf	2	5	500	80	t	f	OldGreyWolf	130	50	3	480	160	2	2.8	1.3	t	60	0	melee
8	Forest Troll	3	8	1200	100	t	f	ForestTroll	180	90	4	350	200	3	1.8	0.8	f	40	0	melee
\.


--
-- Data for Name: mob_active_effect; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mob_active_effect (id, mob_uid, effect_id, attribute_id, value, source_type, source_player_id, applied_at, expires_at, tick_ms) FROM stdin;
\.


--
-- Data for Name: mob_loot_info; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mob_loot_info (id, mob_id, item_id, drop_chance, is_harvest_only, min_quantity, max_quantity) FROM stdin;
10	1	3	0.10	f	1	1
11	1	9	0.60	t	1	1
12	1	10	0.30	t	1	1
13	1	11	0.20	t	1	2
14	1	12	0.15	t	1	1
15	2	6	0.15	f	1	2
16	2	9	0.50	t	1	1
17	2	11	0.30	t	1	1
18	2	12	0.15	t	1	1
19	2	13	0.20	t	1	1
20	6	3	0.05	f	1	1
21	6	9	0.55	t	1	1
22	6	11	0.35	t	1	1
23	6	12	0.20	t	1	1
24	6	13	0.25	t	1	1
25	7	6	0.10	f	1	1
26	7	9	0.60	t	1	1
27	7	11	0.40	t	1	2
28	7	12	0.25	t	1	1
29	7	13	0.35	t	1	1
30	8	3	0.30	f	1	1
31	8	6	0.70	f	2	4
32	8	7	0.20	f	1	1
\.


--
-- Data for Name: mob_position; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mob_position (id, mob_id, x, y, z, rot_z, zone_id) FROM stdin;
\.


--
-- Data for Name: mob_race; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mob_race (id, name) FROM stdin;
1	Goblin
2	Animal
3	Troll
\.


--
-- Data for Name: mob_ranks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mob_ranks (rank_id, code, mult) FROM stdin;
1	normal	1.00
2	pack	0.60
3	strong	1.50
4	elite	2.20
5	miniboss	5.00
6	boss	20.00
\.


--
-- Data for Name: mob_skills; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mob_skills (id, mob_id, skill_id, current_level) FROM stdin;
1	1	1	1
2	2	1	1
3	6	1	1
4	7	1	1
5	8	1	1
\.


--
-- Data for Name: mob_stat; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mob_stat (id, mob_id, attribute_id, flat_value, multiplier, exponent) FROM stdin;
2	2	3	5.00	\N	\N
3	2	4	15.00	\N	\N
4	2	5	3.00	\N	\N
8	2	11	1.00	\N	\N
12	2	9	2.00	\N	\N
15	2	16	15.00	\N	\N
16	2	17	3.00	\N	\N
18	2	19	5.00	\N	\N
19	2	20	7.00	\N	\N
21	1	3	5.00	\N	\N
22	1	4	15.00	\N	\N
23	1	5	3.00	\N	\N
27	1	11	1.00	\N	\N
31	1	9	2.00	\N	\N
34	1	16	15.00	\N	\N
35	1	17	3.00	\N	\N
37	1	19	5.00	\N	\N
38	1	20	7.00	\N	\N
1	2	2	100.00	100.0000	1.0000
20	1	2	100.00	100.0000	1.0000
26	1	10	0.50	0.5000	1.0000
7	2	10	0.50	0.5000	1.0000
39	1	1	-20.00	100.0000	1.0000
28	1	12	0.00	2.0000	1.1000
24	1	6	0.00	3.0000	1.1000
29	1	13	-1.00	3.0000	1.1000
25	1	7	0.00	3.0000	1.1000
33	1	15	6.00	2.0000	1.0000
32	1	14	4.00	2.0000	1.0000
30	1	8	4.50	0.5000	1.0000
36	1	18	6.70	0.3000	1.0000
40	2	1	50.00	100.0000	1.0000
9	2	12	3.00	2.0000	1.1000
5	2	6	4.00	3.0000	1.1000
10	2	13	0.00	3.0000	1.1000
6	2	7	2.00	3.0000	1.1000
14	2	15	1.00	2.0000	1.0000
13	2	14	6.00	2.0000	1.0000
11	2	8	9.50	0.5000	1.0000
17	2	18	4.70	0.3000	1.0000
44	6	1	-100.00	100.0000	1.0000
45	6	2	-40.00	100.0000	1.0000
46	6	12	-3.50	3.0000	1.1000
47	6	6	0.50	2.0000	1.1000
48	6	13	0.00	1.5000	1.1000
49	6	7	0.00	1.5000	1.1000
50	6	14	4.00	2.0000	1.0000
51	6	15	2.00	1.0000	1.0000
52	6	8	3.50	0.5000	1.0000
53	6	9	2.00	\N	\N
54	6	10	1.00	0.5000	1.0000
55	6	11	0.50	\N	\N
56	6	18	4.10	0.3000	1.0000
57	6	19	5.00	\N	\N
58	6	16	0.00	\N	\N
59	6	17	0.00	\N	\N
60	6	3	8.00	\N	\N
61	6	4	3.00	\N	\N
62	6	5	5.00	\N	\N
63	6	23	0.00	\N	\N
64	6	24	0.00	\N	\N
65	7	1	0.00	100.0000	1.0000
66	7	2	-20.00	100.0000	1.0000
67	7	12	5.00	3.0000	1.1000
68	7	6	4.00	2.5000	1.1000
69	7	13	0.00	2.0000	1.1000
70	7	7	2.00	2.0000	1.1000
71	7	14	2.50	2.5000	1.0000
72	7	15	-1.00	1.0000	1.0000
73	7	8	4.50	0.5000	1.0000
74	7	9	2.20	\N	\N
75	7	10	1.50	0.5000	1.0000
76	7	11	0.50	\N	\N
77	7	18	4.00	0.3000	1.0000
78	7	19	5.50	\N	\N
79	7	16	0.00	\N	\N
80	7	17	0.00	\N	\N
81	7	3	15.00	\N	\N
82	7	4	4.00	\N	\N
83	7	5	5.00	\N	\N
84	7	23	5.00	\N	\N
85	7	24	0.00	\N	\N
86	8	1	400.00	200.0000	1.0000
87	8	2	-700.00	100.0000	1.0000
88	8	12	-2.00	5.0000	1.1000
89	8	6	-3.00	4.0000	1.1000
90	8	13	0.00	2.0000	1.1000
91	8	7	5.00	3.0000	1.1000
92	8	14	2.00	2.0000	1.0000
93	8	15	-0.40	0.3000	1.0000
94	8	8	4.00	0.5000	1.0000
95	8	9	2.50	\N	\N
96	8	10	2.00	1.0000	1.0000
97	8	11	0.50	\N	\N
98	8	18	1.40	0.2000	1.0000
99	8	19	3.00	\N	\N
100	8	16	10.00	\N	\N
101	8	17	15.00	\N	\N
102	8	3	30.00	\N	\N
103	8	4	3.00	\N	\N
104	8	5	2.00	\N	\N
105	8	23	15.00	\N	\N
106	8	24	0.00	\N	\N
\.


--
-- Data for Name: npc; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.npc (id, name, race_id, level, current_health, current_mana, is_dead, slug, radius, is_interactable, npc_type) FROM stdin;
1	Varan	1	1	100	10	f	varan	100	t	1
2	Milaya	1	1	100	50	f	milaya	100	t	1
3	Edrik	1	1	100	20	f	edrik	100	t	1
\.


--
-- Data for Name: npc_attributes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.npc_attributes (id, npc_id, attribute_id, value) FROM stdin;
1	1	1	100
2	1	2	10
3	2	1	100
4	2	2	50
5	3	1	100
7	3	2	50
\.


--
-- Data for Name: npc_dialogue; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.npc_dialogue (npc_id, dialogue_id, priority, condition_group) FROM stdin;
2	1	0	\N
\.


--
-- Data for Name: npc_placements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.npc_placements (id, npc_id, zone_id, x, y, z, rot_z) FROM stdin;
1	3	1	-720	2250	200	-135
2	2	1	2200	1120	200	145
3	1	1	585	-3300	200	-40
\.


--
-- Data for Name: npc_position; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.npc_position (id, npc_id, x, y, z, rot_z, zone_id) FROM stdin;
2	3	-720.00	2250.00	200.00	-135.00	\N
3	2	2200.00	1120.00	200.00	145.00	\N
1	1	585.00	-3300.00	200.00	-40.00	\N
\.


--
-- Data for Name: npc_skills; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.npc_skills (id, npc_id, skill_id, current_level) FROM stdin;
1	1	1	1
2	2	1	1
3	3	1	1
\.


--
-- Data for Name: npc_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.npc_type (id, name, slug) FROM stdin;
1	General	general
\.


--
-- Data for Name: player_active_effect; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.player_active_effect (id, player_id, effect_id, source_type, source_id, value, applied_at, expires_at, attribute_id, tick_ms) FROM stdin;
\.


--
-- Data for Name: player_flag; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.player_flag (player_id, flag_key, int_value, bool_value, updated_at) FROM stdin;
\.


--
-- Data for Name: player_inventory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.player_inventory (id, character_id, item_id, quantity, slot_index, durability_current) FROM stdin;
1	3	1	1	\N	\N
2	3	3	5	\N	\N
3	1	3	5	\N	\N
4	2	3	5	\N	\N
5	3	1	1	\N	\N
6	3	3	5	\N	\N
7	1	3	5	\N	\N
8	2	3	5	\N	\N
\.


--
-- Data for Name: player_quest; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.player_quest (player_id, quest_id, state, current_step, progress, updated_at) FROM stdin;
\.


--
-- Data for Name: quest; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.quest (id, slug, min_level, repeatable, cooldown_sec, giver_npc_id, turnin_npc_id, client_quest_key) FROM stdin;
1	wolf_hunt_intro	1	t	600	2	2	wolf_hunt_intro
\.


--
-- Data for Name: quest_reward; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.quest_reward (id, quest_id, reward_type, item_id, quantity, amount) FROM stdin;
1	1	item	3	5	0
2	1	exp	\N	0	300
\.


--
-- Data for Name: quest_step; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.quest_step (id, quest_id, step_index, step_type, params, client_step_key) FROM stdin;
1	1	0	kill	{"count": 5, "mob_id": 2}	kill_wolves
\.


--
-- Data for Name: race; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.race (id, name, slug) FROM stdin;
1	Human	human
2	Elf	elf
\.


--
-- Data for Name: skill_effect_instances; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skill_effect_instances (id, skill_id, order_idx, target_type_id) FROM stdin;
1	1	1	1
2	2	1	1
3	3	1	1
\.


--
-- Data for Name: skill_effects; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skill_effects (id, slug, effect_type_id) FROM stdin;
1	coeff	1
2	flat_add	1
\.


--
-- Data for Name: skill_effects_mapping; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skill_effects_mapping (id, effect_instance_id, effect_id, value, level, tick_ms, duration_ms, attribute_id) FROM stdin;
1	1	1	1.0	1	0	0	\N
2	2	1	1.8	1	0	0	\N
3	2	2	30	1	0	0	\N
4	3	1	2.2	1	0	0	\N
5	1	2	1	1	0	0	\N
6	3	2	20	1	0	0	\N
\.


--
-- Data for Name: skill_effects_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skill_effects_type (id, slug) FROM stdin;
1	damage
3	dot
4	hot
\.


--
-- Data for Name: skill_properties; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skill_properties (id, name, slug) FROM stdin;
2	Cooldown (ms)	cooldown_ms
4	Cast (ms)	cast_ms
5	Cost MP	cost_mp
6	Max Range	max_range
3	Global Cooldown (ms)	gcd_ms
7	Area Radius	area_radius
\.


--
-- Data for Name: skill_properties_mapping; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skill_properties_mapping (id, skill_id, skill_level, property_id, property_value) FROM stdin;
1	1	1	6	2.5
2	2	1	5	20
3	2	1	2	6000
4	2	1	3	1000
5	2	1	6	2.5
6	3	1	5	25
7	3	1	2	8000
9	3	1	6	15
10	1	1	3	500
11	1	1	2	100
8	3	1	4	4000
12	2	1	4	2000
13	3	1	3	2000
\.


--
-- Data for Name: skill_scale_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skill_scale_type (id, name, slug) FROM stdin;
1	PhysAtk	physical_attack
2	MagAtk	magical_attack
\.


--
-- Data for Name: skill_school; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skill_school (id, name, slug) FROM stdin;
1	Physical	physical
2	Magical	magical
\.


--
-- Data for Name: skills; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skills (id, name, slug, scale_stat_id, school_id) FROM stdin;
1	Basic Attack	basic_attack	1	1
2	Power Slash	power_slash	1	1
3	Fireball	fireball	2	2
\.


--
-- Data for Name: spawn_zone_mobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.spawn_zone_mobs (id, spawn_zone_id, mob_id, spawn_count, respawn_time) FROM stdin;
1	1	1	3	00:01:00
2	2	2	5	00:01:00
3	3	6	4	00:02:00
4	4	7	2	00:05:00
5	5	8	1	00:10:00
6	6	6	4	00:02:00
7	7	7	2	00:05:00
8	8	8	1	00:10:00
\.


--
-- Data for Name: spawn_zones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.spawn_zones (zone_id, zone_name, min_spawn_x, min_spawn_y, min_spawn_z, max_spawn_x, max_spawn_y, max_spawn_z, game_zone_id) FROM stdin;
1	Foxes Nest	-2900	4000	100	1000	1000	800	2
2	Wolf Place	-5900	5000	100	1000	1000	800	2
3	Wolf Pack Zone	-4000	5500	100	-2000	7000	800	2
4	Old Wolf Territory	-6500	3000	100	-4500	5000	800	2
5	Troll Cave Area	-8000	2000	100	-5500	4500	800	2
6	Wolf Pack Zone	-4000	5500	100	-2000	7000	800	2
7	Old Wolf Territory	-6500	3000	100	-4500	5000	800	2
8	Troll Cave Area	-8000	2000	100	-5500	4500	800	2
\.


--
-- Data for Name: target_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.target_type (id, slug) FROM stdin;
1	enemy
2	ally
3	self
\.


--
-- Data for Name: user_bans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_bans (id, user_id, banned_by_user_id, reason, created_at, expires_at, is_active) FROM stdin;
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_roles (id, name, label, is_staff) FROM stdin;
1	gm	GM	t
0	player	Player	f
2	admin	Admin	t
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_sessions (id, user_id, token_hash, ip, user_agent, created_at, expires_at, revoked_at) FROM stdin;
1	3	eade23af-3eae-4fd3-b8ca-0db00f4c47a4	\N	\N	2026-03-06 16:53:58.486682+00	2026-04-05 16:53:58.486682+00	\N
2	3	76cec5f3-e37f-4f0d-9544-3075fd401f86	\N	\N	2026-03-06 16:54:46.687878+00	2026-04-05 16:54:46.687878+00	\N
3	3	4a9bce84-b2fd-4d06-9af8-586b1455126d	\N	\N	2026-03-06 16:54:56.015881+00	2026-04-05 16:54:56.015881+00	\N
4	3	605c1627-e276-40a4-ba5a-b6b4e439b7eb	\N	\N	2026-03-06 16:55:55.390084+00	2026-04-05 16:55:55.390084+00	\N
5	3	e51cbaf3-b2a5-48fa-9711-26f3f07399a5	\N	\N	2026-03-06 17:06:59.025837+00	2026-04-05 17:06:59.025837+00	\N
6	4	71e2f6c1-20a3-4248-b899-fab23e540929	\N	\N	2026-03-06 17:07:56.079345+00	2026-04-05 17:07:56.079345+00	\N
7	3	6972d98e-26ae-4515-a1ec-61544ce4f537	\N	\N	2026-03-06 17:20:58.350871+00	2026-04-05 17:20:58.350871+00	\N
8	3	fcfc7725-e908-485b-880c-b49b6781aa72	\N	\N	2026-03-06 17:22:26.031292+00	2026-04-05 17:22:26.031292+00	\N
9	3	d44f4382-bddf-4308-8f8a-28504fda7a10	\N	\N	2026-03-06 17:23:38.159376+00	2026-04-05 17:23:38.159376+00	\N
10	3	72c0c467-8002-41a2-b7cb-7e71ce0714ef	\N	\N	2026-03-06 19:00:43.492241+00	2026-04-05 19:00:43.492241+00	\N
11	3	1c75a0dd-6454-4532-8f7b-8d77bdffb3e0	\N	\N	2026-03-06 19:01:50.188293+00	2026-04-05 19:01:50.188293+00	\N
12	3	0147e478-1632-491c-8cf7-7ccc09014b0c	\N	\N	2026-03-06 20:14:55.72122+00	2026-04-05 20:14:55.72122+00	\N
13	3	c508c0c6-b69b-453f-b238-d3997f54bc7f	\N	\N	2026-03-06 20:17:46.496119+00	2026-04-05 20:17:46.496119+00	\N
14	3	673cbe03-a076-4c8c-8107-2d845e99f0b9	\N	\N	2026-03-06 20:18:44.633977+00	2026-04-05 20:18:44.633977+00	\N
15	3	04857715-4351-4f24-bb89-c4dcbbaf7f49	\N	\N	2026-03-06 20:20:25.938048+00	2026-04-05 20:20:25.938048+00	\N
16	3	29c59f19-2cfa-42e7-a6cd-4e7f061b4fee	\N	\N	2026-03-06 20:22:55.547461+00	2026-04-05 20:22:55.547461+00	\N
17	3	2414a70f-6be1-4f20-a8ef-2f53e400eac6	\N	\N	2026-03-06 20:48:46.140207+00	2026-04-05 20:48:46.140207+00	\N
18	3	334dc5bc-8345-4a8e-94ee-23bb0e5f3016	\N	\N	2026-03-06 20:49:41.356769+00	2026-04-05 20:49:41.356769+00	\N
19	3	8fe9cb81-4f0e-4ab1-907d-0ab9de9d9817	\N	\N	2026-03-07 12:13:04.1728+00	2026-04-06 12:13:04.1728+00	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, login, password, last_login, email, role, created_at, is_active, failed_login_attempts, locked_until, last_login_ip, registration_ip, is_email_verified) FROM stdin;
5	test3	test3	2023-05-04 16:25:31.727922+00	\N	0	2026-03-03 16:16:54.618401+00	t	0	\N	\N	\N	f
4	test2	test2	2023-05-04 16:25:31.727922+00	\N	0	2026-03-03 16:16:54.618401+00	t	0	\N	\N	\N	f
3	test1	test1	2023-05-04 16:25:31.727922+00	\N	0	2026-03-03 16:16:54.618401+00	t	0	\N	\N	\N	f
\.


--
-- Data for Name: vendor_inventory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vendor_inventory (id, vendor_npc_id, item_id, stock_count, price_override) FROM stdin;
1	1	1	5	\N
2	1	2	5	\N
3	1	3	-1	\N
4	1	4	-1	\N
5	1	15	5	\N
\.


--
-- Data for Name: vendor_npc; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vendor_npc (id, npc_id, markup_pct) FROM stdin;
1	1	10
\.


--
-- Data for Name: zones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zones (id, slug, name, min_level, max_level, is_pvp, is_safe_zone) FROM stdin;
1	village	Village	1	10	f	t
2	wilderness	Wilderness	1	20	f	f
\.


--
-- Name: character_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_attributes_id_seq', 70, true);


--
-- Name: character_attributes_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_attributes_id_seq1', 24, true);


--
-- Name: character_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_class_id_seq', 2, true);


--
-- Name: character_equipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_equipment_id_seq', 1, false);


--
-- Name: character_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_position_id_seq', 3, true);


--
-- Name: character_skills_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_skills_id_seq1', 5, true);


--
-- Name: characters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.characters_id_seq', 3, true);


--
-- Name: class_skill_tree_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.class_skill_tree_id_seq', 4, true);


--
-- Name: currency_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.currency_transactions_id_seq', 1, false);


--
-- Name: dialogue_edge_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.dialogue_edge_id_seq', 6, true);


--
-- Name: dialogue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.dialogue_id_seq', 1, true);


--
-- Name: dialogue_node_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.dialogue_node_id_seq', 6, true);


--
-- Name: exp_for_level_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.exp_for_level_id_seq', 10, true);


--
-- Name: gm_action_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.gm_action_log_id_seq', 1, false);


--
-- Name: item_attributes_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_attributes_mapping_id_seq', 7, true);


--
-- Name: item_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_types_id_seq', 9, true);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.items_id_seq', 15, true);


--
-- Name: mob_active_effect_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.mob_active_effect_id_seq', 1, false);


--
-- Name: mob_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.mob_id_seq', 8, true);


--
-- Name: mob_loot_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.mob_loot_info_id_seq', 32, true);


--
-- Name: mob_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.mob_position_id_seq', 1, false);


--
-- Name: mob_race_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.mob_race_id_seq', 3, true);


--
-- Name: mob_skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.mob_skills_id_seq', 5, true);


--
-- Name: mob_stat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.mob_stat_id_seq', 106, true);


--
-- Name: npc_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_attributes_id_seq', 7, true);


--
-- Name: npc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_id_seq', 3, true);


--
-- Name: npc_placements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_placements_id_seq', 3, true);


--
-- Name: npc_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_position_id_seq', 1, false);


--
-- Name: npc_skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_skills_id_seq', 2, true);


--
-- Name: npc_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_type_id_seq', 1, true);


--
-- Name: player_active_effect_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.player_active_effect_id_seq', 1, false);


--
-- Name: player_inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.player_inventory_id_seq', 8, true);


--
-- Name: quest_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.quest_id_seq', 1, true);


--
-- Name: quest_reward_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.quest_reward_id_seq', 2, true);


--
-- Name: quest_step_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.quest_step_id_seq', 2, true);


--
-- Name: race_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.race_id_seq', 2, true);


--
-- Name: skill_effect_instances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skill_effect_instances_id_seq', 3, true);


--
-- Name: skill_effects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skill_effects_id_seq', 4, true);


--
-- Name: skill_effects_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skill_effects_mapping_id_seq', 6, true);


--
-- Name: skill_effects_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skill_effects_type_id_seq', 4, true);


--
-- Name: skill_properties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skill_properties_id_seq', 7, true);


--
-- Name: skill_scale_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skill_scale_type_id_seq', 4, true);


--
-- Name: skill_school_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skill_school_id_seq', 4, true);


--
-- Name: skills_attributes_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skills_attributes_mapping_id_seq', 13, true);


--
-- Name: skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skills_id_seq', 3, true);


--
-- Name: spawn_zone_mobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.spawn_zone_mobs_id_seq', 8, true);


--
-- Name: spawn_zones_zone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.spawn_zones_zone_id_seq', 8, true);


--
-- Name: target_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.target_type_id_seq', 6, true);


--
-- Name: user_bans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_bans_id_seq', 1, false);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_sessions_id_seq', 19, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 5, true);


--
-- Name: vendor_inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vendor_inventory_id_seq', 5, true);


--
-- Name: vendor_npc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vendor_npc_id_seq', 1, true);


--
-- Name: zones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zones_id_seq', 2, true);


--
-- Name: character_permanent_modifiers character_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_permanent_modifiers
    ADD CONSTRAINT character_attributes_pkey PRIMARY KEY (id);


--
-- Name: entity_attributes character_attributes_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_attributes
    ADD CONSTRAINT character_attributes_pkey1 PRIMARY KEY (id);


--
-- Name: character_class character_class_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_class
    ADD CONSTRAINT character_class_pkey PRIMARY KEY (id);


--
-- Name: character_current_state character_current_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_current_state
    ADD CONSTRAINT character_current_state_pkey PRIMARY KEY (character_id);


--
-- Name: character_equipment character_equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_equipment
    ADD CONSTRAINT character_equipment_pkey PRIMARY KEY (id);


--
-- Name: character_genders character_genders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_genders
    ADD CONSTRAINT character_genders_pkey PRIMARY KEY (id);


--
-- Name: character_position character_position_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_position
    ADD CONSTRAINT character_position_pkey PRIMARY KEY (id);


--
-- Name: character_skills character_skills_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_skills
    ADD CONSTRAINT character_skills_pkey1 PRIMARY KEY (id);


--
-- Name: characters characters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_pkey PRIMARY KEY (id);


--
-- Name: class_skill_tree class_skill_tree_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT class_skill_tree_pkey PRIMARY KEY (id);


--
-- Name: class_stat_formula class_stat_formula_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_stat_formula
    ADD CONSTRAINT class_stat_formula_pkey PRIMARY KEY (class_id, attribute_id);


--
-- Name: currency_transactions currency_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_transactions
    ADD CONSTRAINT currency_transactions_pkey PRIMARY KEY (id);


--
-- Name: dialogue_edge dialogue_edge_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_edge
    ADD CONSTRAINT dialogue_edge_pkey PRIMARY KEY (id);


--
-- Name: dialogue_node dialogue_node_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_node
    ADD CONSTRAINT dialogue_node_pkey PRIMARY KEY (id);


--
-- Name: dialogue dialogue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue
    ADD CONSTRAINT dialogue_pkey PRIMARY KEY (id);


--
-- Name: dialogue dialogue_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue
    ADD CONSTRAINT dialogue_slug_key UNIQUE (slug);


--
-- Name: equip_slot equip_slot_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equip_slot
    ADD CONSTRAINT equip_slot_pkey PRIMARY KEY (id);


--
-- Name: equip_slot equip_slot_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equip_slot
    ADD CONSTRAINT equip_slot_slug_key UNIQUE (slug);


--
-- Name: game_config game_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_config
    ADD CONSTRAINT game_config_pkey PRIMARY KEY (key);


--
-- Name: gm_action_log gm_action_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gm_action_log
    ADD CONSTRAINT gm_action_log_pkey PRIMARY KEY (id);


--
-- Name: item_attributes_mapping item_attributes_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_attributes_mapping
    ADD CONSTRAINT item_attributes_mapping_pkey PRIMARY KEY (id);


--
-- Name: item_types item_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_types
    ADD CONSTRAINT item_types_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: mob_active_effect mob_active_effect_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_active_effect
    ADD CONSTRAINT mob_active_effect_pkey PRIMARY KEY (id);


--
-- Name: mob_loot_info mob_loot_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_loot_info
    ADD CONSTRAINT mob_loot_info_pkey PRIMARY KEY (id);


--
-- Name: mob mob_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_pkey PRIMARY KEY (id);


--
-- Name: mob_position mob_position_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_position
    ADD CONSTRAINT mob_position_pkey PRIMARY KEY (id);


--
-- Name: mob_race mob_race_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_race
    ADD CONSTRAINT mob_race_pkey PRIMARY KEY (id);


--
-- Name: mob_ranks mob_ranks_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_ranks
    ADD CONSTRAINT mob_ranks_code_key UNIQUE (code);


--
-- Name: mob_ranks mob_ranks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_ranks
    ADD CONSTRAINT mob_ranks_pkey PRIMARY KEY (rank_id);


--
-- Name: mob_skills mob_skills_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_skills
    ADD CONSTRAINT mob_skills_pkey1 PRIMARY KEY (id);


--
-- Name: mob mob_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_slug_key UNIQUE (slug);


--
-- Name: mob_stat mob_stat_mob_attr_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_stat
    ADD CONSTRAINT mob_stat_mob_attr_unique UNIQUE (mob_id, attribute_id);


--
-- Name: mob_stat mob_stat_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_stat
    ADD CONSTRAINT mob_stat_pkey PRIMARY KEY (id);


--
-- Name: npc_attributes npc_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_attributes
    ADD CONSTRAINT npc_attributes_pkey PRIMARY KEY (id);


--
-- Name: npc_dialogue npc_dialogue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_dialogue
    ADD CONSTRAINT npc_dialogue_pkey PRIMARY KEY (npc_id, dialogue_id);


--
-- Name: npc npc_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_pkey PRIMARY KEY (id);


--
-- Name: npc_placements npc_placements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_placements
    ADD CONSTRAINT npc_placements_pkey PRIMARY KEY (id);


--
-- Name: npc_position npc_position_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_position
    ADD CONSTRAINT npc_position_pkey PRIMARY KEY (id);


--
-- Name: npc_skills npc_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_skills
    ADD CONSTRAINT npc_skills_pkey PRIMARY KEY (id);


--
-- Name: npc npc_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_slug_key UNIQUE (slug);


--
-- Name: npc_type npc_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_type
    ADD CONSTRAINT npc_type_pkey PRIMARY KEY (id);


--
-- Name: player_active_effect player_active_effect_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_pkey PRIMARY KEY (id);


--
-- Name: player_flag player_flag_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_flag
    ADD CONSTRAINT player_flag_pkey PRIMARY KEY (player_id, flag_key);


--
-- Name: player_inventory player_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_inventory
    ADD CONSTRAINT player_inventory_pkey PRIMARY KEY (id);


--
-- Name: player_quest player_quest_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_quest
    ADD CONSTRAINT player_quest_pkey PRIMARY KEY (player_id, quest_id);


--
-- Name: quest quest_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest
    ADD CONSTRAINT quest_pkey PRIMARY KEY (id);


--
-- Name: quest_reward quest_reward_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest_reward
    ADD CONSTRAINT quest_reward_pkey PRIMARY KEY (id);


--
-- Name: quest quest_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest
    ADD CONSTRAINT quest_slug_key UNIQUE (slug);


--
-- Name: quest_step quest_step_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest_step
    ADD CONSTRAINT quest_step_pkey PRIMARY KEY (id);


--
-- Name: quest_step quest_step_quest_id_step_index_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest_step
    ADD CONSTRAINT quest_step_quest_id_step_index_key UNIQUE (quest_id, step_index);


--
-- Name: race race_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.race
    ADD CONSTRAINT race_pkey PRIMARY KEY (id);


--
-- Name: items_rarity rarity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items_rarity
    ADD CONSTRAINT rarity_pkey PRIMARY KEY (id);


--
-- Name: skill_effect_instances skill_effect_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effect_instances
    ADD CONSTRAINT skill_effect_instances_pkey PRIMARY KEY (id);


--
-- Name: skill_effect_instances skill_effect_instances_skill_id_order_idx_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effect_instances
    ADD CONSTRAINT skill_effect_instances_skill_id_order_idx_key UNIQUE (skill_id, order_idx);


--
-- Name: skill_effects_mapping skill_effects_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_pkey PRIMARY KEY (id);


--
-- Name: skill_effects skill_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects
    ADD CONSTRAINT skill_effects_pkey PRIMARY KEY (id);


--
-- Name: skill_effects skill_effects_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects
    ADD CONSTRAINT skill_effects_slug_key UNIQUE (slug);


--
-- Name: skill_effects_type skill_effects_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects_type
    ADD CONSTRAINT skill_effects_type_pkey PRIMARY KEY (id);


--
-- Name: skill_effects_type skill_effects_type_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects_type
    ADD CONSTRAINT skill_effects_type_slug_key UNIQUE (slug);


--
-- Name: skill_properties skill_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_properties
    ADD CONSTRAINT skill_properties_pkey PRIMARY KEY (id);


--
-- Name: skill_scale_type skill_scale_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_scale_type
    ADD CONSTRAINT skill_scale_pkey PRIMARY KEY (id);


--
-- Name: skill_school skill_school_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_school
    ADD CONSTRAINT skill_school_pkey PRIMARY KEY (id);


--
-- Name: skill_properties_mapping skills_attributes_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_properties_mapping
    ADD CONSTRAINT skills_attributes_mapping_pkey PRIMARY KEY (id);


--
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (id);


--
-- Name: spawn_zone_mobs spawn_zone_mobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_zone_mobs
    ADD CONSTRAINT spawn_zone_mobs_pkey PRIMARY KEY (id);


--
-- Name: spawn_zone_mobs spawn_zone_mobs_spawn_zone_id_mob_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_zone_mobs
    ADD CONSTRAINT spawn_zone_mobs_spawn_zone_id_mob_id_key UNIQUE (spawn_zone_id, mob_id);


--
-- Name: spawn_zones spawn_zones_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_zones
    ADD CONSTRAINT spawn_zones_pkey1 PRIMARY KEY (zone_id);


--
-- Name: target_type target_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_type
    ADD CONSTRAINT target_type_pkey PRIMARY KEY (id);


--
-- Name: target_type target_type_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_type
    ADD CONSTRAINT target_type_slug_key UNIQUE (slug);


--
-- Name: character_equipment uq_character_equip_slot; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_equipment
    ADD CONSTRAINT uq_character_equip_slot UNIQUE (character_id, equip_slot_id);


--
-- Name: class_skill_tree uq_class_skill; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT uq_class_skill UNIQUE (class_id, skill_id);


--
-- Name: vendor_inventory uq_vendor_item; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_inventory
    ADD CONSTRAINT uq_vendor_item UNIQUE (vendor_npc_id, item_id);


--
-- Name: user_bans user_bans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_bans
    ADD CONSTRAINT user_bans_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_token_hash_key UNIQUE (token_hash);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vendor_inventory vendor_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_inventory
    ADD CONSTRAINT vendor_inventory_pkey PRIMARY KEY (id);


--
-- Name: vendor_npc vendor_npc_npc_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_npc
    ADD CONSTRAINT vendor_npc_npc_id_key UNIQUE (npc_id);


--
-- Name: vendor_npc vendor_npc_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_npc
    ADD CONSTRAINT vendor_npc_pkey PRIMARY KEY (id);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: zones zones_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_slug_key UNIQUE (slug);


--
-- Name: idx_mob_active_effect_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mob_active_effect_expires_at ON public.mob_active_effect USING btree (expires_at) WHERE (expires_at IS NOT NULL);


--
-- Name: idx_mob_active_effect_mob_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mob_active_effect_mob_uid ON public.mob_active_effect USING btree (mob_uid);


--
-- Name: idx_mob_loot_info_mob; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mob_loot_info_mob ON public.mob_loot_info USING btree (mob_id);


--
-- Name: idx_mob_position_mob; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mob_position_mob ON public.mob_position USING btree (mob_id);


--
-- Name: idx_mob_stat_mob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mob_stat_mob_id ON public.mob_stat USING btree (mob_id);


--
-- Name: idx_npc_dialogue_npc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_npc_dialogue_npc ON public.npc_dialogue USING btree (npc_id);


--
-- Name: idx_npc_placements_npc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_npc_placements_npc ON public.npc_placements USING btree (npc_id);


--
-- Name: idx_npc_placements_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_npc_placements_zone ON public.npc_placements USING btree (zone_id);


--
-- Name: idx_npc_position_npc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_npc_position_npc ON public.npc_position USING btree (npc_id);


--
-- Name: idx_player_active_effect_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_player_active_effect_expires ON public.player_active_effect USING btree (expires_at) WHERE (expires_at IS NOT NULL);


--
-- Name: idx_player_active_effect_player; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_player_active_effect_player ON public.player_active_effect USING btree (player_id);


--
-- Name: idx_player_inventory_character; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_player_inventory_character ON public.player_inventory USING btree (character_id);


--
-- Name: idx_quest_reward_quest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_quest_reward_quest ON public.quest_reward USING btree (quest_id);


--
-- Name: idx_spawn_zone_mobs_mob; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_spawn_zone_mobs_mob ON public.spawn_zone_mobs USING btree (mob_id);


--
-- Name: idx_spawn_zone_mobs_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_spawn_zone_mobs_zone ON public.spawn_zone_mobs USING btree (spawn_zone_id);


--
-- Name: idx_spawn_zones_game_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_spawn_zones_game_zone ON public.spawn_zones USING btree (game_zone_id);


--
-- Name: ix_char_perm_mod_character; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_char_perm_mod_character ON public.character_permanent_modifiers USING btree (character_id);


--
-- Name: ix_char_perm_mod_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_char_perm_mod_source ON public.character_permanent_modifiers USING btree (source_type, source_id) WHERE (source_id IS NOT NULL);


--
-- Name: ix_character_attributes_char_attr; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_character_attributes_char_attr ON public.character_permanent_modifiers USING btree (character_id, attribute_id);


--
-- Name: ix_character_class_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_character_class_slug ON public.character_class USING btree (slug) WHERE (slug IS NOT NULL);


--
-- Name: ix_character_equipment_char; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_character_equipment_char ON public.character_equipment USING btree (character_id);


--
-- Name: ix_character_equipment_inv_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_character_equipment_inv_item ON public.character_equipment USING btree (inventory_item_id);


--
-- Name: ix_character_position_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_character_position_zone ON public.character_position USING btree (zone_id);


--
-- Name: ix_characters_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_characters_deleted ON public.characters USING btree (deleted_at) WHERE (deleted_at IS NOT NULL);


--
-- Name: ix_characters_owner_slot; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_characters_owner_slot ON public.characters USING btree (owner_id, account_slot);


--
-- Name: ix_class_skill_tree_class; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_class_skill_tree_class ON public.class_skill_tree USING btree (class_id);


--
-- Name: ix_class_stat_formula_class; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_class_stat_formula_class ON public.class_stat_formula USING btree (class_id);


--
-- Name: ix_currency_transactions_char; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_currency_transactions_char ON public.currency_transactions USING btree (character_id);


--
-- Name: ix_currency_transactions_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_currency_transactions_created ON public.currency_transactions USING btree (created_at DESC);


--
-- Name: ix_currency_transactions_reason; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_currency_transactions_reason ON public.currency_transactions USING btree (reason_type);


--
-- Name: ix_dialogue_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dialogue_slug ON public.dialogue USING btree (slug);


--
-- Name: ix_edge_act_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_edge_act_gin ON public.dialogue_edge USING gin (action_group);


--
-- Name: ix_edge_cond_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_edge_cond_gin ON public.dialogue_edge USING gin (condition_group);


--
-- Name: INDEX ix_edge_cond_gin; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON INDEX public.ix_edge_cond_gin IS 'GIN по условиям ребра (jsonb)';


--
-- Name: ix_edge_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_edge_from ON public.dialogue_edge USING btree (from_node_id);


--
-- Name: ix_edge_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_edge_to ON public.dialogue_edge USING btree (to_node_id);


--
-- Name: ix_gm_action_log_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_gm_action_log_created ON public.gm_action_log USING btree (created_at DESC);


--
-- Name: ix_gm_action_log_gm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_gm_action_log_gm ON public.gm_action_log USING btree (gm_user_id);


--
-- Name: ix_gm_action_log_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_gm_action_log_target ON public.gm_action_log USING btree (target_type, target_id);


--
-- Name: ix_iam_attribute_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_iam_attribute_id ON public.item_attributes_mapping USING btree (attribute_id);


--
-- Name: ix_iam_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_iam_item_id ON public.item_attributes_mapping USING btree (item_id);


--
-- Name: ix_items_item_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_items_item_type ON public.items USING btree (item_type);


--
-- Name: ix_mob_position_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mob_position_zone ON public.mob_position USING btree (zone_id);


--
-- Name: ix_node_act_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_node_act_gin ON public.dialogue_node USING gin (action_group);


--
-- Name: ix_node_cond_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_node_cond_gin ON public.dialogue_node USING gin (condition_group);


--
-- Name: INDEX ix_node_cond_gin; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON INDEX public.ix_node_cond_gin IS 'GIN по условиям узла (jsonb)';


--
-- Name: ix_node_dialogue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_node_dialogue ON public.dialogue_node USING btree (dialogue_id);


--
-- Name: ix_npc_attributes_npc_attr; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_npc_attributes_npc_attr ON public.npc_attributes USING btree (npc_id, attribute_id);


--
-- Name: ix_npc_position_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_npc_position_zone ON public.npc_position USING btree (zone_id);


--
-- Name: ix_pae_attribute_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pae_attribute_id ON public.player_active_effect USING btree (attribute_id) WHERE (attribute_id IS NOT NULL);


--
-- Name: ix_pae_effect_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pae_effect_id ON public.player_active_effect USING btree (effect_id);


--
-- Name: ix_player_flag_bool; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_player_flag_bool ON public.player_flag USING btree (player_id, flag_key, bool_value);


--
-- Name: ix_player_flag_int; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_player_flag_int ON public.player_flag USING btree (player_id, flag_key, int_value);


--
-- Name: ix_player_inventory_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_player_inventory_item_id ON public.player_inventory USING btree (item_id);


--
-- Name: ix_player_quest_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_player_quest_state ON public.player_quest USING btree (player_id, state);


--
-- Name: ix_quest_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_quest_slug ON public.quest USING btree (slug);


--
-- Name: ix_quest_step_q; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_quest_step_q ON public.quest_step USING btree (quest_id, step_index);


--
-- Name: ix_user_bans_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_bans_active ON public.user_bans USING btree (is_active, expires_at);


--
-- Name: ix_user_bans_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_bans_user ON public.user_bans USING btree (user_id) WHERE (is_active = true);


--
-- Name: ix_user_sessions_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_sessions_expires ON public.user_sessions USING btree (expires_at) WHERE (revoked_at IS NULL);


--
-- Name: ix_user_sessions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_sessions_user ON public.user_sessions USING btree (user_id);


--
-- Name: ix_vendor_inventory_vendor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_vendor_inventory_vendor ON public.vendor_inventory USING btree (vendor_npc_id);


--
-- Name: ix_zones_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zones_slug ON public.zones USING btree (slug);


--
-- Name: uq_character_skills; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_character_skills ON public.character_skills USING btree (character_id, skill_id);


--
-- Name: uq_effects_map; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_effects_map ON public.skill_effects_mapping USING btree (effect_instance_id, level, effect_id);


--
-- Name: uq_entity_attributes_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_entity_attributes_slug ON public.entity_attributes USING btree (slug);


--
-- Name: uq_inventory_slot; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_inventory_slot ON public.player_inventory USING btree (character_id, slot_index) WHERE (slot_index IS NOT NULL);


--
-- Name: uq_item_types_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_item_types_slug ON public.item_types USING btree (slug);


--
-- Name: uq_items_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_items_slug ON public.items USING btree (slug);


--
-- Name: uq_mob_skills; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_mob_skills ON public.mob_skills USING btree (mob_id, skill_id);


--
-- Name: uq_npc_skills; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_npc_skills ON public.npc_skills USING btree (npc_id, skill_id);


--
-- Name: uq_skill_effects_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_skill_effects_slug ON public.skill_effects USING btree (slug);


--
-- Name: uq_skill_effects_type_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_skill_effects_type_slug ON public.skill_effects_type USING btree (slug);


--
-- Name: uq_skill_properties_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_skill_properties_slug ON public.skill_properties USING btree (slug);


--
-- Name: uq_skill_props_map; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_skill_props_map ON public.skill_properties_mapping USING btree (skill_id, skill_level, property_id);


--
-- Name: uq_skill_scale_type_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_skill_scale_type_slug ON public.skill_scale_type USING btree (slug);


--
-- Name: uq_skill_school_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_skill_school_slug ON public.skill_school USING btree (slug);


--
-- Name: uq_skills_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_skills_slug ON public.skills USING btree (slug);


--
-- Name: uq_target_type_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_target_type_slug ON public.target_type USING btree (slug);


--
-- Name: game_config trg_game_config_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_game_config_updated_at BEFORE UPDATE ON public.game_config FOR EACH ROW EXECUTE FUNCTION public.game_config_set_updated_at();


--
-- Name: character_permanent_modifiers character_attributes_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_permanent_modifiers
    ADD CONSTRAINT character_attributes_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: character_permanent_modifiers character_attributes_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_permanent_modifiers
    ADD CONSTRAINT character_attributes_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_equipment character_equipment_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_equipment
    ADD CONSTRAINT character_equipment_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_equipment character_equipment_equip_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_equipment
    ADD CONSTRAINT character_equipment_equip_slot_id_fkey FOREIGN KEY (equip_slot_id) REFERENCES public.equip_slot(id);


--
-- Name: character_equipment character_equipment_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_equipment
    ADD CONSTRAINT character_equipment_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.player_inventory(id) ON DELETE CASCADE;


--
-- Name: character_position character_position_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_position
    ADD CONSTRAINT character_position_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_position character_position_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_position
    ADD CONSTRAINT character_position_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: character_skills character_skills_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_skills
    ADD CONSTRAINT character_skills_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_skills character_skills_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_skills
    ADD CONSTRAINT character_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: characters characters_bind_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_bind_zone_id_fkey FOREIGN KEY (bind_zone_id) REFERENCES public.zones(id);


--
-- Name: characters characters_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id);


--
-- Name: characters characters_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: characters characters_race_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_race_id_fkey FOREIGN KEY (race_id) REFERENCES public.race(id);


--
-- Name: class_skill_tree class_skill_tree_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT class_skill_tree_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id) ON DELETE CASCADE;


--
-- Name: class_skill_tree class_skill_tree_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT class_skill_tree_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: class_stat_formula class_stat_formula_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_stat_formula
    ADD CONSTRAINT class_stat_formula_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id) ON DELETE RESTRICT;


--
-- Name: class_stat_formula class_stat_formula_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_stat_formula
    ADD CONSTRAINT class_stat_formula_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id) ON DELETE CASCADE;


--
-- Name: currency_transactions currency_transactions_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_transactions
    ADD CONSTRAINT currency_transactions_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: dialogue_edge dialogue_edge_from_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_edge
    ADD CONSTRAINT dialogue_edge_from_node_id_fkey FOREIGN KEY (from_node_id) REFERENCES public.dialogue_node(id) ON DELETE CASCADE;


--
-- Name: dialogue_edge dialogue_edge_to_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_edge
    ADD CONSTRAINT dialogue_edge_to_node_id_fkey FOREIGN KEY (to_node_id) REFERENCES public.dialogue_node(id) ON DELETE CASCADE;


--
-- Name: dialogue_node dialogue_node_dialogue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_node
    ADD CONSTRAINT dialogue_node_dialogue_id_fkey FOREIGN KEY (dialogue_id) REFERENCES public.dialogue(id) ON DELETE CASCADE;


--
-- Name: dialogue_node dialogue_node_jump_target_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_node
    ADD CONSTRAINT dialogue_node_jump_target_fkey FOREIGN KEY (jump_target_node_id) REFERENCES public.dialogue_node(id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;


--
-- Name: dialogue_node dialogue_node_speaker_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dialogue_node
    ADD CONSTRAINT dialogue_node_speaker_npc_id_fkey FOREIGN KEY (speaker_npc_id) REFERENCES public.npc(id) ON DELETE SET NULL;


--
-- Name: character_current_state fk_char_current_state; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_current_state
    ADD CONSTRAINT fk_char_current_state FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: characters fk_characters_gender; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT fk_characters_gender FOREIGN KEY (gender) REFERENCES public.character_genders(id);


--
-- Name: mob_position fk_mob_position_mob; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_position
    ADD CONSTRAINT fk_mob_position_mob FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: mob_position fk_mob_position_zone; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_position
    ADD CONSTRAINT fk_mob_position_zone FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;


--
-- Name: npc_position fk_npc_position_npc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_position
    ADD CONSTRAINT fk_npc_position_npc FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: npc_position fk_npc_position_zone; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_position
    ADD CONSTRAINT fk_npc_position_zone FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;


--
-- Name: users fk_users_role; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_role FOREIGN KEY (role) REFERENCES public.user_roles(id);


--
-- Name: gm_action_log gm_action_log_gm_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gm_action_log
    ADD CONSTRAINT gm_action_log_gm_user_id_fkey FOREIGN KEY (gm_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: item_attributes_mapping item_attributes_mapping_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_attributes_mapping
    ADD CONSTRAINT item_attributes_mapping_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: item_attributes_mapping item_attributes_mapping_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_attributes_mapping
    ADD CONSTRAINT item_attributes_mapping_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: items items_equip_slot_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_equip_slot_fkey FOREIGN KEY (equip_slot) REFERENCES public.equip_slot(id) ON DELETE SET NULL;


--
-- Name: items items_item_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_item_type_fkey FOREIGN KEY (item_type) REFERENCES public.item_types(id);


--
-- Name: items items_rarity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_rarity_id_fkey FOREIGN KEY (rarity_id) REFERENCES public.items_rarity(id);


--
-- Name: mob_active_effect mob_active_effect_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_active_effect
    ADD CONSTRAINT mob_active_effect_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id) ON DELETE SET NULL;


--
-- Name: mob_active_effect mob_active_effect_effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_active_effect
    ADD CONSTRAINT mob_active_effect_effect_id_fkey FOREIGN KEY (effect_id) REFERENCES public.skill_effects(id) ON DELETE CASCADE;


--
-- Name: mob_loot_info mob_loot_info_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_loot_info
    ADD CONSTRAINT mob_loot_info_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: mob_loot_info mob_loot_info_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_loot_info
    ADD CONSTRAINT mob_loot_info_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: mob mob_race_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_race_id_fkey FOREIGN KEY (race_id) REFERENCES public.mob_race(id);


--
-- Name: mob mob_rank_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_rank_id_fkey FOREIGN KEY (rank_id) REFERENCES public.mob_ranks(rank_id);


--
-- Name: mob_skills mob_skills_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_skills
    ADD CONSTRAINT mob_skills_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: mob_skills mob_skills_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_skills
    ADD CONSTRAINT mob_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: mob_stat mob_stat_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_stat
    ADD CONSTRAINT mob_stat_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id) ON DELETE CASCADE;


--
-- Name: mob_stat mob_stat_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_stat
    ADD CONSTRAINT mob_stat_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: npc_attributes npc_attributes_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_attributes
    ADD CONSTRAINT npc_attributes_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: npc_attributes npc_attributes_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_attributes
    ADD CONSTRAINT npc_attributes_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id);


--
-- Name: npc_dialogue npc_dialogue_dialogue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_dialogue
    ADD CONSTRAINT npc_dialogue_dialogue_id_fkey FOREIGN KEY (dialogue_id) REFERENCES public.dialogue(id) ON DELETE CASCADE;


--
-- Name: npc_dialogue npc_dialogue_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_dialogue
    ADD CONSTRAINT npc_dialogue_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: npc npc_npc_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_npc_type_fkey FOREIGN KEY (npc_type) REFERENCES public.npc_type(id);


--
-- Name: npc_placements npc_placements_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_placements
    ADD CONSTRAINT npc_placements_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: npc_placements npc_placements_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_placements
    ADD CONSTRAINT npc_placements_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;


--
-- Name: npc npc_race_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_race_id_fkey FOREIGN KEY (race_id) REFERENCES public.race(id);


--
-- Name: npc_skills npc_skills_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_skills
    ADD CONSTRAINT npc_skills_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: npc_skills npc_skills_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_skills
    ADD CONSTRAINT npc_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: player_active_effect player_active_effect_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: player_active_effect player_active_effect_effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_effect_id_fkey FOREIGN KEY (effect_id) REFERENCES public.skill_effects(id);


--
-- Name: player_active_effect player_active_effect_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: player_flag player_flag_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_flag
    ADD CONSTRAINT player_flag_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: player_inventory player_inventory_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_inventory
    ADD CONSTRAINT player_inventory_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: player_inventory player_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_inventory
    ADD CONSTRAINT player_inventory_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: player_quest player_quest_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_quest
    ADD CONSTRAINT player_quest_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: player_quest player_quest_quest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_quest
    ADD CONSTRAINT player_quest_quest_id_fkey FOREIGN KEY (quest_id) REFERENCES public.quest(id) ON DELETE CASCADE;


--
-- Name: quest quest_giver_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest
    ADD CONSTRAINT quest_giver_npc_id_fkey FOREIGN KEY (giver_npc_id) REFERENCES public.npc(id) ON DELETE SET NULL;


--
-- Name: quest_reward quest_reward_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest_reward
    ADD CONSTRAINT quest_reward_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE SET NULL;


--
-- Name: quest_reward quest_reward_quest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest_reward
    ADD CONSTRAINT quest_reward_quest_id_fkey FOREIGN KEY (quest_id) REFERENCES public.quest(id) ON DELETE CASCADE;


--
-- Name: quest_step quest_step_quest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest_step
    ADD CONSTRAINT quest_step_quest_id_fkey FOREIGN KEY (quest_id) REFERENCES public.quest(id) ON DELETE CASCADE;


--
-- Name: quest quest_turnin_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest
    ADD CONSTRAINT quest_turnin_npc_id_fkey FOREIGN KEY (turnin_npc_id) REFERENCES public.npc(id) ON DELETE SET NULL;


--
-- Name: skill_effect_instances skill_effect_instances_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effect_instances
    ADD CONSTRAINT skill_effect_instances_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: skill_effect_instances skill_effect_instances_target_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effect_instances
    ADD CONSTRAINT skill_effect_instances_target_type_id_fkey FOREIGN KEY (target_type_id) REFERENCES public.target_type(id);


--
-- Name: skill_effects skill_effects_effect_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects
    ADD CONSTRAINT skill_effects_effect_type_id_fkey FOREIGN KEY (effect_type_id) REFERENCES public.skill_effects_type(id);


--
-- Name: skill_effects_mapping skill_effects_mapping_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: skill_effects_mapping skill_effects_mapping_effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_effect_id_fkey FOREIGN KEY (effect_id) REFERENCES public.skill_effects(id);


--
-- Name: skill_effects_mapping skill_effects_mapping_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_instance_id_fkey FOREIGN KEY (effect_instance_id) REFERENCES public.skill_effect_instances(id) ON DELETE CASCADE;


--
-- Name: skill_properties_mapping skill_properties_mapping_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_properties_mapping
    ADD CONSTRAINT skill_properties_mapping_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.skill_properties(id);


--
-- Name: skill_properties_mapping skill_properties_mapping_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_properties_mapping
    ADD CONSTRAINT skill_properties_mapping_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id) ON DELETE CASCADE;


--
-- Name: spawn_zone_mobs spawn_zone_mobs_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_zone_mobs
    ADD CONSTRAINT spawn_zone_mobs_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: spawn_zone_mobs spawn_zone_mobs_spawn_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_zone_mobs
    ADD CONSTRAINT spawn_zone_mobs_spawn_zone_id_fkey FOREIGN KEY (spawn_zone_id) REFERENCES public.spawn_zones(zone_id) ON DELETE CASCADE;


--
-- Name: spawn_zones spawn_zones_game_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_zones
    ADD CONSTRAINT spawn_zones_game_zone_id_fkey FOREIGN KEY (game_zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;


--
-- Name: user_bans user_bans_banned_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_bans
    ADD CONSTRAINT user_bans_banned_by_user_id_fkey FOREIGN KEY (banned_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_bans user_bans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_bans
    ADD CONSTRAINT user_bans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: vendor_inventory vendor_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_inventory
    ADD CONSTRAINT vendor_inventory_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: vendor_inventory vendor_inventory_vendor_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_inventory
    ADD CONSTRAINT vendor_inventory_vendor_npc_id_fkey FOREIGN KEY (vendor_npc_id) REFERENCES public.vendor_npc(id) ON DELETE CASCADE;


--
-- Name: vendor_npc vendor_npc_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_npc
    ADD CONSTRAINT vendor_npc_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

