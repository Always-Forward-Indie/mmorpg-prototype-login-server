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
-- Name: effect_modifier_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.effect_modifier_type AS ENUM (
    'flat',
    'percent',
    'percent_all'
);


ALTER TYPE public.effect_modifier_type OWNER TO postgres;

--
-- Name: node_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.node_type AS ENUM (
    'line',
    'choice_hub',
    'action',
    'jump',
    'end'
);


ALTER TYPE public.node_type OWNER TO postgres;

--
-- Name: TYPE node_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE public.node_type IS 'Тип узла диалога: line/choice_hub/action/jump/end';


--
-- Name: quest_state; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.quest_state AS ENUM (
    'offered',
    'active',
    'completed',
    'turned_in',
    'failed'
);


ALTER TYPE public.quest_state OWNER TO postgres;

--
-- Name: TYPE quest_state; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE public.quest_state IS 'Состояние квеста у игрока';


--
-- Name: quest_step_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.quest_step_type AS ENUM (
    'collect',
    'kill',
    'talk',
    'reach',
    'custom'
);


ALTER TYPE public.quest_step_type OWNER TO postgres;

--
-- Name: TYPE quest_step_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE public.quest_step_type IS 'Тип шага квеста (структура в params JSON)';


--
-- Name: status_effect_category; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.status_effect_category AS ENUM (
    'buff',
    'debuff',
    'dot',
    'hot',
    'cc'
);


ALTER TYPE public.status_effect_category OWNER TO postgres;

--
-- Name: game_config_set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.game_config_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.game_config_set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: character_permanent_modifiers; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.character_permanent_modifiers OWNER TO postgres;

--
-- Name: TABLE character_permanent_modifiers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_permanent_modifiers IS 'Постоянные модификаторы характеристик персонажа из внешних источников. Источники: квест, достижение, GM-правка, событие. НЕ является кешем — это источник правды для перманентных бонусов. Базовые статы класса хранятся в class_stat_formula, бонусы шмота — в character_equipment.';


--
-- Name: COLUMN character_permanent_modifiers.attribute_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_permanent_modifiers.attribute_id IS 'Характеристика из entity_attributes';


--
-- Name: COLUMN character_permanent_modifiers.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_permanent_modifiers.value IS 'Значение бонуса (может быть отрицательным для штрафов)';


--
-- Name: COLUMN character_permanent_modifiers.source_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_permanent_modifiers.source_type IS 'Источник: gm | quest | achievement | event | admin';


--
-- Name: COLUMN character_permanent_modifiers.source_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_permanent_modifiers.source_id IS 'ID источника (quest.id / achievement.id / NULL для GM)';


--
-- Name: character_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: entity_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.entity_attributes (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL
);


ALTER TABLE public.entity_attributes OWNER TO postgres;

--
-- Name: TABLE entity_attributes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.entity_attributes IS 'Справочник всех атрибутов игровых сущностей (сила, ловкость, физический урон и т.д.). Единый для персонажей, мобов, NPC и предметов. Использовать slug как стабильный ключ — id может меняться между окружениями.';


--
-- Name: COLUMN entity_attributes.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.entity_attributes.id IS 'Суррогатный PK. В коде ссылаться по slug, не по числу.';


--
-- Name: COLUMN entity_attributes.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.entity_attributes.name IS 'Отображаемое название атрибута (EN), например "Physical Attack".';


--
-- Name: COLUMN entity_attributes.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.entity_attributes.slug IS 'Машиночитаемый ключ атрибута, уникален. Примеры: strength, agility, physical_attack, physical_defense, crit_chance, evasion, heal_on_use, hunger_restore. Использовать в коде вместо числового id.';


--
-- Name: character_attributes_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: character_bestiary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_bestiary (
    character_id integer NOT NULL,
    mob_template_id integer NOT NULL,
    kill_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.character_bestiary OWNER TO postgres;

--
-- Name: character_class; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_class (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50),
    description text
);


ALTER TABLE public.character_class OWNER TO postgres;

--
-- Name: TABLE character_class; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_class IS 'Классы персонажей (воин, маг и т.д.)';


--
-- Name: character_class_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: character_current_state; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_current_state (
    character_id bigint NOT NULL,
    current_health integer DEFAULT 1 NOT NULL,
    current_mana integer DEFAULT 1 NOT NULL,
    is_dead boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.character_current_state OWNER TO postgres;

--
-- Name: TABLE character_current_state; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_current_state IS 'Горячее состояние персонажа (HP/MP/смерть). Пишется часто (каждый тик боя). Хранить отдельно от персистентных данных characters';


--
-- Name: COLUMN character_current_state.current_health; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_current_state.current_health IS 'Текущие HP. Меняются в бою каждые N мс';


--
-- Name: COLUMN character_current_state.current_mana; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_current_state.current_mana IS 'Текущая мана. Меняется при кастах и регене';


--
-- Name: COLUMN character_current_state.is_dead; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_current_state.is_dead IS 'Флаг смерти. TRUE пока персонаж не воскрешён';


--
-- Name: COLUMN character_current_state.updated_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_current_state.updated_at IS 'Время последнего обновления состояния (для staleness-проверок)';


--
-- Name: character_equipment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_equipment (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    equip_slot_id integer NOT NULL,
    inventory_item_id bigint NOT NULL,
    equipped_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.character_equipment OWNER TO postgres;

--
-- Name: TABLE character_equipment; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_equipment IS 'Экипированные предметы персонажа. Ссылается на player_inventory, а не на items напрямую — чтобы учитывать состояние конкретного инстанса (прочность). Один персонаж не может занять один слот дважды (UNIQUE на character_id + equip_slot_id).';


--
-- Name: COLUMN character_equipment.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_equipment.id IS 'Суррогатный PK.';


--
-- Name: COLUMN character_equipment.character_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_equipment.character_id IS 'FK → characters.id.';


--
-- Name: COLUMN character_equipment.equip_slot_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_equipment.equip_slot_id IS 'FK → equip_slots.id. Слот экипировки (голова, грудь, оружие и т.д.).';


--
-- Name: COLUMN character_equipment.inventory_item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_equipment.inventory_item_id IS 'FK → player_inventory.id. Конкретный инстанс предмета из инвентаря персонажа.';


--
-- Name: COLUMN character_equipment.equipped_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_equipment.equipped_at IS 'Метка времени надевания. DEFAULT now().';


--
-- Name: character_equipment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.character_equipment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.character_equipment_id_seq OWNER TO postgres;

--
-- Name: character_equipment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.character_equipment_id_seq OWNED BY public.character_equipment.id;


--
-- Name: character_genders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_genders (
    id smallint NOT NULL,
    name character varying(20) NOT NULL,
    label character varying(30) NOT NULL
);


ALTER TABLE public.character_genders OWNER TO postgres;

--
-- Name: TABLE character_genders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_genders IS 'Справочник полов персонажей: 0=мужской, 1=женский, 2=не задан';


--
-- Name: character_pity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_pity (
    character_id integer NOT NULL,
    item_id integer NOT NULL,
    kill_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.character_pity OWNER TO postgres;

--
-- Name: character_position; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.character_position OWNER TO postgres;

--
-- Name: TABLE character_position; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_position IS 'Текущая позиция персонажа в мире. Одна запись на персонажа';


--
-- Name: COLUMN character_position.zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_position.zone_id IS 'Зона, в которой находится персонаж. NULL = не в зоне/оффлайн';


--
-- Name: COLUMN character_position.rot_z; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_position.rot_z IS 'Угол поворота персонажа по оси Z (направление взгляда, в радианах)';


--
-- Name: character_position_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: character_reputation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_reputation (
    character_id integer NOT NULL,
    faction_slug character varying(60) NOT NULL,
    value integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.character_reputation OWNER TO postgres;

--
-- Name: character_skill_mastery; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_skill_mastery (
    character_id integer NOT NULL,
    mastery_slug character varying(60) NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.character_skill_mastery OWNER TO postgres;

--
-- Name: character_skills; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_skills (
    id integer NOT NULL,
    character_id bigint NOT NULL,
    skill_id integer NOT NULL,
    current_level integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.character_skills OWNER TO postgres;

--
-- Name: TABLE character_skills; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_skills IS 'Скиллы, изученные персонажем, с их текущим уровнем';


--
-- Name: COLUMN character_skills.current_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_skills.current_level IS 'Текущий уровень изученного скилла';


--
-- Name: character_skills_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.character_skills_id_seq1
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.character_skills_id_seq1 OWNER TO postgres;

--
-- Name: character_skills_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.character_skills_id_seq1 OWNED BY public.character_skills.id;


--
-- Name: characters; Type: TABLE; Schema: public; Owner: postgres
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
    appearance jsonb,
    experience_debt integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.characters OWNER TO postgres;

--
-- Name: TABLE characters; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.characters IS 'Персонажи игроков. Привязаны к аккаунту через owner_id';


--
-- Name: COLUMN characters.radius; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.radius IS 'Радиус коллизии/взаимодействия в игровых единицах';


--
-- Name: COLUMN characters.free_skill_points; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.free_skill_points IS 'Очки скиллов, ожидающие распределения игроком';


--
-- Name: COLUMN characters.gender; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.gender IS '0=male, 1=female';


--
-- Name: COLUMN characters.account_slot; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.account_slot IS 'Порядок на экране выбора персонажей';


--
-- Name: COLUMN characters.last_online_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.last_online_at IS 'Время последнего выхода из игры';


--
-- Name: COLUMN characters.deleted_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.deleted_at IS 'Soft delete — персонаж удалён, но восстановим';


--
-- Name: COLUMN characters.play_time_sec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.play_time_sec IS 'Суммарное время игры в секундах';


--
-- Name: COLUMN characters.bind_zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.bind_zone_id IS 'Зона точки воскрешения/возврата';


--
-- Name: COLUMN characters.bind_x; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.bind_x IS 'X-координата точки привязки воскрешения';


--
-- Name: COLUMN characters.bind_y; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.bind_y IS 'Y-координата точки привязки воскрешения';


--
-- Name: COLUMN characters.bind_z; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.bind_z IS 'Z-координата точки привязки воскрешения';


--
-- Name: COLUMN characters.appearance; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.characters.appearance IS 'Кастомизация внешности: цвет волос/глаз, рост и т.д. (JSONB)';


--
-- Name: characters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: class_skill_tree; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.class_skill_tree (
    id integer NOT NULL,
    class_id integer NOT NULL,
    skill_id integer NOT NULL,
    required_level integer DEFAULT 1 NOT NULL,
    is_default boolean DEFAULT false NOT NULL
);


ALTER TABLE public.class_skill_tree OWNER TO postgres;

--
-- Name: TABLE class_skill_tree; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.class_skill_tree IS 'Шаблон доступных скилов для класса. is_default=true — скил выдаётся автоматически при создании персонажа. required_level — минимальный уровень персонажа для изучения скила. Факт выученных скилов хранится в character_skills.';


--
-- Name: COLUMN class_skill_tree.is_default; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_skill_tree.is_default IS 'TRUE = скилл выдаётся автоматически при создании персонажа данного класса';


--
-- Name: class_skill_tree_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.class_skill_tree_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.class_skill_tree_id_seq OWNER TO postgres;

--
-- Name: class_skill_tree_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.class_skill_tree_id_seq OWNED BY public.class_skill_tree.id;


--
-- Name: class_stat_formula; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.class_stat_formula (
    class_id integer NOT NULL,
    attribute_id integer NOT NULL,
    base_value numeric(10,2) DEFAULT 0 NOT NULL,
    multiplier numeric(10,4) DEFAULT 0 NOT NULL,
    exponent numeric(6,4) DEFAULT 1.0000 NOT NULL,
    CONSTRAINT class_stat_formula_exponent_check CHECK ((exponent > (0)::numeric))
);


ALTER TABLE public.class_stat_formula OWNER TO postgres;

--
-- Name: TABLE class_stat_formula; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.class_stat_formula IS 'Формула роста базовых характеристик класса по уровням. Итоговый стат = base_value + multiplier * level^exponent. Заменяет class_base_stats. Используется game server при логине и левел-апе для пересчёта character_permanent_modifiers.';


--
-- Name: COLUMN class_stat_formula.class_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_stat_formula.class_id IS 'Класс персонажа';


--
-- Name: COLUMN class_stat_formula.attribute_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_stat_formula.attribute_id IS 'Характеристика из entity_attributes';


--
-- Name: COLUMN class_stat_formula.base_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_stat_formula.base_value IS 'Значение характеристики на 1 уровне';


--
-- Name: COLUMN class_stat_formula.multiplier; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_stat_formula.multiplier IS 'Множитель роста: ROUND(base_value + multiplier * level^exponent)';


--
-- Name: COLUMN class_stat_formula.exponent; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_stat_formula.exponent IS 'Степень кривой: 1.0 = линейный, >1.0 = ускоряется, <1.0 = замедляется';


--
-- Name: currency_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.currency_transactions (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    amount bigint NOT NULL,
    reason_type character varying(50) NOT NULL,
    source_id bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.currency_transactions OWNER TO postgres;

--
-- Name: TABLE currency_transactions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.currency_transactions IS 'Полный журнал всех денежных операций персонажей (ledger-подход)';


--
-- Name: COLUMN currency_transactions.amount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.currency_transactions.amount IS 'Положительное = доход, отрицательное = расход';


--
-- Name: COLUMN currency_transactions.reason_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.currency_transactions.reason_type IS 'quest_reward, vendor_buy, vendor_sell, drop, gm_grant, trade';


--
-- Name: COLUMN currency_transactions.source_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.currency_transactions.source_id IS 'ID источника (quest_id, vendor_npc_id и т.д.) в зависимости от reason_type';


--
-- Name: COLUMN currency_transactions.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.currency_transactions.created_at IS 'Время транзакции';


--
-- Name: currency_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.currency_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.currency_transactions_id_seq OWNER TO postgres;

--
-- Name: currency_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.currency_transactions_id_seq OWNED BY public.currency_transactions.id;


--
-- Name: damage_elements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.damage_elements (
    slug character varying(64) NOT NULL
);


ALTER TABLE public.damage_elements OWNER TO postgres;

--
-- Name: dialogue; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dialogue (
    id bigint NOT NULL,
    slug text NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    start_node_id bigint
);


ALTER TABLE public.dialogue OWNER TO postgres;

--
-- Name: TABLE dialogue; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.dialogue IS 'Диалог как граф. У NPC может быть несколько диалогов.';


--
-- Name: COLUMN dialogue.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue.slug IS 'Уникальный ключ диалога для поиска/линковки';


--
-- Name: COLUMN dialogue.version; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue.version IS 'Версия контента (для редактора/каталогизации)';


--
-- Name: COLUMN dialogue.start_node_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue.start_node_id IS 'ID стартового узла (dialogue_node.id)';


--
-- Name: dialogue_edge; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.dialogue_edge OWNER TO postgres;

--
-- Name: TABLE dialogue_edge; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.dialogue_edge IS 'Варианты выбора (рёбра графа) из узла в узел';


--
-- Name: COLUMN dialogue_edge.from_node_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_edge.from_node_id IS 'Исходный узел (кнопка показывается на нём)';


--
-- Name: COLUMN dialogue_edge.to_node_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_edge.to_node_id IS 'Узел-назначение при выборе';


--
-- Name: COLUMN dialogue_edge.order_index; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_edge.order_index IS 'Порядок отображения кнопок на клиенте';


--
-- Name: COLUMN dialogue_edge.client_choice_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_edge.client_choice_key IS 'Ключ текста варианта для клиента';


--
-- Name: COLUMN dialogue_edge.condition_group; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_edge.condition_group IS 'JSON-условия доступности варианта';


--
-- Name: COLUMN dialogue_edge.action_group; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_edge.action_group IS 'JSON-действия, применяемые по клику';


--
-- Name: COLUMN dialogue_edge.hide_if_locked; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_edge.hide_if_locked IS 'Если TRUE — скрыть вариант при невыполненных условиях';


--
-- Name: dialogue_edge_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dialogue_edge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dialogue_edge_id_seq OWNER TO postgres;

--
-- Name: dialogue_edge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dialogue_edge_id_seq OWNED BY public.dialogue_edge.id;


--
-- Name: dialogue_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dialogue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dialogue_id_seq OWNER TO postgres;

--
-- Name: dialogue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dialogue_id_seq OWNED BY public.dialogue.id;


--
-- Name: dialogue_node; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.dialogue_node OWNER TO postgres;

--
-- Name: TABLE dialogue_node; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.dialogue_node IS 'Узел графа диалога (реплика, выбор, действие, прыжок, конец)';


--
-- Name: COLUMN dialogue_node.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_node.type IS 'Тип узла: line/choice_hub/action/jump/end';


--
-- Name: COLUMN dialogue_node.speaker_npc_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_node.speaker_npc_id IS 'Идентификатор говорящего NPC (для клиента)';


--
-- Name: COLUMN dialogue_node.client_node_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_node.client_node_key IS 'Ключ строки/контента на клиенте';


--
-- Name: COLUMN dialogue_node.condition_group; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_node.condition_group IS 'JSON-условия: когда узел актуален (иначе пропуск)';


--
-- Name: COLUMN dialogue_node.action_group; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_node.action_group IS 'JSON-действия, исполняемые при входе в action-узел';


--
-- Name: COLUMN dialogue_node.jump_target_node_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dialogue_node.jump_target_node_id IS 'Целевой узел для прыжка (type=jump)';


--
-- Name: dialogue_node_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dialogue_node_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dialogue_node_id_seq OWNER TO postgres;

--
-- Name: dialogue_node_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dialogue_node_id_seq OWNED BY public.dialogue_node.id;


--
-- Name: equip_slot; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equip_slot (
    id smallint NOT NULL,
    slug character varying(30) NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.equip_slot OWNER TO postgres;

--
-- Name: TABLE equip_slot; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.equip_slot IS 'Справочник слотов экипировки (голова, грудь, главная рука и т.д.)';


--
-- Name: exp_for_level; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exp_for_level (
    id integer NOT NULL,
    level integer NOT NULL,
    experience_points bigint NOT NULL
);


ALTER TABLE public.exp_for_level OWNER TO postgres;

--
-- Name: TABLE exp_for_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.exp_for_level IS 'Таблица порогов опыта: сколько XP нужно для достижения каждого уровня';


--
-- Name: COLUMN exp_for_level.experience_points; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.exp_for_level.experience_points IS 'Суммарный опыт, необходимый для достижения данного уровня';


--
-- Name: exp_for_level_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: factions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.factions (
    id integer NOT NULL,
    slug character varying(60) NOT NULL,
    name character varying(120) NOT NULL
);


ALTER TABLE public.factions OWNER TO postgres;

--
-- Name: factions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.factions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.factions_id_seq OWNER TO postgres;

--
-- Name: factions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.factions_id_seq OWNED BY public.factions.id;


--
-- Name: game_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.game_config (
    key text NOT NULL,
    value text NOT NULL,
    value_type text DEFAULT 'float'::text NOT NULL,
    description text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT game_config_value_type_ck CHECK ((value_type = ANY (ARRAY['int'::text, 'float'::text, 'bool'::text, 'string'::text])))
);


ALTER TABLE public.game_config OWNER TO postgres;

--
-- Name: TABLE game_config; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.game_config IS 'Геймплейные константы и параметры баланса. Читаются при старте game-server и отправляются в chunk-server. Изменения применяются без перезапуска через GM-команду reload.';


--
-- Name: COLUMN game_config.key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_config.key IS 'Уникальный ключ параметра. Формат: namespace.param_name. Примеры: combat.defense_formula_k, aggro.base_radius.';


--
-- Name: COLUMN game_config.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_config.value IS 'Значение в виде строки. Интерпретируется согласно value_type.';


--
-- Name: COLUMN game_config.value_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_config.value_type IS 'Тип значения: int | float | bool | string. Используется GameConfigService для корректного приведения типа.';


--
-- Name: COLUMN game_config.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_config.description IS 'Описание параметра и его влияния на геймплей. Для GM-UI и документации.';


--
-- Name: COLUMN game_config.updated_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_config.updated_at IS 'Автообновляется при изменении строки (через триггер ниже).';


--
-- Name: gm_action_log; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.gm_action_log OWNER TO postgres;

--
-- Name: TABLE gm_action_log; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.gm_action_log IS 'Полный аудит-лог действий GM и администраторов';


--
-- Name: COLUMN gm_action_log.old_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.gm_action_log.old_value IS 'Состояние до изменения (JSONB)';


--
-- Name: COLUMN gm_action_log.new_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.gm_action_log.new_value IS 'Состояние после изменения (JSONB)';


--
-- Name: gm_action_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gm_action_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gm_action_log_id_seq OWNER TO postgres;

--
-- Name: gm_action_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gm_action_log_id_seq OWNED BY public.gm_action_log.id;


--
-- Name: item_attributes_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_attributes_mapping (
    id bigint NOT NULL,
    item_id bigint NOT NULL,
    attribute_id integer NOT NULL,
    value integer NOT NULL,
    apply_on text DEFAULT 'equip'::text NOT NULL,
    CONSTRAINT item_attributes_mapping_apply_on_ck CHECK ((apply_on = ANY (ARRAY['equip'::text, 'use'::text])))
);


ALTER TABLE public.item_attributes_mapping OWNER TO postgres;

--
-- Name: TABLE item_attributes_mapping; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.item_attributes_mapping IS 'Атрибуты предметов с их значениями и режимом применения. apply_on=equip → бонус суммируется в стат персонажа при надевании. apply_on=use   → создаётся player_active_effect при использовании предмета. FK attribute_id → entity_attributes (единый справочник атрибутов).';


--
-- Name: COLUMN item_attributes_mapping.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_attributes_mapping.id IS 'Суррогатный PK.';


--
-- Name: COLUMN item_attributes_mapping.item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_attributes_mapping.item_id IS 'FK → items.id. Предмет-шаблон, к которому привязан атрибут.';


--
-- Name: COLUMN item_attributes_mapping.attribute_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_attributes_mapping.attribute_id IS 'Атрибут из entity_attributes (единый справочник для персонажей, мобов и предметов). Экипируемые предметы (apply_on=equip): physical_attack, strength, crit_chance и т.д. Используемые предметы (apply_on=use): heal_on_use, hunger_restore, hp_regen_per_s и т.д.';


--
-- Name: COLUMN item_attributes_mapping.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_attributes_mapping.value IS 'Числовое значение атрибута. Интерпретируется по slug: physical_attack=10 → +10 к атаке; heal_on_use=50 → восстановить 50 HP.';


--
-- Name: COLUMN item_attributes_mapping.apply_on; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_attributes_mapping.apply_on IS 'equip = суммируется в стат персонажа при надевании (броня, оружие). use   = создаёт player_active_effect при использовании предмета (зелья, еда).';


--
-- Name: item_attributes_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: item_class_restrictions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_class_restrictions (
    item_id integer NOT NULL,
    class_id integer NOT NULL
);


ALTER TABLE public.item_class_restrictions OWNER TO postgres;

--
-- Name: item_set_bonuses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_set_bonuses (
    id integer NOT NULL,
    set_id integer NOT NULL,
    pieces_required integer NOT NULL,
    attribute_id integer NOT NULL,
    bonus_value integer NOT NULL
);


ALTER TABLE public.item_set_bonuses OWNER TO postgres;

--
-- Name: item_set_bonuses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.item_set_bonuses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.item_set_bonuses_id_seq OWNER TO postgres;

--
-- Name: item_set_bonuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_set_bonuses_id_seq OWNED BY public.item_set_bonuses.id;


--
-- Name: item_set_members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_set_members (
    set_id integer NOT NULL,
    item_id integer NOT NULL
);


ALTER TABLE public.item_set_members OWNER TO postgres;

--
-- Name: item_sets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_sets (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    slug character varying(128) NOT NULL
);


ALTER TABLE public.item_sets OWNER TO postgres;

--
-- Name: item_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.item_sets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.item_sets_id_seq OWNER TO postgres;

--
-- Name: item_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_sets_id_seq OWNED BY public.item_sets.id;


--
-- Name: item_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL
);


ALTER TABLE public.item_types OWNER TO postgres;

--
-- Name: TABLE item_types; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.item_types IS 'Справочник типов предметов: weapon, armor, accessory, potion, food, quest_item, resource, currency, container.';


--
-- Name: COLUMN item_types.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_types.id IS 'Суррогатный PK.';


--
-- Name: COLUMN item_types.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_types.name IS 'Отображаемое название типа предмета.';


--
-- Name: COLUMN item_types.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_types.slug IS 'Машиночитаемый ключ типа, уникален. Примеры: weapon, armor, potion, food, quest_item, resource.';


--
-- Name: item_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: item_use_effects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_use_effects (
    id integer NOT NULL,
    item_id integer NOT NULL,
    effect_slug character varying(64) NOT NULL,
    attribute_slug character varying(64) DEFAULT ''::character varying NOT NULL,
    value double precision DEFAULT 0 NOT NULL,
    is_instant boolean DEFAULT true NOT NULL,
    duration_seconds integer DEFAULT 0 NOT NULL,
    tick_ms integer DEFAULT 0 NOT NULL,
    cooldown_seconds integer DEFAULT 30 NOT NULL
);


ALTER TABLE public.item_use_effects OWNER TO postgres;

--
-- Name: item_use_effects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.item_use_effects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.item_use_effects_id_seq OWNER TO postgres;

--
-- Name: item_use_effects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_use_effects_id_seq OWNED BY public.item_use_effects.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: postgres
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
    is_usable boolean DEFAULT false NOT NULL,
    is_two_handed boolean DEFAULT false NOT NULL,
    mastery_slug character varying(60) DEFAULT NULL::character varying
);


ALTER TABLE public.items OWNER TO postgres;

--
-- Name: TABLE items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.items IS 'Каталог предметов игры — шаблоны, не инстансы. Инстансы (конкретные предметы персонажа) хранятся в player_inventory. Поля is_equippable / is_usable / is_quest_item определяют поведение предмета.';


--
-- Name: COLUMN items.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.id IS 'Суррогатный PK шаблона предмета.';


--
-- Name: COLUMN items.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.name IS 'Отображаемое название предмета.';


--
-- Name: COLUMN items.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.slug IS 'Машиночитаемый уникальный ключ. Используется в коде и конфигах.';


--
-- Name: COLUMN items.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.description IS 'Текстовое описание предмета для UI-тултипа. NULL допустим.';


--
-- Name: COLUMN items.is_quest_item; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.is_quest_item IS 'TRUE = квестовый предмет, не выпадает из инвентаря';


--
-- Name: COLUMN items.item_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.item_type IS 'FK → item_types.id. Тип предмета (оружие, броня, зелье и т.д.).';


--
-- Name: COLUMN items.weight; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.weight IS 'Вес предмета в килограммах. Используется если включена система веса инвентаря.';


--
-- Name: COLUMN items.rarity_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.rarity_id IS 'FK → item_rarity.id. Редкость: обычный, необычный, редкий и т.д. DEFAULT 1 = обычный.';


--
-- Name: COLUMN items.stack_max; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.stack_max IS 'Максимальное количество предметов в одном стаке инвентаря';


--
-- Name: COLUMN items.is_container; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.is_container IS 'TRUE = предмет является сумкой/контейнером';


--
-- Name: COLUMN items.is_durable; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.is_durable IS 'TRUE = предмет имеет прочность и изнашивается';


--
-- Name: COLUMN items.is_tradable; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.is_tradable IS 'TRUE = предмет можно передать другому игроку или продать';


--
-- Name: COLUMN items.durability_max; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.durability_max IS 'Максимальная прочность (relevantно если is_durable = true)';


--
-- Name: COLUMN items.vendor_price_buy; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.vendor_price_buy IS 'Цена покупки у NPC-торговца (медь)';


--
-- Name: COLUMN items.vendor_price_sell; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.vendor_price_sell IS 'Цена продажи NPC-торговцу (медь). Обычно ниже buy';


--
-- Name: COLUMN items.equip_slot; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.equip_slot IS 'Слот экипировки (FK → equip_slot). NULL = неэкипируемый предмет';


--
-- Name: COLUMN items.level_requirement; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.level_requirement IS 'Минимальный уровень персонажа для экипировки/использования';


--
-- Name: COLUMN items.is_equippable; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.is_equippable IS 'TRUE = предмет можно надеть в слот экипировки';


--
-- Name: COLUMN items.is_harvest; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.is_harvest IS 'TRUE = добываемый ресурс (трава, руда и т.д.)';


--
-- Name: COLUMN items.is_usable; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.is_usable IS 'TRUE = предмет можно использовать из инвентаря (зелья, свитки, еда). При использовании атрибуты (apply_on=''use'') из item_attributes_mapping создают запись в player_active_effect с таймером expires_at.';


--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: items_rarity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.items_rarity (
    id smallint NOT NULL,
    name character varying(30) NOT NULL,
    color_hex character(7) NOT NULL,
    slug character varying(30)
);


ALTER TABLE public.items_rarity OWNER TO postgres;

--
-- Name: TABLE items_rarity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.items_rarity IS 'Редкости предметов с цветовым кодом для UI';


--
-- Name: COLUMN items_rarity.color_hex; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items_rarity.color_hex IS 'Hex-цвет для подсветки предмета в UI (например #00ff00 для необычного)';


--
-- Name: mastery_definitions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mastery_definitions (
    slug character varying(60) NOT NULL,
    name character varying(120) NOT NULL,
    weapon_type_slug character varying(60) DEFAULT NULL::character varying,
    max_value double precision DEFAULT 100.0 NOT NULL
);


ALTER TABLE public.mastery_definitions OWNER TO postgres;

--
-- Name: mob; Type: TABLE; Schema: public; Owner: postgres
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
    can_evolve boolean DEFAULT false NOT NULL,
    is_rare boolean DEFAULT false NOT NULL,
    rare_spawn_chance double precision DEFAULT 0.0 NOT NULL,
    rare_spawn_condition character varying(30) DEFAULT NULL::character varying,
    faction_slug character varying(60) DEFAULT NULL::character varying,
    rep_delta_per_kill integer DEFAULT 0,
    biome_slug character varying(64) DEFAULT ''::character varying NOT NULL,
    mob_type_slug character varying(64) DEFAULT 'beast'::character varying NOT NULL,
    CONSTRAINT mob_ai_archetype_check CHECK (((ai_archetype)::text = ANY ((ARRAY['melee'::character varying, 'caster'::character varying, 'ranged'::character varying, 'support'::character varying, 'summoner'::character varying, 'lurker'::character varying])::text[]))),
    CONSTRAINT mob_flee_hp_threshold_check CHECK (((flee_hp_threshold >= (0.0)::double precision) AND (flee_hp_threshold < (1.0)::double precision)))
);


ALTER TABLE public.mob OWNER TO postgres;

--
-- Name: TABLE mob; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mob IS 'Шаблоны мобов. Это не игровые инстансы, а определения спавна';


--
-- Name: COLUMN mob.spawn_health; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.spawn_health IS 'Стартовое здоровье экземпляра при спавне. НЕ текущее состояние — runtime-хп моба хранится в памяти chunk-server.';


--
-- Name: COLUMN mob.spawn_mana; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.spawn_mana IS 'Стартовая мана экземпляра при спавне. НЕ текущее состояние — runtime-мана моба хранится в памяти chunk-server.';


--
-- Name: COLUMN mob.is_aggressive; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.is_aggressive IS 'TRUE = атакует игроков приближающихся в радиус агра';


--
-- Name: COLUMN mob.is_dead; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.is_dead IS 'TRUE = шаблон моба отмечен как "мёртвый" (для дизайна, не инстанс)';


--
-- Name: COLUMN mob.radius; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.radius IS 'Радиус коллизии и зоны агра в игровых единицах';


--
-- Name: COLUMN mob.base_xp; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.base_xp IS 'Базовый опыт за убийство. Итоговый = base_xp × mob_ranks.mult';


--
-- Name: COLUMN mob.rank_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.rank_id IS 'Ранг моба (FK → mob_ranks). Влияет на множитель характеристик и XP';


--
-- Name: COLUMN mob.aggro_range; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.aggro_range IS 'Radius at which mob detects and begins chasing a player (world units)';


--
-- Name: COLUMN mob.attack_range; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.attack_range IS 'Distance at which mob can attack a player (world units)';


--
-- Name: COLUMN mob.attack_cooldown; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.attack_cooldown IS 'Seconds between consecutive mob attacks';


--
-- Name: COLUMN mob.chase_multiplier; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.chase_multiplier IS 'aggro_range * chase_multiplier = max chase distance before giving up';


--
-- Name: COLUMN mob.patrol_speed; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.patrol_speed IS 'Speed multiplier for patrol movement (1.0 = normal)';


--
-- Name: COLUMN mob.is_social; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.is_social IS 'TRUE = mob participates in group-aggro and passive-social mechanics.';


--
-- Name: COLUMN mob.chase_duration; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.chase_duration IS 'Max seconds a mob will chase before leashing (replaces hard-coded 30 s). Per-mob override; larger values = more persistent pursuit.';


--
-- Name: COLUMN mob.flee_hp_threshold; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.flee_hp_threshold IS '0.0 = не убегает. 0.25 = убегает при HP <= 25%. Используется, когда реализован FLEEING state в MobAIController.';


--
-- Name: COLUMN mob.ai_archetype; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob.ai_archetype IS 'Архетип ИИ: melee (ближний бой, дефолт) | caster (kiting+заклинания) | ranged | support | summoner | lurker (засада). Используется, когда реализован выбор поведения по архетипу.';


--
-- Name: mob_active_effect; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.mob_active_effect OWNER TO postgres;

--
-- Name: TABLE mob_active_effect; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mob_active_effect IS 'Активные баффы/дебаффы runtime-экземпляров мобов. mob_uid = MobDataStruct::uid из памяти chunk-server (не mob.id). Записи создаются при применении скила игрока на моба и удаляются при смерти моба или истечении таймера.';


--
-- Name: COLUMN mob_active_effect.mob_uid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_active_effect.mob_uid IS 'Runtime UID экземпляра моба (MobDataStruct::uid)';


--
-- Name: COLUMN mob_active_effect.effect_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_active_effect.effect_id IS 'Ссылка на skill_effects';


--
-- Name: COLUMN mob_active_effect.attribute_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_active_effect.attribute_id IS 'Модифицируемый атрибут (NULL для non-stat эффектов)';


--
-- Name: COLUMN mob_active_effect.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_active_effect.value IS 'Величина изменения атрибута';


--
-- Name: COLUMN mob_active_effect.source_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_active_effect.source_type IS 'Источник активного эффекта: skill | zone | quest | admin';


--
-- Name: COLUMN mob_active_effect.source_player_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_active_effect.source_player_id IS 'ID персонажа, применившего эффект';


--
-- Name: COLUMN mob_active_effect.expires_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_active_effect.expires_at IS 'NULL = постоянный (до смерти моба)';


--
-- Name: mob_active_effect_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: mob_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: mob_loot_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_loot_info (
    id bigint NOT NULL,
    mob_id integer NOT NULL,
    item_id bigint NOT NULL,
    drop_chance numeric(5,2) DEFAULT 0.00 NOT NULL,
    is_harvest_only boolean DEFAULT false NOT NULL,
    min_quantity smallint DEFAULT 1 NOT NULL,
    max_quantity smallint DEFAULT 1 NOT NULL,
    loot_tier character varying(32) DEFAULT 'common'::character varying NOT NULL,
    CONSTRAINT mob_loot_info_loot_tier_check CHECK (((loot_tier)::text = ANY ((ARRAY['common'::character varying, 'uncommon'::character varying, 'rare'::character varying, 'very_rare'::character varying])::text[]))),
    CONSTRAINT mob_loot_quantity_check CHECK (((max_quantity >= min_quantity) AND (min_quantity >= 1)))
);


ALTER TABLE public.mob_loot_info OWNER TO postgres;

--
-- Name: TABLE mob_loot_info; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mob_loot_info IS 'Таблица дропа моба: какие предметы и с какой вероятностью';


--
-- Name: COLUMN mob_loot_info.drop_chance; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_loot_info.drop_chance IS 'Вероятность выпадения: 0.0 = никогда, 1.0 = всегда';


--
-- Name: COLUMN mob_loot_info.is_harvest_only; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_loot_info.is_harvest_only IS 'TRUE = предмет доступен только через harvest (взаимодействие с трупом), не выпадает при обычном убийстве.';


--
-- Name: COLUMN mob_loot_info.min_quantity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_loot_info.min_quantity IS 'Минимальное количество выпадающего предмета (>= 1)';


--
-- Name: COLUMN mob_loot_info.max_quantity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_loot_info.max_quantity IS 'Максимальное количество выпадающего предмета (>= min_quantity)';


--
-- Name: mob_loot_info_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: mob_position; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.mob_position OWNER TO postgres;

--
-- Name: TABLE mob_position; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mob_position IS 'Статические позиции спавна шаблонов мобов в зонах. FK: mob_id → mob';


--
-- Name: COLUMN mob_position.rot_z; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_position.rot_z IS 'Начальный угол поворота моба в точке спавна (в радианах)';


--
-- Name: COLUMN mob_position.zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_position.zone_id IS 'Зона, в которой размещён моб. NULL = не привязан к зоне';


--
-- Name: mob_position_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: mob_race; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_race (
    id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.mob_race OWNER TO postgres;

--
-- Name: TABLE mob_race; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mob_race IS 'Расы мобов (нежить, зверь, демон и т.д.)';


--
-- Name: mob_race_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: mob_ranks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_ranks (
    rank_id smallint NOT NULL,
    code text NOT NULL,
    mult numeric(4,2) NOT NULL
);


ALTER TABLE public.mob_ranks OWNER TO postgres;

--
-- Name: TABLE mob_ranks; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mob_ranks IS 'Ранги мобов (normal/elite/boss) с множителем характеристик';


--
-- Name: COLUMN mob_ranks.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_ranks.code IS 'Код ранга: normal / elite / boss / world_boss';


--
-- Name: COLUMN mob_ranks.mult; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_ranks.mult IS 'Множитель характеристик относительно нормального моба (1.0 = норма)';


--
-- Name: mob_resistances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_resistances (
    mob_id integer NOT NULL,
    element_slug character varying(64) NOT NULL
);


ALTER TABLE public.mob_resistances OWNER TO postgres;

--
-- Name: mob_skills; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_skills (
    id integer NOT NULL,
    mob_id integer NOT NULL,
    skill_id integer NOT NULL,
    current_level integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.mob_skills OWNER TO postgres;

--
-- Name: TABLE mob_skills; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mob_skills IS 'Скиллы шаблона моба с уровнем';


--
-- Name: COLUMN mob_skills.current_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_skills.current_level IS 'Уровень скилла у данного шаблона моба';


--
-- Name: mob_skills_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mob_skills_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.mob_skills_id_seq OWNER TO postgres;

--
-- Name: mob_skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mob_skills_id_seq OWNED BY public.mob_skills.id;


--
-- Name: mob_stat; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.mob_stat OWNER TO postgres;

--
-- Name: TABLE mob_stat; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mob_stat IS 'Единая таблица статов шаблона моба. multiplier IS NULL → использовать flat_value как есть. multiplier IS NOT NULL → ROUND(flat_value + multiplier * level^exponent).';


--
-- Name: COLUMN mob_stat.flat_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_stat.flat_value IS 'Базовое значение (или константа L1 при multiplier IS NULL)';


--
-- Name: COLUMN mob_stat.multiplier; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_stat.multiplier IS 'NULL = нет формулы; иначе — коэффициент масштабирования';


--
-- Name: COLUMN mob_stat.exponent; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_stat.exponent IS 'Показатель степени для level (только при multiplier IS NOT NULL)';


--
-- Name: mob_stat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: mob_weaknesses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_weaknesses (
    mob_id integer NOT NULL,
    element_slug character varying(64) NOT NULL
);


ALTER TABLE public.mob_weaknesses OWNER TO postgres;

--
-- Name: npc; Type: TABLE; Schema: public; Owner: postgres
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
    npc_type integer DEFAULT 1 NOT NULL,
    faction_slug character varying(60) DEFAULT NULL::character varying
);


ALTER TABLE public.npc OWNER TO postgres;

--
-- Name: TABLE npc; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.npc IS 'Шаблоны NPC. Содержат торговцев, квестодателей, диалоговых персонажей';


--
-- Name: COLUMN npc.radius; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc.radius IS 'Радиус коллизии, используемый клиентом';


--
-- Name: COLUMN npc.is_interactable; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc.is_interactable IS 'TRUE = игрок может начать диалог / взаимодействие с этим NPC';


--
-- Name: COLUMN npc.npc_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc.npc_type IS 'Тип NPC (FK → npc_type): торговец, квестодатель и т.д.';


--
-- Name: npc_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_attributes (
    id bigint NOT NULL,
    npc_id integer NOT NULL,
    attribute_id integer NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.npc_attributes OWNER TO postgres;

--
-- Name: TABLE npc_attributes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.npc_attributes IS 'Значения атрибутов NPC';


--
-- Name: COLUMN npc_attributes.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_attributes.value IS 'Значение атрибута для данного NPC';


--
-- Name: npc_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: npc_dialogue; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_dialogue (
    npc_id bigint NOT NULL,
    dialogue_id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    condition_group jsonb
);


ALTER TABLE public.npc_dialogue OWNER TO postgres;

--
-- Name: TABLE npc_dialogue; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.npc_dialogue IS 'Связка NPC → Диалог с приоритетом выбора';


--
-- Name: COLUMN npc_dialogue.priority; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_dialogue.priority IS 'Чем выше число, тем раньше выбирается диалог для NPC';


--
-- Name: COLUMN npc_dialogue.condition_group; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_dialogue.condition_group IS 'JSON-условия активации диалога (те же правила что в dialogue_edge.condition_group)';


--
-- Name: npc_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: npc_placements; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.npc_placements OWNER TO postgres;

--
-- Name: TABLE npc_placements; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.npc_placements IS 'Статичное размещение NPC в игровом мире. Используется gameserver при инициализации локации.';


--
-- Name: npc_placements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.npc_placements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.npc_placements_id_seq OWNER TO postgres;

--
-- Name: npc_placements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.npc_placements_id_seq OWNED BY public.npc_placements.id;


--
-- Name: npc_position; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.npc_position OWNER TO postgres;

--
-- Name: TABLE npc_position; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.npc_position IS 'Статические позиции размещения NPC в зонах. FK: npc_id → npc';


--
-- Name: COLUMN npc_position.rot_z; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_position.rot_z IS 'Начальный угол поворота NPC (в радианах)';


--
-- Name: COLUMN npc_position.zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_position.zone_id IS 'Зона, в которой размещён NPC. NULL = не привязан к зоне';


--
-- Name: npc_position_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: npc_skills; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_skills (
    id integer NOT NULL,
    npc_id integer NOT NULL,
    skill_id integer NOT NULL,
    current_level integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.npc_skills OWNER TO postgres;

--
-- Name: TABLE npc_skills; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.npc_skills IS 'Скиллы NPC с уровнем';


--
-- Name: COLUMN npc_skills.current_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_skills.current_level IS 'Уровень скилла у данного NPC';


--
-- Name: npc_skills_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.npc_skills_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.npc_skills_id_seq OWNER TO postgres;

--
-- Name: npc_skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.npc_skills_id_seq OWNED BY public.npc_skills.id;


--
-- Name: npc_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_type (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL
);


ALTER TABLE public.npc_type OWNER TO postgres;

--
-- Name: TABLE npc_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.npc_type IS 'Типы NPC: торговец, квестодатель, страж и т.д.';


--
-- Name: npc_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: passive_skill_modifiers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.passive_skill_modifiers (
    id integer NOT NULL,
    skill_id integer NOT NULL,
    attribute_slug text NOT NULL,
    modifier_type text DEFAULT 'flat'::text NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT passive_skill_modifiers_modifier_type_check CHECK ((modifier_type = ANY (ARRAY['flat'::text, 'percent'::text])))
);


ALTER TABLE public.passive_skill_modifiers OWNER TO postgres;

--
-- Name: TABLE passive_skill_modifiers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.passive_skill_modifiers IS 'Stat modifiers granted by passive skills. Loaded by game server on character join.';


--
-- Name: COLUMN passive_skill_modifiers.modifier_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.passive_skill_modifiers.modifier_type IS 'flat = additive delta; percent = percent of base value';


--
-- Name: COLUMN passive_skill_modifiers.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.passive_skill_modifiers.value IS 'Magnitude. Negative = penalty. Percent: -20 means -20 %.';


--
-- Name: passive_skill_modifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.passive_skill_modifiers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.passive_skill_modifiers_id_seq OWNER TO postgres;

--
-- Name: passive_skill_modifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.passive_skill_modifiers_id_seq OWNED BY public.passive_skill_modifiers.id;


--
-- Name: player_active_effect; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player_active_effect (
    id bigint NOT NULL,
    player_id bigint NOT NULL,
    status_effect_id integer NOT NULL,
    source_type text NOT NULL,
    source_id bigint,
    value numeric DEFAULT 0 NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    attribute_id integer,
    tick_ms integer DEFAULT 0 NOT NULL,
    group_id bigint,
    CONSTRAINT player_active_effect_source_type_ck CHECK ((source_type = ANY (ARRAY['quest'::text, 'dialogue'::text, 'skill'::text, 'item'::text, 'death'::text, 'environment'::text, 'skill_passive'::text])))
);


ALTER TABLE public.player_active_effect OWNER TO postgres;

--
-- Name: TABLE player_active_effect; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.player_active_effect IS 'Активные эффекты персонажа: баффы/дебаффы с таймером или постоянные. Постоянные (квестовые награды, GM-модификаторы) хранятся в character_permanent_modifiers. Здесь — временые эффекты с expires_at и on-use эффекты от предметов (зелья, еда).';


--
-- Name: COLUMN player_active_effect.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_active_effect.id IS 'Суррогатный PK.';


--
-- Name: COLUMN player_active_effect.player_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_active_effect.player_id IS 'FK → characters.id. Персонаж, на которого наложен эффект.';


--
-- Name: COLUMN player_active_effect.status_effect_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_active_effect.status_effect_id IS 'FK to status_effects.id — the named status condition';


--
-- Name: COLUMN player_active_effect.source_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_active_effect.source_type IS 'Источник эффекта: quest / dialogue / skill / item';


--
-- Name: COLUMN player_active_effect.source_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_active_effect.source_id IS 'ID источника (quest_id, dialogue_node_id, skill_id, item_id)';


--
-- Name: COLUMN player_active_effect.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_active_effect.value IS 'Величина эффекта (например, +50 к макс. HP)';


--
-- Name: COLUMN player_active_effect.applied_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_active_effect.applied_at IS 'Время наложения эффекта. DEFAULT now().';


--
-- Name: COLUMN player_active_effect.expires_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_active_effect.expires_at IS 'Время истечения. NULL = бессрочный эффект';


--
-- Name: COLUMN player_active_effect.attribute_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_active_effect.attribute_id IS 'Какой атрибут модифицирует эффект (FK → entity_attributes). NULL допустим для не-стат эффектов (stun, silence, root).';


--
-- Name: COLUMN player_active_effect.group_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_active_effect.group_id IS 'Groups rows belonging to the same multi-attribute effect instance. NULL = single-row effect.';


--
-- Name: player_active_effect_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.player_active_effect_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.player_active_effect_id_seq OWNER TO postgres;

--
-- Name: player_active_effect_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.player_active_effect_id_seq OWNED BY public.player_active_effect.id;


--
-- Name: player_flag; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player_flag (
    player_id bigint NOT NULL,
    flag_key text NOT NULL,
    int_value integer,
    bool_value boolean,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.player_flag OWNER TO postgres;

--
-- Name: TABLE player_flag; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.player_flag IS 'Флаги/счётчики игрока для условной логики диалогов и квестов';


--
-- Name: COLUMN player_flag.flag_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_flag.flag_key IS 'Имя флага (например, "mila_thanked")';


--
-- Name: player_inventory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player_inventory (
    id bigint NOT NULL,
    character_id bigint,
    item_id bigint NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    slot_index smallint,
    durability_current integer,
    kill_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.player_inventory OWNER TO postgres;

--
-- Name: TABLE player_inventory; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.player_inventory IS 'Инвентарь персонажа: инстансы предметов с количеством и состоянием. Один ряд = один стак. Экипированные предметы дополнительно присутствуют в character_equipment.';


--
-- Name: COLUMN player_inventory.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_inventory.id IS 'Суррогатный PK инстанса предмета в инвентаре.';


--
-- Name: COLUMN player_inventory.character_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_inventory.character_id IS 'FK → characters.id. Владелец предмета.';


--
-- Name: COLUMN player_inventory.item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_inventory.item_id IS 'FK → items.id. Шаблон предмета.';


--
-- Name: COLUMN player_inventory.quantity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_inventory.quantity IS 'Количество предметов в стаке. DEFAULT 1.';


--
-- Name: COLUMN player_inventory.slot_index; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_inventory.slot_index IS 'Позиция предмета в сумке (NULL = не назначена)';


--
-- Name: COLUMN player_inventory.durability_current; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_inventory.durability_current IS 'Текущая прочность (NULL если item.is_durable = false)';


--
-- Name: player_inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: player_quest; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.player_quest OWNER TO postgres;

--
-- Name: TABLE player_quest; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.player_quest IS 'Текущее состояние квестов конкретного игрока';


--
-- Name: COLUMN player_quest.state; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_quest.state IS 'offered/active/completed/turned_in/failed';


--
-- Name: COLUMN player_quest.current_step; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_quest.current_step IS 'Индекс текущего шага квеста (0-based). Соответствует quest_step.step_index';


--
-- Name: COLUMN player_quest.progress; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_quest.progress IS 'JSON прогресса текущего шага (например, {"have":3})';


--
-- Name: COLUMN player_quest.updated_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_quest.updated_at IS 'Время последнего изменения состояния квеста';


--
-- Name: quest; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.quest OWNER TO postgres;

--
-- Name: TABLE quest; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.quest IS 'Карточка квеста (без текстов), базовые правила/валидаторы';


--
-- Name: COLUMN quest.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest.slug IS 'Уникальный ключ квеста';


--
-- Name: COLUMN quest.min_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest.min_level IS 'Мин. уровень для взятия квеста';


--
-- Name: COLUMN quest.repeatable; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest.repeatable IS 'Можно ли повторять квест';


--
-- Name: COLUMN quest.cooldown_sec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest.cooldown_sec IS 'Кулдаун перед повторным взятием (если repeatable)';


--
-- Name: COLUMN quest.giver_npc_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest.giver_npc_id IS 'NPC, выдающий квест';


--
-- Name: COLUMN quest.turnin_npc_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest.turnin_npc_id IS 'NPC, принимающий квест';


--
-- Name: COLUMN quest.client_quest_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest.client_quest_key IS 'Ключ для клиентского UI (название/описание)';


--
-- Name: quest_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quest_id_seq OWNER TO postgres;

--
-- Name: quest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quest_id_seq OWNED BY public.quest.id;


--
-- Name: quest_reward; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.quest_reward OWNER TO postgres;

--
-- Name: TABLE quest_reward; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.quest_reward IS 'Награды за сдачу квеста (предметы, опыт, золото)';


--
-- Name: COLUMN quest_reward.reward_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest_reward.reward_type IS 'Тип награды: item / exp / gold';


--
-- Name: COLUMN quest_reward.item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest_reward.item_id IS 'ID предмета (только если reward_type = item)';


--
-- Name: COLUMN quest_reward.quantity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest_reward.quantity IS 'Количество предметов (только если reward_type = item)';


--
-- Name: COLUMN quest_reward.amount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest_reward.amount IS 'Количество опыта или золота (только если reward_type = exp / gold)';


--
-- Name: quest_reward_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quest_reward_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quest_reward_id_seq OWNER TO postgres;

--
-- Name: quest_reward_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quest_reward_id_seq OWNED BY public.quest_reward.id;


--
-- Name: quest_step; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quest_step (
    id bigint NOT NULL,
    quest_id bigint NOT NULL,
    step_index integer NOT NULL,
    step_type public.quest_step_type NOT NULL,
    params jsonb NOT NULL,
    client_step_key text,
    completion_mode text DEFAULT 'auto'::text NOT NULL,
    CONSTRAINT quest_step_completion_mode_ck CHECK ((completion_mode = ANY (ARRAY['auto'::text, 'manual'::text]))),
    CONSTRAINT quest_step_index_ck CHECK ((step_index >= 0))
);


ALTER TABLE public.quest_step OWNER TO postgres;

--
-- Name: TABLE quest_step; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.quest_step IS 'Шаги квеста с параметрами в JSON';


--
-- Name: COLUMN quest_step.params; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest_step.params IS 'JSON параметров шага (item/count, npcId, зона и т.п.)';


--
-- Name: COLUMN quest_step.client_step_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest_step.client_step_key IS 'Ключ строки цели на клиенте';


--
-- Name: quest_step_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quest_step_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quest_step_id_seq OWNER TO postgres;

--
-- Name: quest_step_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quest_step_id_seq OWNED BY public.quest_step.id;


--
-- Name: race; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.race (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying NOT NULL
);


ALTER TABLE public.race OWNER TO postgres;

--
-- Name: TABLE race; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.race IS 'Играбельные расы персонажей';


--
-- Name: race_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: respawn_zones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.respawn_zones (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    x double precision DEFAULT 0 NOT NULL,
    y double precision DEFAULT 0 NOT NULL,
    z double precision DEFAULT 0 NOT NULL,
    zone_id integer DEFAULT 1 NOT NULL,
    is_default boolean DEFAULT false NOT NULL
);


ALTER TABLE public.respawn_zones OWNER TO postgres;

--
-- Name: respawn_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.respawn_zones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.respawn_zones_id_seq OWNER TO postgres;

--
-- Name: respawn_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.respawn_zones_id_seq OWNED BY public.respawn_zones.id;


--
-- Name: skill_damage_formulas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_damage_formulas (
    id integer NOT NULL,
    slug text NOT NULL,
    effect_type_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.skill_damage_formulas OWNER TO postgres;

--
-- Name: TABLE skill_damage_formulas; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.skill_damage_formulas IS 'Определения конкретных эффектов с типом и базовыми параметрами';


--
-- Name: skill_damage_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_damage_types (
    id integer NOT NULL,
    slug text NOT NULL
);


ALTER TABLE public.skill_damage_types OWNER TO postgres;

--
-- Name: TABLE skill_damage_types; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.skill_damage_types IS 'Категории эффектов скиллов (урон, исцеление, дебафф и т.д.)';


--
-- Name: skill_effect_instances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_effect_instances (
    id integer NOT NULL,
    skill_id integer NOT NULL,
    order_idx smallint DEFAULT 1 NOT NULL,
    target_type_id integer NOT NULL
);


ALTER TABLE public.skill_effect_instances OWNER TO postgres;

--
-- Name: TABLE skill_effect_instances; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.skill_effect_instances IS 'Привязка эффектов к конкретным скиллам с порядком применения';


--
-- Name: COLUMN skill_effect_instances.order_idx; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_effect_instances.order_idx IS 'Порядок выполнения эффектов внутри одного скилла (меньше = раньше)';


--
-- Name: COLUMN skill_effect_instances.target_type_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_effect_instances.target_type_id IS 'На кого направлен эффект: self / enemy / ally / area';


--
-- Name: skill_effect_instances_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.skill_effect_instances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.skill_effect_instances_id_seq OWNER TO postgres;

--
-- Name: skill_effect_instances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.skill_effect_instances_id_seq OWNED BY public.skill_effect_instances.id;


--
-- Name: skill_effects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.skill_effects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.skill_effects_id_seq OWNER TO postgres;

--
-- Name: skill_effects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.skill_effects_id_seq OWNED BY public.skill_damage_formulas.id;


--
-- Name: skill_effects_mapping; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.skill_effects_mapping OWNER TO postgres;

--
-- Name: TABLE skill_effects_mapping; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.skill_effects_mapping IS 'Значения эффектов на каждом уровне скилла';


--
-- Name: COLUMN skill_effects_mapping.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_effects_mapping.value IS 'Числовое значение эффекта на данном уровне скилла';


--
-- Name: COLUMN skill_effects_mapping.level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_effects_mapping.level IS 'Уровень скилла, которому соответствует эта строка';


--
-- Name: COLUMN skill_effects_mapping.tick_ms; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_effects_mapping.tick_ms IS 'Интервал тика DoT/HoT в миллисекундах. 0 = мгновенный эффект (не тиковый).';


--
-- Name: COLUMN skill_effects_mapping.duration_ms; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_effects_mapping.duration_ms IS 'Полная продолжительность эффекта в миллисекундах. 0 = мгновенное применение.';


--
-- Name: COLUMN skill_effects_mapping.attribute_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_effects_mapping.attribute_id IS 'Атрибут-цель эффекта (например hp_regen_per_s для HoT). NULL = стандартный damage/heal без привязки к конкретному атрибуту.';


--
-- Name: skill_effects_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.skill_effects_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.skill_effects_mapping_id_seq OWNER TO postgres;

--
-- Name: skill_effects_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.skill_effects_mapping_id_seq OWNED BY public.skill_effects_mapping.id;


--
-- Name: skill_effects_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.skill_effects_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.skill_effects_type_id_seq OWNER TO postgres;

--
-- Name: skill_effects_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.skill_effects_type_id_seq OWNED BY public.skill_damage_types.id;


--
-- Name: skill_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_properties (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying NOT NULL
);


ALTER TABLE public.skill_properties OWNER TO postgres;

--
-- Name: TABLE skill_properties; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.skill_properties IS 'Справочник свойств скиллов (кулдаун, дальность, стоимость маны и т.д.)';


--
-- Name: skill_properties_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: skill_properties_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_properties_mapping (
    id integer NOT NULL,
    skill_id integer NOT NULL,
    skill_level integer NOT NULL,
    property_id integer NOT NULL,
    property_value numeric NOT NULL
);


ALTER TABLE public.skill_properties_mapping OWNER TO postgres;

--
-- Name: TABLE skill_properties_mapping; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.skill_properties_mapping IS 'Значения свойств скилла на каждом уровне';


--
-- Name: COLUMN skill_properties_mapping.skill_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_properties_mapping.skill_level IS 'Уровень скилла, для которого задано значение свойства';


--
-- Name: COLUMN skill_properties_mapping.property_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_properties_mapping.property_value IS 'Конкретное значение свойства (например, cooldown=3.0)';


--
-- Name: skill_scale_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_scale_type (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL
);


ALTER TABLE public.skill_scale_type OWNER TO postgres;

--
-- Name: TABLE skill_scale_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.skill_scale_type IS 'Типы масштабирования урона скилла (от силы, от интеллекта и т.д.)';


--
-- Name: skill_scale_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: skill_school; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_school (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL
);


ALTER TABLE public.skill_school OWNER TO postgres;

--
-- Name: TABLE skill_school; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.skill_school IS 'Магические/боевые школы скиллов (огонь, тьма, физика и т.д.)';


--
-- Name: skill_school_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: skills; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skills (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL,
    scale_stat_id integer DEFAULT 1 NOT NULL,
    school_id integer DEFAULT 1 NOT NULL,
    animation_name character varying(100) DEFAULT NULL::character varying,
    is_passive boolean DEFAULT false NOT NULL
);


ALTER TABLE public.skills OWNER TO postgres;

--
-- Name: TABLE skills; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.skills IS 'Каталог скиллов игры (шаблоны, не привязанные к персонажу)';


--
-- Name: COLUMN skills.scale_stat_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skills.scale_stat_id IS 'Атрибут, от которого масштабируется скилл (FK → skill_scale_type). NULL = без скейла';


--
-- Name: COLUMN skills.school_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skills.school_id IS 'Школа скилла (FK → skill_school). NULL = универсальный';


--
-- Name: COLUMN skills.animation_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skills.animation_name IS 'Название анимационного клипа (Unity Animator state), проигрываемого на кастере при применении скилла. NULL = клиент использует дефолтную анимацию.';


--
-- Name: COLUMN skills.is_passive; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skills.is_passive IS 'TRUE = always-on passive; no hotbar slot, never cast actively.';


--
-- Name: skills_attributes_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: skills_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: spawn_zone_mobs; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.spawn_zone_mobs OWNER TO postgres;

--
-- Name: TABLE spawn_zone_mobs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.spawn_zone_mobs IS 'Какие мобы спавнятся в зоне, в каком количестве и с каким интервалом. Одна зона может содержать несколько разных мобов.';


--
-- Name: COLUMN spawn_zone_mobs.respawn_time; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spawn_zone_mobs.respawn_time IS 'Интервал до следующего спавна в формате HH:MM:SS';


--
-- Name: spawn_zone_mobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.spawn_zone_mobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.spawn_zone_mobs_id_seq OWNER TO postgres;

--
-- Name: spawn_zone_mobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.spawn_zone_mobs_id_seq OWNED BY public.spawn_zone_mobs.id;


--
-- Name: spawn_zones; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.spawn_zones OWNER TO postgres;

--
-- Name: TABLE spawn_zones; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.spawn_zones IS 'Геометрия зоны спавна (прямоугольник координат). Принадлежит игровому региону (zones). Мобы настраиваются в spawn_zone_mobs.';


--
-- Name: COLUMN spawn_zones.game_zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spawn_zones.game_zone_id IS 'Игровой регион (zones), которому принадлежит точка спавна';


--
-- Name: spawn_zones_zone_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.spawn_zones_zone_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.spawn_zones_zone_id_seq OWNER TO postgres;

--
-- Name: spawn_zones_zone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.spawn_zones_zone_id_seq OWNED BY public.spawn_zones.zone_id;


--
-- Name: status_effect_modifiers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status_effect_modifiers (
    id integer NOT NULL,
    status_effect_id integer NOT NULL,
    attribute_id integer,
    modifier_type public.effect_modifier_type NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT chk_sem_percent_all_no_attr CHECK (((modifier_type <> 'percent_all'::public.effect_modifier_type) OR (attribute_id IS NULL)))
);


ALTER TABLE public.status_effect_modifiers OWNER TO postgres;

--
-- Name: TABLE status_effect_modifiers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.status_effect_modifiers IS 'Stat modifiers attached to a status effect. One row per attribute (or one row with attribute_id=NULL for percent_all).';


--
-- Name: COLUMN status_effect_modifiers.modifier_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.status_effect_modifiers.modifier_type IS 'flat | percent | percent_all';


--
-- Name: COLUMN status_effect_modifiers.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.status_effect_modifiers.value IS 'Numeric magnitude. Negative = penalty. For percent types: -20 means -20%.';


--
-- Name: status_effect_modifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.status_effect_modifiers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.status_effect_modifiers_id_seq OWNER TO postgres;

--
-- Name: status_effect_modifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.status_effect_modifiers_id_seq OWNED BY public.status_effect_modifiers.id;


--
-- Name: status_effects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status_effects (
    id integer NOT NULL,
    slug text NOT NULL,
    category public.status_effect_category NOT NULL,
    duration_sec integer
);


ALTER TABLE public.status_effects OWNER TO postgres;

--
-- Name: TABLE status_effects; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.status_effects IS 'Catalog of named status conditions (buffs, debuffs, DoTs, CC). Not to be confused with skill_damage_formulas.';


--
-- Name: COLUMN status_effects.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.status_effects.slug IS 'Machine-readable identifier, e.g. resurrection_sickness, burning, blessed';


--
-- Name: COLUMN status_effects.category; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.status_effects.category IS 'buff | debuff | dot | hot | cc';


--
-- Name: COLUMN status_effects.duration_sec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.status_effects.duration_sec IS 'Default duration in seconds; NULL = permanent. Chunk server uses this when applying the effect.';


--
-- Name: status_effects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.status_effects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.status_effects_id_seq OWNER TO postgres;

--
-- Name: status_effects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.status_effects_id_seq OWNED BY public.status_effects.id;


--
-- Name: target_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.target_type (
    id integer NOT NULL,
    slug text NOT NULL
);


ALTER TABLE public.target_type OWNER TO postgres;

--
-- Name: TABLE target_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.target_type IS 'Типы целей скиллов: self, enemy, ally, area и т.д.';


--
-- Name: target_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.target_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.target_type_id_seq OWNER TO postgres;

--
-- Name: target_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.target_type_id_seq OWNED BY public.target_type.id;


--
-- Name: timed_champion_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.timed_champion_templates (
    id integer NOT NULL,
    slug character varying(60) NOT NULL,
    zone_id integer NOT NULL,
    mob_template_id integer NOT NULL,
    interval_hours integer DEFAULT 6 NOT NULL,
    window_minutes integer DEFAULT 15 NOT NULL,
    next_spawn_at bigint,
    last_killed_at timestamp with time zone,
    announcement_key character varying(120) DEFAULT NULL::character varying
);


ALTER TABLE public.timed_champion_templates OWNER TO postgres;

--
-- Name: timed_champion_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.timed_champion_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.timed_champion_templates_id_seq OWNER TO postgres;

--
-- Name: timed_champion_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.timed_champion_templates_id_seq OWNED BY public.timed_champion_templates.id;


--
-- Name: user_bans; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.user_bans OWNER TO postgres;

--
-- Name: TABLE user_bans; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_bans IS 'Записи блокировок аккаунтов. expires_at = NULL означает перманентный бан';


--
-- Name: COLUMN user_bans.expires_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_bans.expires_at IS 'NULL = перманентный бан';


--
-- Name: user_bans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_bans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_bans_id_seq OWNER TO postgres;

--
-- Name: user_bans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_bans_id_seq OWNED BY public.user_bans.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    id smallint NOT NULL,
    name character varying(30) NOT NULL,
    label character varying(50) NOT NULL,
    is_staff boolean DEFAULT false NOT NULL
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- Name: TABLE user_roles; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_roles IS 'Справочник ролей аккаунтов: 0=player, 1=gm, 2=admin';


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.user_sessions OWNER TO postgres;

--
-- Name: TABLE user_sessions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_sessions IS 'Сессии пользователей — позволяет мультисессионность и точечный отзыв токена';


--
-- Name: user_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_sessions_id_seq OWNER TO postgres;

--
-- Name: user_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.users IS 'Аккаунты игроков и персонала. Один аккаунт — до неск. персонажей';


--
-- Name: COLUMN users.login; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.login IS 'Уникальный логин для входа';


--
-- Name: COLUMN users.password; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.password IS 'Пароль (в реальном проекте — хэш bcrypt)';


--
-- Name: COLUMN users.last_login; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.last_login IS 'Время последнего входа в аккаунт';


--
-- Name: COLUMN users.role; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.role IS '0=player, 1=GM, 2=администратор. FK → user_roles';


--
-- Name: COLUMN users.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.created_at IS 'Дата регистрации аккаунта';


--
-- Name: COLUMN users.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.is_active IS 'FALSE = аккаунт заблокирован/отключён администратором';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
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
-- Name: vendor_inventory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vendor_inventory (
    id bigint NOT NULL,
    vendor_npc_id integer NOT NULL,
    item_id bigint NOT NULL,
    stock_count integer DEFAULT '-1'::integer NOT NULL,
    price_override bigint,
    restock_amount integer DEFAULT 0 NOT NULL,
    stock_max integer DEFAULT '-1'::integer NOT NULL,
    restock_interval_sec integer DEFAULT 3600 NOT NULL,
    last_restock_at timestamp with time zone
);


ALTER TABLE public.vendor_inventory OWNER TO postgres;

--
-- Name: TABLE vendor_inventory; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.vendor_inventory IS 'Ассортимент конкретного торговца с остатком и ценой';


--
-- Name: COLUMN vendor_inventory.stock_count; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vendor_inventory.stock_count IS 'Остаток товара. -1 = бесконечный запас';


--
-- Name: COLUMN vendor_inventory.price_override; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vendor_inventory.price_override IS 'Ценовое исключение для этого товара у этого торговца. NULL = стандартная цена';


--
-- Name: vendor_inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vendor_inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.vendor_inventory_id_seq OWNER TO postgres;

--
-- Name: vendor_inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vendor_inventory_id_seq OWNED BY public.vendor_inventory.id;


--
-- Name: vendor_npc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vendor_npc (
    id integer NOT NULL,
    npc_id integer NOT NULL,
    markup_pct smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.vendor_npc OWNER TO postgres;

--
-- Name: TABLE vendor_npc; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.vendor_npc IS 'Торговая конфигурация NPC: базовая наценка';


--
-- Name: COLUMN vendor_npc.markup_pct; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vendor_npc.markup_pct IS 'Наценка в % поверх vendor_price_buy предмета. 0 = без наценки';


--
-- Name: vendor_npc_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vendor_npc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.vendor_npc_id_seq OWNER TO postgres;

--
-- Name: vendor_npc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vendor_npc_id_seq OWNED BY public.vendor_npc.id;


--
-- Name: zone_event_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zone_event_templates (
    id integer NOT NULL,
    slug character varying(60) NOT NULL,
    game_zone_id integer DEFAULT 0,
    trigger_type character varying(20) DEFAULT 'manual'::character varying NOT NULL,
    duration_sec integer DEFAULT 1200 NOT NULL,
    loot_multiplier double precision DEFAULT 1.0 NOT NULL,
    spawn_rate_multiplier double precision DEFAULT 1.0 NOT NULL,
    mob_speed_multiplier double precision DEFAULT 1.0 NOT NULL,
    announce_key character varying(120) DEFAULT NULL::character varying,
    interval_hours integer DEFAULT 0,
    random_chance_per_hour double precision DEFAULT 0.0,
    has_invasion_wave boolean DEFAULT false,
    invasion_mob_template_id integer DEFAULT 0,
    invasion_wave_count integer DEFAULT 0,
    invasion_champion_template_id integer DEFAULT 0,
    invasion_champion_slug character varying(60) DEFAULT NULL::character varying
);


ALTER TABLE public.zone_event_templates OWNER TO postgres;

--
-- Name: zone_event_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.zone_event_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.zone_event_templates_id_seq OWNER TO postgres;

--
-- Name: zone_event_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.zone_event_templates_id_seq OWNED BY public.zone_event_templates.id;


--
-- Name: zones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zones (
    id integer NOT NULL,
    slug character varying(100) NOT NULL,
    name character varying(100) NOT NULL,
    min_level integer DEFAULT 1 NOT NULL,
    max_level integer DEFAULT 999 NOT NULL,
    is_pvp boolean DEFAULT false NOT NULL,
    is_safe_zone boolean DEFAULT false NOT NULL,
    min_x double precision DEFAULT 0 NOT NULL,
    max_x double precision DEFAULT 0 NOT NULL,
    min_y double precision DEFAULT 0 NOT NULL,
    max_y double precision DEFAULT 0 NOT NULL,
    exploration_xp_reward integer DEFAULT 100 NOT NULL,
    champion_threshold_kills integer DEFAULT 100 NOT NULL
);


ALTER TABLE public.zones OWNER TO postgres;

--
-- Name: TABLE zones; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.zones IS 'Игровые зоны/карты. Без zone_id координаты позиций теряют смысл';


--
-- Name: zones_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.zones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.zones_id_seq OWNER TO postgres;

--
-- Name: zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.zones_id_seq OWNED BY public.zones.id;


--
-- Name: character_equipment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_equipment ALTER COLUMN id SET DEFAULT nextval('public.character_equipment_id_seq'::regclass);


--
-- Name: character_skills id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skills ALTER COLUMN id SET DEFAULT nextval('public.character_skills_id_seq1'::regclass);


--
-- Name: class_skill_tree id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_skill_tree ALTER COLUMN id SET DEFAULT nextval('public.class_skill_tree_id_seq'::regclass);


--
-- Name: currency_transactions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currency_transactions ALTER COLUMN id SET DEFAULT nextval('public.currency_transactions_id_seq'::regclass);


--
-- Name: dialogue id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue ALTER COLUMN id SET DEFAULT nextval('public.dialogue_id_seq'::regclass);


--
-- Name: dialogue_edge id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_edge ALTER COLUMN id SET DEFAULT nextval('public.dialogue_edge_id_seq'::regclass);


--
-- Name: dialogue_node id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_node ALTER COLUMN id SET DEFAULT nextval('public.dialogue_node_id_seq'::regclass);


--
-- Name: factions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factions ALTER COLUMN id SET DEFAULT nextval('public.factions_id_seq'::regclass);


--
-- Name: gm_action_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gm_action_log ALTER COLUMN id SET DEFAULT nextval('public.gm_action_log_id_seq'::regclass);


--
-- Name: item_set_bonuses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_set_bonuses ALTER COLUMN id SET DEFAULT nextval('public.item_set_bonuses_id_seq'::regclass);


--
-- Name: item_sets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_sets ALTER COLUMN id SET DEFAULT nextval('public.item_sets_id_seq'::regclass);


--
-- Name: item_use_effects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_use_effects ALTER COLUMN id SET DEFAULT nextval('public.item_use_effects_id_seq'::regclass);


--
-- Name: mob_skills id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_skills ALTER COLUMN id SET DEFAULT nextval('public.mob_skills_id_seq'::regclass);


--
-- Name: npc_placements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_placements ALTER COLUMN id SET DEFAULT nextval('public.npc_placements_id_seq'::regclass);


--
-- Name: npc_skills id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_skills ALTER COLUMN id SET DEFAULT nextval('public.npc_skills_id_seq'::regclass);


--
-- Name: passive_skill_modifiers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passive_skill_modifiers ALTER COLUMN id SET DEFAULT nextval('public.passive_skill_modifiers_id_seq'::regclass);


--
-- Name: player_active_effect id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_active_effect ALTER COLUMN id SET DEFAULT nextval('public.player_active_effect_id_seq'::regclass);


--
-- Name: quest id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest ALTER COLUMN id SET DEFAULT nextval('public.quest_id_seq'::regclass);


--
-- Name: quest_reward id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_reward ALTER COLUMN id SET DEFAULT nextval('public.quest_reward_id_seq'::regclass);


--
-- Name: quest_step id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_step ALTER COLUMN id SET DEFAULT nextval('public.quest_step_id_seq'::regclass);


--
-- Name: respawn_zones id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.respawn_zones ALTER COLUMN id SET DEFAULT nextval('public.respawn_zones_id_seq'::regclass);


--
-- Name: skill_damage_formulas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_damage_formulas ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_id_seq'::regclass);


--
-- Name: skill_damage_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_damage_types ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_type_id_seq'::regclass);


--
-- Name: skill_effect_instances id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effect_instances ALTER COLUMN id SET DEFAULT nextval('public.skill_effect_instances_id_seq'::regclass);


--
-- Name: skill_effects_mapping id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects_mapping ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_mapping_id_seq'::regclass);


--
-- Name: spawn_zone_mobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spawn_zone_mobs ALTER COLUMN id SET DEFAULT nextval('public.spawn_zone_mobs_id_seq'::regclass);


--
-- Name: spawn_zones zone_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spawn_zones ALTER COLUMN zone_id SET DEFAULT nextval('public.spawn_zones_zone_id_seq'::regclass);


--
-- Name: status_effect_modifiers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_effect_modifiers ALTER COLUMN id SET DEFAULT nextval('public.status_effect_modifiers_id_seq'::regclass);


--
-- Name: status_effects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_effects ALTER COLUMN id SET DEFAULT nextval('public.status_effects_id_seq'::regclass);


--
-- Name: target_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.target_type ALTER COLUMN id SET DEFAULT nextval('public.target_type_id_seq'::regclass);


--
-- Name: timed_champion_templates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timed_champion_templates ALTER COLUMN id SET DEFAULT nextval('public.timed_champion_templates_id_seq'::regclass);


--
-- Name: user_bans id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_bans ALTER COLUMN id SET DEFAULT nextval('public.user_bans_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.user_sessions_id_seq'::regclass);


--
-- Name: vendor_inventory id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_inventory ALTER COLUMN id SET DEFAULT nextval('public.vendor_inventory_id_seq'::regclass);


--
-- Name: vendor_npc id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_npc ALTER COLUMN id SET DEFAULT nextval('public.vendor_npc_id_seq'::regclass);


--
-- Name: zone_event_templates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zone_event_templates ALTER COLUMN id SET DEFAULT nextval('public.zone_event_templates_id_seq'::regclass);


--
-- Name: zones id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zones ALTER COLUMN id SET DEFAULT nextval('public.zones_id_seq'::regclass);


--
-- Data for Name: character_bestiary; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_bestiary (character_id, mob_template_id, kill_count) FROM stdin;
\.


--
-- Data for Name: character_class; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_class (id, name, slug, description) FROM stdin;
1	Mage	\N	\N
2	Warrior	\N	\N
\.


--
-- Data for Name: character_current_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_current_state (character_id, current_health, current_mana, is_dead, updated_at) FROM stdin;
3	287	174	f	2026-03-14 16:57:11.42033+00
1	197	454	f	2026-03-07 12:41:29.615005+00
2	188	425	f	2026-03-13 14:35:54.267726+00
\.


--
-- Data for Name: character_equipment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_equipment (id, character_id, equip_slot_id, inventory_item_id, equipped_at) FROM stdin;
21	3	6	161	2026-03-14 16:48:56.657787+00
\.


--
-- Data for Name: character_genders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_genders (id, name, label) FROM stdin;
0	male	Male
1	female	Female
2	unknown	Unknown
\.


--
-- Data for Name: character_permanent_modifiers; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- Data for Name: character_pity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_pity (character_id, item_id, kill_count) FROM stdin;
\.


--
-- Data for Name: character_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_position (id, character_id, x, y, z, zone_id, rot_z) FROM stdin;
1	1	-2000.00	4000.00	300.00	2	0
2	2	1714.08	-534.28	187.15	2	0
3	3	647.79	-3161.12	187.15	1	0
\.


--
-- Data for Name: character_reputation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_reputation (character_id, faction_slug, value) FROM stdin;
\.


--
-- Data for Name: character_skill_mastery; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_skill_mastery (character_id, mastery_slug, value) FROM stdin;
\.


--
-- Data for Name: character_skills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_skills (id, character_id, skill_id, current_level) FROM stdin;
1	1	1	1
4	2	1	1
5	3	1	1
\.


--
-- Data for Name: characters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.characters (id, name, owner_id, class_id, race_id, experience_points, level, radius, free_skill_points, gender, account_slot, created_at, last_online_at, deleted_at, play_time_sec, bind_zone_id, bind_x, bind_y, bind_z, appearance, experience_debt) FROM stdin;
1	TetsMage1Player	5	1	1	57	2	100	0	0	1	2026-03-03 16:16:54.741947+00	\N	\N	0	1	0	0	200	\N	0
2	TetsMage2Player	4	1	1	130	1	100	0	0	1	2026-03-03 16:16:54.741947+00	\N	\N	0	1	0	0	200	\N	0
3	TetsWarrior1Player	3	2	1	2048	4	100	0	0	1	2026-03-03 16:16:54.741947+00	\N	\N	0	1	0	0	200	\N	3672
\.


--
-- Data for Name: class_skill_tree; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.class_skill_tree (id, class_id, skill_id, required_level, is_default) FROM stdin;
1	1	1	1	t
2	1	3	5	f
3	2	1	1	t
4	2	2	5	f
\.


--
-- Data for Name: class_stat_formula; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- Data for Name: currency_transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.currency_transactions (id, character_id, amount, reason_type, source_id, created_at) FROM stdin;
\.


--
-- Data for Name: damage_elements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.damage_elements (slug) FROM stdin;
physical
fire
water
nature
arcane
holy
shadow
\.


--
-- Data for Name: dialogue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dialogue (id, slug, version, start_node_id) FROM stdin;
1	milaya_main	1	1
2	varan_main	1	201
3	edrik_main	1	301
\.


--
-- Data for Name: dialogue_edge; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dialogue_edge (id, from_node_id, to_node_id, order_index, client_choice_key, condition_group, action_group, hide_if_locked) FROM stdin;
23	4	7	1	milaya.choice.quest_decline	{"any": [{"slug": "wolf_hunt_intro", "type": "quest", "state": "not_started"}, {"slug": "wolf_hunt_intro", "type": "quest", "state": "turned_in"}, {"slug": "wolf_hunt_intro", "type": "quest", "state": "failed"}]}	\N	t
41	201	202	0	varan.choice.continue	\N	\N	f
42	202	203	0	varan.choice.dangers	\N	\N	f
43	202	204	1	varan.choice.road	\N	\N	f
44	202	205	2	varan.choice.watch	\N	\N	f
46	203	202	0	varan.choice.back	\N	\N	f
47	204	202	0	varan.choice.back	\N	\N	f
48	205	202	0	varan.choice.back	\N	\N	f
49	301	302	0	edrik.choice.continue	\N	\N	f
50	302	303	0	edrik.choice.about_past	\N	\N	f
51	302	304	1	edrik.choice.about_craft	\N	\N	f
52	302	305	2	edrik.choice.about_village	\N	\N	f
53	302	306	3	edrik.choice.advice	\N	\N	f
55	303	302	0	edrik.choice.back	\N	\N	f
56	304	302	0	edrik.choice.back	\N	\N	f
57	305	302	0	edrik.choice.back	\N	\N	f
58	306	302	0	edrik.choice.back	\N	\N	f
61	15	12	0	milaya.choice.quest_abandon_yes	\N	\N	f
62	15	1	1	milaya.choice.quest_abandon_no	\N	\N	f
60	4	15	5	milaya.choice.quest_abandon	{"slug": "wolf_hunt_intro", "type": "quest", "state": "active"}	\N	t
33	10	11	0		\N	\N	f
24	4	8	2	milaya.choice.quest_status	{"all": [{"slug": "wolf_hunt_intro", "type": "quest", "state": "active"}, {"slug": "wolf_hunt_intro", "step": 0, "type": "quest_step"}]}	\N	t
39	4	103	2	milaya.choice.quest_status	{"all": [{"slug": "wolf_hunt_intro", "type": "quest", "state": "active"}, {"slug": "wolf_hunt_intro", "step": 2, "type": "quest_step"}]}	\N	t
63	4	101	2	milaya.choice.quest_report_wolves	{"all": [{"slug": "wolf_hunt_intro", "type": "quest", "state": "active"}, {"slug": "wolf_hunt_intro", "step": 1, "type": "quest_step"}]}	\N	t
35	12	13	0		\N	\N	f
64	101	102	0		\N	\N	f
20	2	1	0	milaya.choice.back	\N	\N	f
65	102	4	0	milaya.choice.got_it	\N	\N	f
21	3	1	0	milaya.choice.back	\N	\N	f
66	103	4	0	milaya.choice.got_it	\N	\N	f
16	1	2	0	milaya.choice.about_village	\N	\N	f
17	1	3	1	milaya.choice.about_self	\N	\N	f
34	11	4	0	milaya.choice.back	\N	\N	f
38	100	4	0	milaya.choice.got_it	\N	\N	f
18	1	4	2	milaya.choice.any_work	\N	\N	f
19	1	99	3	milaya.choice.farewell	\N	\N	f
25	4	9	3	milaya.choice.quest_turnin	{"slug": "wolf_hunt_intro", "type": "quest", "state": "completed"}	\N	t
27	5	6	0		\N	\N	f
31	9	10	0	milaya.choice.give_wolves	\N	\N	f
32	9	12	1	milaya.choice.wont_give	\N	\N	f
45	202	299	5	varan.choice.farewell	\N	\N	f
67	202	299	3	varan.choice.trade_buy	\N	{"actions": [{"mode": "buy", "type": "open_vendor_shop"}]}	f
68	202	299	4	varan.choice.trade_sell	\N	{"actions": [{"mode": "sell", "type": "open_vendor_shop"}]}	f
54	302	399	5	edrik.choice.farewell	\N	\N	f
69	302	399	4	edrik.choice.repair	\N	{"actions": [{"type": "open_repair_shop"}]}	f
28	6	4	0	milaya.choice.back	\N	\N	f
30	8	4	0	milaya.choice.got_it	\N	\N	f
29	7	1	0	milaya.choice.back	\N	\N	f
36	13	1	0	milaya.choice.back	\N	\N	f
37	14	1	0	milaya.choice.back	\N	\N	f
26	4	14	4	milaya.choice.quest_done	{"slug": "wolf_hunt_intro", "type": "quest", "state": "turned_in"}	\N	t
22	4	5	0	milaya.choice.quest_accept	{"any": [{"slug": "wolf_hunt_intro", "type": "quest", "state": "not_started"}, {"slug": "wolf_hunt_intro", "type": "quest", "state": "turned_in"}, {"slug": "wolf_hunt_intro", "type": "quest", "state": "failed"}]}	\N	t
\.


--
-- Data for Name: dialogue_node; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dialogue_node (id, dialogue_id, type, speaker_npc_id, client_node_key, condition_group, action_group, jump_target_node_id) FROM stdin;
13	1	line	2	milaya.dialogue.quest_sad	\N	\N	\N
14	1	line	2	milaya.dialogue.quest_done	\N	\N	\N
99	1	end	2		\N	\N	\N
100	1	line	2	milaya.dialogue.quest_step1_reminder	\N	\N	\N
1	1	line	2	milaya.dialogue.greeting	\N	\N	\N
2	1	line	2	milaya.dialogue.about_village	\N	\N	\N
3	1	line	2	milaya.dialogue.about_self	\N	\N	\N
4	1	choice_hub	2	milaya.dialogue.quest_hub	\N	\N	\N
5	1	action	2		\N	{"actions": [{"slug": "wolf_hunt_intro", "type": "offer_quest"}]}	\N
6	1	line	2	milaya.dialogue.quest_accepted	\N	\N	\N
7	1	line	2	milaya.dialogue.quest_decline	\N	\N	\N
8	1	line	2	milaya.dialogue.quest_reminder	\N	\N	\N
9	1	line	2	milaya.dialogue.quest_turnin_ask	\N	\N	\N
10	1	action	2		\N	{"actions": [{"slug": "wolf_hunt_intro", "type": "turn_in_quest"}]}	\N
11	1	line	2	milaya.dialogue.quest_thanks	\N	\N	\N
12	1	action	2		\N	{"actions": [{"slug": "wolf_hunt_intro", "type": "fail_quest"}]}	\N
15	1	line	2	milaya.dialogue.quest_abandon_confirm	\N	\N	\N
101	1	action	2		\N	{"actions": [{"slug": "wolf_hunt_intro", "type": "advance_quest_step"}]}	\N
102	1	line	2	milaya.dialogue.next_task_skins	\N	\N	\N
103	1	line	2	milaya.dialogue.quest_step2_reminder	\N	\N	\N
201	2	line	1	varan.dialogue.greeting	\N	\N	\N
202	2	choice_hub	1	varan.dialogue.main_hub	\N	\N	\N
203	2	line	1	varan.dialogue.about_dangers	\N	\N	\N
204	2	line	1	varan.dialogue.about_road	\N	\N	\N
205	2	line	1	varan.dialogue.about_watch	\N	\N	\N
299	2	end	\N	\N	\N	\N	\N
301	3	line	3	edrik.dialogue.greeting	\N	\N	\N
302	3	choice_hub	3	edrik.dialogue.main_hub	\N	\N	\N
303	3	line	3	edrik.dialogue.about_past	\N	\N	\N
304	3	line	3	edrik.dialogue.about_craft	\N	\N	\N
305	3	line	3	edrik.dialogue.about_village	\N	\N	\N
306	3	line	3	edrik.dialogue.advice	\N	\N	\N
399	3	end	\N	\N	\N	\N	\N
\.


--
-- Data for Name: entity_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
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
26	Шанс парирования	parry_chance
\.


--
-- Data for Name: equip_slot; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- Data for Name: exp_for_level; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- Data for Name: factions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.factions (id, slug, name) FROM stdin;
1	hunters	Гильдия Охотников
2	city_guard	Городская Стража
3	bandits	Bandit Brotherhood
4	merchants	Торговый Союз
5	nature	Духи Природы
\.


--
-- Data for Name: game_config; Type: TABLE DATA; Schema: public; Owner: postgres
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
economy.vendor_sell_tax_pct	0.0	float	Global tax on items sold TO vendor (0–1). 0 = vendor pays full vendorPriceSell.	2026-03-11 12:07:55.916948+00
economy.vendor_buy_markup_pct	0.0	float	Global markup on items bought FROM vendor (0–1). 0 = base vendorPriceBuy.	2026-03-11 12:07:55.916948+00
economy.trade_range	5.0	float	Max distance (units) between two players for P2P trade to start.	2026-03-11 12:07:55.916948+00
durability.death_penalty_pct	0.05	float	Fraction of durabilityMax lost on death for each equipped durable item (0–1).	2026-03-11 12:07:55.916948+00
durability.weapon_loss_per_hit	1	int	Durability points weapon loses per successful attack.	2026-03-11 12:07:55.916948+00
durability.armor_loss_per_hit	1	int	Durability points each armour piece loses when player receives a hit.	2026-03-11 12:07:55.916948+00
durability.warning_threshold_pct	0.30	float	Fraction of max durability below which the item shows a warning icon	2026-03-11 12:07:55.941465+00
durability.warning_penalty_pct	0.15	float	Stat penalty (as fraction) applied when item durability is in warning range	2026-03-11 12:07:55.941465+00
carry_weight.base	50	int	Base carry weight limit before strength bonus.	2026-03-11 12:07:56.000172+00
carry_weight.per_strength	3	float	Additional carry weight granted per point of the strength attribute.	2026-03-11 12:07:56.000172+00
carry_weight.overweight_speed_penalty	0.30	float	Movement speed penalty (fraction 0-1) applied when the character is overweight. 0.30 = -30%.	2026-03-11 12:07:56.000172+00
regen.tickIntervalMs	4000	float	\N	2026-03-13 19:16:56.542313+00
regen.baseHpRegen	2	float	\N	2026-03-13 19:16:56.542313+00
regen.baseMpRegen	1	float	\N	2026-03-13 19:16:56.542313+00
regen.hpRegenConCoeff	0.3	float	\N	2026-03-13 19:16:56.542313+00
regen.mpRegenWisCoeff	0.5	float	\N	2026-03-13 19:16:56.542313+00
regen.disableInCombatMs	8000	float	\N	2026-03-13 19:16:56.542313+00
fellowship.bonus_pct	0.07	float	Fellowship XP bonus fraction (0–1). Killer and fellows who attacked same mob within window each receive this % of base mob XP.	2026-03-14 20:09:43.797621+00
fellowship.attack_window_sec	15	int	Time window (seconds) within which a co-attacker qualifies for the fellowship bonus.	2026-03-14 20:09:43.797621+00
item_soul.tier1_kills	50	int	Kill count threshold for suffix [Veteran] and +1 attribute	2026-03-14 20:09:43.80189+00
item_soul.tier2_kills	200	int	Kill count threshold for suffix [Bloody] and +2 attribute + 5% crit	2026-03-14 20:09:43.80189+00
item_soul.tier3_kills	500	int	Kill count threshold for suffix [Legendary] and +3 attribute + 8% crit	2026-03-14 20:09:43.80189+00
item_soul.tier1_bonus_flat	1	int	Flat attribute bonus at tier 1	2026-03-14 20:09:43.80189+00
item_soul.tier2_bonus_flat	2	int	Flat attribute bonus at tier 2	2026-03-14 20:09:43.80189+00
item_soul.tier3_bonus_flat	3	int	Flat attribute bonus at tier 3	2026-03-14 20:09:43.80189+00
item_soul.tier2_crit_pct	0.05	float	Crit chance bonus at tier 2	2026-03-14 20:09:43.80189+00
item_soul.tier3_crit_pct	0.08	float	Crit chance bonus at tier 3	2026-03-14 20:09:43.80189+00
item_soul.db_flush_every_kills	5	float	\N	2026-03-14 20:09:48.042848+00
exploration.default_xp_reward	100	float	\N	2026-03-14 20:09:48.045159+00
pity.soft_pity_kills	300	int	Kill count from which soft pity starts boosting drop chance	2026-03-15 07:40:02.83585+00
pity.hard_pity_kills	800	int	Kill count at which a guaranteed drop triggers (hard cap, resets counter)	2026-03-15 07:40:02.83585+00
pity.soft_bonus_per_kill	0.00005	float	Additional flat drop chance per kill after soft_pity_kills threshold	2026-03-15 07:40:02.83585+00
pity.hint_threshold_kills	500	int	Kill count at which to send a pity_hint world notification to the player	2026-03-15 07:40:02.83585+00
bestiary.tier1_kills	1	int	Kills to unlock tier 1: name, type, HP range, biome	2026-03-15 07:40:02.83585+00
bestiary.tier2_kills	5	int	Kills to unlock tier 2: weaknesses and resistances	2026-03-15 07:40:02.83585+00
bestiary.tier3_kills	15	int	Kills to unlock tier 3: common loot table	2026-03-15 07:40:02.83585+00
bestiary.tier4_kills	30	int	Kills to unlock tier 4: uncommon loot table	2026-03-15 07:40:02.83585+00
bestiary.tier5_kills	75	int	Kills to unlock tier 5: rare loot table	2026-03-15 07:40:02.83585+00
bestiary.tier6_kills	150	int	Kills to unlock tier 6: very rare loot (approximate rate shown)	2026-03-15 07:40:02.83585+00
mastery.base_delta	0.5	float	Base mastery gain per successful hit	2026-03-15 10:36:42.853016+00
mastery.db_flush_every_hits	10	int	Write mastery to DB every N hits (debounce)	2026-03-15 10:36:42.853016+00
mastery.tier1_value	20	float	Mastery tier 1 threshold	2026-03-15 10:36:42.853016+00
mastery.tier2_value	50	float	Mastery tier 2 threshold	2026-03-15 10:36:42.853016+00
mastery.tier3_value	80	float	Mastery tier 3 threshold (crit unlock)	2026-03-15 10:36:42.853016+00
mastery.tier4_value	100	float	Mastery tier 4 threshold (parry unlock)	2026-03-15 10:36:42.853016+00
reputation.enemy_threshold	-500	int	Below this: enemy tier	2026-03-15 10:36:42.853016+00
reputation.neutral_threshold	0	int	Below this: stranger tier	2026-03-15 10:36:42.853016+00
reputation.friendly_threshold	200	int	Below this: neutral tier	2026-03-15 10:36:42.853016+00
reputation.ally_threshold	500	int	Below this: friendly tier	2026-03-15 10:36:42.853016+00
zone_event.pre_announce_sec	300	int	Seconds before event to send pre-announcement	2026-03-15 10:36:42.853016+00
reputation.vendor_buy_discount	0.05	float	Buy price reduction for friendly/ally	2026-03-15 10:36:42.853016+00
reputation.vendor_sell_bonus	0.05	float	Sell price bonus for friendly/ally	2026-03-15 10:36:42.853016+00
\.


--
-- Data for Name: gm_action_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gm_action_log (id, gm_user_id, action_type, target_type, target_id, old_value, new_value, created_at) FROM stdin;
\.


--
-- Data for Name: item_attributes_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item_attributes_mapping (id, item_id, attribute_id, value, apply_on) FROM stdin;
1	1	12	10	equip
2	2	6	5	equip
3	3	21	50	use
7	15	13	8	equip
4	4	21	15	use
\.


--
-- Data for Name: item_class_restrictions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item_class_restrictions (item_id, class_id) FROM stdin;
\.


--
-- Data for Name: item_set_bonuses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item_set_bonuses (id, set_id, pieces_required, attribute_id, bonus_value) FROM stdin;
\.


--
-- Data for Name: item_set_members; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item_set_members (set_id, item_id) FROM stdin;
\.


--
-- Data for Name: item_sets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item_sets (id, name, slug) FROM stdin;
\.


--
-- Data for Name: item_types; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- Data for Name: item_use_effects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item_use_effects (id, item_id, effect_slug, attribute_slug, value, is_instant, duration_seconds, tick_ms, cooldown_seconds) FROM stdin;
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.items (id, name, slug, description, is_quest_item, item_type, weight, rarity_id, stack_max, is_container, is_durable, is_tradable, durability_max, vendor_price_buy, vendor_price_sell, equip_slot, level_requirement, is_equippable, is_harvest, is_usable, is_two_handed, mastery_slug) FROM stdin;
5	Ancient Artifact	ancient_artifact	A mysterious artifact for quests.	t	5	0.5	1	64	f	f	t	100	1	1	\N	0	f	f	f	f	\N
1	Iron Sword	iron_sworld	A sturdy iron sword.	f	1	5	1	64	f	t	t	100	50	20	6	1	t	f	f	f	\N
2	Wooden Shield	wooden_shield	A basic wooden shield.	f	2	3	1	64	f	t	t	100	40	15	7	1	t	f	f	f	\N
3	Health Potion	health_potion	Restores 50 health points.	f	3	0.5	1	64	f	f	t	100	10	4	\N	0	f	f	t	f	\N
4	Bread	bread	A loaf of bread to restore hunger.	f	4	0.1	1	64	f	f	t	100	3	1	\N	0	f	f	t	f	\N
6	Iron Ore	iron_ore	A piece of iron ore, useful for crafting.	f	6	2	1	64	f	f	t	100	5	2	\N	0	f	f	f	f	\N
9	Small Animal Skin	small_animal_skin	A basic skin of small animal.	f	6	0.3	1	64	f	f	t	100	8	3	\N	0	f	t	f	f	\N
10	Animal Fat	animal_fat	Fat extracted from animal.	f	6	0.2	1	64	f	f	t	100	4	2	\N	0	f	t	f	f	\N
11	Animal Blood	animal_blood	Blood extracted from animal.	f	6	0.5	1	64	f	f	t	100	4	1	\N	0	f	t	f	f	\N
12	Animal Meat	animal_meet	Meat extracted from animal.	f	6	1	1	64	f	f	t	100	5	2	\N	0	f	t	f	f	\N
13	Animal Fang	animal_fang	Fang extracted from animal.	f	6	0.2	1	64	f	f	t	100	6	3	\N	0	f	t	f	f	\N
14	Animal Eye	animal_eye	Eye extracted from animal.	f	6	0.1	1	64	f	f	t	100	5	2	\N	0	f	t	f	f	\N
7	Small Animal Bone	small_animal_bone	A small bones of small animal.	f	6	0.5	1	64	f	f	t	100	3	1	\N	0	f	t	f	f	\N
15	Wooden Staff	wooden_staff	A simple wooden staff for apprentice mages.	f	1	2	1	64	f	t	t	80	30	12	8	1	t	f	f	f	\N
17	Wolf Skin	wolf_skin	A rough skin of a forest wolf. Milaya will know what to do with it.	t	6	0.5	1	10	f	f	f	100	5	2	\N	0	f	f	f	f	\N
16	Gold Coin	gold_coin	Universal currency of the realm. Used as payment for goods and services.	f	8	0.01	1	9999999	f	f	t	100	1	1	\N	0	f	f	f	f	\N
\.


--
-- Data for Name: items_rarity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.items_rarity (id, name, color_hex, slug) FROM stdin;
1	Common	#FFFFFF	common
2	Uncommon	#1EFF00	uncommon
3	Rare	#0070DD	rare
4	Epic	#A335EE	epic
5	Legendary	#FF8000	legendary
\.


--
-- Data for Name: mastery_definitions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mastery_definitions (slug, name, weapon_type_slug, max_value) FROM stdin;
sword_mastery	Мастерство меча	sword	100
axe_mastery	Мастерство топора	axe	100
staff_mastery	Мастерство посоха	staff	100
bow_mastery	Мастерство лука	bow	100
unarmed_mastery	Рукопашный бой	\N	100
\.


--
-- Data for Name: mob; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob (id, name, race_id, level, spawn_health, spawn_mana, is_aggressive, is_dead, slug, radius, base_xp, rank_id, aggro_range, attack_range, attack_cooldown, chase_multiplier, patrol_speed, is_social, chase_duration, flee_hp_threshold, ai_archetype, can_evolve, is_rare, rare_spawn_chance, rare_spawn_condition, faction_slug, rep_delta_per_kill, biome_slug, mob_type_slug) FROM stdin;
2	Grey Wolf	2	1	150	50	t	f	GreyWolf	100	20	1	700	120	2	2.2	1.1	f	30	0	melee	f	f	0	\N	\N	0		beast
1	Small Fox	2	1	80	50	f	f	SmallFox	100	15	1	600	120	2.5	1.8	0.9	t	30	0	melee	f	f	0	\N	\N	0		beast
6	Wolf Pack Leader	2	3	200	60	t	f	WolfPackLeader	120	35	2	1000	140	2.2	2.5	1.2	t	45	0	melee	f	f	0	\N	\N	0		beast
7	Old Grey Wolf	2	5	500	80	t	f	OldGreyWolf	130	50	3	650	160	2	2.8	1.3	t	60	0	melee	f	f	0	\N	\N	0		beast
8	Forest Troll	3	8	1200	100	t	f	ForestTroll	180	90	4	600	200	3	1.8	0.8	f	40	0	melee	f	f	0	\N	\N	0		beast
\.


--
-- Data for Name: mob_active_effect; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_active_effect (id, mob_uid, effect_id, attribute_id, value, source_type, source_player_id, applied_at, expires_at, tick_ms) FROM stdin;
\.


--
-- Data for Name: mob_loot_info; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_loot_info (id, mob_id, item_id, drop_chance, is_harvest_only, min_quantity, max_quantity, loot_tier) FROM stdin;
10	1	3	0.10	f	1	1	common
11	1	9	0.60	t	1	1	common
12	1	10	0.30	t	1	1	common
13	1	11	0.20	t	1	2	common
14	1	12	0.15	t	1	1	common
15	2	6	0.15	f	1	2	common
16	2	9	0.50	t	1	1	common
17	2	11	0.30	t	1	1	common
18	2	12	0.15	t	1	1	common
19	2	13	0.20	t	1	1	common
20	6	3	0.05	f	1	1	common
21	6	9	0.55	t	1	1	common
22	6	11	0.35	t	1	1	common
23	6	12	0.20	t	1	1	common
24	6	13	0.25	t	1	1	common
25	7	6	0.10	f	1	1	common
26	7	9	0.60	t	1	1	common
27	7	11	0.40	t	1	2	common
28	7	12	0.25	t	1	1	common
29	7	13	0.35	t	1	1	common
30	8	3	0.30	f	1	1	common
31	8	6	0.70	f	2	4	common
32	8	7	0.20	f	1	1	common
35	2	17	0.40	f	1	1	common
\.


--
-- Data for Name: mob_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_position (id, mob_id, x, y, z, rot_z, zone_id) FROM stdin;
\.


--
-- Data for Name: mob_race; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_race (id, name) FROM stdin;
1	Goblin
2	Animal
3	Troll
\.


--
-- Data for Name: mob_ranks; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- Data for Name: mob_resistances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_resistances (mob_id, element_slug) FROM stdin;
\.


--
-- Data for Name: mob_skills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_skills (id, mob_id, skill_id, current_level) FROM stdin;
1	1	1	1
2	2	1	1
3	6	1	1
4	7	1	1
5	8	1	1
\.


--
-- Data for Name: mob_stat; Type: TABLE DATA; Schema: public; Owner: postgres
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
28	1	12	0.00	10.0000	1.1000
9	2	12	0.00	15.0000	1.1000
46	6	12	0.00	5.0000	1.1000
20	1	2	100.00	100.0000	1.0000
26	1	10	0.50	0.5000	1.0000
7	2	10	0.50	0.5000	1.0000
39	1	1	-20.00	100.0000	1.0000
24	1	6	0.00	3.0000	1.1000
29	1	13	-1.00	3.0000	1.1000
25	1	7	0.00	3.0000	1.1000
33	1	15	6.00	2.0000	1.0000
32	1	14	4.00	2.0000	1.0000
30	1	8	4.50	0.5000	1.0000
36	1	18	6.70	0.3000	1.0000
40	2	1	50.00	100.0000	1.0000
5	2	6	4.00	3.0000	1.1000
10	2	13	0.00	3.0000	1.1000
6	2	7	2.00	3.0000	1.1000
14	2	15	1.00	2.0000	1.0000
13	2	14	6.00	2.0000	1.0000
11	2	8	9.50	0.5000	1.0000
17	2	18	4.70	0.3000	1.0000
44	6	1	-100.00	100.0000	1.0000
45	6	2	-40.00	100.0000	1.0000
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
-- Data for Name: mob_weaknesses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_weaknesses (mob_id, element_slug) FROM stdin;
\.


--
-- Data for Name: npc; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc (id, name, race_id, level, current_health, current_mana, is_dead, slug, radius, is_interactable, npc_type, faction_slug) FROM stdin;
1	Varan	1	1	100	10	f	varan	100	t	1	\N
2	Milaya	1	1	100	50	f	milaya	100	t	1	\N
3	Edrik	1	1	100	20	f	edrik	100	t	1	\N
\.


--
-- Data for Name: npc_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- Data for Name: npc_dialogue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_dialogue (npc_id, dialogue_id, priority, condition_group) FROM stdin;
2	1	0	\N
1	2	0	\N
3	3	0	\N
\.


--
-- Data for Name: npc_placements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_placements (id, npc_id, zone_id, x, y, z, rot_z) FROM stdin;
1	3	1	-720	2250	200	-135
2	2	1	2200	1120	200	145
3	1	1	585	-3300	200	-40
\.


--
-- Data for Name: npc_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_position (id, npc_id, x, y, z, rot_z, zone_id) FROM stdin;
2	3	-720.00	2250.00	200.00	-135.00	\N
3	2	2200.00	1120.00	200.00	145.00	\N
1	1	585.00	-3300.00	200.00	-40.00	\N
\.


--
-- Data for Name: npc_skills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_skills (id, npc_id, skill_id, current_level) FROM stdin;
1	1	1	1
2	2	1	1
3	3	1	1
\.


--
-- Data for Name: npc_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_type (id, name, slug) FROM stdin;
1	General	general
\.


--
-- Data for Name: passive_skill_modifiers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.passive_skill_modifiers (id, skill_id, attribute_slug, modifier_type, value) FROM stdin;
\.


--
-- Data for Name: player_active_effect; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_active_effect (id, player_id, status_effect_id, source_type, source_id, value, applied_at, expires_at, attribute_id, tick_ms, group_id) FROM stdin;
1	3	1	death	\N	-68.000000	2026-03-13 17:44:38.060204+00	2026-03-13 17:46:38+00	1	0	\N
2	3	1	death	\N	-54.000000	2026-03-13 17:44:38.06612+00	2026-03-13 17:46:38+00	2	0	\N
3	3	1	death	\N	-5.000000	2026-03-13 17:44:38.068683+00	2026-03-13 17:46:38+00	3	0	\N
4	3	1	death	\N	-4.000000	2026-03-13 17:44:38.071482+00	2026-03-13 17:46:38+00	4	0	\N
5	3	1	death	\N	-1.000000	2026-03-13 17:44:38.074413+00	2026-03-13 17:46:38+00	5	0	\N
6	3	1	death	\N	-8.000000	2026-03-13 17:44:38.077174+00	2026-03-13 17:46:38+00	6	0	\N
7	3	1	death	\N	-3.000000	2026-03-13 17:44:38.079835+00	2026-03-13 17:46:38+00	7	0	\N
8	3	1	death	\N	-6.000000	2026-03-13 17:44:38.082697+00	2026-03-13 17:46:38+00	8	0	\N
9	3	1	death	\N	-1.000000	2026-03-13 17:44:38.085409+00	2026-03-13 17:46:38+00	9	0	\N
10	3	1	death	\N	-1.000000	2026-03-13 17:44:38.088784+00	2026-03-13 17:46:38+00	10	0	\N
11	3	1	death	\N	-1.000000	2026-03-13 17:44:38.091544+00	2026-03-13 17:46:38+00	11	0	\N
12	3	1	death	\N	-6.000000	2026-03-13 17:44:38.094373+00	2026-03-13 17:46:38+00	12	0	\N
13	3	1	death	\N	-2.000000	2026-03-13 17:44:38.096909+00	2026-03-13 17:46:38+00	13	0	\N
14	3	1	death	\N	-2.000000	2026-03-13 17:44:38.099815+00	2026-03-13 17:46:38+00	14	0	\N
15	3	1	death	\N	-2.000000	2026-03-13 17:44:38.102783+00	2026-03-13 17:46:38+00	15	0	\N
16	3	1	death	\N	-6.000000	2026-03-13 17:44:38.106341+00	2026-03-13 17:46:38+00	16	0	\N
17	3	1	death	\N	-2.000000	2026-03-13 17:44:38.109371+00	2026-03-13 17:46:38+00	17	0	\N
18	3	1	death	\N	-2.000000	2026-03-13 17:44:38.112231+00	2026-03-13 17:46:38+00	18	0	\N
19	3	1	death	\N	-2.000000	2026-03-13 17:44:38.114796+00	2026-03-13 17:46:38+00	19	0	\N
20	3	1	death	\N	-2.000000	2026-03-13 17:44:38.117315+00	2026-03-13 17:46:38+00	20	0	\N
21	3	1	death	\N	-68.000000	2026-03-13 17:45:34.620572+00	2026-03-13 17:47:34+00	1	0	\N
22	3	1	death	\N	-54.000000	2026-03-13 17:45:34.623918+00	2026-03-13 17:47:34+00	2	0	\N
23	3	1	death	\N	-5.000000	2026-03-13 17:45:34.626368+00	2026-03-13 17:47:34+00	3	0	\N
24	3	1	death	\N	-4.000000	2026-03-13 17:45:34.629035+00	2026-03-13 17:47:34+00	4	0	\N
25	3	1	death	\N	-1.000000	2026-03-13 17:45:34.632126+00	2026-03-13 17:47:34+00	5	0	\N
26	3	1	death	\N	-8.000000	2026-03-13 17:45:34.634769+00	2026-03-13 17:47:34+00	6	0	\N
27	3	1	death	\N	-3.000000	2026-03-13 17:45:34.637757+00	2026-03-13 17:47:34+00	7	0	\N
28	3	1	death	\N	-6.000000	2026-03-13 17:45:34.640729+00	2026-03-13 17:47:34+00	8	0	\N
29	3	1	death	\N	-1.000000	2026-03-13 17:45:34.643468+00	2026-03-13 17:47:34+00	9	0	\N
30	3	1	death	\N	-1.000000	2026-03-13 17:45:34.646149+00	2026-03-13 17:47:34+00	10	0	\N
31	3	1	death	\N	-1.000000	2026-03-13 17:45:34.649082+00	2026-03-13 17:47:34+00	11	0	\N
32	3	1	death	\N	-6.000000	2026-03-13 17:45:34.652003+00	2026-03-13 17:47:34+00	12	0	\N
33	3	1	death	\N	-2.000000	2026-03-13 17:45:34.654696+00	2026-03-13 17:47:34+00	13	0	\N
34	3	1	death	\N	-2.000000	2026-03-13 17:45:34.657491+00	2026-03-13 17:47:34+00	14	0	\N
35	3	1	death	\N	-2.000000	2026-03-13 17:45:34.660378+00	2026-03-13 17:47:34+00	15	0	\N
36	3	1	death	\N	-6.000000	2026-03-13 17:45:34.663024+00	2026-03-13 17:47:34+00	16	0	\N
37	3	1	death	\N	-2.000000	2026-03-13 17:45:34.666809+00	2026-03-13 17:47:34+00	17	0	\N
38	3	1	death	\N	-2.000000	2026-03-13 17:45:34.669804+00	2026-03-13 17:47:34+00	18	0	\N
39	3	1	death	\N	-2.000000	2026-03-13 17:45:34.672592+00	2026-03-13 17:47:34+00	19	0	\N
40	3	1	death	\N	-2.000000	2026-03-13 17:45:34.675276+00	2026-03-13 17:47:34+00	20	0	\N
41	3	1	death	\N	-68.000000	2026-03-13 17:51:05.381591+00	2026-03-13 17:53:05+00	1	0	\N
42	3	1	death	\N	-54.000000	2026-03-13 17:51:05.385439+00	2026-03-13 17:53:05+00	2	0	\N
43	3	1	death	\N	-5.000000	2026-03-13 17:51:05.388071+00	2026-03-13 17:53:05+00	3	0	\N
44	3	1	death	\N	-4.000000	2026-03-13 17:51:05.391058+00	2026-03-13 17:53:05+00	4	0	\N
45	3	1	death	\N	-1.000000	2026-03-13 17:51:05.39376+00	2026-03-13 17:53:05+00	5	0	\N
46	3	1	death	\N	-8.000000	2026-03-13 17:51:05.396473+00	2026-03-13 17:53:05+00	6	0	\N
47	3	1	death	\N	-3.000000	2026-03-13 17:51:05.399303+00	2026-03-13 17:53:05+00	7	0	\N
48	3	1	death	\N	-6.000000	2026-03-13 17:51:05.40264+00	2026-03-13 17:53:05+00	8	0	\N
49	3	1	death	\N	-1.000000	2026-03-13 17:51:05.405258+00	2026-03-13 17:53:05+00	9	0	\N
50	3	1	death	\N	-1.000000	2026-03-13 17:51:05.407915+00	2026-03-13 17:53:05+00	10	0	\N
51	3	1	death	\N	-1.000000	2026-03-13 17:51:05.410738+00	2026-03-13 17:53:05+00	11	0	\N
52	3	1	death	\N	-6.000000	2026-03-13 17:51:05.41343+00	2026-03-13 17:53:05+00	12	0	\N
53	3	1	death	\N	-2.000000	2026-03-13 17:51:05.415943+00	2026-03-13 17:53:05+00	13	0	\N
54	3	1	death	\N	-2.000000	2026-03-13 17:51:05.418613+00	2026-03-13 17:53:05+00	14	0	\N
55	3	1	death	\N	-2.000000	2026-03-13 17:51:05.421387+00	2026-03-13 17:53:05+00	15	0	\N
56	3	1	death	\N	-6.000000	2026-03-13 17:51:05.424301+00	2026-03-13 17:53:05+00	16	0	\N
57	3	1	death	\N	-2.000000	2026-03-13 17:51:05.42701+00	2026-03-13 17:53:05+00	17	0	\N
58	3	1	death	\N	-2.000000	2026-03-13 17:51:05.429615+00	2026-03-13 17:53:05+00	18	0	\N
59	3	1	death	\N	-2.000000	2026-03-13 17:51:05.432393+00	2026-03-13 17:53:05+00	19	0	\N
60	3	1	death	\N	-2.000000	2026-03-13 17:51:05.435221+00	2026-03-13 17:53:05+00	20	0	\N
61	3	1	death	\N	-68.000000	2026-03-13 17:59:59.585431+00	2026-03-13 18:01:59+00	1	0	\N
62	3	1	death	\N	-6.000000	2026-03-13 17:59:59.588521+00	2026-03-13 18:01:59+00	16	0	\N
63	3	1	death	\N	-5.000000	2026-03-13 17:59:59.591494+00	2026-03-13 18:01:59+00	3	0	\N
64	3	1	death	\N	-4.000000	2026-03-13 17:59:59.594172+00	2026-03-13 18:01:59+00	4	0	\N
65	3	1	death	\N	-1.000000	2026-03-13 17:59:59.596813+00	2026-03-13 18:01:59+00	5	0	\N
66	3	1	death	\N	-8.000000	2026-03-13 17:59:59.59942+00	2026-03-13 18:01:59+00	6	0	\N
67	3	1	death	\N	-3.000000	2026-03-13 17:59:59.602168+00	2026-03-13 18:01:59+00	7	0	\N
68	3	1	death	\N	-6.000000	2026-03-13 17:59:59.604473+00	2026-03-13 18:01:59+00	8	0	\N
69	3	1	death	\N	-1.000000	2026-03-13 17:59:59.606662+00	2026-03-13 18:01:59+00	9	0	\N
70	3	1	death	\N	-1.000000	2026-03-13 17:59:59.608946+00	2026-03-13 18:01:59+00	10	0	\N
71	3	1	death	\N	-1.000000	2026-03-13 17:59:59.611286+00	2026-03-13 18:01:59+00	11	0	\N
72	3	1	death	\N	-6.000000	2026-03-13 17:59:59.61373+00	2026-03-13 18:01:59+00	12	0	\N
73	3	1	death	\N	-2.000000	2026-03-13 17:59:59.616136+00	2026-03-13 18:01:59+00	13	0	\N
74	3	1	death	\N	-2.000000	2026-03-13 17:59:59.618528+00	2026-03-13 18:01:59+00	14	0	\N
75	3	1	death	\N	-2.000000	2026-03-13 17:59:59.62087+00	2026-03-13 18:01:59+00	15	0	\N
76	3	1	death	\N	-54.000000	2026-03-13 17:59:59.6233+00	2026-03-13 18:01:59+00	2	0	\N
77	3	1	death	\N	-2.000000	2026-03-13 17:59:59.625878+00	2026-03-13 18:01:59+00	17	0	\N
78	3	1	death	\N	-2.000000	2026-03-13 17:59:59.628366+00	2026-03-13 18:01:59+00	18	0	\N
79	3	1	death	\N	-2.000000	2026-03-13 17:59:59.631021+00	2026-03-13 18:01:59+00	19	0	\N
80	3	1	death	\N	-2.000000	2026-03-13 17:59:59.633634+00	2026-03-13 18:01:59+00	20	0	\N
81	3	1	death	\N	-68.000000	2026-03-13 18:02:34.1827+00	2026-03-13 18:04:34+00	1	0	\N
82	3	1	death	\N	-54.000000	2026-03-13 18:02:34.185901+00	2026-03-13 18:04:34+00	2	0	\N
83	3	1	death	\N	-5.000000	2026-03-13 18:02:34.188817+00	2026-03-13 18:04:34+00	3	0	\N
84	3	1	death	\N	-4.000000	2026-03-13 18:02:34.191578+00	2026-03-13 18:04:34+00	4	0	\N
85	3	1	death	\N	-1.000000	2026-03-13 18:02:34.194604+00	2026-03-13 18:04:34+00	5	0	\N
86	3	1	death	\N	-8.000000	2026-03-13 18:02:34.197506+00	2026-03-13 18:04:34+00	6	0	\N
87	3	1	death	\N	-3.000000	2026-03-13 18:02:34.200597+00	2026-03-13 18:04:34+00	7	0	\N
88	3	1	death	\N	-6.000000	2026-03-13 18:02:34.203415+00	2026-03-13 18:04:34+00	8	0	\N
89	3	1	death	\N	-1.000000	2026-03-13 18:02:34.206253+00	2026-03-13 18:04:34+00	9	0	\N
90	3	1	death	\N	-1.000000	2026-03-13 18:02:34.209495+00	2026-03-13 18:04:34+00	10	0	\N
91	3	1	death	\N	-1.000000	2026-03-13 18:02:34.212361+00	2026-03-13 18:04:34+00	11	0	\N
92	3	1	death	\N	-6.000000	2026-03-13 18:02:34.215126+00	2026-03-13 18:04:34+00	12	0	\N
93	3	1	death	\N	-2.000000	2026-03-13 18:02:34.218233+00	2026-03-13 18:04:34+00	13	0	\N
94	3	1	death	\N	-2.000000	2026-03-13 18:02:34.220921+00	2026-03-13 18:04:34+00	14	0	\N
95	3	1	death	\N	-2.000000	2026-03-13 18:02:34.223393+00	2026-03-13 18:04:34+00	15	0	\N
96	3	1	death	\N	-6.000000	2026-03-13 18:02:34.226192+00	2026-03-13 18:04:34+00	16	0	\N
97	3	1	death	\N	-2.000000	2026-03-13 18:02:34.23072+00	2026-03-13 18:04:34+00	17	0	\N
98	3	1	death	\N	-2.000000	2026-03-13 18:02:34.233413+00	2026-03-13 18:04:34+00	18	0	\N
99	3	1	death	\N	-2.000000	2026-03-13 18:02:34.236382+00	2026-03-13 18:04:34+00	19	0	\N
100	3	1	death	\N	-2.000000	2026-03-13 18:02:34.239391+00	2026-03-13 18:04:34+00	20	0	\N
101	3	1	death	\N	-68.000000	2026-03-13 18:12:38.646498+00	2026-03-13 18:14:38+00	1	0	\N
102	3	1	death	\N	-54.000000	2026-03-13 18:12:38.64992+00	2026-03-13 18:14:38+00	2	0	\N
103	3	1	death	\N	-5.000000	2026-03-13 18:12:38.652611+00	2026-03-13 18:14:38+00	3	0	\N
104	3	1	death	\N	-4.000000	2026-03-13 18:12:38.655563+00	2026-03-13 18:14:38+00	4	0	\N
105	3	1	death	\N	-1.000000	2026-03-13 18:12:38.658373+00	2026-03-13 18:14:38+00	5	0	\N
106	3	1	death	\N	-8.000000	2026-03-13 18:12:38.661148+00	2026-03-13 18:14:38+00	6	0	\N
107	3	1	death	\N	-3.000000	2026-03-13 18:12:38.664323+00	2026-03-13 18:14:38+00	7	0	\N
108	3	1	death	\N	-6.000000	2026-03-13 18:12:38.666972+00	2026-03-13 18:14:38+00	8	0	\N
109	3	1	death	\N	-1.000000	2026-03-13 18:12:38.671837+00	2026-03-13 18:14:38+00	9	0	\N
110	3	1	death	\N	-1.000000	2026-03-13 18:12:38.6759+00	2026-03-13 18:14:38+00	10	0	\N
111	3	1	death	\N	-1.000000	2026-03-13 18:12:38.678885+00	2026-03-13 18:14:38+00	11	0	\N
112	3	1	death	\N	-6.000000	2026-03-13 18:12:38.681497+00	2026-03-13 18:14:38+00	12	0	\N
113	3	1	death	\N	-2.000000	2026-03-13 18:12:38.68383+00	2026-03-13 18:14:38+00	13	0	\N
114	3	1	death	\N	-2.000000	2026-03-13 18:12:38.686767+00	2026-03-13 18:14:38+00	14	0	\N
115	3	1	death	\N	-2.000000	2026-03-13 18:12:38.689809+00	2026-03-13 18:14:38+00	15	0	\N
116	3	1	death	\N	-6.000000	2026-03-13 18:12:38.692851+00	2026-03-13 18:14:38+00	16	0	\N
117	3	1	death	\N	-2.000000	2026-03-13 18:12:38.695742+00	2026-03-13 18:14:38+00	17	0	\N
118	3	1	death	\N	-2.000000	2026-03-13 18:12:38.698704+00	2026-03-13 18:14:38+00	18	0	\N
119	3	1	death	\N	-2.000000	2026-03-13 18:12:38.701687+00	2026-03-13 18:14:38+00	19	0	\N
120	3	1	death	\N	-2.000000	2026-03-13 18:12:38.704658+00	2026-03-13 18:14:38+00	20	0	\N
121	3	1	death	\N	-68.000000	2026-03-13 18:21:36.53102+00	2026-03-13 18:23:36+00	1	0	\N
122	3	1	death	\N	-54.000000	2026-03-13 18:21:36.53462+00	2026-03-13 18:23:36+00	2	0	\N
123	3	1	death	\N	-5.000000	2026-03-13 18:21:36.537756+00	2026-03-13 18:23:36+00	3	0	\N
124	3	1	death	\N	-4.000000	2026-03-13 18:21:36.540538+00	2026-03-13 18:23:36+00	4	0	\N
125	3	1	death	\N	-1.000000	2026-03-13 18:21:36.543482+00	2026-03-13 18:23:36+00	5	0	\N
126	3	1	death	\N	-8.000000	2026-03-13 18:21:36.546229+00	2026-03-13 18:23:36+00	6	0	\N
127	3	1	death	\N	-3.000000	2026-03-13 18:21:36.548918+00	2026-03-13 18:23:36+00	7	0	\N
128	3	1	death	\N	-6.000000	2026-03-13 18:21:36.55144+00	2026-03-13 18:23:36+00	8	0	\N
129	3	1	death	\N	-1.000000	2026-03-13 18:21:36.553983+00	2026-03-13 18:23:36+00	9	0	\N
130	3	1	death	\N	-1.000000	2026-03-13 18:21:36.55657+00	2026-03-13 18:23:36+00	10	0	\N
131	3	1	death	\N	-1.000000	2026-03-13 18:21:36.55904+00	2026-03-13 18:23:36+00	11	0	\N
132	3	1	death	\N	-6.000000	2026-03-13 18:21:36.561688+00	2026-03-13 18:23:36+00	12	0	\N
133	3	1	death	\N	-2.000000	2026-03-13 18:21:36.564383+00	2026-03-13 18:23:36+00	13	0	\N
134	3	1	death	\N	-2.000000	2026-03-13 18:21:36.567078+00	2026-03-13 18:23:36+00	14	0	\N
135	3	1	death	\N	-2.000000	2026-03-13 18:21:36.569785+00	2026-03-13 18:23:36+00	15	0	\N
136	3	1	death	\N	-6.000000	2026-03-13 18:21:36.572548+00	2026-03-13 18:23:36+00	16	0	\N
137	3	1	death	\N	-2.000000	2026-03-13 18:21:36.575461+00	2026-03-13 18:23:36+00	17	0	\N
138	3	1	death	\N	-2.000000	2026-03-13 18:21:36.578471+00	2026-03-13 18:23:36+00	18	0	\N
139	3	1	death	\N	-2.000000	2026-03-13 18:21:36.581396+00	2026-03-13 18:23:36+00	19	0	\N
140	3	1	death	\N	-2.000000	2026-03-13 18:21:36.584107+00	2026-03-13 18:23:36+00	20	0	\N
141	3	1	death	\N	-68.000000	2026-03-14 13:42:40.881272+00	2026-03-14 13:44:40+00	1	0	\N
142	3	1	death	\N	-54.000000	2026-03-14 13:42:40.888457+00	2026-03-14 13:44:40+00	2	0	\N
143	3	1	death	\N	-5.000000	2026-03-14 13:42:40.891642+00	2026-03-14 13:44:40+00	3	0	\N
144	3	1	death	\N	-4.000000	2026-03-14 13:42:40.894776+00	2026-03-14 13:44:40+00	4	0	\N
145	3	1	death	\N	-1.000000	2026-03-14 13:42:40.897727+00	2026-03-14 13:44:40+00	5	0	\N
146	3	1	death	\N	-8.000000	2026-03-14 13:42:40.90076+00	2026-03-14 13:44:40+00	6	0	\N
147	3	1	death	\N	-3.000000	2026-03-14 13:42:40.903382+00	2026-03-14 13:44:40+00	7	0	\N
148	3	1	death	\N	-6.000000	2026-03-14 13:42:40.905924+00	2026-03-14 13:44:40+00	8	0	\N
149	3	1	death	\N	-1.000000	2026-03-14 13:42:40.909385+00	2026-03-14 13:44:40+00	9	0	\N
150	3	1	death	\N	-1.000000	2026-03-14 13:42:40.912265+00	2026-03-14 13:44:40+00	10	0	\N
151	3	1	death	\N	-1.000000	2026-03-14 13:42:40.916018+00	2026-03-14 13:44:40+00	11	0	\N
152	3	1	death	\N	-6.000000	2026-03-14 13:42:40.918473+00	2026-03-14 13:44:40+00	12	0	\N
153	3	1	death	\N	-2.000000	2026-03-14 13:42:40.922741+00	2026-03-14 13:44:40+00	13	0	\N
154	3	1	death	\N	-2.000000	2026-03-14 13:42:40.925295+00	2026-03-14 13:44:40+00	14	0	\N
155	3	1	death	\N	-2.000000	2026-03-14 13:42:40.928003+00	2026-03-14 13:44:40+00	15	0	\N
156	3	1	death	\N	-6.000000	2026-03-14 13:42:40.930829+00	2026-03-14 13:44:40+00	16	0	\N
157	3	1	death	\N	-2.000000	2026-03-14 13:42:40.933506+00	2026-03-14 13:44:40+00	17	0	\N
158	3	1	death	\N	-2.000000	2026-03-14 13:42:40.93641+00	2026-03-14 13:44:40+00	18	0	\N
159	3	1	death	\N	-2.000000	2026-03-14 13:42:40.9395+00	2026-03-14 13:44:40+00	19	0	\N
160	3	1	death	\N	-2.000000	2026-03-14 13:42:40.942387+00	2026-03-14 13:44:40+00	20	0	\N
\.


--
-- Data for Name: player_flag; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_flag (player_id, flag_key, int_value, bool_value, updated_at) FROM stdin;
\.


--
-- Data for Name: player_inventory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_inventory (id, character_id, item_id, quantity, slot_index, durability_current, kill_count) FROM stdin;
3	1	3	5	\N	\N	0
4	2	3	5	\N	\N	0
43	3	16	28	\N	\N	0
18	3	17	7	\N	\N	0
161	3	1	1	\N	\N	0
92	3	3	76	\N	\N	0
164	3	6	1	\N	\N	0
\.


--
-- Data for Name: player_quest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_quest (player_id, quest_id, state, current_step, progress, updated_at) FROM stdin;
3	1	active	0	{"killed": 2}	2026-03-14 16:57:11.423593+00
\.


--
-- Data for Name: quest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quest (id, slug, min_level, repeatable, cooldown_sec, giver_npc_id, turnin_npc_id, client_quest_key) FROM stdin;
1	wolf_hunt_intro	1	t	600	2	2	quest.wolf_hunt_intro
\.


--
-- Data for Name: quest_reward; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quest_reward (id, quest_id, reward_type, item_id, quantity, amount) FROM stdin;
2	1	exp	\N	0	300
1	1	item	3	5	5
\.


--
-- Data for Name: quest_step; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quest_step (id, quest_id, step_index, step_type, params, client_step_key, completion_mode) FROM stdin;
1	1	0	kill	{"count": 5, "mob_id": 2}	quest.wolf_hunt_intro.kill_wolves	auto
4	1	2	collect	{"count": 2, "item_id": 17}	quest.wolf_hunt_intro.collect_wolf_skins	auto
3	1	1	custom	{}	quest.wolf_hunt_intro.report_to_milaya	manual
\.


--
-- Data for Name: race; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.race (id, name, slug) FROM stdin;
1	Human	human
2	Elf	elf
\.


--
-- Data for Name: respawn_zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.respawn_zones (id, name, x, y, z, zone_id, is_default) FROM stdin;
1	Starting Village	0	0	200	1	t
\.


--
-- Data for Name: skill_damage_formulas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_damage_formulas (id, slug, effect_type_id) FROM stdin;
1	coeff	1
2	flat_add	1
\.


--
-- Data for Name: skill_damage_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_damage_types (id, slug) FROM stdin;
1	damage
3	dot
4	hot
\.


--
-- Data for Name: skill_effect_instances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_effect_instances (id, skill_id, order_idx, target_type_id) FROM stdin;
1	1	1	1
2	2	1	1
3	3	1	1
\.


--
-- Data for Name: skill_effects_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- Data for Name: skill_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_properties (id, name, slug) FROM stdin;
2	Cooldown (ms)	cooldown_ms
4	Cast (ms)	cast_ms
5	Cost MP	cost_mp
6	Max Range	max_range
3	Global Cooldown (ms)	gcd_ms
7	Area Radius	area_radius
8	Swing Duration (ms)	swing_ms
\.


--
-- Data for Name: skill_properties_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
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
14	1	1	4	1000
\.


--
-- Data for Name: skill_scale_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_scale_type (id, name, slug) FROM stdin;
1	PhysAtk	physical_attack
2	MagAtk	magical_attack
\.


--
-- Data for Name: skill_school; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_school (id, name, slug) FROM stdin;
1	Physical	physical
2	Magical	magical
\.


--
-- Data for Name: skills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skills (id, name, slug, scale_stat_id, school_id, animation_name, is_passive) FROM stdin;
1	Basic Attack	basic_attack	1	1	\N	f
2	Power Slash	power_slash	1	1	\N	f
3	Fireball	fireball	2	2	\N	f
\.


--
-- Data for Name: spawn_zone_mobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spawn_zone_mobs (id, spawn_zone_id, mob_id, spawn_count, respawn_time) FROM stdin;
1	1	1	3	00:01:00
2	2	2	5	00:01:00
3	3	6	4	00:02:00
4	4	7	2	00:05:00
5	5	8	1	00:10:00
\.


--
-- Data for Name: spawn_zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spawn_zones (zone_id, zone_name, min_spawn_x, min_spawn_y, min_spawn_z, max_spawn_x, max_spawn_y, max_spawn_z, game_zone_id) FROM stdin;
1	Foxes Nest	500	3500	100	3500	5000	500	2
2	Wolf Place	-1500	3500	100	0	5000	500	2
3	Wolf Pack Zone	-4000	5500	100	-2000	7000	500	2
4	Old Wolf Territory	-6500	3000	100	-4500	5000	500	2
5	Troll Cave Area	-8000	2000	100	-5500	4500	500	2
\.


--
-- Data for Name: status_effect_modifiers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.status_effect_modifiers (id, status_effect_id, attribute_id, modifier_type, value) FROM stdin;
1	1	\N	percent_all	-20
\.


--
-- Data for Name: status_effects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.status_effects (id, slug, category, duration_sec) FROM stdin;
1	resurrection_sickness	debuff	120
\.


--
-- Data for Name: target_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.target_type (id, slug) FROM stdin;
1	enemy
2	ally
3	self
\.


--
-- Data for Name: timed_champion_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.timed_champion_templates (id, slug, zone_id, mob_template_id, interval_hours, window_minutes, next_spawn_at, last_killed_at, announcement_key) FROM stdin;
\.


--
-- Data for Name: user_bans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_bans (id, user_id, banned_by_user_id, reason, created_at, expires_at, is_active) FROM stdin;
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (id, name, label, is_staff) FROM stdin;
1	gm	GM	t
0	player	Player	f
2	admin	Admin	t
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_sessions (id, user_id, token_hash, ip, user_agent, created_at, expires_at, revoked_at) FROM stdin;
1	3	99a2ff2c-71d0-44af-8551-228eaa9f321b	\N	\N	2026-03-07 17:32:24.180671+00	2026-04-06 17:32:24.180671+00	\N
2	3	3beef1a4-83f3-4470-a080-ec36c73f7329	\N	\N	2026-03-07 17:35:18.853984+00	2026-04-06 17:35:18.853984+00	\N
3	3	15b5e388-89bd-46de-812d-212cb12bd4bb	\N	\N	2026-03-07 17:35:29.616026+00	2026-04-06 17:35:29.616026+00	\N
4	3	c4d1996f-b00d-4803-b072-43fde712d71c	\N	\N	2026-03-07 17:36:57.808504+00	2026-04-06 17:36:57.808504+00	\N
5	3	d07b0ebf-ee41-4332-8bfb-bf8df4de3d86	\N	\N	2026-03-07 17:37:32.135309+00	2026-04-06 17:37:32.135309+00	\N
6	3	9a2fd7dc-71c9-45b1-8a16-9a067740b6b9	\N	\N	2026-03-07 17:37:48.307715+00	2026-04-06 17:37:48.307715+00	\N
7	3	291f7369-457f-4049-b5ee-f6c3f8e84412	\N	\N	2026-03-07 17:43:11.963798+00	2026-04-06 17:43:11.963798+00	\N
8	3	eaa869fd-bebe-48b2-b443-ae529f153774	\N	\N	2026-03-07 17:44:59.536453+00	2026-04-06 17:44:59.536453+00	\N
9	3	8733615c-6153-4b9d-b694-2375a4ab01dc	\N	\N	2026-03-07 17:46:14.328222+00	2026-04-06 17:46:14.328222+00	\N
10	3	25ef102c-1712-4dd4-961d-ce952714bf59	\N	\N	2026-03-07 17:49:46.110537+00	2026-04-06 17:49:46.110537+00	\N
11	3	4316baa8-e2f1-45f0-a335-bce06d8a60f3	\N	\N	2026-03-07 18:13:50.800143+00	2026-04-06 18:13:50.800143+00	\N
12	3	82d35e77-850b-4da0-97a5-4e97b0e76a85	\N	\N	2026-03-07 18:17:28.423213+00	2026-04-06 18:17:28.423213+00	\N
13	3	9928dd7f-3a80-42cd-92e8-17d830fd3dd0	\N	\N	2026-03-07 18:40:56.794183+00	2026-04-06 18:40:56.794183+00	\N
14	3	4ad6e2b5-e035-4a2c-913d-956f172075f5	\N	\N	2026-03-07 18:43:16.799234+00	2026-04-06 18:43:16.799234+00	\N
15	4	1073d1dc-7c5d-4fb2-9381-a8a17e688abf	\N	\N	2026-03-07 18:44:18.705858+00	2026-04-06 18:44:18.705858+00	\N
16	3	33395bfc-1373-451c-b2c3-01fec658df46	\N	\N	2026-03-07 18:44:57.723866+00	2026-04-06 18:44:57.723866+00	\N
17	3	6336607d-a11f-40ad-b4cb-aa3fda4f4854	\N	\N	2026-03-07 18:45:42.046647+00	2026-04-06 18:45:42.046647+00	\N
18	3	fe1639fe-4cbd-43e7-bc9c-d16d09aab99d	\N	\N	2026-03-07 18:46:34.56956+00	2026-04-06 18:46:34.56956+00	\N
19	3	8db64948-97dd-4dd6-b84f-16e59f8e15b5	\N	\N	2026-03-07 18:47:41.753275+00	2026-04-06 18:47:41.753275+00	\N
20	3	38a6d692-5a1e-422d-a376-89734c2d5aee	\N	\N	2026-03-07 18:50:17.381839+00	2026-04-06 18:50:17.381839+00	\N
21	3	6c6a4227-4065-4c84-8f0c-8523fd5182ee	\N	\N	2026-03-07 18:55:25.887149+00	2026-04-06 18:55:25.887149+00	\N
22	3	afcc993c-20e3-4b1b-8eda-b294cdb0a0e8	\N	\N	2026-03-07 20:05:49.534365+00	2026-04-06 20:05:49.534365+00	\N
23	3	b183d94a-d7de-4d24-b994-52f3adb51a70	\N	\N	2026-03-07 20:07:01.210666+00	2026-04-06 20:07:01.210666+00	\N
24	3	89e9cd9e-323d-46d0-9a8e-2c10f8be93b1	\N	\N	2026-03-08 09:21:10.828375+00	2026-04-07 09:21:10.828375+00	\N
25	3	5ba7d305-5a2d-45f5-b7a8-6a3948b7f886	\N	\N	2026-03-08 09:24:08.11083+00	2026-04-07 09:24:08.11083+00	\N
26	3	7ac3a53e-691f-4f28-a0f6-0acece443c08	\N	\N	2026-03-08 10:27:01.454244+00	2026-04-07 10:27:01.454244+00	\N
27	3	8463894c-454f-4aa8-96c2-083a695dd54c	\N	\N	2026-03-08 10:29:19.361399+00	2026-04-07 10:29:19.361399+00	\N
28	3	d978a1dd-0c46-433f-92ac-418c31727b2b	\N	\N	2026-03-08 10:33:36.916101+00	2026-04-07 10:33:36.916101+00	\N
29	3	1c7f07e0-5da4-48b4-a9fb-e28a8e6cbc8e	\N	\N	2026-03-08 14:21:24.659531+00	2026-04-07 14:21:24.659531+00	\N
30	3	63edbc34-3f3a-464d-81e9-9abdf579f34f	\N	\N	2026-03-08 14:22:51.344094+00	2026-04-07 14:22:51.344094+00	\N
31	3	870e4e34-e219-4379-8752-a42e26fbbefb	\N	\N	2026-03-08 14:29:13.84404+00	2026-04-07 14:29:13.84404+00	\N
32	3	48021151-c4bc-4e7f-9325-bbccb84d6485	\N	\N	2026-03-08 14:29:31.487557+00	2026-04-07 14:29:31.487557+00	\N
33	3	6490826d-ca88-464a-8286-7c530c1c2184	\N	\N	2026-03-08 14:30:11.492025+00	2026-04-07 14:30:11.492025+00	\N
34	3	2865734b-c55b-4917-bcdd-f5165d927901	\N	\N	2026-03-08 14:30:33.934546+00	2026-04-07 14:30:33.934546+00	\N
35	3	b059f69a-9323-4949-a39f-b34f8f949670	\N	\N	2026-03-08 14:33:21.903579+00	2026-04-07 14:33:21.903579+00	\N
36	3	b40f4781-5de8-4cfe-9cc1-7fb38fed04d4	\N	\N	2026-03-08 14:51:55.302306+00	2026-04-07 14:51:55.302306+00	\N
37	3	99fde917-af68-49db-bfc5-2c26d23f0e8d	\N	\N	2026-03-08 15:02:25.782403+00	2026-04-07 15:02:25.782403+00	\N
38	3	5b25687b-e8c8-4561-af51-fd2aa6fedb73	\N	\N	2026-03-08 15:03:56.906006+00	2026-04-07 15:03:56.906006+00	\N
39	3	73858f8a-85a4-4bf7-ae97-5520ad181399	\N	\N	2026-03-08 15:04:19.572953+00	2026-04-07 15:04:19.572953+00	\N
40	3	1b3bb862-a15f-4f07-8ba2-5aae0d34b933	\N	\N	2026-03-08 15:46:03.154305+00	2026-04-07 15:46:03.154305+00	\N
41	3	d4b005ce-350d-47e6-9bb4-a0ebcb533b58	\N	\N	2026-03-08 15:50:04.158063+00	2026-04-07 15:50:04.158063+00	\N
42	3	bb32be05-9da9-4d2e-b740-0bf0f5159872	\N	\N	2026-03-08 15:54:03.974247+00	2026-04-07 15:54:03.974247+00	\N
43	3	4b85fe33-ce3c-44b4-bfc9-a578cc94269e	\N	\N	2026-03-08 15:56:21.221204+00	2026-04-07 15:56:21.221204+00	\N
44	3	541c4b9c-adfc-4682-8d50-e92aa172a13b	\N	\N	2026-03-08 16:00:40.782595+00	2026-04-07 16:00:40.782595+00	\N
45	3	72c5320f-4528-4f89-885f-7391c3188c75	\N	\N	2026-03-08 16:24:02.692169+00	2026-04-07 16:24:02.692169+00	\N
46	3	ac513e50-f15c-4f05-9334-b9738969e51e	\N	\N	2026-03-08 16:24:28.274504+00	2026-04-07 16:24:28.274504+00	\N
47	3	c295d34e-0cd3-4458-974d-3dc2dc737232	\N	\N	2026-03-08 16:28:40.965602+00	2026-04-07 16:28:40.965602+00	\N
48	3	43a54ca5-6619-48c8-a0c3-3d4748933a91	\N	\N	2026-03-08 16:51:25.660727+00	2026-04-07 16:51:25.660727+00	\N
49	3	f56f0699-5748-479b-96d3-3058eded9417	\N	\N	2026-03-08 16:58:20.525678+00	2026-04-07 16:58:20.525678+00	\N
50	3	13b162d7-f584-4d48-b893-6d7c035a02fc	\N	\N	2026-03-08 17:08:10.439094+00	2026-04-07 17:08:10.439094+00	\N
51	3	a28e8643-1f21-455d-9241-777eb59c5648	\N	\N	2026-03-08 17:08:41.86904+00	2026-04-07 17:08:41.86904+00	\N
52	3	26a3685e-7215-45fe-842b-9caa989e6e40	\N	\N	2026-03-08 17:13:42.689669+00	2026-04-07 17:13:42.689669+00	\N
53	3	90ed6556-69a9-4bc1-83aa-f9e10729c09e	\N	\N	2026-03-08 17:19:28.029076+00	2026-04-07 17:19:28.029076+00	\N
54	3	b8ae4c2f-3642-4d50-9e7f-d46e7883b3e6	\N	\N	2026-03-08 17:51:37.977366+00	2026-04-07 17:51:37.977366+00	\N
55	3	00067616-e5ed-4249-a32d-d98d5e26247f	\N	\N	2026-03-08 17:52:01.6138+00	2026-04-07 17:52:01.6138+00	\N
56	3	02c8a2c7-92de-45c6-8700-f5114c629f5b	\N	\N	2026-03-08 18:25:14.022881+00	2026-04-07 18:25:14.022881+00	\N
59	3	40b4ffe3-a1af-4e5f-858d-54109ce28a57	\N	\N	2026-03-08 18:43:22.516677+00	2026-04-07 18:43:22.516677+00	\N
60	3	e6bf4c5a-7094-4f2b-8435-a1996456693b	\N	\N	2026-03-08 19:05:16.984555+00	2026-04-07 19:05:16.984555+00	\N
61	3	38222b59-d471-408e-aa80-f9f2ec0048be	\N	\N	2026-03-08 19:08:22.010048+00	2026-04-07 19:08:22.010048+00	\N
64	3	134ff92d-b12c-4ca4-a3d7-10dc10f23ffd	\N	\N	2026-03-08 19:23:06.872366+00	2026-04-07 19:23:06.872366+00	\N
65	3	3ca99682-a0c3-403b-b899-6ae19d2d0ea5	\N	\N	2026-03-08 19:26:54.8865+00	2026-04-07 19:26:54.8865+00	\N
66	3	26439c47-651b-46f3-bc5b-1ec5b3fd7ea3	\N	\N	2026-03-08 19:27:42.440225+00	2026-04-07 19:27:42.440225+00	\N
69	3	8678cedf-062f-4356-9ee7-f1701316a1d3	\N	\N	2026-03-08 19:30:12.054986+00	2026-04-07 19:30:12.054986+00	\N
70	3	b063f607-aabd-4c02-8c3a-96ecd7bf8661	\N	\N	2026-03-08 19:30:24.807742+00	2026-04-07 19:30:24.807742+00	\N
71	3	31094d56-ad6a-4747-9168-d2437835142f	\N	\N	2026-03-08 19:31:18.188108+00	2026-04-07 19:31:18.188108+00	\N
74	3	46b8cf87-f250-4f0f-8bfe-482345ecf8d5	\N	\N	2026-03-08 19:37:11.374791+00	2026-04-07 19:37:11.374791+00	\N
75	3	027b23ea-fce4-45a8-b70a-fdc02598179a	\N	\N	2026-03-08 19:39:04.673443+00	2026-04-07 19:39:04.673443+00	\N
76	3	e241c74f-fb49-4b9e-b925-043947101493	\N	\N	2026-03-08 19:41:21.96586+00	2026-04-07 19:41:21.96586+00	\N
79	3	3b2defe8-1957-42c2-a1a5-aee9a3f643ad	\N	\N	2026-03-08 19:53:27.461945+00	2026-04-07 19:53:27.461945+00	\N
80	3	7e115df9-ff70-4d2f-a533-b782344d3d7c	\N	\N	2026-03-08 20:03:00.02722+00	2026-04-07 20:03:00.02722+00	\N
81	3	d276e50a-4fff-4a41-a432-081f7d28f2f1	\N	\N	2026-03-08 20:25:08.445133+00	2026-04-07 20:25:08.445133+00	\N
57	3	74bb8b73-c272-4fae-9403-221c38e31203	\N	\N	2026-03-08 18:26:53.15476+00	2026-04-07 18:26:53.15476+00	\N
62	3	0df60d46-d4c8-46f0-88d5-2c54b5a30bfa	\N	\N	2026-03-08 19:11:51.525327+00	2026-04-07 19:11:51.525327+00	\N
67	3	98e654a5-0195-4ffc-ac44-5e35d469a75f	\N	\N	2026-03-08 19:29:35.326028+00	2026-04-07 19:29:35.326028+00	\N
72	3	bab0ffa9-daae-469b-9b0a-7aa397782b5e	\N	\N	2026-03-08 19:31:38.663579+00	2026-04-07 19:31:38.663579+00	\N
77	3	4f08a117-422c-4e7c-b8a3-04f433ddc4d7	\N	\N	2026-03-08 19:41:46.16963+00	2026-04-07 19:41:46.16963+00	\N
82	3	2436244e-e8dd-465c-b2d2-8a9e193b2ad4	\N	\N	2026-03-08 20:26:45.369475+00	2026-04-07 20:26:45.369475+00	\N
58	3	c37ba991-352d-4028-bb30-ea5a6f473ef6	\N	\N	2026-03-08 18:27:44.820534+00	2026-04-07 18:27:44.820534+00	\N
63	3	add75591-9bee-4385-9417-7c120e280bdd	\N	\N	2026-03-08 19:20:54.361689+00	2026-04-07 19:20:54.361689+00	\N
68	3	fb352fce-3243-40d7-89f2-7142dc3ba2b9	\N	\N	2026-03-08 19:30:03.61446+00	2026-04-07 19:30:03.61446+00	\N
73	3	37edd5d6-ae8d-4374-95c2-3643f6e5fca9	\N	\N	2026-03-08 19:32:22.517913+00	2026-04-07 19:32:22.517913+00	\N
78	3	858b1242-f138-41fe-80d9-0d99d74ee864	\N	\N	2026-03-08 19:52:38.228018+00	2026-04-07 19:52:38.228018+00	\N
83	3	80c1426b-e4c6-4ca4-855f-f133a1dc2f76	\N	\N	2026-03-09 08:06:43.519587+00	2026-04-08 08:06:43.519587+00	\N
84	3	2754787f-dbbd-46f1-a362-02a21ca1ce95	\N	\N	2026-03-09 08:11:22.477041+00	2026-04-08 08:11:22.477041+00	\N
85	3	27f95da3-b2ca-4f91-9318-b7676819a673	\N	\N	2026-03-09 08:11:44.074101+00	2026-04-08 08:11:44.074101+00	\N
86	3	fcb32f21-e7d2-46e2-9995-6b33f8eecfb6	\N	\N	2026-03-09 08:12:35.84911+00	2026-04-08 08:12:35.84911+00	\N
87	3	18f43a4e-b536-447f-b9cb-74abe8eb8365	\N	\N	2026-03-09 08:23:12.672829+00	2026-04-08 08:23:12.672829+00	\N
88	3	b89ae3f1-f84f-424c-9975-b4c227efa0ae	\N	\N	2026-03-09 09:50:50.72924+00	2026-04-08 09:50:50.72924+00	\N
89	3	0e2da033-a93f-4b38-b855-11f6ee671205	\N	\N	2026-03-09 10:10:41.591981+00	2026-04-08 10:10:41.591981+00	\N
90	3	570c6c50-cf5f-4642-b2e7-a80ed6ba4a0f	\N	\N	2026-03-09 10:22:01.64965+00	2026-04-08 10:22:01.64965+00	\N
91	3	e3031ea7-7e52-4278-8d76-b2bdc9e84740	\N	\N	2026-03-09 16:03:35.672752+00	2026-04-08 16:03:35.672752+00	\N
92	3	6d8c5586-8805-461a-9af2-ffb2b2503d7c	\N	\N	2026-03-09 16:04:47.95676+00	2026-04-08 16:04:47.95676+00	\N
93	3	0b6defcb-8c47-444a-aed8-0e47678bdfbd	\N	\N	2026-03-09 16:05:03.758118+00	2026-04-08 16:05:03.758118+00	\N
94	3	16a9a3aa-15c3-4b64-98ed-7dc573b74509	\N	\N	2026-03-09 17:47:42.08931+00	2026-04-08 17:47:42.08931+00	\N
95	3	1abe7973-dc7a-4c0c-bbbc-95a40d693069	\N	\N	2026-03-09 17:48:00.218843+00	2026-04-08 17:48:00.218843+00	\N
96	3	7838fa48-ba19-40ab-b9db-60eac24fd929	\N	\N	2026-03-09 17:49:32.3317+00	2026-04-08 17:49:32.3317+00	\N
97	3	062ef930-db83-4ad0-8b51-375ae9fdce97	\N	\N	2026-03-09 17:54:09.760053+00	2026-04-08 17:54:09.760053+00	\N
98	3	029944b4-d27e-4779-89bb-5c6fe13858c7	\N	\N	2026-03-09 17:58:16.799055+00	2026-04-08 17:58:16.799055+00	\N
99	3	3256d654-66c4-4732-b6e1-789e17d8f21c	\N	\N	2026-03-09 18:02:12.270953+00	2026-04-08 18:02:12.270953+00	\N
100	3	e7af4af2-77ff-4a2f-b547-db8348196609	\N	\N	2026-03-09 18:06:15.50633+00	2026-04-08 18:06:15.50633+00	\N
101	3	71d1f84e-a361-4439-9cbb-e60394ee6560	\N	\N	2026-03-09 18:09:40.875107+00	2026-04-08 18:09:40.875107+00	\N
102	3	5586a9a9-2717-4513-9ecc-49d081c2c171	\N	\N	2026-03-09 18:20:46.182198+00	2026-04-08 18:20:46.182198+00	\N
103	3	808429e4-93ea-45d6-aa3f-23a5d83be28d	\N	\N	2026-03-09 18:21:52.92545+00	2026-04-08 18:21:52.92545+00	\N
104	3	236629e6-5e0c-4763-a086-5950b5d979b8	\N	\N	2026-03-09 18:22:44.179227+00	2026-04-08 18:22:44.179227+00	\N
105	3	94e7c32d-055e-4057-93ad-a57bbf4a1711	\N	\N	2026-03-09 18:23:16.960616+00	2026-04-08 18:23:16.960616+00	\N
106	3	d717e830-7c93-430b-b3b7-eeaf7978f98e	\N	\N	2026-03-09 18:44:52.141847+00	2026-04-08 18:44:52.141847+00	\N
107	3	dee3e1f3-d2f9-4403-9c1c-d06254e24e40	\N	\N	2026-03-09 18:52:05.287588+00	2026-04-08 18:52:05.287588+00	\N
108	3	c8912c42-c58a-4dd5-b965-8c019e12aee8	\N	\N	2026-03-09 19:04:29.238877+00	2026-04-08 19:04:29.238877+00	\N
109	3	3ae1331b-7a01-4860-a090-39683a4ad2bd	\N	\N	2026-03-09 19:08:44.108048+00	2026-04-08 19:08:44.108048+00	\N
110	3	6a563e22-a56c-4503-83ae-2e6c08f85178	\N	\N	2026-03-09 19:16:43.639591+00	2026-04-08 19:16:43.639591+00	\N
111	3	7f08235d-c7c8-4815-a0e9-b67b6326bd40	\N	\N	2026-03-09 19:20:08.248232+00	2026-04-08 19:20:08.248232+00	\N
112	3	b4834ac3-8b84-49c7-9e81-425ca7d6ca76	\N	\N	2026-03-09 19:20:59.973776+00	2026-04-08 19:20:59.973776+00	\N
113	3	5c844d8b-d031-4317-b4c4-0f4cb73bec35	\N	\N	2026-03-09 19:23:58.965263+00	2026-04-08 19:23:58.965263+00	\N
114	3	486ed61a-d67a-4e56-b0cb-c9aeb42cf171	\N	\N	2026-03-09 19:25:09.944509+00	2026-04-08 19:25:09.944509+00	\N
115	3	f2c9cd52-15a1-434b-997d-3cdcc0c9f28b	\N	\N	2026-03-09 19:27:48.347753+00	2026-04-08 19:27:48.347753+00	\N
116	3	b01a787a-3132-4a0c-8b22-50b99bb53489	\N	\N	2026-03-09 19:28:14.797283+00	2026-04-08 19:28:14.797283+00	\N
117	3	12af5b40-f414-4130-b9f7-f9f3964a322d	\N	\N	2026-03-09 19:41:39.46046+00	2026-04-08 19:41:39.46046+00	\N
118	3	e76ae09d-710c-49f5-ae9e-7ba35f0e5dd4	\N	\N	2026-03-09 19:51:59.683616+00	2026-04-08 19:51:59.683616+00	\N
119	3	a3affaa6-8669-46be-8125-c107d6e11302	\N	\N	2026-03-09 19:53:36.693247+00	2026-04-08 19:53:36.693247+00	\N
120	3	56026d50-6629-49b7-ad10-93d60bc9f65c	\N	\N	2026-03-09 20:00:45.263402+00	2026-04-08 20:00:45.263402+00	\N
121	3	bb342708-96de-4c10-b471-58861cdc63dc	\N	\N	2026-03-09 20:03:14.442108+00	2026-04-08 20:03:14.442108+00	\N
122	3	f8ffbd00-0747-4e37-90cd-1366e6385256	\N	\N	2026-03-09 20:03:28.589505+00	2026-04-08 20:03:28.589505+00	\N
123	3	35ba743c-1ec5-44de-bd73-51059924b89b	\N	\N	2026-03-09 20:04:15.225563+00	2026-04-08 20:04:15.225563+00	\N
124	3	01c149e6-59b0-4291-a8e7-3d045b5bd878	\N	\N	2026-03-09 20:08:00.588534+00	2026-04-08 20:08:00.588534+00	\N
125	3	7e5105c2-1d00-4e0d-9892-d2c498b41d6e	\N	\N	2026-03-10 09:06:54.583085+00	2026-04-09 09:06:54.583085+00	\N
126	3	62fdab86-ed55-4ced-962a-6cbe3416832f	\N	\N	2026-03-10 09:10:59.804577+00	2026-04-09 09:10:59.804577+00	\N
127	3	cb773dc9-c18b-4378-a290-fb02f8862427	\N	\N	2026-03-10 09:16:09.247462+00	2026-04-09 09:16:09.247462+00	\N
128	3	290b42f0-6a9e-4e55-b283-f8f85a7e0642	\N	\N	2026-03-10 09:17:48.136181+00	2026-04-09 09:17:48.136181+00	\N
129	3	0e8b0d0a-9654-48fa-95fd-7934224730c4	\N	\N	2026-03-10 09:41:48.235585+00	2026-04-09 09:41:48.235585+00	\N
130	3	4b47b8de-ae46-407b-970a-37149efe7a04	\N	\N	2026-03-10 09:52:28.712149+00	2026-04-09 09:52:28.712149+00	\N
131	3	83c59fc7-6065-44a3-af39-b45f50a4ad5a	\N	\N	2026-03-10 09:53:17.304707+00	2026-04-09 09:53:17.304707+00	\N
132	3	4198f99b-d58f-4131-b247-66bf28910f8c	\N	\N	2026-03-10 09:58:58.57772+00	2026-04-09 09:58:58.57772+00	\N
133	3	de2a52ea-dc5d-4cc7-942e-179ab227af67	\N	\N	2026-03-10 14:25:01.318949+00	2026-04-09 14:25:01.318949+00	\N
134	3	d23ebbf3-9702-4a9b-be4f-51e3c3a4ee41	\N	\N	2026-03-10 14:25:15.819574+00	2026-04-09 14:25:15.819574+00	\N
135	3	5c453792-8967-4324-8aa4-ed7c73ed01e5	\N	\N	2026-03-10 16:32:14.079977+00	2026-04-09 16:32:14.079977+00	\N
136	3	edf7d176-2e8f-4a2b-8a84-337f411495ae	\N	\N	2026-03-10 16:38:48.448323+00	2026-04-09 16:38:48.448323+00	\N
137	3	1ea55b93-3461-4c0d-9c0f-cc5f40c899c0	\N	\N	2026-03-10 16:44:36.628311+00	2026-04-09 16:44:36.628311+00	\N
138	3	90b85236-445a-4747-aebd-a3513eaad454	\N	\N	2026-03-10 16:52:47.494064+00	2026-04-09 16:52:47.494064+00	\N
139	3	b24f3bbf-7df2-4952-b2bb-340505ba9c17	\N	\N	2026-03-10 19:27:09.688359+00	2026-04-09 19:27:09.688359+00	\N
140	3	f01c1d80-deaa-4b3f-a61b-cf65122c044f	\N	\N	2026-03-10 19:41:10.218566+00	2026-04-09 19:41:10.218566+00	\N
141	3	5e212fef-2062-4084-a054-437a56445c1a	\N	\N	2026-03-10 20:04:00.370053+00	2026-04-09 20:04:00.370053+00	\N
142	3	3820e609-3456-4905-b206-f43630b22655	\N	\N	2026-03-11 14:16:46.051776+00	2026-04-10 14:16:46.051776+00	\N
143	3	dcf073b6-ec28-42c3-a955-c9a0836412b0	\N	\N	2026-03-11 14:16:59.996268+00	2026-04-10 14:16:59.996268+00	\N
144	3	7ee927a9-411a-4cf1-8c49-e9e63a0df624	\N	\N	2026-03-11 15:32:13.585216+00	2026-04-10 15:32:13.585216+00	\N
145	3	a58bc4f6-da9b-4e3f-a6bb-1e9fcf40fb2c	\N	\N	2026-03-11 15:35:23.846296+00	2026-04-10 15:35:23.846296+00	\N
146	3	b1fe0278-9823-4f81-8326-d7d165694fd7	\N	\N	2026-03-11 16:12:08.387658+00	2026-04-10 16:12:08.387658+00	\N
147	3	dd515293-e762-46d2-b0ef-952206361271	\N	\N	2026-03-11 17:28:18.110236+00	2026-04-10 17:28:18.110236+00	\N
148	3	004844da-1a0f-4c5a-a9d9-ea957a28a487	\N	\N	2026-03-11 18:09:48.940148+00	2026-04-10 18:09:48.940148+00	\N
149	3	1073275e-bf22-451c-aa53-463b377b650b	\N	\N	2026-03-11 18:11:02.642779+00	2026-04-10 18:11:02.642779+00	\N
150	3	9faa4825-df0c-41ad-93b3-3c51ace8b1c0	\N	\N	2026-03-11 18:14:15.064291+00	2026-04-10 18:14:15.064291+00	\N
151	3	6bde7feb-ff62-4896-8e3c-a7c77f2c3eac	\N	\N	2026-03-11 18:14:52.94146+00	2026-04-10 18:14:52.94146+00	\N
152	3	5a5a5364-8fcf-4fe9-8fe9-e7b67aeaa3c7	\N	\N	2026-03-11 18:19:26.488204+00	2026-04-10 18:19:26.488204+00	\N
153	3	08657c64-b00c-4642-9038-b9afd32978e4	\N	\N	2026-03-11 18:21:23.603881+00	2026-04-10 18:21:23.603881+00	\N
154	3	654d6d24-d85c-4929-8e59-56c56ab7df25	\N	\N	2026-03-11 18:22:52.977836+00	2026-04-10 18:22:52.977836+00	\N
155	3	db8a6af5-03dc-4e8b-b542-6a544431fdc8	\N	\N	2026-03-11 18:33:05.223759+00	2026-04-10 18:33:05.223759+00	\N
156	3	06744d2d-d2fc-493f-bff6-ac5dca0da13e	\N	\N	2026-03-11 18:35:18.255818+00	2026-04-10 18:35:18.255818+00	\N
157	3	dc8c7a43-1322-4c5d-b02d-4a661bb61b38	\N	\N	2026-03-11 18:35:25.027119+00	2026-04-10 18:35:25.027119+00	\N
158	3	00b6155c-cc41-4dfd-a1ab-986a41b869fb	\N	\N	2026-03-11 18:36:18.720394+00	2026-04-10 18:36:18.720394+00	\N
159	3	69017818-55e2-4343-8290-2c5b26750f6c	\N	\N	2026-03-11 18:36:30.664861+00	2026-04-10 18:36:30.664861+00	\N
164	3	bdb3971b-1942-4013-a534-de750ef9108d	\N	\N	2026-03-11 20:28:09.584425+00	2026-04-10 20:28:09.584425+00	\N
160	3	f2c2ca6f-a44d-4bb3-880c-2d9a136fe077	\N	\N	2026-03-11 18:49:44.895645+00	2026-04-10 18:49:44.895645+00	\N
161	3	147a5c00-60e1-4c20-b735-37df4bf4a5ad	\N	\N	2026-03-11 18:49:51.746887+00	2026-04-10 18:49:51.746887+00	\N
162	3	e05cec08-fb9b-4fca-b33e-3a472ad6f1bf	\N	\N	2026-03-11 18:59:19.803221+00	2026-04-10 18:59:19.803221+00	\N
163	3	13abd57c-70c2-4594-9fe4-39cda2b510c5	\N	\N	2026-03-11 18:59:50.70104+00	2026-04-10 18:59:50.70104+00	\N
165	3	d0bb9b62-f1f5-4f62-b127-cba371b3da4c	\N	\N	2026-03-12 10:00:08.487635+00	2026-04-11 10:00:08.487635+00	\N
166	3	de51e61a-6293-4275-a3e0-349bf1276daa	\N	\N	2026-03-12 10:00:28.701581+00	2026-04-11 10:00:28.701581+00	\N
167	3	e6a0a96f-c7ae-41be-9b06-195cd7400aca	\N	\N	2026-03-12 10:00:38.083142+00	2026-04-11 10:00:38.083142+00	\N
168	3	25b886ed-80ce-4cbe-87b9-54e50b1aee9a	\N	\N	2026-03-12 10:03:18.78144+00	2026-04-11 10:03:18.78144+00	\N
169	3	2a2a43e1-f7a8-48f3-a855-64fc0410e690	\N	\N	2026-03-12 10:13:03.562675+00	2026-04-11 10:13:03.562675+00	\N
170	3	9cb6018b-aa85-4952-a623-6a2b93df2132	\N	\N	2026-03-12 10:13:35.833822+00	2026-04-11 10:13:35.833822+00	\N
171	3	71fbf901-48e1-41c0-bc08-9675959d5755	\N	\N	2026-03-12 10:19:04.06523+00	2026-04-11 10:19:04.06523+00	\N
172	3	85e7450f-3575-4ba2-aa1c-0f3651f31b23	\N	\N	2026-03-12 10:31:57.437643+00	2026-04-11 10:31:57.437643+00	\N
173	3	79e31b04-c15f-4311-b328-1ac1444be752	\N	\N	2026-03-12 10:33:25.347789+00	2026-04-11 10:33:25.347789+00	\N
174	3	085b1f57-795f-4f03-884a-f0c1da3dfb30	\N	\N	2026-03-12 10:37:50.219486+00	2026-04-11 10:37:50.219486+00	\N
175	3	e3b810a3-2ee3-48ca-8bfe-f180ffcdd84e	\N	\N	2026-03-12 10:40:47.584575+00	2026-04-11 10:40:47.584575+00	\N
176	3	d7eefa40-3805-4aa7-8441-bdd1c9a4d61d	\N	\N	2026-03-12 11:15:35.406336+00	2026-04-11 11:15:35.406336+00	\N
177	3	ca1c7216-fd53-4f33-8d46-f32221bb503b	\N	\N	2026-03-12 11:18:56.402774+00	2026-04-11 11:18:56.402774+00	\N
178	3	dfdd9043-f0dc-4434-94ff-85fee1cb99ab	\N	\N	2026-03-12 11:58:23.105527+00	2026-04-11 11:58:23.105527+00	\N
179	3	94487b5c-75d5-410f-b390-62e6362cc216	\N	\N	2026-03-12 11:58:33.867681+00	2026-04-11 11:58:33.867681+00	\N
180	3	90f59399-fcf1-4b07-bde3-35bbbb5d78a4	\N	\N	2026-03-12 11:58:41.594301+00	2026-04-11 11:58:41.594301+00	\N
181	3	d47e591b-1924-4f78-bf1c-9beb1c704687	\N	\N	2026-03-12 11:58:51.457583+00	2026-04-11 11:58:51.457583+00	\N
182	3	9a17612a-fe9c-4281-b696-69488d2f5d47	\N	\N	2026-03-12 12:02:03.645454+00	2026-04-11 12:02:03.645454+00	\N
183	3	3cc69432-ae22-46aa-8e4e-7e04fae9594f	\N	\N	2026-03-12 12:15:14.572886+00	2026-04-11 12:15:14.572886+00	\N
184	3	8f485949-227d-4023-9d02-ad2ee1c36256	\N	\N	2026-03-12 12:21:30.28872+00	2026-04-11 12:21:30.28872+00	\N
185	3	3bbbb7e8-f7ee-4463-af92-5d00000d662e	\N	\N	2026-03-12 12:41:26.669672+00	2026-04-11 12:41:26.669672+00	\N
186	3	59f964d5-24bc-47ba-9bde-736a65e6823c	\N	\N	2026-03-12 12:46:29.223748+00	2026-04-11 12:46:29.223748+00	\N
187	3	c4bab473-ed64-4650-a5c8-e98f03b43591	\N	\N	2026-03-12 12:55:11.081648+00	2026-04-11 12:55:11.081648+00	\N
188	3	ac6eeb46-f7fc-471d-b24d-02f87ef50e71	\N	\N	2026-03-12 12:56:08.321505+00	2026-04-11 12:56:08.321505+00	\N
189	3	744f6c71-343a-4067-83c8-b84509ba4347	\N	\N	2026-03-12 12:59:52.081972+00	2026-04-11 12:59:52.081972+00	\N
190	3	e565c479-351b-4689-815c-d9bd10d89dbf	\N	\N	2026-03-12 14:48:46.706382+00	2026-04-11 14:48:46.706382+00	\N
191	3	2ef1fdcf-b514-4b63-90ec-e6e52ccf33ce	\N	\N	2026-03-12 19:29:02.692784+00	2026-04-11 19:29:02.692784+00	\N
192	3	e6f31d5f-2b1d-4809-8661-b5fff2b46814	\N	\N	2026-03-12 20:08:12.231609+00	2026-04-11 20:08:12.231609+00	\N
193	3	b910828f-2890-4cc3-a209-f4454acbab8b	\N	\N	2026-03-12 20:19:39.90663+00	2026-04-11 20:19:39.90663+00	\N
194	3	ded193e1-4004-495e-846d-e8711fd9075d	\N	\N	2026-03-12 20:21:46.80838+00	2026-04-11 20:21:46.80838+00	\N
195	3	3170cd5a-495a-4b10-8e51-fcbf33732149	\N	\N	2026-03-12 20:24:54.012823+00	2026-04-11 20:24:54.012823+00	\N
196	3	e8075721-c235-48e5-86d7-30c03693444a	\N	\N	2026-03-12 20:29:19.394024+00	2026-04-11 20:29:19.394024+00	\N
197	3	96c181a3-af6f-4597-a130-b13747ad6ff4	\N	\N	2026-03-12 20:35:21.438222+00	2026-04-11 20:35:21.438222+00	\N
198	3	06acbbbc-75fa-43d7-a481-9cc7a9d9328f	\N	\N	2026-03-12 20:36:08.804504+00	2026-04-11 20:36:08.804504+00	\N
199	3	74a8a13c-a94d-4638-a1d0-3e4b37765ebe	\N	\N	2026-03-12 20:37:19.6653+00	2026-04-11 20:37:19.6653+00	\N
200	3	4fc30252-cb10-4b7a-82dd-207d6950db99	\N	\N	2026-03-12 20:38:38.372948+00	2026-04-11 20:38:38.372948+00	\N
201	3	251d680f-74c9-4521-9928-f0b72efa0e06	\N	\N	2026-03-12 20:46:50.278823+00	2026-04-11 20:46:50.278823+00	\N
202	3	21c59636-5718-4b93-b869-72f6bf262556	\N	\N	2026-03-12 20:52:50.418251+00	2026-04-11 20:52:50.418251+00	\N
203	3	3030c7ef-8caa-49d9-ac4b-ccf54b3e639b	\N	\N	2026-03-13 10:51:19.387062+00	2026-04-12 10:51:19.387062+00	\N
204	3	9a5ee74d-2290-4c09-b116-05bc3530f006	\N	\N	2026-03-13 12:08:45.672244+00	2026-04-12 12:08:45.672244+00	\N
205	3	0fa84fd5-ae92-4cfd-b800-cf97af8810aa	\N	\N	2026-03-13 12:09:34.87981+00	2026-04-12 12:09:34.87981+00	\N
206	3	e829d842-937b-4ac7-b80f-b1c89fa1aaab	\N	\N	2026-03-13 12:57:30.086514+00	2026-04-12 12:57:30.086514+00	\N
207	3	b4ab440e-0d6b-4b36-913e-4dc092e09ded	\N	\N	2026-03-13 12:59:40.26498+00	2026-04-12 12:59:40.26498+00	\N
208	3	f0926099-8772-489e-a810-1566fdfb4243	\N	\N	2026-03-13 13:00:32.231385+00	2026-04-12 13:00:32.231385+00	\N
209	3	009ed353-5f79-42fc-b9b6-4d43c6c0ec2d	\N	\N	2026-03-13 13:01:41.939685+00	2026-04-12 13:01:41.939685+00	\N
210	3	b3c28588-0486-45b8-bc6f-248e4b19234f	\N	\N	2026-03-13 13:18:28.965938+00	2026-04-12 13:18:28.965938+00	\N
211	3	5343feb2-0ed5-44f7-aa0e-cb13f1458bab	\N	\N	2026-03-13 13:51:07.272363+00	2026-04-12 13:51:07.272363+00	\N
212	3	29b917e3-be12-4cb9-aaf6-c0040aa633a6	\N	\N	2026-03-13 13:51:18.592809+00	2026-04-12 13:51:18.592809+00	\N
213	3	11072172-a8d9-497c-995e-4ed7a08978a4	\N	\N	2026-03-13 14:02:43.00115+00	2026-04-12 14:02:43.00115+00	\N
214	3	7f5be4ba-7fe7-428e-85f6-cfbb2e8c2a09	\N	\N	2026-03-13 14:15:07.095778+00	2026-04-12 14:15:07.095778+00	\N
215	3	d35da487-3f64-4a29-ba0c-d02d457f2198	\N	\N	2026-03-13 14:15:34.14289+00	2026-04-12 14:15:34.14289+00	\N
216	3	e3570fd5-0663-4ed5-ae75-a97da6c660d2	\N	\N	2026-03-13 14:33:54.143887+00	2026-04-12 14:33:54.143887+00	\N
217	4	970a9506-7765-407c-8c63-ca875bf93f6a	\N	\N	2026-03-13 14:34:21.566454+00	2026-04-12 14:34:21.566454+00	\N
218	3	6260f1c5-91c4-4e95-b4a2-045d048d17cf	\N	\N	2026-03-13 15:03:26.296184+00	2026-04-12 15:03:26.296184+00	\N
219	3	ab0f6195-c900-4279-bb04-9e87a666936c	\N	\N	2026-03-13 15:07:00.5383+00	2026-04-12 15:07:00.5383+00	\N
220	3	462e711a-89e1-43d2-9307-b71e9b26116c	\N	\N	2026-03-13 15:34:47.899348+00	2026-04-12 15:34:47.899348+00	\N
221	3	2801f2d3-a488-41bb-af89-bb04c35a75bd	\N	\N	2026-03-13 15:36:32.482425+00	2026-04-12 15:36:32.482425+00	\N
222	3	f86edde0-b913-44cf-9272-a3be7e806c61	\N	\N	2026-03-13 15:39:53.815996+00	2026-04-12 15:39:53.815996+00	\N
223	3	77d820ed-3bf4-4054-85ef-6890152834d6	\N	\N	2026-03-13 15:40:50.622854+00	2026-04-12 15:40:50.622854+00	\N
224	3	9cf23170-bf71-4f9b-9716-acda7e60da2a	\N	\N	2026-03-13 15:41:14.160413+00	2026-04-12 15:41:14.160413+00	\N
225	3	ba11c0b8-445d-400e-bb1a-9d50a4341071	\N	\N	2026-03-13 15:47:14.654721+00	2026-04-12 15:47:14.654721+00	\N
226	3	d983b013-dcff-47d6-bc36-4fc89e13e851	\N	\N	2026-03-13 15:47:50.759516+00	2026-04-12 15:47:50.759516+00	\N
227	3	10b9130f-6daf-4c1e-9457-851cbfa546fc	\N	\N	2026-03-13 15:49:00.397694+00	2026-04-12 15:49:00.397694+00	\N
228	3	4a30688d-4a94-463f-814e-5cf078a152e7	\N	\N	2026-03-13 15:53:16.510293+00	2026-04-12 15:53:16.510293+00	\N
229	3	2c6293b6-915b-427e-8dd2-e56e9528367f	\N	\N	2026-03-13 15:55:07.949396+00	2026-04-12 15:55:07.949396+00	\N
230	3	b0bfb3e8-9a27-4b94-a68f-313c5d58b4fd	\N	\N	2026-03-13 15:55:54.936664+00	2026-04-12 15:55:54.936664+00	\N
231	3	f8aae373-9d4d-4c45-b590-87c664fe52e3	\N	\N	2026-03-13 15:57:04.937297+00	2026-04-12 15:57:04.937297+00	\N
232	3	c90bf3b1-8611-41ea-bb95-aaa337023912	\N	\N	2026-03-13 15:59:22.470085+00	2026-04-12 15:59:22.470085+00	\N
233	3	09fff33b-9957-4516-8a21-348806b24903	\N	\N	2026-03-13 16:00:10.836311+00	2026-04-12 16:00:10.836311+00	\N
234	3	dd540db3-bc86-4437-9f1b-4fcd70138268	\N	\N	2026-03-13 17:06:24.419902+00	2026-04-12 17:06:24.419902+00	\N
235	3	086cd11d-1086-411f-8969-9f11fa505328	\N	\N	2026-03-13 17:08:27.832523+00	2026-04-12 17:08:27.832523+00	\N
236	3	311e90c4-6ae9-45de-9ae1-1197445e1688	\N	\N	2026-03-13 17:09:06.226429+00	2026-04-12 17:09:06.226429+00	\N
237	3	c1d3aa75-7ac9-444f-87f9-5dcc80f8cb49	\N	\N	2026-03-13 17:24:39.561696+00	2026-04-12 17:24:39.561696+00	\N
238	3	eddfe6d2-ea07-45ea-a33e-744773077f4a	\N	\N	2026-03-13 17:25:36.06491+00	2026-04-12 17:25:36.06491+00	\N
239	3	8f8d017f-8a4a-4634-a152-2b21d694d586	\N	\N	2026-03-13 17:25:47.724971+00	2026-04-12 17:25:47.724971+00	\N
240	3	f09a1c47-98a5-4dda-81f7-ddc7a7ddfeed	\N	\N	2026-03-13 17:26:43.113273+00	2026-04-12 17:26:43.113273+00	\N
241	3	ce70c4e5-ee44-4c7d-8d0c-14df6742154c	\N	\N	2026-03-13 17:27:19.660868+00	2026-04-12 17:27:19.660868+00	\N
242	3	5a997f8f-72ef-4d15-944b-9476eda5bc6b	\N	\N	2026-03-13 17:43:20.631613+00	2026-04-12 17:43:20.631613+00	\N
243	3	4bd41591-2986-4375-8c65-cf53c9f70254	\N	\N	2026-03-13 17:44:05.986676+00	2026-04-12 17:44:05.986676+00	\N
244	3	9ad7105b-8ce2-4776-b978-dafb80a731d3	\N	\N	2026-03-13 17:44:47.905865+00	2026-04-12 17:44:47.905865+00	\N
245	3	0c0d8337-0cb2-4458-afae-e8c1df70cdec	\N	\N	2026-03-13 17:50:47.282597+00	2026-04-12 17:50:47.282597+00	\N
250	3	44095eed-a38f-4fce-b1a0-d0b14eb5cd92	\N	\N	2026-03-13 18:20:59.431654+00	2026-04-12 18:20:59.431654+00	\N
246	3	ba07a704-2757-4861-8a23-804c72cf7b5b	\N	\N	2026-03-13 17:53:15.18251+00	2026-04-12 17:53:15.18251+00	\N
251	3	5910d4b7-85be-4a39-a331-31418288e409	\N	\N	2026-03-13 20:22:32.539933+00	2026-04-12 20:22:32.539933+00	\N
247	3	d5d697f6-d12e-4585-8f24-0990f3509178	\N	\N	2026-03-13 17:59:14.560418+00	2026-04-12 17:59:14.560418+00	\N
248	3	e6a7d0d3-cec4-4859-a44f-a1f62258eefb	\N	\N	2026-03-13 18:02:06.441508+00	2026-04-12 18:02:06.441508+00	\N
249	3	3bac065a-ffc8-4b09-a352-2122534fe5b1	\N	\N	2026-03-13 18:12:07.67246+00	2026-04-12 18:12:07.67246+00	\N
252	3	fc1100ba-b71f-40a5-96d7-27a16aa6238a	\N	\N	2026-03-14 11:12:56.364339+00	2026-04-13 11:12:56.364339+00	\N
253	3	27a00820-7311-4c18-9fbe-8c46ab64c7c2	\N	\N	2026-03-14 11:14:53.958429+00	2026-04-13 11:14:53.958429+00	\N
254	3	8da698d7-8678-4a63-a67d-5438524fba67	\N	\N	2026-03-14 11:15:38.094052+00	2026-04-13 11:15:38.094052+00	\N
255	3	e5849902-b180-4d12-8a3f-9f9dab292735	\N	\N	2026-03-14 11:16:03.153966+00	2026-04-13 11:16:03.153966+00	\N
256	3	fff264eb-b99a-4562-9620-05daabf31689	\N	\N	2026-03-14 11:18:03.130025+00	2026-04-13 11:18:03.130025+00	\N
257	3	acce7bd0-a1ba-43c9-bda3-1213db16c70a	\N	\N	2026-03-14 11:46:50.796113+00	2026-04-13 11:46:50.796113+00	\N
258	3	31f315a9-500c-4b66-a3ea-e83cc3692b64	\N	\N	2026-03-14 11:48:57.083049+00	2026-04-13 11:48:57.083049+00	\N
259	3	fd0fdcfc-5f5b-4c03-b41f-f34140a3a308	\N	\N	2026-03-14 11:50:46.883915+00	2026-04-13 11:50:46.883915+00	\N
260	3	08d5f155-43c7-471b-ab2b-16bdccd24596	\N	\N	2026-03-14 11:56:49.295898+00	2026-04-13 11:56:49.295898+00	\N
261	3	81b65381-8743-4601-bf0b-697b30eab69f	\N	\N	2026-03-14 11:57:17.902291+00	2026-04-13 11:57:17.902291+00	\N
262	3	33b60dab-8f97-4338-8737-9473d14d0028	\N	\N	2026-03-14 11:57:35.6456+00	2026-04-13 11:57:35.6456+00	\N
263	3	8d01e80f-e1d0-4dfb-8743-7609d1602d2d	\N	\N	2026-03-14 11:59:40.359989+00	2026-04-13 11:59:40.359989+00	\N
264	3	779d7964-5e27-4f78-93f7-978c3ddedd78	\N	\N	2026-03-14 12:01:41.780799+00	2026-04-13 12:01:41.780799+00	\N
265	3	2bcb8353-5119-4d90-8710-fe1f2245309f	\N	\N	2026-03-14 12:08:31.041424+00	2026-04-13 12:08:31.041424+00	\N
266	3	39f14fb2-b60f-46af-80fb-ffc14d1d3847	\N	\N	2026-03-14 12:09:43.887379+00	2026-04-13 12:09:43.887379+00	\N
267	3	dc4472d6-a323-4643-ba33-330c69c5ab2d	\N	\N	2026-03-14 12:10:54.23336+00	2026-04-13 12:10:54.23336+00	\N
268	3	5682fd12-97b2-40c5-ae28-d88598c4fe4d	\N	\N	2026-03-14 12:11:43.26716+00	2026-04-13 12:11:43.26716+00	\N
269	3	4b1e35cc-1332-4c1f-bb3e-a10f87518242	\N	\N	2026-03-14 12:27:46.628055+00	2026-04-13 12:27:46.628055+00	\N
270	3	fada169e-81fb-4145-ad51-9f6259c07b91	\N	\N	2026-03-14 12:52:03.107445+00	2026-04-13 12:52:03.107445+00	\N
271	3	d7c2f135-f7b9-4f05-91b5-5a70959cbb0a	\N	\N	2026-03-14 12:52:39.738964+00	2026-04-13 12:52:39.738964+00	\N
272	3	5170cec8-9670-4a0c-9536-68ce978c9a9b	\N	\N	2026-03-14 12:57:30.233773+00	2026-04-13 12:57:30.233773+00	\N
273	3	b2043c52-ea3b-4d3a-a21e-436cdf7001f9	\N	\N	2026-03-14 12:59:32.827945+00	2026-04-13 12:59:32.827945+00	\N
274	3	2f579857-d0dc-4cb7-8802-30d0b51e1e75	\N	\N	2026-03-14 13:05:13.478676+00	2026-04-13 13:05:13.478676+00	\N
275	3	c0a20db5-e936-4f95-96f2-42e1c8606cc2	\N	\N	2026-03-14 13:05:26.463117+00	2026-04-13 13:05:26.463117+00	\N
276	3	17b6e141-9ace-44ed-9875-a2a8af427bff	\N	\N	2026-03-14 13:15:51.573653+00	2026-04-13 13:15:51.573653+00	\N
277	3	f48d91fe-57c1-42b8-956f-1c5b28af1d88	\N	\N	2026-03-14 13:17:39.474219+00	2026-04-13 13:17:39.474219+00	\N
278	3	7c6d5194-7a21-4f15-b38c-b4271d462de1	\N	\N	2026-03-14 13:25:00.385933+00	2026-04-13 13:25:00.385933+00	\N
279	3	14b9a5a6-06b4-42cb-9e79-ec74f955780c	\N	\N	2026-03-14 13:25:18.98747+00	2026-04-13 13:25:18.98747+00	\N
280	3	0253674a-766c-4ab1-9adb-8af9d35ff8f5	\N	\N	2026-03-14 13:26:09.57735+00	2026-04-13 13:26:09.57735+00	\N
281	3	77cebfb1-75e3-4904-9574-58261d7e9b20	\N	\N	2026-03-14 13:36:54.244624+00	2026-04-13 13:36:54.244624+00	\N
282	3	dec985f9-d1b9-49a1-9f7d-7b90bb78d02b	\N	\N	2026-03-14 13:39:16.640125+00	2026-04-13 13:39:16.640125+00	\N
283	3	1dcbc5a7-730a-4722-a768-a5ddeb60820c	\N	\N	2026-03-14 13:41:25.450458+00	2026-04-13 13:41:25.450458+00	\N
284	3	92f730fe-f60e-4a00-965c-89bba8ff96fd	\N	\N	2026-03-14 13:43:31.137683+00	2026-04-13 13:43:31.137683+00	\N
285	3	7cbf0c24-e8a4-43ab-afb1-f01616d2cf74	\N	\N	2026-03-14 13:45:17.7281+00	2026-04-13 13:45:17.7281+00	\N
286	3	4a485cc3-3bf3-48dc-9bef-8d118afbc5d3	\N	\N	2026-03-14 13:46:45.465894+00	2026-04-13 13:46:45.465894+00	\N
287	3	2f32a3e9-11b5-4396-b73f-11de772b09b2	\N	\N	2026-03-14 16:45:48.978623+00	2026-04-13 16:45:48.978623+00	\N
288	3	73bdf823-f765-4b39-8843-8dfd0d104378	\N	\N	2026-03-14 16:48:11.692529+00	2026-04-13 16:48:11.692529+00	\N
289	3	9b2e8617-b432-4733-bbd2-29fd35cd1634	\N	\N	2026-03-14 16:56:17.38203+00	2026-04-13 16:56:17.38203+00	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, login, password, last_login, email, role, created_at, is_active, failed_login_attempts, locked_until, last_login_ip, registration_ip, is_email_verified) FROM stdin;
5	test3	test3	2023-05-04 16:25:31.727922+00	\N	0	2026-03-03 16:16:54.618401+00	t	0	\N	\N	\N	f
4	test2	test2	2026-03-13 14:34:21.562779+00	\N	0	2026-03-03 16:16:54.618401+00	t	0	\N	127.0.0.1	\N	f
3	test1	test1	2026-03-14 16:56:17.371741+00	\N	0	2026-03-03 16:16:54.618401+00	t	0	\N	127.0.0.1	\N	f
\.


--
-- Data for Name: vendor_inventory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendor_inventory (id, vendor_npc_id, item_id, stock_count, price_override, restock_amount, stock_max, restock_interval_sec, last_restock_at) FROM stdin;
3	1	3	-1	\N	0	-1	3600	\N
4	1	4	-1	\N	0	-1	3600	\N
1	1	1	5	\N	5	-1	3600	\N
2	1	2	5	\N	5	-1	3600	\N
5	1	15	5	\N	5	-1	3600	\N
\.


--
-- Data for Name: vendor_npc; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendor_npc (id, npc_id, markup_pct) FROM stdin;
1	1	10
\.


--
-- Data for Name: zone_event_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zone_event_templates (id, slug, game_zone_id, trigger_type, duration_sec, loot_multiplier, spawn_rate_multiplier, mob_speed_multiplier, announce_key, interval_hours, random_chance_per_hour, has_invasion_wave, invasion_mob_template_id, invasion_wave_count, invasion_champion_template_id, invasion_champion_slug) FROM stdin;
1	wolf_hour	1	random	1200	1.5	1	1.3	event.wolf_hour.announce	0	0.15	f	0	0	0	\N
2	merchant_convoy	1	scheduled	900	1	1	1	event.merchant_convoy	6	0	f	0	0	0	\N
3	fog_of_twilight	0	random	1800	1.2	1	0.8	event.fog_of_twilight	0	0.08	f	0	0	0	\N
\.


--
-- Data for Name: zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zones (id, slug, name, min_level, max_level, is_pvp, is_safe_zone, min_x, max_x, min_y, max_y, exploration_xp_reward, champion_threshold_kills) FROM stdin;
1	village	Village	1	10	f	t	0	0	0	0	100	100
2	wilderness	Wilderness	1	20	f	f	0	0	0	0	100	100
\.


--
-- Name: character_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_attributes_id_seq', 70, true);


--
-- Name: character_attributes_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_attributes_id_seq1', 26, true);


--
-- Name: character_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_class_id_seq', 2, true);


--
-- Name: character_equipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_equipment_id_seq', 21, true);


--
-- Name: character_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_position_id_seq', 3, true);


--
-- Name: character_skills_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_skills_id_seq1', 5, true);


--
-- Name: characters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.characters_id_seq', 3, true);


--
-- Name: class_skill_tree_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.class_skill_tree_id_seq', 4, true);


--
-- Name: currency_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.currency_transactions_id_seq', 1, false);


--
-- Name: dialogue_edge_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dialogue_edge_id_seq', 69, true);


--
-- Name: dialogue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dialogue_id_seq', 3, true);


--
-- Name: dialogue_node_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dialogue_node_id_seq', 399, true);


--
-- Name: exp_for_level_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exp_for_level_id_seq', 10, true);


--
-- Name: factions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.factions_id_seq', 5, true);


--
-- Name: gm_action_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gm_action_log_id_seq', 1, false);


--
-- Name: item_attributes_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_attributes_mapping_id_seq', 7, true);


--
-- Name: item_set_bonuses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_set_bonuses_id_seq', 1, false);


--
-- Name: item_sets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_sets_id_seq', 1, false);


--
-- Name: item_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_types_id_seq', 9, true);


--
-- Name: item_use_effects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_use_effects_id_seq', 1, false);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.items_id_seq', 17, true);


--
-- Name: mob_active_effect_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_active_effect_id_seq', 1, false);


--
-- Name: mob_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_id_seq', 8, true);


--
-- Name: mob_loot_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_loot_info_id_seq', 35, true);


--
-- Name: mob_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_position_id_seq', 1, false);


--
-- Name: mob_race_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_race_id_seq', 3, true);


--
-- Name: mob_skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_skills_id_seq', 5, true);


--
-- Name: mob_stat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_stat_id_seq', 106, true);


--
-- Name: npc_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_attributes_id_seq', 7, true);


--
-- Name: npc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_id_seq', 3, true);


--
-- Name: npc_placements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_placements_id_seq', 3, true);


--
-- Name: npc_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_position_id_seq', 1, false);


--
-- Name: npc_skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_skills_id_seq', 2, true);


--
-- Name: npc_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_type_id_seq', 1, true);


--
-- Name: passive_skill_modifiers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.passive_skill_modifiers_id_seq', 1, false);


--
-- Name: player_active_effect_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.player_active_effect_id_seq', 160, true);


--
-- Name: player_inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.player_inventory_id_seq', 164, true);


--
-- Name: quest_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quest_id_seq', 1, true);


--
-- Name: quest_reward_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quest_reward_id_seq', 2, true);


--
-- Name: quest_step_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quest_step_id_seq', 4, true);


--
-- Name: race_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.race_id_seq', 2, true);


--
-- Name: respawn_zones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.respawn_zones_id_seq', 1, true);


--
-- Name: skill_effect_instances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_effect_instances_id_seq', 3, true);


--
-- Name: skill_effects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_effects_id_seq', 4, true);


--
-- Name: skill_effects_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_effects_mapping_id_seq', 6, true);


--
-- Name: skill_effects_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_effects_type_id_seq', 4, true);


--
-- Name: skill_properties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_properties_id_seq', 8, true);


--
-- Name: skill_scale_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_scale_type_id_seq', 4, true);


--
-- Name: skill_school_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_school_id_seq', 4, true);


--
-- Name: skills_attributes_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skills_attributes_mapping_id_seq', 14, true);


--
-- Name: skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skills_id_seq', 3, true);


--
-- Name: spawn_zone_mobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.spawn_zone_mobs_id_seq', 5, true);


--
-- Name: spawn_zones_zone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.spawn_zones_zone_id_seq', 5, true);


--
-- Name: status_effect_modifiers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.status_effect_modifiers_id_seq', 1, true);


--
-- Name: status_effects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.status_effects_id_seq', 1, true);


--
-- Name: target_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.target_type_id_seq', 6, true);


--
-- Name: timed_champion_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.timed_champion_templates_id_seq', 1, false);


--
-- Name: user_bans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_bans_id_seq', 1, false);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_sessions_id_seq', 289, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 5, true);


--
-- Name: vendor_inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vendor_inventory_id_seq', 5, true);


--
-- Name: vendor_npc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vendor_npc_id_seq', 1, true);


--
-- Name: zone_event_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zone_event_templates_id_seq', 3, true);


--
-- Name: zones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zones_id_seq', 2, true);


--
-- Name: character_permanent_modifiers character_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_permanent_modifiers
    ADD CONSTRAINT character_attributes_pkey PRIMARY KEY (id);


--
-- Name: entity_attributes character_attributes_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entity_attributes
    ADD CONSTRAINT character_attributes_pkey1 PRIMARY KEY (id);


--
-- Name: character_bestiary character_bestiary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_bestiary
    ADD CONSTRAINT character_bestiary_pkey PRIMARY KEY (character_id, mob_template_id);


--
-- Name: character_class character_class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_class
    ADD CONSTRAINT character_class_pkey PRIMARY KEY (id);


--
-- Name: character_current_state character_current_state_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_current_state
    ADD CONSTRAINT character_current_state_pkey PRIMARY KEY (character_id);


--
-- Name: character_equipment character_equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_equipment
    ADD CONSTRAINT character_equipment_pkey PRIMARY KEY (id);


--
-- Name: character_genders character_genders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_genders
    ADD CONSTRAINT character_genders_pkey PRIMARY KEY (id);


--
-- Name: character_pity character_pity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_pity
    ADD CONSTRAINT character_pity_pkey PRIMARY KEY (character_id, item_id);


--
-- Name: character_position character_position_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_position
    ADD CONSTRAINT character_position_pkey PRIMARY KEY (id);


--
-- Name: character_reputation character_reputation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_reputation
    ADD CONSTRAINT character_reputation_pkey PRIMARY KEY (character_id, faction_slug);


--
-- Name: character_skill_mastery character_skill_mastery_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skill_mastery
    ADD CONSTRAINT character_skill_mastery_pkey PRIMARY KEY (character_id, mastery_slug);


--
-- Name: character_skills character_skills_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skills
    ADD CONSTRAINT character_skills_pkey1 PRIMARY KEY (id);


--
-- Name: characters characters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_pkey PRIMARY KEY (id);


--
-- Name: class_skill_tree class_skill_tree_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT class_skill_tree_pkey PRIMARY KEY (id);


--
-- Name: class_stat_formula class_stat_formula_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_stat_formula
    ADD CONSTRAINT class_stat_formula_pkey PRIMARY KEY (class_id, attribute_id);


--
-- Name: currency_transactions currency_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currency_transactions
    ADD CONSTRAINT currency_transactions_pkey PRIMARY KEY (id);


--
-- Name: damage_elements damage_elements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.damage_elements
    ADD CONSTRAINT damage_elements_pkey PRIMARY KEY (slug);


--
-- Name: dialogue_edge dialogue_edge_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_edge
    ADD CONSTRAINT dialogue_edge_pkey PRIMARY KEY (id);


--
-- Name: dialogue_node dialogue_node_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_node
    ADD CONSTRAINT dialogue_node_pkey PRIMARY KEY (id);


--
-- Name: dialogue dialogue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue
    ADD CONSTRAINT dialogue_pkey PRIMARY KEY (id);


--
-- Name: dialogue dialogue_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue
    ADD CONSTRAINT dialogue_slug_key UNIQUE (slug);


--
-- Name: equip_slot equip_slot_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equip_slot
    ADD CONSTRAINT equip_slot_pkey PRIMARY KEY (id);


--
-- Name: equip_slot equip_slot_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equip_slot
    ADD CONSTRAINT equip_slot_slug_key UNIQUE (slug);


--
-- Name: factions factions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factions
    ADD CONSTRAINT factions_pkey PRIMARY KEY (id);


--
-- Name: factions factions_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factions
    ADD CONSTRAINT factions_slug_key UNIQUE (slug);


--
-- Name: game_config game_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_config
    ADD CONSTRAINT game_config_pkey PRIMARY KEY (key);


--
-- Name: gm_action_log gm_action_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gm_action_log
    ADD CONSTRAINT gm_action_log_pkey PRIMARY KEY (id);


--
-- Name: item_attributes_mapping item_attributes_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_attributes_mapping
    ADD CONSTRAINT item_attributes_mapping_pkey PRIMARY KEY (id);


--
-- Name: item_class_restrictions item_class_restrictions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_class_restrictions
    ADD CONSTRAINT item_class_restrictions_pkey PRIMARY KEY (item_id, class_id);


--
-- Name: item_set_bonuses item_set_bonuses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_set_bonuses
    ADD CONSTRAINT item_set_bonuses_pkey PRIMARY KEY (id);


--
-- Name: item_set_members item_set_members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_set_members
    ADD CONSTRAINT item_set_members_pkey PRIMARY KEY (set_id, item_id);


--
-- Name: item_sets item_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_sets
    ADD CONSTRAINT item_sets_pkey PRIMARY KEY (id);


--
-- Name: item_sets item_sets_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_sets
    ADD CONSTRAINT item_sets_slug_key UNIQUE (slug);


--
-- Name: item_types item_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_types
    ADD CONSTRAINT item_types_pkey PRIMARY KEY (id);


--
-- Name: item_use_effects item_use_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_use_effects
    ADD CONSTRAINT item_use_effects_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: mastery_definitions mastery_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mastery_definitions
    ADD CONSTRAINT mastery_definitions_pkey PRIMARY KEY (slug);


--
-- Name: mob_active_effect mob_active_effect_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_active_effect
    ADD CONSTRAINT mob_active_effect_pkey PRIMARY KEY (id);


--
-- Name: mob_loot_info mob_loot_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_loot_info
    ADD CONSTRAINT mob_loot_info_pkey PRIMARY KEY (id);


--
-- Name: mob mob_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_pkey PRIMARY KEY (id);


--
-- Name: mob_position mob_position_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_position
    ADD CONSTRAINT mob_position_pkey PRIMARY KEY (id);


--
-- Name: mob_race mob_race_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_race
    ADD CONSTRAINT mob_race_pkey PRIMARY KEY (id);


--
-- Name: mob_ranks mob_ranks_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_ranks
    ADD CONSTRAINT mob_ranks_code_key UNIQUE (code);


--
-- Name: mob_ranks mob_ranks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_ranks
    ADD CONSTRAINT mob_ranks_pkey PRIMARY KEY (rank_id);


--
-- Name: mob_resistances mob_resistances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_resistances
    ADD CONSTRAINT mob_resistances_pkey PRIMARY KEY (mob_id, element_slug);


--
-- Name: mob_skills mob_skills_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_skills
    ADD CONSTRAINT mob_skills_pkey1 PRIMARY KEY (id);


--
-- Name: mob mob_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_slug_key UNIQUE (slug);


--
-- Name: mob_stat mob_stat_mob_attr_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_stat
    ADD CONSTRAINT mob_stat_mob_attr_unique UNIQUE (mob_id, attribute_id);


--
-- Name: mob_stat mob_stat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_stat
    ADD CONSTRAINT mob_stat_pkey PRIMARY KEY (id);


--
-- Name: mob_weaknesses mob_weaknesses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_weaknesses
    ADD CONSTRAINT mob_weaknesses_pkey PRIMARY KEY (mob_id, element_slug);


--
-- Name: npc_attributes npc_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_attributes
    ADD CONSTRAINT npc_attributes_pkey PRIMARY KEY (id);


--
-- Name: npc_dialogue npc_dialogue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_dialogue
    ADD CONSTRAINT npc_dialogue_pkey PRIMARY KEY (npc_id, dialogue_id);


--
-- Name: npc npc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_pkey PRIMARY KEY (id);


--
-- Name: npc_placements npc_placements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_placements
    ADD CONSTRAINT npc_placements_pkey PRIMARY KEY (id);


--
-- Name: npc_position npc_position_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_position
    ADD CONSTRAINT npc_position_pkey PRIMARY KEY (id);


--
-- Name: npc_skills npc_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_skills
    ADD CONSTRAINT npc_skills_pkey PRIMARY KEY (id);


--
-- Name: npc npc_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_slug_key UNIQUE (slug);


--
-- Name: npc_type npc_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_type
    ADD CONSTRAINT npc_type_pkey PRIMARY KEY (id);


--
-- Name: passive_skill_modifiers passive_skill_modifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passive_skill_modifiers
    ADD CONSTRAINT passive_skill_modifiers_pkey PRIMARY KEY (id);


--
-- Name: player_active_effect player_active_effect_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_pkey PRIMARY KEY (id);


--
-- Name: player_flag player_flag_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_flag
    ADD CONSTRAINT player_flag_pkey PRIMARY KEY (player_id, flag_key);


--
-- Name: player_inventory player_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_inventory
    ADD CONSTRAINT player_inventory_pkey PRIMARY KEY (id);


--
-- Name: player_quest player_quest_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_quest
    ADD CONSTRAINT player_quest_pkey PRIMARY KEY (player_id, quest_id);


--
-- Name: quest quest_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest
    ADD CONSTRAINT quest_pkey PRIMARY KEY (id);


--
-- Name: quest_reward quest_reward_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_reward
    ADD CONSTRAINT quest_reward_pkey PRIMARY KEY (id);


--
-- Name: quest quest_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest
    ADD CONSTRAINT quest_slug_key UNIQUE (slug);


--
-- Name: quest_step quest_step_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_step
    ADD CONSTRAINT quest_step_pkey PRIMARY KEY (id);


--
-- Name: quest_step quest_step_quest_id_step_index_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_step
    ADD CONSTRAINT quest_step_quest_id_step_index_key UNIQUE (quest_id, step_index);


--
-- Name: race race_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.race
    ADD CONSTRAINT race_pkey PRIMARY KEY (id);


--
-- Name: items_rarity rarity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items_rarity
    ADD CONSTRAINT rarity_pkey PRIMARY KEY (id);


--
-- Name: respawn_zones respawn_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.respawn_zones
    ADD CONSTRAINT respawn_zones_pkey PRIMARY KEY (id);


--
-- Name: skill_effect_instances skill_effect_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effect_instances
    ADD CONSTRAINT skill_effect_instances_pkey PRIMARY KEY (id);


--
-- Name: skill_effect_instances skill_effect_instances_skill_id_order_idx_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effect_instances
    ADD CONSTRAINT skill_effect_instances_skill_id_order_idx_key UNIQUE (skill_id, order_idx);


--
-- Name: skill_effects_mapping skill_effects_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_pkey PRIMARY KEY (id);


--
-- Name: skill_damage_formulas skill_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_damage_formulas
    ADD CONSTRAINT skill_effects_pkey PRIMARY KEY (id);


--
-- Name: skill_damage_formulas skill_effects_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_damage_formulas
    ADD CONSTRAINT skill_effects_slug_key UNIQUE (slug);


--
-- Name: skill_damage_types skill_effects_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_damage_types
    ADD CONSTRAINT skill_effects_type_pkey PRIMARY KEY (id);


--
-- Name: skill_damage_types skill_effects_type_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_damage_types
    ADD CONSTRAINT skill_effects_type_slug_key UNIQUE (slug);


--
-- Name: skill_properties skill_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_properties
    ADD CONSTRAINT skill_properties_pkey PRIMARY KEY (id);


--
-- Name: skill_scale_type skill_scale_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_scale_type
    ADD CONSTRAINT skill_scale_pkey PRIMARY KEY (id);


--
-- Name: skill_school skill_school_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_school
    ADD CONSTRAINT skill_school_pkey PRIMARY KEY (id);


--
-- Name: skill_properties_mapping skills_attributes_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_properties_mapping
    ADD CONSTRAINT skills_attributes_mapping_pkey PRIMARY KEY (id);


--
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (id);


--
-- Name: spawn_zone_mobs spawn_zone_mobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spawn_zone_mobs
    ADD CONSTRAINT spawn_zone_mobs_pkey PRIMARY KEY (id);


--
-- Name: spawn_zone_mobs spawn_zone_mobs_spawn_zone_id_mob_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spawn_zone_mobs
    ADD CONSTRAINT spawn_zone_mobs_spawn_zone_id_mob_id_key UNIQUE (spawn_zone_id, mob_id);


--
-- Name: spawn_zones spawn_zones_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spawn_zones
    ADD CONSTRAINT spawn_zones_pkey1 PRIMARY KEY (zone_id);


--
-- Name: status_effect_modifiers status_effect_modifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_effect_modifiers
    ADD CONSTRAINT status_effect_modifiers_pkey PRIMARY KEY (id);


--
-- Name: status_effects status_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_effects
    ADD CONSTRAINT status_effects_pkey PRIMARY KEY (id);


--
-- Name: status_effects status_effects_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_effects
    ADD CONSTRAINT status_effects_slug_key UNIQUE (slug);


--
-- Name: target_type target_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.target_type
    ADD CONSTRAINT target_type_pkey PRIMARY KEY (id);


--
-- Name: target_type target_type_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.target_type
    ADD CONSTRAINT target_type_slug_key UNIQUE (slug);


--
-- Name: timed_champion_templates timed_champion_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timed_champion_templates
    ADD CONSTRAINT timed_champion_templates_pkey PRIMARY KEY (id);


--
-- Name: timed_champion_templates timed_champion_templates_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timed_champion_templates
    ADD CONSTRAINT timed_champion_templates_slug_key UNIQUE (slug);


--
-- Name: character_equipment uq_character_equip_slot; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_equipment
    ADD CONSTRAINT uq_character_equip_slot UNIQUE (character_id, equip_slot_id);


--
-- Name: class_skill_tree uq_class_skill; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT uq_class_skill UNIQUE (class_id, skill_id);


--
-- Name: passive_skill_modifiers uq_psm_skill_attr; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passive_skill_modifiers
    ADD CONSTRAINT uq_psm_skill_attr UNIQUE (skill_id, attribute_slug);


--
-- Name: status_effect_modifiers uq_sem_effect_attr; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_effect_modifiers
    ADD CONSTRAINT uq_sem_effect_attr UNIQUE (status_effect_id, attribute_id);


--
-- Name: vendor_inventory uq_vendor_item; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_inventory
    ADD CONSTRAINT uq_vendor_item UNIQUE (vendor_npc_id, item_id);


--
-- Name: user_bans user_bans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_bans
    ADD CONSTRAINT user_bans_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_token_hash_key UNIQUE (token_hash);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vendor_inventory vendor_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_inventory
    ADD CONSTRAINT vendor_inventory_pkey PRIMARY KEY (id);


--
-- Name: vendor_npc vendor_npc_npc_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_npc
    ADD CONSTRAINT vendor_npc_npc_id_key UNIQUE (npc_id);


--
-- Name: vendor_npc vendor_npc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_npc
    ADD CONSTRAINT vendor_npc_pkey PRIMARY KEY (id);


--
-- Name: zone_event_templates zone_event_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zone_event_templates
    ADD CONSTRAINT zone_event_templates_pkey PRIMARY KEY (id);


--
-- Name: zone_event_templates zone_event_templates_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zone_event_templates
    ADD CONSTRAINT zone_event_templates_slug_key UNIQUE (slug);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: zones zones_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_slug_key UNIQUE (slug);


--
-- Name: idx_char_mastery_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_char_mastery_char ON public.character_skill_mastery USING btree (character_id);


--
-- Name: idx_char_rep_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_char_rep_char ON public.character_reputation USING btree (character_id);


--
-- Name: idx_character_bestiary_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_character_bestiary_char ON public.character_bestiary USING btree (character_id);


--
-- Name: idx_character_equipment_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_character_equipment_char ON public.character_equipment USING btree (character_id);


--
-- Name: idx_character_pity_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_character_pity_char ON public.character_pity USING btree (character_id);


--
-- Name: idx_item_set_bonuses_set; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_item_set_bonuses_set ON public.item_set_bonuses USING btree (set_id);


--
-- Name: idx_item_set_members_item; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_item_set_members_item ON public.item_set_members USING btree (item_id);


--
-- Name: idx_item_use_effects_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_item_use_effects_item_id ON public.item_use_effects USING btree (item_id);


--
-- Name: idx_mob_active_effect_expires_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mob_active_effect_expires_at ON public.mob_active_effect USING btree (expires_at) WHERE (expires_at IS NOT NULL);


--
-- Name: idx_mob_active_effect_mob_uid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mob_active_effect_mob_uid ON public.mob_active_effect USING btree (mob_uid);


--
-- Name: idx_mob_loot_info_mob; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mob_loot_info_mob ON public.mob_loot_info USING btree (mob_id);


--
-- Name: idx_mob_loot_tier; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mob_loot_tier ON public.mob_loot_info USING btree (mob_id, loot_tier);


--
-- Name: idx_mob_mob_type_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mob_mob_type_slug ON public.mob USING btree (mob_type_slug);


--
-- Name: idx_mob_position_mob; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mob_position_mob ON public.mob_position USING btree (mob_id);


--
-- Name: idx_mob_resistances_mob; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mob_resistances_mob ON public.mob_resistances USING btree (mob_id);


--
-- Name: idx_mob_stat_mob_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mob_stat_mob_id ON public.mob_stat USING btree (mob_id);


--
-- Name: idx_mob_weaknesses_mob; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mob_weaknesses_mob ON public.mob_weaknesses USING btree (mob_id);


--
-- Name: idx_npc_dialogue_npc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_npc_dialogue_npc ON public.npc_dialogue USING btree (npc_id);


--
-- Name: idx_npc_placements_npc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_npc_placements_npc ON public.npc_placements USING btree (npc_id);


--
-- Name: idx_npc_placements_zone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_npc_placements_zone ON public.npc_placements USING btree (zone_id);


--
-- Name: idx_npc_position_npc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_npc_position_npc ON public.npc_position USING btree (npc_id);


--
-- Name: idx_player_active_effect_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_player_active_effect_expires ON public.player_active_effect USING btree (expires_at) WHERE (expires_at IS NOT NULL);


--
-- Name: idx_player_active_effect_player; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_player_active_effect_player ON public.player_active_effect USING btree (player_id);


--
-- Name: idx_player_inventory_char_item; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_player_inventory_char_item ON public.player_inventory USING btree (character_id, item_id);


--
-- Name: idx_player_inventory_character; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_player_inventory_character ON public.player_inventory USING btree (character_id);


--
-- Name: idx_player_inventory_ground; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_player_inventory_ground ON public.player_inventory USING btree (id) WHERE (character_id IS NULL);


--
-- Name: idx_quest_reward_quest; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quest_reward_quest ON public.quest_reward USING btree (quest_id);


--
-- Name: idx_spawn_zone_mobs_mob; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_spawn_zone_mobs_mob ON public.spawn_zone_mobs USING btree (mob_id);


--
-- Name: idx_spawn_zone_mobs_zone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_spawn_zone_mobs_zone ON public.spawn_zone_mobs USING btree (spawn_zone_id);


--
-- Name: idx_spawn_zones_game_zone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_spawn_zones_game_zone ON public.spawn_zones USING btree (game_zone_id);


--
-- Name: idx_timed_champion_next; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timed_champion_next ON public.timed_champion_templates USING btree (next_spawn_at);


--
-- Name: idx_timed_champion_zone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timed_champion_zone ON public.timed_champion_templates USING btree (zone_id);


--
-- Name: ix_char_perm_mod_character; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_char_perm_mod_character ON public.character_permanent_modifiers USING btree (character_id);


--
-- Name: ix_char_perm_mod_source; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_char_perm_mod_source ON public.character_permanent_modifiers USING btree (source_type, source_id) WHERE (source_id IS NOT NULL);


--
-- Name: ix_character_attributes_char_attr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_character_attributes_char_attr ON public.character_permanent_modifiers USING btree (character_id, attribute_id);


--
-- Name: ix_character_class_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_character_class_slug ON public.character_class USING btree (slug) WHERE (slug IS NOT NULL);


--
-- Name: ix_character_equipment_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_character_equipment_char ON public.character_equipment USING btree (character_id);


--
-- Name: ix_character_equipment_inv_item; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_character_equipment_inv_item ON public.character_equipment USING btree (inventory_item_id);


--
-- Name: ix_character_position_zone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_character_position_zone ON public.character_position USING btree (zone_id);


--
-- Name: ix_characters_deleted; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_characters_deleted ON public.characters USING btree (deleted_at) WHERE (deleted_at IS NOT NULL);


--
-- Name: ix_characters_owner_slot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_characters_owner_slot ON public.characters USING btree (owner_id, account_slot);


--
-- Name: ix_class_skill_tree_class; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_class_skill_tree_class ON public.class_skill_tree USING btree (class_id);


--
-- Name: ix_class_stat_formula_class; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_class_stat_formula_class ON public.class_stat_formula USING btree (class_id);


--
-- Name: ix_currency_transactions_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_currency_transactions_char ON public.currency_transactions USING btree (character_id);


--
-- Name: ix_currency_transactions_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_currency_transactions_created ON public.currency_transactions USING btree (created_at DESC);


--
-- Name: ix_currency_transactions_reason; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_currency_transactions_reason ON public.currency_transactions USING btree (reason_type);


--
-- Name: ix_dialogue_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_dialogue_slug ON public.dialogue USING btree (slug);


--
-- Name: ix_edge_act_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_edge_act_gin ON public.dialogue_edge USING gin (action_group);


--
-- Name: ix_edge_cond_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_edge_cond_gin ON public.dialogue_edge USING gin (condition_group);


--
-- Name: INDEX ix_edge_cond_gin; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON INDEX public.ix_edge_cond_gin IS 'GIN по условиям ребра (jsonb)';


--
-- Name: ix_edge_from; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_edge_from ON public.dialogue_edge USING btree (from_node_id);


--
-- Name: ix_edge_to; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_edge_to ON public.dialogue_edge USING btree (to_node_id);


--
-- Name: ix_gm_action_log_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_gm_action_log_created ON public.gm_action_log USING btree (created_at DESC);


--
-- Name: ix_gm_action_log_gm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_gm_action_log_gm ON public.gm_action_log USING btree (gm_user_id);


--
-- Name: ix_gm_action_log_target; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_gm_action_log_target ON public.gm_action_log USING btree (target_type, target_id);


--
-- Name: ix_iam_attribute_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_iam_attribute_id ON public.item_attributes_mapping USING btree (attribute_id);


--
-- Name: ix_iam_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_iam_item_id ON public.item_attributes_mapping USING btree (item_id);


--
-- Name: ix_items_item_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_items_item_type ON public.items USING btree (item_type);


--
-- Name: ix_mob_position_zone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_mob_position_zone ON public.mob_position USING btree (zone_id);


--
-- Name: ix_node_act_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_node_act_gin ON public.dialogue_node USING gin (action_group);


--
-- Name: ix_node_cond_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_node_cond_gin ON public.dialogue_node USING gin (condition_group);


--
-- Name: INDEX ix_node_cond_gin; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON INDEX public.ix_node_cond_gin IS 'GIN по условиям узла (jsonb)';


--
-- Name: ix_node_dialogue; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_node_dialogue ON public.dialogue_node USING btree (dialogue_id);


--
-- Name: ix_npc_attributes_npc_attr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_npc_attributes_npc_attr ON public.npc_attributes USING btree (npc_id, attribute_id);


--
-- Name: ix_npc_position_zone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_npc_position_zone ON public.npc_position USING btree (zone_id);


--
-- Name: ix_pae_attribute_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_pae_attribute_id ON public.player_active_effect USING btree (attribute_id) WHERE (attribute_id IS NOT NULL);


--
-- Name: ix_pae_effect_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_pae_effect_id ON public.player_active_effect USING btree (status_effect_id);


--
-- Name: ix_player_flag_bool; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_player_flag_bool ON public.player_flag USING btree (player_id, flag_key, bool_value);


--
-- Name: ix_player_flag_int; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_player_flag_int ON public.player_flag USING btree (player_id, flag_key, int_value);


--
-- Name: ix_player_inventory_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_player_inventory_item_id ON public.player_inventory USING btree (item_id);


--
-- Name: ix_player_quest_state; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_player_quest_state ON public.player_quest USING btree (player_id, state);


--
-- Name: ix_quest_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_quest_slug ON public.quest USING btree (slug);


--
-- Name: ix_quest_step_q; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_quest_step_q ON public.quest_step USING btree (quest_id, step_index);


--
-- Name: ix_user_bans_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_bans_active ON public.user_bans USING btree (is_active, expires_at);


--
-- Name: ix_user_bans_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_bans_user ON public.user_bans USING btree (user_id) WHERE (is_active = true);


--
-- Name: ix_user_sessions_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_sessions_expires ON public.user_sessions USING btree (expires_at) WHERE (revoked_at IS NULL);


--
-- Name: ix_user_sessions_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_sessions_user ON public.user_sessions USING btree (user_id);


--
-- Name: ix_vendor_inventory_vendor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_vendor_inventory_vendor ON public.vendor_inventory USING btree (vendor_npc_id);


--
-- Name: ix_zones_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_zones_slug ON public.zones USING btree (slug);


--
-- Name: uq_character_skills; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_character_skills ON public.character_skills USING btree (character_id, skill_id);


--
-- Name: uq_effects_map; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_effects_map ON public.skill_effects_mapping USING btree (effect_instance_id, level, effect_id);


--
-- Name: uq_entity_attributes_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_entity_attributes_slug ON public.entity_attributes USING btree (slug);


--
-- Name: uq_inventory_slot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_inventory_slot ON public.player_inventory USING btree (character_id, slot_index) WHERE (slot_index IS NOT NULL);


--
-- Name: uq_item_types_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_item_types_slug ON public.item_types USING btree (slug);


--
-- Name: uq_items_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_items_slug ON public.items USING btree (slug);


--
-- Name: uq_mob_skills; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_mob_skills ON public.mob_skills USING btree (mob_id, skill_id);


--
-- Name: uq_npc_skills; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_npc_skills ON public.npc_skills USING btree (npc_id, skill_id);


--
-- Name: uq_skill_effects_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_skill_effects_slug ON public.skill_damage_formulas USING btree (slug);


--
-- Name: uq_skill_effects_type_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_skill_effects_type_slug ON public.skill_damage_types USING btree (slug);


--
-- Name: uq_skill_properties_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_skill_properties_slug ON public.skill_properties USING btree (slug);


--
-- Name: uq_skill_props_map; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_skill_props_map ON public.skill_properties_mapping USING btree (skill_id, skill_level, property_id);


--
-- Name: uq_skill_scale_type_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_skill_scale_type_slug ON public.skill_scale_type USING btree (slug);


--
-- Name: uq_skill_school_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_skill_school_slug ON public.skill_school USING btree (slug);


--
-- Name: uq_skills_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_skills_slug ON public.skills USING btree (slug);


--
-- Name: uq_target_type_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_target_type_slug ON public.target_type USING btree (slug);


--
-- Name: game_config trg_game_config_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_game_config_updated_at BEFORE UPDATE ON public.game_config FOR EACH ROW EXECUTE FUNCTION public.game_config_set_updated_at();


--
-- Name: character_permanent_modifiers character_attributes_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_permanent_modifiers
    ADD CONSTRAINT character_attributes_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: character_permanent_modifiers character_attributes_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_permanent_modifiers
    ADD CONSTRAINT character_attributes_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_bestiary character_bestiary_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_bestiary
    ADD CONSTRAINT character_bestiary_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_bestiary character_bestiary_mob_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_bestiary
    ADD CONSTRAINT character_bestiary_mob_template_id_fkey FOREIGN KEY (mob_template_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: character_equipment character_equipment_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_equipment
    ADD CONSTRAINT character_equipment_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_equipment character_equipment_equip_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_equipment
    ADD CONSTRAINT character_equipment_equip_slot_id_fkey FOREIGN KEY (equip_slot_id) REFERENCES public.equip_slot(id);


--
-- Name: character_equipment character_equipment_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_equipment
    ADD CONSTRAINT character_equipment_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.player_inventory(id) ON DELETE CASCADE;


--
-- Name: character_pity character_pity_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_pity
    ADD CONSTRAINT character_pity_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_pity character_pity_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_pity
    ADD CONSTRAINT character_pity_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: character_position character_position_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_position
    ADD CONSTRAINT character_position_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_position character_position_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_position
    ADD CONSTRAINT character_position_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: character_reputation character_reputation_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_reputation
    ADD CONSTRAINT character_reputation_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_skill_mastery character_skill_mastery_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skill_mastery
    ADD CONSTRAINT character_skill_mastery_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_skills character_skills_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skills
    ADD CONSTRAINT character_skills_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_skills character_skills_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skills
    ADD CONSTRAINT character_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: characters characters_bind_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_bind_zone_id_fkey FOREIGN KEY (bind_zone_id) REFERENCES public.zones(id);


--
-- Name: characters characters_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id);


--
-- Name: characters characters_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: characters characters_race_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_race_id_fkey FOREIGN KEY (race_id) REFERENCES public.race(id);


--
-- Name: class_skill_tree class_skill_tree_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT class_skill_tree_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id) ON DELETE CASCADE;


--
-- Name: class_skill_tree class_skill_tree_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT class_skill_tree_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: class_stat_formula class_stat_formula_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_stat_formula
    ADD CONSTRAINT class_stat_formula_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id) ON DELETE RESTRICT;


--
-- Name: class_stat_formula class_stat_formula_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_stat_formula
    ADD CONSTRAINT class_stat_formula_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id) ON DELETE CASCADE;


--
-- Name: currency_transactions currency_transactions_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currency_transactions
    ADD CONSTRAINT currency_transactions_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: dialogue_edge dialogue_edge_from_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_edge
    ADD CONSTRAINT dialogue_edge_from_node_id_fkey FOREIGN KEY (from_node_id) REFERENCES public.dialogue_node(id) ON DELETE CASCADE;


--
-- Name: dialogue_edge dialogue_edge_to_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_edge
    ADD CONSTRAINT dialogue_edge_to_node_id_fkey FOREIGN KEY (to_node_id) REFERENCES public.dialogue_node(id) ON DELETE CASCADE;


--
-- Name: dialogue_node dialogue_node_dialogue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_node
    ADD CONSTRAINT dialogue_node_dialogue_id_fkey FOREIGN KEY (dialogue_id) REFERENCES public.dialogue(id) ON DELETE CASCADE;


--
-- Name: dialogue_node dialogue_node_jump_target_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_node
    ADD CONSTRAINT dialogue_node_jump_target_fkey FOREIGN KEY (jump_target_node_id) REFERENCES public.dialogue_node(id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;


--
-- Name: dialogue_node dialogue_node_speaker_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dialogue_node
    ADD CONSTRAINT dialogue_node_speaker_npc_id_fkey FOREIGN KEY (speaker_npc_id) REFERENCES public.npc(id) ON DELETE SET NULL;


--
-- Name: character_current_state fk_char_current_state; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_current_state
    ADD CONSTRAINT fk_char_current_state FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: characters fk_characters_gender; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT fk_characters_gender FOREIGN KEY (gender) REFERENCES public.character_genders(id);


--
-- Name: mob_position fk_mob_position_mob; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_position
    ADD CONSTRAINT fk_mob_position_mob FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: mob_position fk_mob_position_zone; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_position
    ADD CONSTRAINT fk_mob_position_zone FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;


--
-- Name: npc_position fk_npc_position_npc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_position
    ADD CONSTRAINT fk_npc_position_npc FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: npc_position fk_npc_position_zone; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_position
    ADD CONSTRAINT fk_npc_position_zone FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;


--
-- Name: users fk_users_role; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_role FOREIGN KEY (role) REFERENCES public.user_roles(id);


--
-- Name: gm_action_log gm_action_log_gm_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gm_action_log
    ADD CONSTRAINT gm_action_log_gm_user_id_fkey FOREIGN KEY (gm_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: item_attributes_mapping item_attributes_mapping_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_attributes_mapping
    ADD CONSTRAINT item_attributes_mapping_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: item_attributes_mapping item_attributes_mapping_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_attributes_mapping
    ADD CONSTRAINT item_attributes_mapping_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: item_class_restrictions item_class_restrictions_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_class_restrictions
    ADD CONSTRAINT item_class_restrictions_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id) ON DELETE CASCADE;


--
-- Name: item_class_restrictions item_class_restrictions_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_class_restrictions
    ADD CONSTRAINT item_class_restrictions_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: item_set_bonuses item_set_bonuses_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_set_bonuses
    ADD CONSTRAINT item_set_bonuses_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: item_set_bonuses item_set_bonuses_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_set_bonuses
    ADD CONSTRAINT item_set_bonuses_set_id_fkey FOREIGN KEY (set_id) REFERENCES public.item_sets(id) ON DELETE CASCADE;


--
-- Name: item_set_members item_set_members_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_set_members
    ADD CONSTRAINT item_set_members_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: item_set_members item_set_members_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_set_members
    ADD CONSTRAINT item_set_members_set_id_fkey FOREIGN KEY (set_id) REFERENCES public.item_sets(id) ON DELETE CASCADE;


--
-- Name: item_use_effects item_use_effects_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_use_effects
    ADD CONSTRAINT item_use_effects_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: items items_equip_slot_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_equip_slot_fkey FOREIGN KEY (equip_slot) REFERENCES public.equip_slot(id) ON DELETE SET NULL;


--
-- Name: items items_item_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_item_type_fkey FOREIGN KEY (item_type) REFERENCES public.item_types(id);


--
-- Name: items items_rarity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_rarity_id_fkey FOREIGN KEY (rarity_id) REFERENCES public.items_rarity(id);


--
-- Name: mob_active_effect mob_active_effect_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_active_effect
    ADD CONSTRAINT mob_active_effect_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id) ON DELETE SET NULL;


--
-- Name: mob_active_effect mob_active_effect_effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_active_effect
    ADD CONSTRAINT mob_active_effect_effect_id_fkey FOREIGN KEY (effect_id) REFERENCES public.skill_damage_formulas(id) ON DELETE CASCADE;


--
-- Name: mob_loot_info mob_loot_info_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_loot_info
    ADD CONSTRAINT mob_loot_info_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: mob_loot_info mob_loot_info_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_loot_info
    ADD CONSTRAINT mob_loot_info_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: mob mob_race_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_race_id_fkey FOREIGN KEY (race_id) REFERENCES public.mob_race(id);


--
-- Name: mob mob_rank_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_rank_id_fkey FOREIGN KEY (rank_id) REFERENCES public.mob_ranks(rank_id);


--
-- Name: mob_resistances mob_resistances_element_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_resistances
    ADD CONSTRAINT mob_resistances_element_slug_fkey FOREIGN KEY (element_slug) REFERENCES public.damage_elements(slug);


--
-- Name: mob_resistances mob_resistances_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_resistances
    ADD CONSTRAINT mob_resistances_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: mob_skills mob_skills_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_skills
    ADD CONSTRAINT mob_skills_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: mob_skills mob_skills_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_skills
    ADD CONSTRAINT mob_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: mob_stat mob_stat_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_stat
    ADD CONSTRAINT mob_stat_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id) ON DELETE CASCADE;


--
-- Name: mob_stat mob_stat_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_stat
    ADD CONSTRAINT mob_stat_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: mob_weaknesses mob_weaknesses_element_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_weaknesses
    ADD CONSTRAINT mob_weaknesses_element_slug_fkey FOREIGN KEY (element_slug) REFERENCES public.damage_elements(slug);


--
-- Name: mob_weaknesses mob_weaknesses_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_weaknesses
    ADD CONSTRAINT mob_weaknesses_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: npc_attributes npc_attributes_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_attributes
    ADD CONSTRAINT npc_attributes_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: npc_attributes npc_attributes_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_attributes
    ADD CONSTRAINT npc_attributes_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id);


--
-- Name: npc_dialogue npc_dialogue_dialogue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_dialogue
    ADD CONSTRAINT npc_dialogue_dialogue_id_fkey FOREIGN KEY (dialogue_id) REFERENCES public.dialogue(id) ON DELETE CASCADE;


--
-- Name: npc_dialogue npc_dialogue_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_dialogue
    ADD CONSTRAINT npc_dialogue_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: npc npc_npc_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_npc_type_fkey FOREIGN KEY (npc_type) REFERENCES public.npc_type(id);


--
-- Name: npc_placements npc_placements_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_placements
    ADD CONSTRAINT npc_placements_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: npc_placements npc_placements_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_placements
    ADD CONSTRAINT npc_placements_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;


--
-- Name: npc npc_race_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_race_id_fkey FOREIGN KEY (race_id) REFERENCES public.race(id);


--
-- Name: npc_skills npc_skills_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_skills
    ADD CONSTRAINT npc_skills_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: npc_skills npc_skills_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_skills
    ADD CONSTRAINT npc_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: passive_skill_modifiers passive_skill_modifiers_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passive_skill_modifiers
    ADD CONSTRAINT passive_skill_modifiers_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id) ON DELETE CASCADE;


--
-- Name: player_active_effect player_active_effect_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: player_active_effect player_active_effect_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: player_active_effect player_active_effect_status_effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_status_effect_id_fkey FOREIGN KEY (status_effect_id) REFERENCES public.status_effects(id);


--
-- Name: player_flag player_flag_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_flag
    ADD CONSTRAINT player_flag_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: player_inventory player_inventory_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_inventory
    ADD CONSTRAINT player_inventory_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: player_inventory player_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_inventory
    ADD CONSTRAINT player_inventory_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: player_quest player_quest_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_quest
    ADD CONSTRAINT player_quest_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: player_quest player_quest_quest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_quest
    ADD CONSTRAINT player_quest_quest_id_fkey FOREIGN KEY (quest_id) REFERENCES public.quest(id) ON DELETE CASCADE;


--
-- Name: quest quest_giver_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest
    ADD CONSTRAINT quest_giver_npc_id_fkey FOREIGN KEY (giver_npc_id) REFERENCES public.npc(id) ON DELETE SET NULL;


--
-- Name: quest_reward quest_reward_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_reward
    ADD CONSTRAINT quest_reward_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE SET NULL;


--
-- Name: quest_reward quest_reward_quest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_reward
    ADD CONSTRAINT quest_reward_quest_id_fkey FOREIGN KEY (quest_id) REFERENCES public.quest(id) ON DELETE CASCADE;


--
-- Name: quest_step quest_step_quest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_step
    ADD CONSTRAINT quest_step_quest_id_fkey FOREIGN KEY (quest_id) REFERENCES public.quest(id) ON DELETE CASCADE;


--
-- Name: quest quest_turnin_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest
    ADD CONSTRAINT quest_turnin_npc_id_fkey FOREIGN KEY (turnin_npc_id) REFERENCES public.npc(id) ON DELETE SET NULL;


--
-- Name: skill_effect_instances skill_effect_instances_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effect_instances
    ADD CONSTRAINT skill_effect_instances_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: skill_effect_instances skill_effect_instances_target_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effect_instances
    ADD CONSTRAINT skill_effect_instances_target_type_id_fkey FOREIGN KEY (target_type_id) REFERENCES public.target_type(id);


--
-- Name: skill_damage_formulas skill_effects_effect_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_damage_formulas
    ADD CONSTRAINT skill_effects_effect_type_id_fkey FOREIGN KEY (effect_type_id) REFERENCES public.skill_damage_types(id);


--
-- Name: skill_effects_mapping skill_effects_mapping_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: skill_effects_mapping skill_effects_mapping_effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_effect_id_fkey FOREIGN KEY (effect_id) REFERENCES public.skill_damage_formulas(id);


--
-- Name: skill_effects_mapping skill_effects_mapping_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_instance_id_fkey FOREIGN KEY (effect_instance_id) REFERENCES public.skill_effect_instances(id) ON DELETE CASCADE;


--
-- Name: skill_properties_mapping skill_properties_mapping_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_properties_mapping
    ADD CONSTRAINT skill_properties_mapping_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.skill_properties(id);


--
-- Name: skill_properties_mapping skill_properties_mapping_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_properties_mapping
    ADD CONSTRAINT skill_properties_mapping_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id) ON DELETE CASCADE;


--
-- Name: spawn_zone_mobs spawn_zone_mobs_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spawn_zone_mobs
    ADD CONSTRAINT spawn_zone_mobs_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: spawn_zone_mobs spawn_zone_mobs_spawn_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spawn_zone_mobs
    ADD CONSTRAINT spawn_zone_mobs_spawn_zone_id_fkey FOREIGN KEY (spawn_zone_id) REFERENCES public.spawn_zones(zone_id) ON DELETE CASCADE;


--
-- Name: spawn_zones spawn_zones_game_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spawn_zones
    ADD CONSTRAINT spawn_zones_game_zone_id_fkey FOREIGN KEY (game_zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;


--
-- Name: status_effect_modifiers status_effect_modifiers_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_effect_modifiers
    ADD CONSTRAINT status_effect_modifiers_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: status_effect_modifiers status_effect_modifiers_status_effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_effect_modifiers
    ADD CONSTRAINT status_effect_modifiers_status_effect_id_fkey FOREIGN KEY (status_effect_id) REFERENCES public.status_effects(id) ON DELETE CASCADE;


--
-- Name: timed_champion_templates timed_champion_templates_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timed_champion_templates
    ADD CONSTRAINT timed_champion_templates_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE CASCADE;


--
-- Name: user_bans user_bans_banned_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_bans
    ADD CONSTRAINT user_bans_banned_by_user_id_fkey FOREIGN KEY (banned_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_bans user_bans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_bans
    ADD CONSTRAINT user_bans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: vendor_inventory vendor_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_inventory
    ADD CONSTRAINT vendor_inventory_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: vendor_inventory vendor_inventory_vendor_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_inventory
    ADD CONSTRAINT vendor_inventory_vendor_npc_id_fkey FOREIGN KEY (vendor_npc_id) REFERENCES public.vendor_npc(id) ON DELETE CASCADE;


--
-- Name: vendor_npc vendor_npc_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_npc
    ADD CONSTRAINT vendor_npc_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

