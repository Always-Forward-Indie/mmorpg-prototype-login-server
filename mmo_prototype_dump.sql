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
-- Name: spawn_zone_shape; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.spawn_zone_shape AS ENUM (
    'RECT',
    'CIRCLE',
    'ANNULUS'
);


ALTER TYPE public.spawn_zone_shape OWNER TO postgres;

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
    slug character varying(100) NOT NULL,
    is_percentage boolean DEFAULT false NOT NULL
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
-- Name: TABLE character_bestiary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_bestiary IS 'Бестиарий персонажа: сколько раз игрок убил каждый шаблон моба. Используется для разблокировки записей бестиария и potential pity-механик.';


--
-- Name: COLUMN character_bestiary.character_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_bestiary.character_id IS 'FK → characters.id. Персонаж-владелец записи бестиария.';


--
-- Name: COLUMN character_bestiary.mob_template_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_bestiary.mob_template_id IS 'FK → mob.id. Шаблон моба (не runtime-инстанс).';


--
-- Name: COLUMN character_bestiary.kill_count; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_bestiary.kill_count IS 'Суммарное количество убийств данного моба персонажем.';


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
-- Name: character_emotes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_emotes (
    id integer NOT NULL,
    character_id integer NOT NULL,
    emote_slug character varying(64) NOT NULL,
    unlocked_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.character_emotes OWNER TO postgres;

--
-- Name: TABLE character_emotes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_emotes IS 'Per-character unlocked emotes; default emotes are seeded here too';


--
-- Name: character_emotes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.character_emotes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.character_emotes_id_seq OWNER TO postgres;

--
-- Name: character_emotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.character_emotes_id_seq OWNED BY public.character_emotes.id;


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
-- Name: TABLE character_pity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_pity IS 'Pity-счётчики редких дропов. Хранит количество убийств без выпадения конкретного предмета, чтобы гарантировать дроп при превышении порога (гарантированный лут).';


--
-- Name: COLUMN character_pity.character_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_pity.character_id IS 'FK → characters.id. Персонаж.';


--
-- Name: COLUMN character_pity.item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_pity.item_id IS 'FK → items.id. Предмет с pity-механикой (редкий дроп).';


--
-- Name: COLUMN character_pity.kill_count; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_pity.kill_count IS 'Счётчик убийств без выпадения данного предмета. Сбрасывается в 0 после получения предмета.';


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
-- Name: TABLE character_reputation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_reputation IS 'Репутация персонажа у каждой фракции. Положительные значения = союзник, отрицательные = враг. Используется для диалоговых условий и доступа к контенту.';


--
-- Name: COLUMN character_reputation.character_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_reputation.character_id IS 'FK → characters.id. Персонаж.';


--
-- Name: COLUMN character_reputation.faction_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_reputation.faction_slug IS 'FK → factions.slug. Фракция.';


--
-- Name: COLUMN character_reputation.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_reputation.value IS 'Очки репутации. > 0 = союзник, < 0 = враг. Диапазон определяется дизайном.';


--
-- Name: character_skill_bar; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_skill_bar (
    character_id integer NOT NULL,
    slot_index smallint NOT NULL,
    skill_slug character varying(64) NOT NULL,
    CONSTRAINT character_skill_bar_slot_index_check CHECK (((slot_index >= 0) AND (slot_index < 12)))
);


ALTER TABLE public.character_skill_bar OWNER TO postgres;

--
-- Name: TABLE character_skill_bar; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_skill_bar IS 'Stores which skill slug is assigned to each hotbar slot per character. Absent rows = empty slot.';


--
-- Name: COLUMN character_skill_bar.slot_index; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_skill_bar.slot_index IS 'Zero-based hotbar slot index (0–11). Max 12 slots enforced by CHECK constraint.';


--
-- Name: COLUMN character_skill_bar.skill_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_skill_bar.skill_slug IS 'Slug of the skill assigned to this slot. Must be a known skill slug.';


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
-- Name: TABLE character_skill_mastery; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_skill_mastery IS 'Накопленные очки мастерства персонажа по типу оружия/школы. Например, sword_mastery растёт при ударах мечом и влияет на бонусы к урону.';


--
-- Name: COLUMN character_skill_mastery.character_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_skill_mastery.character_id IS 'FK → characters.id. Персонаж.';


--
-- Name: COLUMN character_skill_mastery.mastery_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_skill_mastery.mastery_slug IS 'FK → mastery_definitions.slug. Тип мастерства.';


--
-- Name: COLUMN character_skill_mastery.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_skill_mastery.value IS 'Текущие накопленные очки мастерства. Ограничены mastery_definitions.max_value.';


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
-- Name: character_titles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_titles (
    character_id integer NOT NULL,
    title_slug character varying(80) NOT NULL,
    equipped boolean DEFAULT false NOT NULL,
    earned_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.character_titles OWNER TO postgres;

--
-- Name: TABLE character_titles; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.character_titles IS 'Титулы, заработанные персонажем. equipped=true означает, что этот титул отображается над именем в мире. Только один может быть активным одновременно.';


--
-- Name: COLUMN character_titles.character_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_titles.character_id IS 'FK → characters.id. Персонаж.';


--
-- Name: COLUMN character_titles.title_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_titles.title_slug IS 'FK → title_definitions.slug. Полученный титул.';


--
-- Name: COLUMN character_titles.equipped; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_titles.equipped IS 'TRUE = этот титул отображается над именем персонажа в игровом мире.';


--
-- Name: COLUMN character_titles.earned_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.character_titles.earned_at IS 'Временная метка получения титула.';


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
    is_default boolean DEFAULT false NOT NULL,
    prerequisite_skill_id integer,
    skill_point_cost smallint DEFAULT 0 NOT NULL,
    gold_cost integer DEFAULT 0 NOT NULL,
    max_level smallint DEFAULT 1 NOT NULL,
    requires_book boolean DEFAULT false NOT NULL,
    skill_book_item_id integer
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
-- Name: COLUMN class_skill_tree.prerequisite_skill_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_skill_tree.prerequisite_skill_id IS 'Skill that must already be learned before this one becomes available. NULL = no prereq.';


--
-- Name: COLUMN class_skill_tree.skill_point_cost; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_skill_tree.skill_point_cost IS 'Skill points consumed when this skill is learned. 0 = free (default skills).';


--
-- Name: COLUMN class_skill_tree.gold_cost; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_skill_tree.gold_cost IS 'Gold (gold_coin quantity) required to learn this skill. 0 = no gold cost.';


--
-- Name: COLUMN class_skill_tree.max_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_skill_tree.max_level IS 'Maximum level to which this skill can be upgraded. 1 = cannot be upgraded.';


--
-- Name: COLUMN class_skill_tree.requires_book; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_skill_tree.requires_book IS 'If TRUE the player must have the skill_book_item_id item in inventory to learn.';


--
-- Name: COLUMN class_skill_tree.skill_book_item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_skill_tree.skill_book_item_id IS 'The skill book item that is consumed when learning this skill (if requires_book=TRUE).';


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
-- Name: class_starter_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.class_starter_items (
    id integer NOT NULL,
    class_id integer NOT NULL,
    item_id integer NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    slot_index smallint,
    durability_current integer
);


ALTER TABLE public.class_starter_items OWNER TO postgres;

--
-- Name: TABLE class_starter_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.class_starter_items IS 'Предметы, автоматически выдаваемые персонажу при создании в зависимости от класса. Количество и слот настраиваются. Durability = NULL означает полную прочность по умолчанию.';


--
-- Name: COLUMN class_starter_items.class_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_starter_items.class_id IS 'FK → character_class.id. Класс которому выдаётся предмет.';


--
-- Name: COLUMN class_starter_items.item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_starter_items.item_id IS 'FK → items.id. Шаблон предмета для выдачи.';


--
-- Name: COLUMN class_starter_items.quantity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_starter_items.quantity IS 'Количество предметов в стаке.';


--
-- Name: COLUMN class_starter_items.slot_index; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_starter_items.slot_index IS 'Позиция в инвентаре. NULL = сервер назначает автоматически.';


--
-- Name: COLUMN class_starter_items.durability_current; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.class_starter_items.durability_current IS 'Начальная прочность. NULL = использовать durability_max из таблицы items.';


--
-- Name: class_starter_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.class_starter_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.class_starter_items_id_seq OWNER TO postgres;

--
-- Name: class_starter_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.class_starter_items_id_seq OWNED BY public.class_starter_items.id;


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
-- Name: TABLE damage_elements; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.damage_elements IS 'Справочник элементов урона: fire, ice, physical, shadow, holy и т.д. PK — slug. Используется в mob_resistances и mob_weaknesses.';


--
-- Name: COLUMN damage_elements.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.damage_elements.slug IS 'PK. Уникальный код элемента урона: physical, fire, ice, shadow, holy, arcane и т.д.';


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
-- Name: emote_definitions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.emote_definitions (
    id integer NOT NULL,
    slug character varying(64) NOT NULL,
    display_name character varying(128) NOT NULL,
    animation_name character varying(128) NOT NULL,
    category character varying(64) DEFAULT 'general'::character varying NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.emote_definitions OWNER TO postgres;

--
-- Name: TABLE emote_definitions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.emote_definitions IS 'Static catalog of player emote / animation definitions';


--
-- Name: COLUMN emote_definitions.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.emote_definitions.slug IS 'Unique snake_case key used in packets, e.g. dance_silly';


--
-- Name: COLUMN emote_definitions.animation_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.emote_definitions.animation_name IS 'Name of the client-side animation clip to play';


--
-- Name: COLUMN emote_definitions.category; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.emote_definitions.category IS 'UI grouping: basic | social | dance | sit | ...';


--
-- Name: COLUMN emote_definitions.is_default; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.emote_definitions.is_default IS 'TRUE = all characters own this emote automatically';


--
-- Name: emote_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.emote_definitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.emote_definitions_id_seq OWNER TO postgres;

--
-- Name: emote_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.emote_definitions_id_seq OWNED BY public.emote_definitions.id;


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
-- Name: TABLE factions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.factions IS 'Справочник фракций игрового мира. Мобы и NPC принадлежат фракции (faction_slug). Репутация персонажа ко фракции хранится в character_reputation.';


--
-- Name: COLUMN factions.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.factions.id IS 'Суррогатный PK.';


--
-- Name: COLUMN factions.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.factions.slug IS 'Уникальный код фракции. Используется как FK в mob, npc, character_reputation.';


--
-- Name: COLUMN factions.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.factions.name IS 'Отображаемое имя фракции.';


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
-- Name: game_analytics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.game_analytics (
    id bigint NOT NULL,
    event_type character varying(64) NOT NULL,
    character_id bigint,
    session_id character varying(128) DEFAULT ''::character varying NOT NULL,
    level smallint DEFAULT 0 NOT NULL,
    zone_id integer DEFAULT 0 NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.game_analytics OWNER TO postgres;

--
-- Name: TABLE game_analytics; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.game_analytics IS 'Append-only event log for playtest analytics. Written by Game Server; never updated or deleted manually.';


--
-- Name: COLUMN game_analytics.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_analytics.id IS 'Auto-increment primary key.';


--
-- Name: COLUMN game_analytics.event_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_analytics.event_type IS 'Type of event: session_start, session_end, level_up, player_death, quest_accept, quest_complete, quest_abandon, mob_killed, item_acquired, gold_change, skill_used, etc.';


--
-- Name: COLUMN game_analytics.character_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_analytics.character_id IS 'FK → characters.id. SET NULL on character deletion so historic rows are preserved.';


--
-- Name: COLUMN game_analytics.session_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_analytics.session_id IS 'Server-generated session token "sess_{characterId}_{unix_ms}". Generated once on joinGameCharacter and reused for every event in that play session.';


--
-- Name: COLUMN game_analytics.level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_analytics.level IS 'Character level at the moment the event occurred. Direct column (not in payload) for fast GROUP BY / filter queries.';


--
-- Name: COLUMN game_analytics.zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_analytics.zone_id IS 'Zone/chunk where the event occurred. 0 = unknown/global.';


--
-- Name: COLUMN game_analytics.payload; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_analytics.payload IS 'Event-specific JSONB. Schema varies by event_type — see analytics-system-plan.md.';


--
-- Name: COLUMN game_analytics.created_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.game_analytics.created_at IS 'Server-side UTC timestamp when the row was inserted.';


--
-- Name: game_analytics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.game_analytics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.game_analytics_id_seq OWNER TO postgres;

--
-- Name: game_analytics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.game_analytics_id_seq OWNED BY public.game_analytics.id;


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
-- Name: TABLE item_class_restrictions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.item_class_restrictions IS 'Ограничения предмета по классу персонажа. Если для предмета есть хотя бы одна запись — предмет может использовать только указанный класс.';


--
-- Name: COLUMN item_class_restrictions.item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_class_restrictions.item_id IS 'FK → items.id. Предмет с ограничением по классу.';


--
-- Name: COLUMN item_class_restrictions.class_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_class_restrictions.class_id IS 'FK → character_class.id. Класс, которому разрешён данный предмет.';


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
-- Name: TABLE item_set_bonuses; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.item_set_bonuses IS 'Сетовые бонусы: бонус к атрибуту, который даётся при надевании pieces_required предметов из одного сета. Несколько строк на сет для разных порогов.';


--
-- Name: COLUMN item_set_bonuses.set_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_set_bonuses.set_id IS 'FK → item_sets.id. Набор, к которому относится бонус.';


--
-- Name: COLUMN item_set_bonuses.pieces_required; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_set_bonuses.pieces_required IS 'Минимальное количество предметов набора для активации этого бонуса.';


--
-- Name: COLUMN item_set_bonuses.attribute_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_set_bonuses.attribute_id IS 'FK → entity_attributes.id. Атрибут, к которому прибавляется бонус.';


--
-- Name: COLUMN item_set_bonuses.bonus_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_set_bonuses.bonus_value IS 'Величина прибавки к атрибуту при активации бонуса.';


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
-- Name: TABLE item_set_members; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.item_set_members IS 'Состав сетов: какие предметы входят в набор. Один предмет может быть только в одном сете.';


--
-- Name: COLUMN item_set_members.set_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_set_members.set_id IS 'FK → item_sets.id. Набор.';


--
-- Name: COLUMN item_set_members.item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_set_members.item_id IS 'FK → items.id. Предмет, входящий в набор.';


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
-- Name: TABLE item_sets; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.item_sets IS 'Именованные наборы предметов (сеты). Бонусы за сборку набора хранятся в item_set_bonuses.';


--
-- Name: COLUMN item_sets.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_sets.id IS 'Суррогатный PK.';


--
-- Name: COLUMN item_sets.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_sets.name IS 'Отображаемое имя набора.';


--
-- Name: COLUMN item_sets.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_sets.slug IS 'Уникальный код набора: используется в game-server и клиентском UI.';


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
-- Name: TABLE item_use_effects; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.item_use_effects IS 'Эффекты, применяемые при использовании предмета (зелье, еда). is_instant=true → разовое мгновенное применение; false → эффект с длительностью и тиками.';


--
-- Name: COLUMN item_use_effects.item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_use_effects.item_id IS 'FK → items.id. Предмет, за которым закреплён эффект.';


--
-- Name: COLUMN item_use_effects.effect_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_use_effects.effect_slug IS 'Идентификатор эффекта (произвольный slug или ссылка на status_effects.slug).';


--
-- Name: COLUMN item_use_effects.attribute_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_use_effects.attribute_slug IS 'Атрибут-цель эффекта (ссылается на entity_attributes.slug).';


--
-- Name: COLUMN item_use_effects.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_use_effects.value IS 'Числовое значение изменения атрибута.';


--
-- Name: COLUMN item_use_effects.is_instant; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_use_effects.is_instant IS 'TRUE = мгновенное применение (зелье). FALSE = длительный эффект.';


--
-- Name: COLUMN item_use_effects.duration_seconds; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_use_effects.duration_seconds IS 'Продолжительность эффекта в секундах (0 для мгновенных).';


--
-- Name: COLUMN item_use_effects.tick_ms; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_use_effects.tick_ms IS 'Интервал тика в мс для периодических эффектов (0 для мгновенных).';


--
-- Name: COLUMN item_use_effects.cooldown_seconds; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.item_use_effects.cooldown_seconds IS 'Кулдаун предмета после использования в секундах.';


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
-- Name: COLUMN items.mastery_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.items.mastery_slug IS 'FK → mastery_definitions.slug. Требуемый тип мастерства для использования/экипировки предмета. NULL = без требований к мастерству.';


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
-- Name: TABLE mastery_definitions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mastery_definitions IS 'Справочник типов мастерства оружия/магии (sword, bow, fire_magic и т.д.). PK — slug. max_value задаёт капу накопления.';


--
-- Name: COLUMN mastery_definitions.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mastery_definitions.slug IS 'PK. Уникальный код типа мастерства: sword, bow, fire_magic и т.д.';


--
-- Name: COLUMN mastery_definitions.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mastery_definitions.name IS 'Отображаемое имя мастерства.';


--
-- Name: COLUMN mastery_definitions.weapon_type_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mastery_definitions.weapon_type_slug IS 'NULL = общая мастерства; иначе — привязана к конкретному типу оружия.';


--
-- Name: COLUMN mastery_definitions.max_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mastery_definitions.max_value IS 'Максимальный уровень накопления очков мастерства (капа).';


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

COMMENT ON COLUMN public.mob_active_effect.source_player_id IS 'FK → characters.id. Персонаж, наложивший эффект на моба. NULL = эффект от зоны, квеста или системы.';


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
-- Name: TABLE mob_resistances; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mob_resistances IS 'Сопротивления моба к элементам урона. Значение сопротивления задаётся логикой combat_calculator в chunk-server согласно записи в этой таблице.';


--
-- Name: COLUMN mob_resistances.mob_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_resistances.mob_id IS 'FK → mob.id. Шаблон моба.';


--
-- Name: COLUMN mob_resistances.element_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_resistances.element_slug IS 'FK → damage_elements.slug. Элемент, к которому у моба есть сопротивление.';


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
-- Name: TABLE mob_weaknesses; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mob_weaknesses IS 'Уязвимости моба к элементам урона. При попадании атакой уязвимого элемента chunk-server применяет множитель урона.';


--
-- Name: COLUMN mob_weaknesses.mob_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_weaknesses.mob_id IS 'FK → mob.id. Шаблон моба.';


--
-- Name: COLUMN mob_weaknesses.element_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mob_weaknesses.element_slug IS 'FK → damage_elements.slug. Элемент, к которому у моба есть уязвимость.';


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
-- Name: npc_ambient_speech_configs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_ambient_speech_configs (
    id integer NOT NULL,
    npc_id integer NOT NULL,
    min_interval_sec integer DEFAULT 20 NOT NULL,
    max_interval_sec integer DEFAULT 60 NOT NULL
);


ALTER TABLE public.npc_ambient_speech_configs OWNER TO postgres;

--
-- Name: TABLE npc_ambient_speech_configs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.npc_ambient_speech_configs IS 'Per-NPC ambient speech timing configuration.';


--
-- Name: COLUMN npc_ambient_speech_configs.npc_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_ambient_speech_configs.npc_id IS 'FK to npcs.id. One config per NPC.';


--
-- Name: COLUMN npc_ambient_speech_configs.min_interval_sec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_ambient_speech_configs.min_interval_sec IS 'Minimum interval (seconds) between periodic lines on client.';


--
-- Name: COLUMN npc_ambient_speech_configs.max_interval_sec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_ambient_speech_configs.max_interval_sec IS 'Maximum interval (seconds) between periodic lines on client.';


--
-- Name: npc_ambient_speech_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.npc_ambient_speech_configs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.npc_ambient_speech_configs_id_seq OWNER TO postgres;

--
-- Name: npc_ambient_speech_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.npc_ambient_speech_configs_id_seq OWNED BY public.npc_ambient_speech_configs.id;


--
-- Name: npc_ambient_speech_lines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_ambient_speech_lines (
    id integer NOT NULL,
    npc_id integer NOT NULL,
    line_key character varying(128) NOT NULL,
    trigger_type character varying(16) DEFAULT 'periodic'::character varying NOT NULL,
    trigger_radius integer DEFAULT 400 NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    weight integer DEFAULT 10 NOT NULL,
    cooldown_sec integer DEFAULT 60 NOT NULL,
    condition_group jsonb
);


ALTER TABLE public.npc_ambient_speech_lines OWNER TO postgres;

--
-- Name: TABLE npc_ambient_speech_lines; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.npc_ambient_speech_lines IS 'Individual ambient speech lines for NPCs.';


--
-- Name: COLUMN npc_ambient_speech_lines.line_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.line_key IS 'Localisation key sent to client, e.g. npc.blacksmith.idle_1';


--
-- Name: COLUMN npc_ambient_speech_lines.trigger_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.trigger_type IS '"periodic" = fired by client timer; "proximity" = fired once on player approach.';


--
-- Name: COLUMN npc_ambient_speech_lines.trigger_radius; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.trigger_radius IS 'Trigger / display radius in world units (used for proximity trigger and UI culling).';


--
-- Name: COLUMN npc_ambient_speech_lines.priority; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.priority IS 'Highest-priority non-empty pool is used. Within a pool, lines are weighted-random.';


--
-- Name: COLUMN npc_ambient_speech_lines.weight; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.weight IS 'Relative weight for weighted-random selection within same priority group.';


--
-- Name: COLUMN npc_ambient_speech_lines.cooldown_sec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.cooldown_sec IS 'Per-client cooldown (seconds) before this specific line may show again.';


--
-- Name: COLUMN npc_ambient_speech_lines.condition_group; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.condition_group IS 'Optional JSONB condition tree compatible with DialogueConditionEvaluator. NULL = always show.';


--
-- Name: npc_ambient_speech_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.npc_ambient_speech_lines_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.npc_ambient_speech_lines_id_seq OWNER TO postgres;

--
-- Name: npc_ambient_speech_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.npc_ambient_speech_lines_id_seq OWNED BY public.npc_ambient_speech_lines.id;


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
-- Name: npc_trainer_class; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_trainer_class (
    id integer NOT NULL,
    npc_id integer NOT NULL,
    class_id integer NOT NULL
);


ALTER TABLE public.npc_trainer_class OWNER TO postgres;

--
-- Name: TABLE npc_trainer_class; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.npc_trainer_class IS 'Maps trainer NPC ids to the class whose skills they can teach. Used by game-server to build setTrainerData payload sent to chunk-servers at startup.';


--
-- Name: npc_trainer_class_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.npc_trainer_class_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.npc_trainer_class_id_seq OWNER TO postgres;

--
-- Name: npc_trainer_class_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.npc_trainer_class_id_seq OWNED BY public.npc_trainer_class.id;


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
-- Name: player_skill_cooldown; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player_skill_cooldown (
    character_id integer NOT NULL,
    skill_slug character varying(100) NOT NULL,
    cooldown_ends_at timestamp with time zone NOT NULL
);


ALTER TABLE public.player_skill_cooldown OWNER TO postgres;

--
-- Name: TABLE player_skill_cooldown; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.player_skill_cooldown IS 'Per-character active skill cooldowns. Upserted every time a skill is used; expired rows cleaned up when the character''s cooldowns are loaded on join.';


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
    client_quest_key text,
    reputation_faction_slug character varying(64) DEFAULT NULL::character varying,
    reputation_on_complete integer DEFAULT 0 NOT NULL,
    reputation_on_fail integer DEFAULT 0 NOT NULL
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
    is_hidden boolean DEFAULT false NOT NULL,
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
-- Name: COLUMN quest_reward.is_hidden; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.quest_reward.is_hidden IS 'TRUE = client displays "???" instead of item/amount until quest_turned_in. Revealed in the rewardsReceived array of the quest_turned_in notification.';


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
-- Name: TABLE respawn_zones; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.respawn_zones IS 'Точки возрождения персонажей в зонах. is_default=true — используется при первом входе или смерти без выбранной точки. Несколько точек на зону допустимо.';


--
-- Name: COLUMN respawn_zones.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.respawn_zones.id IS 'Суррогатный PK.';


--
-- Name: COLUMN respawn_zones.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.respawn_zones.name IS 'Отображаемое название точки возрождения.';


--
-- Name: COLUMN respawn_zones.x; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.respawn_zones.x IS 'X-координата точки возрождения.';


--
-- Name: COLUMN respawn_zones.y; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.respawn_zones.y IS 'Y-координата точки возрождения.';


--
-- Name: COLUMN respawn_zones.z; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.respawn_zones.z IS 'Z-координата точки возрождения.';


--
-- Name: COLUMN respawn_zones.zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.respawn_zones.zone_id IS 'FK → zones.id. Зона, к которой принадлежит точка возрождения.';


--
-- Name: COLUMN respawn_zones.is_default; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.respawn_zones.is_default IS 'TRUE = эта точка используется по умолчанию при первом входе или смерти без явно выбранной точки.';


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
-- Name: skill_active_effects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_active_effects (
    id integer NOT NULL,
    skill_id integer NOT NULL,
    effect_slug text NOT NULL,
    effect_type_slug text NOT NULL,
    attribute_slug text NOT NULL,
    value numeric DEFAULT 0 NOT NULL,
    duration_seconds integer DEFAULT 0 NOT NULL,
    tick_ms integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.skill_active_effects OWNER TO postgres;

--
-- Name: TABLE skill_active_effects; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.skill_active_effects IS 'Timed effects applied when an active skill is cast. Differs from passive_skill_modifiers (always-on) and status effect templates.';


--
-- Name: COLUMN skill_active_effects.effect_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_active_effects.effect_slug IS 'Unique slug for this effect instance, e.g. "battle_cry_phys_atk".';


--
-- Name: COLUMN skill_active_effects.effect_type_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_active_effects.effect_type_slug IS '"buff" | "debuff" | "dot" | "hot"';


--
-- Name: COLUMN skill_active_effects.attribute_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_active_effects.attribute_slug IS 'Which character attribute is modified, e.g. "physical_attack".';


--
-- Name: COLUMN skill_active_effects.value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_active_effects.value IS 'Magnitude of the effect (flat additive).';


--
-- Name: COLUMN skill_active_effects.duration_seconds; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_active_effects.duration_seconds IS 'Effect duration in seconds. 0 = permanent.';


--
-- Name: COLUMN skill_active_effects.tick_ms; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.skill_active_effects.tick_ms IS 'Tick interval in ms for DoT/HoT. 0 = not periodic.';


--
-- Name: skill_active_effects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.skill_active_effects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.skill_active_effects_id_seq OWNER TO postgres;

--
-- Name: skill_active_effects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.skill_active_effects_id_seq OWNED BY public.skill_active_effects.id;


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
    game_zone_id integer,
    shape_type public.spawn_zone_shape DEFAULT 'RECT'::public.spawn_zone_shape NOT NULL,
    center_x double precision DEFAULT 0 NOT NULL,
    center_y double precision DEFAULT 0 NOT NULL,
    inner_radius double precision DEFAULT 0 NOT NULL,
    outer_radius double precision DEFAULT 0 NOT NULL,
    exclusion_game_zone_id integer
);


ALTER TABLE public.spawn_zones OWNER TO postgres;

--
-- Name: TABLE spawn_zones; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.spawn_zones IS 'Defines where mobs may spawn in the world.  Three geometry variants are supported: RECT (AABB), CIRCLE (disc), and ANNULUS (ring).  Mob quotas and respawn timers are configured in spawn_zone_mobs.';


--
-- Name: COLUMN spawn_zones.game_zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spawn_zones.game_zone_id IS 'Игровой регион (zones), которому принадлежит точка спавна';


--
-- Name: COLUMN spawn_zones.shape_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spawn_zones.shape_type IS 'Geometry variant for this spawn zone.  RECT = AABB prism defined by (min_spawn_x/y, max_spawn_x/y).  CIRCLE = filled disc defined by (center_x/y, outer_radius).  ANNULUS = ring/donut defined by (center_x/y, inner_radius, outer_radius).  Use ANNULUS to surround a village or landmark with mobs while leaving the centre empty.';


--
-- Name: COLUMN spawn_zones.center_x; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spawn_zones.center_x IS 'World X coordinate of zone centre.  Required for CIRCLE and ANNULUS.  For RECT zones this is auto-derived as (min_spawn_x + max_spawn_x) / 2 and used for champion spawn-point resolution.';


--
-- Name: COLUMN spawn_zones.center_y; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spawn_zones.center_y IS 'World Y coordinate of zone centre.  Mirror of center_x for the Y axis.';


--
-- Name: COLUMN spawn_zones.inner_radius; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spawn_zones.inner_radius IS 'ANNULUS only.  Spawn candidates whose distance to center is less than inner_radius are rejected.  Set to 0 for RECT and CIRCLE.';


--
-- Name: COLUMN spawn_zones.outer_radius; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spawn_zones.outer_radius IS 'CIRCLE / ANNULUS.  Maximum distance from center at which mobs may spawn.  Set to 0 for RECT zones (AABB boundary is used instead).';


--
-- Name: COLUMN spawn_zones.exclusion_game_zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.spawn_zones.exclusion_game_zone_id IS 'Optional FK → zones.id.  Spawn candidates whose position falls inside this game zone are rejected at runtime regardless of the primary shape.  Typical use: prevent mobs spawning inside is_safe_zone=true areas when using RECT.';


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
-- Name: TABLE timed_champion_templates; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.timed_champion_templates IS 'Шаблоны мировых чемпионов с таймером спавна. Чемпион — усиленный моб, появляется с заданным интервалом в указанной зоне. next_spawn_at — unix-timestamp следующего спавна.';


--
-- Name: COLUMN timed_champion_templates.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.timed_champion_templates.id IS 'Суррогатный PK.';


--
-- Name: COLUMN timed_champion_templates.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.timed_champion_templates.slug IS 'Уникальный код шаблона чемпиона.';


--
-- Name: COLUMN timed_champion_templates.zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.timed_champion_templates.zone_id IS 'FK → zones.id. Зона, в которой появляется чемпион.';


--
-- Name: COLUMN timed_champion_templates.mob_template_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.timed_champion_templates.mob_template_id IS 'FK → mob.id. Шаблон моба, на основе которого создаётся чемпион.';


--
-- Name: COLUMN timed_champion_templates.interval_hours; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.timed_champion_templates.interval_hours IS 'Интервал между спавнами чемпиона в часах.';


--
-- Name: COLUMN timed_champion_templates.window_minutes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.timed_champion_templates.window_minutes IS 'Временное окно (в минутах) в котором чемпион может появиться после истечения интервала.';


--
-- Name: COLUMN timed_champion_templates.next_spawn_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.timed_champion_templates.next_spawn_at IS 'Unix timestamp (секунды) ближайшего возможного спавна. NULL = ещё не рассчитан.';


--
-- Name: COLUMN timed_champion_templates.last_killed_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.timed_champion_templates.last_killed_at IS 'Временная метка последнего убийства чемпиона.';


--
-- Name: COLUMN timed_champion_templates.announcement_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.timed_champion_templates.announcement_key IS 'Ключ строки анонса для клиентского UI при появлении чемпиона. NULL = без анонса.';


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
-- Name: title_definitions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.title_definitions (
    id integer NOT NULL,
    slug character varying(80) NOT NULL,
    display_name character varying(120) NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    earn_condition character varying(80) DEFAULT ''::character varying NOT NULL,
    bonuses jsonb DEFAULT '[]'::jsonb NOT NULL,
    condition_params jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.title_definitions OWNER TO postgres;

--
-- Name: TABLE title_definitions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.title_definitions IS 'Каталог титулов. earn_condition — строковый ключ для логики выдачи на game-server. bonuses — JSON-массив модификаторов атрибутов.';


--
-- Name: COLUMN title_definitions.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.title_definitions.id IS 'Суррогатный PK.';


--
-- Name: COLUMN title_definitions.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.title_definitions.slug IS 'Уникальный код титула. Используется как FK в character_titles.';


--
-- Name: COLUMN title_definitions.display_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.title_definitions.display_name IS 'Отображаемое имя титула в UI.';


--
-- Name: COLUMN title_definitions.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.title_definitions.description IS 'Описание способа получения/значения титула.';


--
-- Name: COLUMN title_definitions.earn_condition; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.title_definitions.earn_condition IS 'Строковый ключ условия получения. Обрабатывается логикой game-server (achievement_manager и т.п.).';


--
-- Name: COLUMN title_definitions.bonuses; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.title_definitions.bonuses IS 'JSON-массив бонусов: [{\"attribute\":\"slug\",\"value\":N}]. Применяются при активации титула.';


--
-- Name: COLUMN title_definitions.condition_params; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.title_definitions.condition_params IS 'Data-driven unlock params (JSONB). Fields depend on earn_condition:
     bestiary:   {"mobSlug":"GreyWolf","minTier":6}   — unlocked when bestiary tier >= minTier
     mastery:    {"masterySlug":"sword_mastery","minTier":3} — unlocked when mastery tier >= minTier (1-4)
     reputation: {"factionSlug":"hunters","minTierName":"ally"} — unlocked when faction tier == minTierName
     level:      {"level":10}                          — unlocked on exact level-up
     quest:      {"questSlug":"wolf_hunt_intro"}       — unlocked on quest turn-in';


--
-- Name: title_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.title_definitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.title_definitions_id_seq OWNER TO postgres;

--
-- Name: title_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.title_definitions_id_seq OWNED BY public.title_definitions.id;


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
-- Name: world_object_states; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.world_object_states (
    object_id integer NOT NULL,
    state character varying(16) DEFAULT 'active'::character varying NOT NULL,
    depleted_at timestamp with time zone,
    CONSTRAINT world_object_states_state_check CHECK (((state)::text = ANY ((ARRAY['active'::character varying, 'depleted'::character varying, 'disabled'::character varying])::text[])))
);


ALTER TABLE public.world_object_states OWNER TO postgres;

--
-- Name: TABLE world_object_states; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.world_object_states IS 'Persisted runtime state for global-scope world objects. Per-player state is in player_flags (wio_interacted_<id>).';


--
-- Name: COLUMN world_object_states.object_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_object_states.object_id IS 'FK to world_objects.id (PK + cascade delete).';


--
-- Name: COLUMN world_object_states.state; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_object_states.state IS 'Current state: active | depleted | disabled.';


--
-- Name: COLUMN world_object_states.depleted_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_object_states.depleted_at IS 'Timestamp of last depletion. NULL if never depleted.';


--
-- Name: world_objects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.world_objects (
    id integer NOT NULL,
    slug character varying(128) NOT NULL,
    name_key character varying(128) NOT NULL,
    object_type character varying(32) NOT NULL,
    scope character varying(16) DEFAULT 'per_player'::character varying NOT NULL,
    pos_x double precision DEFAULT 0 NOT NULL,
    pos_y double precision DEFAULT 0 NOT NULL,
    pos_z double precision DEFAULT 0 NOT NULL,
    rot_z double precision DEFAULT 0 NOT NULL,
    zone_id integer,
    dialogue_id integer,
    loot_table_id integer,
    required_item_id integer,
    interaction_radius double precision DEFAULT 250 NOT NULL,
    channel_time_sec integer DEFAULT 0 NOT NULL,
    respawn_sec integer DEFAULT 0 NOT NULL,
    is_active_by_default boolean DEFAULT true NOT NULL,
    min_level integer DEFAULT 0 NOT NULL,
    condition_group jsonb DEFAULT 'null'::jsonb NOT NULL,
    CONSTRAINT world_objects_object_type_check CHECK (((object_type)::text = ANY ((ARRAY['examine'::character varying, 'search'::character varying, 'activate'::character varying, 'use_with_item'::character varying, 'channeled'::character varying])::text[]))),
    CONSTRAINT world_objects_scope_check CHECK (((scope)::text = ANY ((ARRAY['per_player'::character varying, 'global'::character varying])::text[])))
);


ALTER TABLE public.world_objects OWNER TO postgres;

--
-- Name: TABLE world_objects; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.world_objects IS 'Static definitions of world interactive objects (WIO). Mesh binding is performed in UE5 by slug. Loaded by game-server at startup and forwarded to chunk-server.';


--
-- Name: COLUMN world_objects.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.id IS 'Primary key, auto-incremented.';


--
-- Name: COLUMN world_objects.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.slug IS 'Unique machine-readable identifier. UE5 uses this to look up the static mesh / blueprint asset at runtime.';


--
-- Name: COLUMN world_objects.name_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.name_key IS 'Localisation key forwarded to the client (e.g. wio.forest_tracks_01.name).';


--
-- Name: COLUMN world_objects.object_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.object_type IS 'Interaction type: examine | search | activate | use_with_item | channeled.';


--
-- Name: COLUMN world_objects.scope; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.scope IS 'State scope: per_player (stored in player_flags) or global (stored in world_object_states).';


--
-- Name: COLUMN world_objects.pos_x; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.pos_x IS 'World X position (Unreal Engine units).';


--
-- Name: COLUMN world_objects.pos_y; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.pos_y IS 'World Y position.';


--
-- Name: COLUMN world_objects.pos_z; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.pos_z IS 'World Z position.';


--
-- Name: COLUMN world_objects.rot_z; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.rot_z IS 'Yaw rotation around Z axis (degrees).';


--
-- Name: COLUMN world_objects.zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.zone_id IS 'FK to zones.id. NULL = global / not zone-specific.';


--
-- Name: COLUMN world_objects.dialogue_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.dialogue_id IS 'FK to dialogue.id. NULL = no dialogue.';


--
-- Name: COLUMN world_objects.loot_table_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.loot_table_id IS 'Synthetic mob_id for loot gen. No FK by design. NULL = no loot.';


--
-- Name: COLUMN world_objects.required_item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.required_item_id IS 'FK to items.id. NULL = no requirement.';


--
-- Name: COLUMN world_objects.interaction_radius; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.interaction_radius IS 'Max distance (UE units) for interaction trigger.';


--
-- Name: COLUMN world_objects.channel_time_sec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.channel_time_sec IS 'Channeling duration in seconds. 0 = instant.';


--
-- Name: COLUMN world_objects.respawn_sec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.respawn_sec IS 'Seconds before object resets after depletion. 0 = never.';


--
-- Name: COLUMN world_objects.is_active_by_default; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.is_active_by_default IS 'Initial enabled state when no state row exists yet.';


--
-- Name: COLUMN world_objects.min_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.min_level IS 'Minimum character level required. 0 = unrestricted.';


--
-- Name: COLUMN world_objects.condition_group; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.world_objects.condition_group IS 'JSONB condition tree (dialogue schema). null = always allowed.';


--
-- Name: world_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.world_objects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.world_objects_id_seq OWNER TO postgres;

--
-- Name: world_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.world_objects_id_seq OWNED BY public.world_objects.id;


--
-- Name: zone_event_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zone_event_templates (
    id integer NOT NULL,
    slug character varying(60) NOT NULL,
    game_zone_id integer,
    trigger_type character varying(20) DEFAULT 'manual'::character varying NOT NULL,
    duration_sec integer DEFAULT 1200 NOT NULL,
    loot_multiplier double precision DEFAULT 1.0 NOT NULL,
    spawn_rate_multiplier double precision DEFAULT 1.0 NOT NULL,
    mob_speed_multiplier double precision DEFAULT 1.0 NOT NULL,
    announce_key character varying(120) DEFAULT NULL::character varying,
    interval_hours integer DEFAULT 0,
    random_chance_per_hour double precision DEFAULT 0.0,
    has_invasion_wave boolean DEFAULT false,
    invasion_mob_template_id integer,
    invasion_wave_count integer DEFAULT 0,
    invasion_champion_template_id integer,
    invasion_champion_slug character varying(60) DEFAULT NULL::character varying
);


ALTER TABLE public.zone_event_templates OWNER TO postgres;

--
-- Name: TABLE zone_event_templates; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.zone_event_templates IS 'Шаблоны мировых событий (вторжения, праздники, осады). При срабатывании trigger_type chunk-server клонирует шаблон в активное событие. invasion_* поля задают волну мобов.';


--
-- Name: COLUMN zone_event_templates.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.id IS 'Суррогатный PK.';


--
-- Name: COLUMN zone_event_templates.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.slug IS 'Уникальный код шаблона события.';


--
-- Name: COLUMN zone_event_templates.game_zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.game_zone_id IS 'FK → zones.id. Зона, в которой происходит событие. NULL = глобальное событие.';


--
-- Name: COLUMN zone_event_templates.trigger_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.trigger_type IS 'Способ запуска: manual (GM-команда), timed (по расписанию), random (случайный по вероятности).';


--
-- Name: COLUMN zone_event_templates.duration_sec; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.duration_sec IS 'Продолжительность активного события в секундах.';


--
-- Name: COLUMN zone_event_templates.loot_multiplier; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.loot_multiplier IS 'Множитель вероятности дропа во время события (1.0 = норма).';


--
-- Name: COLUMN zone_event_templates.spawn_rate_multiplier; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.spawn_rate_multiplier IS 'Множитель скорости спавна мобов (1.0 = норма).';


--
-- Name: COLUMN zone_event_templates.mob_speed_multiplier; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.mob_speed_multiplier IS 'Множитель скорости движения мобов (1.0 = норма).';


--
-- Name: COLUMN zone_event_templates.announce_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.announce_key IS 'Ключ строки анонса для клиентского UI при старте события. NULL = без анонса.';


--
-- Name: COLUMN zone_event_templates.interval_hours; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.interval_hours IS 'Интервал повторения события в часах (0 = не повторяется). Применяется при trigger_type=timed.';


--
-- Name: COLUMN zone_event_templates.random_chance_per_hour; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.random_chance_per_hour IS 'Вероятность случайного запуска в час (0.0–1.0). Применяется при trigger_type=random.';


--
-- Name: COLUMN zone_event_templates.has_invasion_wave; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.has_invasion_wave IS 'TRUE = событие сопровождается волной вторжения мобов.';


--
-- Name: COLUMN zone_event_templates.invasion_mob_template_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.invasion_mob_template_id IS 'FK → mob.id. Шаблон моба-захватчика. NULL = нет вторжения.';


--
-- Name: COLUMN zone_event_templates.invasion_wave_count; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.invasion_wave_count IS 'Количество волн вторжения.';


--
-- Name: COLUMN zone_event_templates.invasion_champion_template_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.invasion_champion_template_id IS 'FK → timed_champion_templates.id. Чемпион, появляющийся в финальной волне. NULL = без чемпиона.';


--
-- Name: COLUMN zone_event_templates.invasion_champion_slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zone_event_templates.invasion_champion_slug IS 'Slug чемпиона (дублирует FK для runtime без JOIN). NULL = без чемпиона.';


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
    champion_threshold_kills integer DEFAULT 100 NOT NULL,
    shape_type public.spawn_zone_shape DEFAULT 'RECT'::public.spawn_zone_shape NOT NULL,
    center_x double precision NOT NULL,
    center_y double precision NOT NULL,
    inner_radius double precision DEFAULT 0 NOT NULL,
    outer_radius double precision DEFAULT 0 NOT NULL
);


ALTER TABLE public.zones OWNER TO postgres;

--
-- Name: TABLE zones; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.zones IS 'Игровые зоны/карты. Без zone_id координаты позиций теряют смысл';


--
-- Name: COLUMN zones.shape_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zones.shape_type IS 'Zone boundary shape: RECT (AABB), CIRCLE (center + outer_radius), ANNULUS (center + inner_radius + outer_radius)';


--
-- Name: COLUMN zones.center_x; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zones.center_x IS 'World-space X of zone centre. For RECT this equals (min_x+max_x)/2';


--
-- Name: COLUMN zones.center_y; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zones.center_y IS 'World-space Y of zone centre. For RECT this equals (min_y+max_y)/2';


--
-- Name: COLUMN zones.inner_radius; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zones.inner_radius IS 'Inner exclusion radius (ANNULUS only). Zero for RECT/CIRCLE';


--
-- Name: COLUMN zones.outer_radius; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.zones.outer_radius IS 'Outer boundary radius for CIRCLE/ANNULUS. Zero for RECT (use AABB instead)';


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
-- Name: character_emotes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_emotes ALTER COLUMN id SET DEFAULT nextval('public.character_emotes_id_seq'::regclass);


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
-- Name: class_starter_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_starter_items ALTER COLUMN id SET DEFAULT nextval('public.class_starter_items_id_seq'::regclass);


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
-- Name: emote_definitions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.emote_definitions ALTER COLUMN id SET DEFAULT nextval('public.emote_definitions_id_seq'::regclass);


--
-- Name: factions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factions ALTER COLUMN id SET DEFAULT nextval('public.factions_id_seq'::regclass);


--
-- Name: game_analytics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_analytics ALTER COLUMN id SET DEFAULT nextval('public.game_analytics_id_seq'::regclass);


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
-- Name: npc_ambient_speech_configs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_ambient_speech_configs ALTER COLUMN id SET DEFAULT nextval('public.npc_ambient_speech_configs_id_seq'::regclass);


--
-- Name: npc_ambient_speech_lines id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_ambient_speech_lines ALTER COLUMN id SET DEFAULT nextval('public.npc_ambient_speech_lines_id_seq'::regclass);


--
-- Name: npc_placements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_placements ALTER COLUMN id SET DEFAULT nextval('public.npc_placements_id_seq'::regclass);


--
-- Name: npc_skills id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_skills ALTER COLUMN id SET DEFAULT nextval('public.npc_skills_id_seq'::regclass);


--
-- Name: npc_trainer_class id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_trainer_class ALTER COLUMN id SET DEFAULT nextval('public.npc_trainer_class_id_seq'::regclass);


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
-- Name: skill_active_effects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_active_effects ALTER COLUMN id SET DEFAULT nextval('public.skill_active_effects_id_seq'::regclass);


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
-- Name: title_definitions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.title_definitions ALTER COLUMN id SET DEFAULT nextval('public.title_definitions_id_seq'::regclass);


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
-- Name: world_objects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.world_objects ALTER COLUMN id SET DEFAULT nextval('public.world_objects_id_seq'::regclass);


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
3	1	380
2	1	8
3	2	18
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
3	265	477	f	2026-04-19 19:35:47.704094+00
2	107	286	f	2026-04-20 16:06:57.389983+00
1	197	454	f	2026-03-07 12:41:29.615005+00
\.


--
-- Data for Name: character_emotes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_emotes (id, character_id, emote_slug, unlocked_at) FROM stdin;
4	1	wave	2026-04-13 08:53:40.211313+00
5	2	wave	2026-04-13 08:53:40.211313+00
6	3	wave	2026-04-13 08:53:40.211313+00
\.


--
-- Data for Name: character_equipment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_equipment (id, character_id, equip_slot_id, inventory_item_id, equipped_at) FROM stdin;
80	3	6	176	2026-04-08 18:25:58.153336+00
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
\.


--
-- Data for Name: character_pity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_pity (character_id, item_id, kill_count) FROM stdin;
3	6	0
3	17	0
3	3	0
\.


--
-- Data for Name: character_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_position (id, character_id, x, y, z, zone_id, rot_z) FROM stdin;
1	1	-2000.00	4000.00	300.00	2	0
3	3	19318.04	-19033.01	1541.01	1	179.910675
2	2	873.44	-912.04	94.27	2	134.452255
\.


--
-- Data for Name: character_reputation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_reputation (character_id, faction_slug, value) FROM stdin;
3	hunters	750
3	city_guard	500
3	merchants	-200
\.


--
-- Data for Name: character_skill_bar; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_skill_bar (character_id, slot_index, skill_slug) FROM stdin;
3	0	basic_attack
3	1	fireball
3	2	blink_home
2	1	blink_home
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
6	3	2	1
7	3	3	1
8	3	8	1
18	3	11	1
19	3	15	1
20	2	15	1
\.


--
-- Data for Name: character_titles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_titles (character_id, title_slug, equipped, earned_at) FROM stdin;
\.


--
-- Data for Name: characters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.characters (id, name, owner_id, class_id, race_id, experience_points, level, radius, free_skill_points, gender, account_slot, created_at, last_online_at, deleted_at, play_time_sec, bind_zone_id, bind_x, bind_y, bind_z, appearance, experience_debt) FROM stdin;
1	TetsMage1Player	5	1	1	57	2	100	0	0	1	2026-03-03 16:16:54.741947+00	\N	\N	0	1	0	0	200	\N	0
3	TetsWarrior1Player	3	2	1	5730	5	100	39	0	1	2026-03-03 16:16:54.741947+00	\N	\N	0	1	0	0	200	\N	3616
2	TetsMage2Player	4	1	1	1460	3	100	0	0	1	2026-03-03 16:16:54.741947+00	\N	\N	0	1	0	0	200	\N	1994
\.


--
-- Data for Name: class_skill_tree; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.class_skill_tree (id, class_id, skill_id, required_level, is_default, prerequisite_skill_id, skill_point_cost, gold_cost, max_level, requires_book, skill_book_item_id) FROM stdin;
1	1	1	1	t	\N	0	0	1	f	\N
3	2	1	1	t	\N	0	0	1	f	\N
5	2	4	5	f	\N	1	150	1	f	\N
7	2	6	5	f	\N	1	120	1	f	\N
8	2	7	8	f	6	1	200	1	f	\N
4	2	2	5	f	\N	1	100	1	f	\N
13	1	8	5	f	\N	1	100	1	f	\N
14	1	9	8	f	8	1	200	1	f	\N
16	1	11	5	f	\N	1	150	1	f	\N
17	1	12	10	f	11	1	300	1	f	\N
2	1	3	5	f	\N	1	120	1	f	\N
6	2	5	10	f	4	1	300	1	t	19
15	1	10	12	f	9	1	400	1	t	24
23	2	13	5	f	\N	1	100	1	f	\N
24	1	14	8	f	\N	1	150	1	f	\N
25	1	15	5	f	\N	1	80	1	f	\N
26	2	15	5	f	\N	1	80	1	f	\N
\.


--
-- Data for Name: class_starter_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.class_starter_items (id, class_id, item_id, quantity, slot_index, durability_current) FROM stdin;
1	1	15	1	0	\N
2	1	16	50	1	\N
3	2	1	1	0	\N
4	2	2	1	1	\N
5	2	16	50	2	\N
\.


--
-- Data for Name: class_stat_formula; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.class_stat_formula (class_id, attribute_id, base_value, multiplier, exponent) FROM stdin;
1	3	4.00	0.6000	1.0000
1	4	15.00	2.5000	1.0500
1	27	6.00	0.8000	1.0000
1	28	10.00	2.0000	1.0500
1	29	5.00	0.5000	1.0000
1	1	80.00	8.0000	1.1000
1	2	200.00	25.0000	1.1200
1	12	2.00	0.5000	1.0000
1	13	5.00	1.8000	1.0800
1	6	4.00	1.0000	1.0500
1	7	8.00	2.0000	1.0800
1	8	5.00	0.3000	1.0000
1	9	200.00	0.0000	1.0000
1	14	5.00	0.5000	1.0000
1	15	5.00	0.5000	1.0000
1	16	0.00	0.0000	1.0000
1	17	0.00	0.0000	1.0000
1	10	1.00	0.2000	1.0000
1	11	2.00	0.8000	1.0500
1	18	5.00	0.0000	1.0000
1	19	5.00	0.2000	1.0000
1	20	7.00	0.4000	1.0000
1	30	0.00	0.3000	1.0000
1	31	0.00	0.3000	1.0000
1	32	0.00	0.3000	1.0000
1	33	0.00	0.3000	1.0000
1	34	0.00	0.3000	1.0000
1	35	0.00	0.3000	1.0000
2	3	12.00	2.0000	1.0800
2	4	5.00	0.5000	1.0000
2	27	10.00	2.0000	1.0800
2	28	4.00	0.5000	1.0000
2	29	6.00	0.8000	1.0000
2	1	150.00	18.0000	1.1500
2	2	50.00	5.0000	1.0500
2	12	10.00	3.5000	1.1000
2	13	2.00	0.5000	1.0000
2	6	15.00	4.0000	1.1200
2	7	5.00	1.5000	1.0500
2	8	5.00	0.3000	1.0000
2	9	200.00	0.0000	1.0000
2	14	5.00	0.5000	1.0000
2	15	3.00	0.3000	1.0000
2	16	10.00	0.5000	1.0000
2	17	3.00	1.0000	1.0500
2	10	1.00	0.4000	1.0000
2	11	0.50	0.2000	1.0000
2	18	5.00	0.0000	1.0000
2	19	5.00	0.3000	1.0000
2	20	3.00	0.1000	1.0000
2	30	0.00	0.2000	1.0000
2	31	0.00	0.2000	1.0000
2	32	0.00	0.2000	1.0000
2	33	0.00	0.2000	1.0000
2	34	0.00	0.2000	1.0000
2	35	0.00	0.2000	1.0000
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
ice
\.


--
-- Data for Name: dialogue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dialogue (id, slug, version, start_node_id) FROM stdin;
1	milaya_main	1	1
2	varan_main	1	201
3	edrik_main	1	301
4	theron_main	1	400
5	sylara_main	1	500
6	ruins_dying_stranger_main	1	600
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
70	400	401	0	theron.choice.continue	\N	\N	f
71	401	402	0	theron.choice.learn_power_slash	{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "power_slash", "type": "skill_not_learned"}]}	\N	t
72	401	410	1	theron.choice.learn_shield_bash	{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "shield_bash", "type": "skill_not_learned"}]}	\N	t
73	401	420	2	theron.choice.learn_whirlwind	{"all": [{"gte": 10, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "whirlwind", "type": "skill_not_learned"}, {"slug": "shield_bash", "type": "skill_learned"}, {"gte": 1, "type": "item", "item_id": 19}]}	\N	t
74	401	430	3	theron.choice.learn_iron_skin	{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "iron_skin", "type": "skill_not_learned"}]}	\N	t
75	401	440	4	theron.choice.learn_constitution_mastery	{"all": [{"gte": 8, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "constitution_mastery", "type": "skill_not_learned"}, {"slug": "iron_skin", "type": "skill_learned"}]}	\N	t
76	401	499	5	theron.choice.open_shop	\N	{"actions": [{"type": "open_skill_shop"}]}	f
28	6	4	0	milaya.choice.back	\N	\N	f
30	8	4	0	milaya.choice.got_it	\N	\N	f
29	7	1	0	milaya.choice.back	\N	\N	f
36	13	1	0	milaya.choice.back	\N	\N	f
37	14	1	0	milaya.choice.back	\N	\N	f
26	4	14	4	milaya.choice.quest_done	{"slug": "wolf_hunt_intro", "type": "quest", "state": "turned_in"}	\N	t
22	4	5	0	milaya.choice.quest_accept	{"any": [{"slug": "wolf_hunt_intro", "type": "quest", "state": "not_started"}, {"slug": "wolf_hunt_intro", "type": "quest", "state": "turned_in"}, {"slug": "wolf_hunt_intro", "type": "quest", "state": "failed"}]}	\N	t
77	401	499	6	theron.choice.farewell	\N	\N	f
78	402	403	0	theron.choice.yes	\N	\N	f
79	402	401	1	theron.choice.no	\N	\N	f
80	403	404	0	theron.choice.continue	\N	\N	f
81	404	401	0	theron.choice.continue	\N	\N	f
82	410	411	0	theron.choice.yes	\N	\N	f
83	410	401	1	theron.choice.no	\N	\N	f
84	411	412	0	theron.choice.continue	\N	\N	f
85	412	401	0	theron.choice.continue	\N	\N	f
86	420	421	0	theron.choice.yes	\N	\N	f
87	420	401	1	theron.choice.no	\N	\N	f
88	421	422	0	theron.choice.continue	\N	\N	f
89	422	401	0	theron.choice.continue	\N	\N	f
90	430	431	0	theron.choice.yes	\N	\N	f
91	430	401	1	theron.choice.no	\N	\N	f
92	431	432	0	theron.choice.continue	\N	\N	f
93	432	401	0	theron.choice.continue	\N	\N	f
94	440	441	0	theron.choice.yes	\N	\N	f
95	440	401	1	theron.choice.no	\N	\N	f
96	441	442	0	theron.choice.continue	\N	\N	f
97	442	401	0	theron.choice.continue	\N	\N	f
100	500	501	0	sylara.choice.continue	\N	\N	f
101	501	502	0	sylara.choice.learn_fireball	{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "fireball", "type": "skill_not_learned"}]}	\N	t
102	501	510	1	sylara.choice.learn_frost_bolt	{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "frost_bolt", "type": "skill_not_learned"}]}	\N	t
103	501	520	2	sylara.choice.learn_arcane_blast	{"all": [{"gte": 8, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "arcane_blast", "type": "skill_not_learned"}, {"slug": "frost_bolt", "type": "skill_learned"}]}	\N	t
104	501	530	3	sylara.choice.learn_chain_lightning	{"all": [{"gte": 12, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "chain_lightning", "type": "skill_not_learned"}, {"slug": "arcane_blast", "type": "skill_learned"}, {"gte": 1, "type": "item", "item_id": 24}]}	\N	t
105	501	540	4	sylara.choice.learn_mana_shield	{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "mana_shield", "type": "skill_not_learned"}]}	\N	t
106	501	550	5	sylara.choice.learn_elemental_mastery	{"all": [{"gte": 10, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "elemental_mastery", "type": "skill_not_learned"}, {"slug": "mana_shield", "type": "skill_learned"}]}	\N	t
108	501	599	7	sylara.choice.farewell	\N	\N	f
110	502	503	0	sylara.choice.yes	\N	\N	f
111	502	501	1	sylara.choice.no	\N	\N	f
112	503	504	0	sylara.choice.continue	\N	\N	f
113	504	501	0	sylara.choice.continue	\N	\N	f
114	510	511	0	sylara.choice.yes	\N	\N	f
115	510	501	1	sylara.choice.no	\N	\N	f
116	511	512	0	sylara.choice.continue	\N	\N	f
117	512	501	0	sylara.choice.continue	\N	\N	f
118	520	521	0	sylara.choice.yes	\N	\N	f
119	520	501	1	sylara.choice.no	\N	\N	f
120	521	522	0	sylara.choice.continue	\N	\N	f
121	522	501	0	sylara.choice.continue	\N	\N	f
122	530	531	0	sylara.choice.yes	\N	\N	f
123	530	501	1	sylara.choice.no	\N	\N	f
124	531	532	0	sylara.choice.continue	\N	\N	f
125	532	501	0	sylara.choice.continue	\N	\N	f
126	540	541	0	sylara.choice.yes	\N	\N	f
127	540	501	1	sylara.choice.no	\N	\N	f
128	541	542	0	sylara.choice.continue	\N	\N	f
129	542	501	0	sylara.choice.continue	\N	\N	f
130	550	551	0	sylara.choice.yes	\N	\N	f
131	550	501	1	sylara.choice.no	\N	\N	f
132	551	552	0	sylara.choice.continue	\N	\N	f
133	552	501	0	sylara.choice.continue	\N	\N	f
107	501	599	6	sylara.choice.open_shop	\N	{"actions": [{"type": "open_skill_shop"}]}	f
140	605	609	0	ruins_dying_stranger.choice.farewell	\N	\N	f
137	603	605	0	ruins_dying_stranger.choice.accept	[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}, {"type": "class", "class_id": 2}]	[{"type": "give_item", "item_id": 1, "quantity": 1}, {"type": "give_item", "item_id": 3, "quantity": 2}, {"key": "ruins_dying_stranger.received_gift", "type": "set_flag", "bool_value": true}]	t
141	603	605	1	ruins_dying_stranger.choice.accept	[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}, {"type": "class", "class_id": 1}]	[{"type": "give_item", "item_id": 15, "quantity": 1}, {"type": "give_item", "item_id": 3, "quantity": 2}, {"key": "ruins_dying_stranger.received_gift", "type": "set_flag", "bool_value": true}]	t
134	600	601	0	ruins_dying_stranger.choice.why_here	\N	\N	f
135	601	602	0	ruins_dying_stranger.choice.i_will_try	\N	\N	f
143	611	609	0	ruins_dying_stranger.choice.farewell	\N	\N	f
138	603	605	2	ruins_dying_stranger.choice.decline	[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}]	\N	t
136	602	603	0	ruins_dying_stranger.choice.what_can_i_do	[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}]	\N	t
144	602	611	1	ruins_dying_stranger.choice.nothing_more	[{"eq": true, "key": "ruins_dying_stranger.received_gift", "type": "flag"}]	\N	t
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
400	4	line	4	theron.dialogue.greeting	\N	\N	\N
401	4	choice_hub	4	theron.dialogue.skill_hub	\N	\N	\N
402	4	line	4	theron.dialogue.confirm_power_slash	\N	\N	\N
403	4	action	4	\N	\N	{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 100, "skill_slug": "power_slash", "book_item_id": 0, "requires_book": false}]}	\N
404	4	line	4	theron.dialogue.learned_power_slash	\N	\N	\N
410	4	line	4	theron.dialogue.confirm_shield_bash	\N	\N	\N
411	4	action	4	\N	\N	{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 150, "skill_slug": "shield_bash", "book_item_id": 0, "requires_book": false}]}	\N
412	4	line	4	theron.dialogue.learned_shield_bash	\N	\N	\N
420	4	line	4	theron.dialogue.confirm_whirlwind	\N	\N	\N
421	4	action	4	\N	\N	{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 300, "skill_slug": "whirlwind", "book_item_id": 19, "requires_book": true}]}	\N
422	4	line	4	theron.dialogue.learned_whirlwind	\N	\N	\N
430	4	line	4	theron.dialogue.confirm_iron_skin	\N	\N	\N
431	4	action	4	\N	\N	{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 120, "skill_slug": "iron_skin", "book_item_id": 0, "requires_book": false}]}	\N
432	4	line	4	theron.dialogue.learned_iron_skin	\N	\N	\N
440	4	line	4	theron.dialogue.confirm_constitution_mastery	\N	\N	\N
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
441	4	action	4	\N	\N	{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 200, "skill_slug": "constitution_mastery", "book_item_id": 0, "requires_book": false}]}	\N
442	4	line	4	theron.dialogue.learned_constitution_mastery	\N	\N	\N
499	4	end	4	\N	\N	\N	\N
500	5	line	5	sylara.dialogue.greeting	\N	\N	\N
501	5	choice_hub	5	sylara.dialogue.skill_hub	\N	\N	\N
502	5	line	5	sylara.dialogue.confirm_fireball	\N	\N	\N
503	5	action	5	\N	\N	{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 120, "skill_slug": "fireball", "book_item_id": 0, "requires_book": false}]}	\N
504	5	line	5	sylara.dialogue.learned_fireball	\N	\N	\N
510	5	line	5	sylara.dialogue.confirm_frost_bolt	\N	\N	\N
511	5	action	5	\N	\N	{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 100, "skill_slug": "frost_bolt", "book_item_id": 0, "requires_book": false}]}	\N
512	5	line	5	sylara.dialogue.learned_frost_bolt	\N	\N	\N
520	5	line	5	sylara.dialogue.confirm_arcane_blast	\N	\N	\N
521	5	action	5	\N	\N	{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 200, "skill_slug": "arcane_blast", "book_item_id": 0, "requires_book": false}]}	\N
522	5	line	5	sylara.dialogue.learned_arcane_blast	\N	\N	\N
530	5	line	5	sylara.dialogue.confirm_chain_lightning	\N	\N	\N
531	5	action	5	\N	\N	{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 400, "skill_slug": "chain_lightning", "book_item_id": 24, "requires_book": true}]}	\N
532	5	line	5	sylara.dialogue.learned_chain_lightning	\N	\N	\N
540	5	line	5	sylara.dialogue.confirm_mana_shield	\N	\N	\N
541	5	action	5	\N	\N	{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 150, "skill_slug": "mana_shield", "book_item_id": 0, "requires_book": false}]}	\N
542	5	line	5	sylara.dialogue.learned_mana_shield	\N	\N	\N
550	5	line	5	sylara.dialogue.confirm_elemental_mastery	\N	\N	\N
551	5	action	5	\N	\N	{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 300, "skill_slug": "elemental_mastery", "book_item_id": 0, "requires_book": false}]}	\N
552	5	line	5	sylara.dialogue.learned_elemental_mastery	\N	\N	\N
599	5	end	5	\N	\N	\N	\N
600	6	line	6	npc.ruins_dying_stranger.place_wont_let_go	\N	\N	\N
601	6	line	6	npc.ruins_dying_stranger.if_survive_go_exit	\N	\N	\N
602	6	line	6	npc.ruins_dying_stranger.wont_escape_but_you_can	\N	\N	\N
605	6	line	6	npc.ruins_dying_stranger.farewell	\N	\N	\N
609	6	end	6	\N	\N	\N	\N
611	6	line	6	npc.ruins_dying_stranger.nothing_more_reply	\N	\N	\N
603	6	choice_hub	6	npc.ruins_dying_stranger.take_this_with_you	\N	\N	\N
\.


--
-- Data for Name: emote_definitions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.emote_definitions (id, slug, display_name, animation_name, category, is_default, sort_order, created_at) FROM stdin;
7	salute	Козырять	emote_salute	social	f	10	2026-04-13 08:53:40.207308+00
8	clap	Аплодировать	emote_clap	social	f	11	2026-04-13 08:53:40.207308+00
9	shrug	Пожать плечами	emote_shrug	social	f	12	2026-04-13 08:53:40.207308+00
10	taunt	Дразниться	emote_taunt	social	f	13	2026-04-13 08:53:40.207308+00
11	dance_basic	Танцевать	emote_dance_basic	dance	f	20	2026-04-13 08:53:40.207308+00
12	dance_wild	Дикий танец	emote_dance_wild	dance	f	21	2026-04-13 08:53:40.207308+00
13	dance_slow	Медленный танец	emote_dance_slow	dance	f	22	2026-04-13 08:53:40.207308+00
1	sit	Сесть	emote_sit	basic	f	1	2026-04-13 08:53:40.207308+00
2	wave	Помахать рукой	emote_wave	basic	t	2	2026-04-13 08:53:40.207308+00
3	bow	Поклониться	emote_bow	basic	f	3	2026-04-13 08:53:40.207308+00
4	laugh	Смеяться	emote_laugh	social	f	4	2026-04-13 08:53:40.207308+00
5	cry	Плакать	emote_cry	social	f	5	2026-04-13 08:53:40.207308+00
6	point	Указать	emote_point	basic	f	6	2026-04-13 08:53:40.207308+00
\.


--
-- Data for Name: entity_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.entity_attributes (id, name, slug, is_percentage) FROM stdin;
1	Maximum Health	max_health	f
2	Maximum Mana	max_mana	f
3	Strength	strength	f
4	Intelligence	intelligence	f
6	Physical Defense	physical_defense	f
7	Magical Defense	magical_defense	f
10	HP Regen /s	hp_regen_per_s	f
11	MP Regen /s	mp_regen_per_s	f
12	Physical Attack	physical_attack	f
13	Magical Attack	magical_attack	f
14	Accuracy	accuracy	f
15	Evasion	evasion	f
17	Block Value	block_value	f
18	Move Speed	move_speed	f
19	Attack Speed	attack_speed	f
20	Cast Speed	cast_speed	f
27	Constitution	constitution	f
28	Wisdom	wisdom	f
29	Agility	agility	f
8	Crit Chance	crit_chance	t
9	Crit Multiplier	crit_multiplier	t
16	Block Chance	block_chance	t
30	Fire Resistance	fire_resistance	t
31	Ice Resistance	ice_resistance	t
32	Nature Resistance	nature_resistance	t
33	Arcane Resistance	arcane_resistance	t
34	Holy Resistance	holy_resistance	t
35	Shadow Resistance	shadow_resistance	t
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
-- Data for Name: game_analytics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.game_analytics (id, event_type, character_id, session_id, level, zone_id, payload, created_at) FROM stdin;
1	session_start	3	sess_3_1776532169675	5	0	{}	2026-04-18 17:09:29.683871+00
2	session_end	3	sess_3_1776532169675	5	0	{}	2026-04-18 17:11:28.74126+00
3	session_start	3	sess_3_1776532294479	5	0	{}	2026-04-18 17:11:34.482173+00
4	session_start	2	sess_2_1776532300730	3	1	{}	2026-04-18 17:11:40.732878+00
5	session_end	2	sess_2_1776532300730	3	1	{}	2026-04-18 17:12:43.734353+00
6	session_end	3	sess_3_1776532294479	5	0	{}	2026-04-18 17:12:44.057909+00
7	session_start	2	sess_2_1776533727181	3	1	{}	2026-04-18 17:35:27.18395+00
8	session_end	2	sess_2_1776533727181	3	1	{}	2026-04-18 17:36:39.415591+00
9	session_start	3	sess_3_1776535740355	5	0	{}	2026-04-18 18:09:00.357144+00
10	session_end	3	sess_3_1776535740355	5	0	{}	2026-04-18 18:09:06.691684+00
11	session_start	2	sess_2_1776535806302	3	1	{}	2026-04-18 18:10:06.3053+00
12	session_end	2	sess_2_1776535806302	3	2	{}	2026-04-18 18:11:23.624705+00
13	session_start	2	sess_2_1776536739659	3	2	{}	2026-04-18 18:25:39.661539+00
14	session_end	2	sess_2_1776536739659	3	2	{}	2026-04-18 18:27:32.368379+00
15	session_start	2	sess_2_1776536966030	3	2	{}	2026-04-18 18:29:26.031996+00
16	session_end	2	sess_2_1776536966030	3	2	{}	2026-04-18 18:29:41.510435+00
17	session_start	2	sess_2_1776540224544	3	2	{}	2026-04-18 19:23:44.548907+00
18	session_end	2	sess_2_1776540224544	3	2	{}	2026-04-18 19:25:54.642143+00
19	session_start	2	sess_2_1776540432193	3	2	{}	2026-04-18 19:27:12.19556+00
20	session_end	2	sess_2_1776540432193	3	0	{}	2026-04-18 19:30:01.465378+00
21	session_start	2	sess_2_1776540902152	3	0	{}	2026-04-18 19:35:02.155665+00
22	session_end	2	sess_2_1776540902152	3	0	{}	2026-04-18 19:35:32.593989+00
23	session_start	2	sess_2_1776540981404	3	0	{}	2026-04-18 19:36:21.406084+00
24	session_start	2	sess_2_1776541042773	3	0	{}	2026-04-18 19:37:22.775856+00
25	session_end	2	sess_2_1776541042773	3	0	{}	2026-04-18 19:37:43.759733+00
26	session_start	2	sess_2_1776541126619	3	0	{}	2026-04-18 19:38:46.621128+00
27	session_end	2	sess_2_1776541126619	3	0	{}	2026-04-18 19:38:58.611338+00
28	session_start	2	sess_2_1776541189246	3	0	{}	2026-04-18 19:39:49.248552+00
29	session_end	2	sess_2_1776541189246	3	0	{}	2026-04-18 19:40:06.354141+00
30	session_start	2	sess_2_1776541286287	3	0	{}	2026-04-18 19:41:26.288954+00
31	session_end	2	sess_2_1776541286287	3	0	{}	2026-04-18 19:41:37.24835+00
32	session_start	2	sess_2_1776541343543	3	0	{}	2026-04-18 19:42:23.545532+00
33	session_end	2	sess_2_1776541343543	3	0	{}	2026-04-18 19:43:45.497993+00
34	session_start	2	sess_2_1776541563455	3	0	{}	2026-04-18 19:46:03.45734+00
35	session_end	2	sess_2_1776541563455	3	2	{}	2026-04-18 19:47:23.942526+00
36	session_start	2	sess_2_1776541660137	3	2	{}	2026-04-18 19:47:40.140663+00
37	session_end	2	sess_2_1776541660137	3	2	{}	2026-04-18 19:48:25.960811+00
38	session_start	2	sess_2_1776542694250	3	2	{}	2026-04-18 20:04:54.252937+00
39	session_end	2	sess_2_1776542694250	3	2	{}	2026-04-18 20:05:38.062503+00
40	session_start	2	sess_2_1776544447540	3	2	{}	2026-04-18 20:34:07.543159+00
41	player_death	2	sess_2_1776544447540	3	2	{}	2026-04-18 20:36:22.665027+00
42	session_end	2	sess_2_1776544447540	3	1	{}	2026-04-18 20:36:46.318055+00
43	session_start	2	sess_2_1776544681531	3	1	{}	2026-04-18 20:38:01.533652+00
44	session_end	2	sess_2_1776544681531	3	1	{}	2026-04-18 20:40:06.569261+00
45	session_start	2	sess_2_1776544812796	3	1	{}	2026-04-18 20:40:12.798927+00
46	mob_killed	2	sess_2_1776544812796	3	2	{"mobId": 1, "mobSlug": "SmallFox", "mobLevel": 1}	2026-04-18 20:41:13.859648+00
47	mob_killed	2	sess_2_1776544812796	3	1	{"mobId": 1, "mobSlug": "SmallFox", "mobLevel": 1}	2026-04-18 20:42:30.052226+00
48	session_end	2	sess_2_1776544812796	3	1	{}	2026-04-18 20:43:00.229689+00
49	session_start	3	sess_3_1776598998993	5	0	{}	2026-04-19 11:43:18.997309+00
50	session_end	3	sess_3_1776598998993	5	0	{}	2026-04-19 11:43:49.190022+00
51	session_start	3	sess_3_1776599079538	5	0	{}	2026-04-19 11:44:39.541262+00
52	session_end	3	sess_3_1776599079538	5	0	{}	2026-04-19 11:45:14.057249+00
53	session_start	3	sess_3_1776599176943	5	0	{}	2026-04-19 11:46:16.945878+00
54	session_end	3	sess_3_1776599176943	5	0	{}	2026-04-19 11:46:44.056621+00
55	session_start	3	sess_3_1776599211845	5	0	{}	2026-04-19 11:46:51.847167+00
56	session_end	3	sess_3_1776599211845	5	0	{}	2026-04-19 11:47:15.25941+00
57	session_start	3	sess_3_1776604298105	5	0	{}	2026-04-19 13:11:38.108596+00
58	session_end	3	sess_3_1776604298105	5	0	{}	2026-04-19 13:11:44.816938+00
59	session_start	2	sess_2_1776604313102	3	1	{}	2026-04-19 13:11:53.104792+00
60	session_end	2	sess_2_1776604313102	3	2	{}	2026-04-19 13:12:36.641808+00
61	session_start	2	sess_2_1776604449869	3	2	{}	2026-04-19 13:14:09.871181+00
62	mob_killed	2	sess_2_1776604449869	3	2	{"mobId": 1, "mobSlug": "SmallFox", "mobLevel": 1}	2026-04-19 13:14:52.946237+00
63	session_end	2	sess_2_1776604449869	3	2	{}	2026-04-19 13:15:14.243541+00
64	session_start	3	sess_3_1776605624900	5	0	{}	2026-04-19 13:33:44.902701+00
65	session_end	3	sess_3_1776605624900	5	0	{}	2026-04-19 13:33:49.538024+00
66	session_start	2	sess_2_1776605635237	3	2	{}	2026-04-19 13:33:55.23964+00
67	mob_killed	2	sess_2_1776605635237	3	2	{"mobId": 1, "mobSlug": "SmallFox", "mobLevel": 1}	2026-04-19 13:34:36.318046+00
68	item_acquired	2	sess_2_1776605635237	3	2	{"source": "corpse_loot", "itemSlug": "small_animal_skin", "quantity": 1}	2026-04-19 13:34:44.661827+00
69	session_end	2	sess_2_1776605635237	3	2	{}	2026-04-19 13:34:52.448744+00
70	session_start	2	sess_2_1776606532503	3	2	{}	2026-04-19 13:48:52.505777+00
71	mob_killed	2	sess_2_1776606532503	3	2	{"mobId": 1, "mobSlug": "SmallFox", "mobLevel": 1}	2026-04-19 13:49:56.112215+00
72	player_death	2	sess_2_1776606532503	3	1	{}	2026-04-19 13:50:43.350676+00
73	item_acquired	2	sess_2_1776606532503	3	1	{"source": "loot_pickup", "itemSlug": "small_animal_skin", "quantity": 1}	2026-04-19 13:51:05.186213+00
74	item_acquired	2	sess_2_1776606532503	3	1	{"source": "loot_pickup", "itemSlug": "health_potion", "quantity": 1}	2026-04-19 13:51:11.718731+00
75	session_end	2	sess_2_1776606532503	3	1	{}	2026-04-19 13:51:15.568042+00
76	session_start	3	sess_3_1776607538026	5	0	{}	2026-04-19 14:05:38.028831+00
77	session_end	3	sess_3_1776607538026	5	0	{}	2026-04-19 14:05:43.9463+00
78	session_start	3	sess_3_1776607549840	5	0	{}	2026-04-19 14:05:49.842655+00
79	session_end	3	sess_3_1776607549840	5	0	{}	2026-04-19 14:05:57.451319+00
80	session_start	3	sess_3_1776611136332	5	0	{}	2026-04-19 15:05:36.334221+00
81	session_end	3	sess_3_1776611136332	5	0	{}	2026-04-19 15:05:42.022416+00
82	session_start	3	sess_3_1776611147487	5	0	{}	2026-04-19 15:05:47.48901+00
83	session_end	3	sess_3_1776611147487	5	0	{}	2026-04-19 15:05:53.969053+00
84	session_start	3	sess_3_1776611179062	5	0	{}	2026-04-19 15:06:19.06444+00
85	session_end	3	sess_3_1776611179062	5	0	{}	2026-04-19 15:06:43.795309+00
86	session_start	3	sess_3_1776611552130	5	0	{}	2026-04-19 15:12:32.132206+00
87	session_end	3	sess_3_1776611552130	5	0	{}	2026-04-19 15:12:44.978606+00
88	session_start	3	sess_3_1776617757629	5	0	{}	2026-04-19 16:55:57.632215+00
89	session_end	3	sess_3_1776617757629	5	0	{}	2026-04-19 16:57:18.967051+00
90	session_start	3	sess_3_1776617867944	5	0	{}	2026-04-19 16:57:47.946478+00
91	session_end	3	sess_3_1776617867944	5	0	{}	2026-04-19 16:58:02.904957+00
92	session_start	3	sess_3_1776617963174	5	0	{}	2026-04-19 16:59:23.176455+00
93	session_end	3	sess_3_1776617963174	5	0	{}	2026-04-19 17:00:03.011722+00
94	session_start	2	sess_2_1776618166756	3	1	{}	2026-04-19 17:02:46.758146+00
95	session_start	2	sess_2_1776621066467	3	1	{}	2026-04-19 17:51:06.470029+00
96	session_end	2	sess_2_1776621066467	3	1	{}	2026-04-19 17:51:41.550352+00
97	session_start	2	sess_2_1776621150834	3	1	{}	2026-04-19 17:52:30.835729+00
98	session_end	2	sess_2_1776621150834	3	1	{}	2026-04-19 17:52:52.675356+00
99	session_start	2	sess_2_1776621611258	3	1	{}	2026-04-19 18:00:11.260797+00
100	session_end	2	sess_2_1776621611258	3	1	{}	2026-04-19 18:00:34.651994+00
101	session_start	2	sess_2_1776621935842	3	1	{}	2026-04-19 18:05:35.845113+00
102	session_end	2	sess_2_1776621935842	3	1	{}	2026-04-19 18:05:51.674363+00
103	session_start	3	sess_3_1776622031706	5	0	{}	2026-04-19 18:07:11.709319+00
104	session_end	3	sess_3_1776622031706	5	0	{}	2026-04-19 18:07:17.327+00
105	session_start	2	sess_2_1776622043359	3	1	{}	2026-04-19 18:07:23.361872+00
106	session_end	2	sess_2_1776622043359	3	1	{}	2026-04-19 18:07:35.864734+00
107	session_start	2	sess_2_1776622194681	3	1	{}	2026-04-19 18:09:54.684681+00
108	session_end	2	sess_2_1776622194681	3	1	{}	2026-04-19 18:10:10.667599+00
109	session_start	2	sess_2_1776622647599	3	1	{}	2026-04-19 18:17:27.601643+00
110	session_end	2	sess_2_1776622647599	3	1	{}	2026-04-19 18:17:49.201741+00
111	session_start	2	sess_2_1776622918564	3	1	{}	2026-04-19 18:21:58.568008+00
112	session_end	2	sess_2_1776622918564	3	1	{}	2026-04-19 18:22:49.242467+00
113	session_start	2	sess_2_1776622976030	3	1	{}	2026-04-19 18:22:56.033066+00
114	session_end	2	sess_2_1776622976030	3	1	{}	2026-04-19 18:23:20.472295+00
115	session_start	2	sess_2_1776623448159	3	1	{}	2026-04-19 18:30:48.161712+00
116	session_end	2	sess_2_1776623448159	3	1	{}	2026-04-19 18:31:03.603364+00
117	session_start	2	sess_2_1776625780285	3	1	{}	2026-04-19 19:09:40.287494+00
118	session_end	2	sess_2_1776625780285	3	1	{}	2026-04-19 19:10:13.454201+00
119	session_start	2	sess_2_1776625900210	3	1	{}	2026-04-19 19:11:40.212715+00
120	session_end	2	sess_2_1776625900210	3	1	{}	2026-04-19 19:12:19.238237+00
121	session_start	2	sess_2_1776625949415	3	1	{}	2026-04-19 19:12:29.417891+00
122	session_end	2	sess_2_1776625949415	3	1	{}	2026-04-19 19:13:06.378961+00
123	session_start	2	sess_2_1776625994467	3	1	{}	2026-04-19 19:13:14.469723+00
124	session_end	2	sess_2_1776625994467	3	1	{}	2026-04-19 19:13:23.618884+00
125	session_start	2	sess_2_1776626011808	3	1	{}	2026-04-19 19:13:31.811314+00
126	session_end	2	sess_2_1776626011808	3	1	{}	2026-04-19 19:13:35.962945+00
127	session_start	2	sess_2_1776626849738	3	1	{}	2026-04-19 19:27:29.739606+00
128	session_end	2	sess_2_1776626849738	3	1	{}	2026-04-19 19:27:49.734615+00
129	session_start	2	sess_2_1776627154848	3	1	{}	2026-04-19 19:32:34.85217+00
130	session_end	2	sess_2_1776627154848	3	1	{}	2026-04-19 19:32:47.46183+00
131	session_start	3	sess_3_1776627334597	5	0	{}	2026-04-19 19:35:34.600106+00
132	session_end	3	sess_3_1776627334597	5	0	{}	2026-04-19 19:35:38.922794+00
133	session_start	3	sess_3_1776627345006	5	0	{}	2026-04-19 19:35:45.008796+00
134	session_end	3	sess_3_1776627345006	5	0	{}	2026-04-19 19:35:47.706434+00
135	session_start	2	sess_2_1776627354113	3	1	{}	2026-04-19 19:35:54.114976+00
136	session_end	2	sess_2_1776627354113	3	1	{}	2026-04-19 19:36:08.94899+00
137	session_start	2	sess_2_1776627376374	3	1	{}	2026-04-19 19:36:16.37687+00
138	session_end	2	sess_2_1776627376374	3	1	{}	2026-04-19 19:36:21.097232+00
139	session_start	2	sess_2_1776627422647	3	1	{}	2026-04-19 19:37:02.649533+00
140	session_end	2	sess_2_1776627422647	3	1	{}	2026-04-19 19:37:06.338386+00
141	session_start	2	sess_2_1776627720191	3	1	{}	2026-04-19 19:42:00.192938+00
142	session_end	2	sess_2_1776627720191	3	1	{}	2026-04-19 19:42:14.812425+00
143	session_start	2	sess_2_1776627745490	3	1	{}	2026-04-19 19:42:25.492119+00
144	session_end	2	sess_2_1776627745490	3	1	{}	2026-04-19 19:42:35.329722+00
145	session_start	2	sess_2_1776701165092	3	1	{}	2026-04-20 16:06:05.095779+00
146	session_end	2	sess_2_1776701165092	3	1	{}	2026-04-20 16:06:21.279716+00
147	session_start	2	sess_2_1776701190093	3	1	{}	2026-04-20 16:06:30.095495+00
148	session_end	2	sess_2_1776701190093	3	1	{}	2026-04-20 16:06:39.579643+00
149	session_start	2	sess_2_1776701208968	3	1	{}	2026-04-20 16:06:48.970754+00
150	session_end	2	sess_2_1776701208968	3	1	{}	2026-04-20 16:06:57.392401+00
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
combat.default_crit_multiplier	200	float	Default crit multiplier as percentage (200 = x2.0). Used when attacker has no crit_multiplier attribute.	2026-04-18 08:09:30.487328+00
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
durability.tier1_threshold_pct	0.75	float	\N	2026-04-16 08:33:27.432886+00
durability.tier1_penalty_pct	0.05	float	\N	2026-04-16 08:33:27.432886+00
durability.tier2_threshold_pct	0.50	float	\N	2026-04-16 08:33:27.432886+00
durability.tier2_penalty_pct	0.15	float	\N	2026-04-16 08:33:27.432886+00
durability.tier3_threshold_pct	0.25	float	\N	2026-04-16 08:33:27.432886+00
durability.tier3_penalty_pct	0.30	float	\N	2026-04-16 08:33:27.432886+00
combat.crit_chance_cap	75	float	Maximum crit_chance (%). Prevents 100% crit builds.	2026-04-18 08:09:30.487328+00
combat.block_chance_cap	75	float	Maximum block_chance (%). Prevents unkillable tank builds.	2026-04-18 08:09:30.487328+00
combat.evasion_cap	75	float	Maximum evasion effectiveness (%). Prevents un-hittable builds.	2026-04-18 08:09:30.487328+00
combat.elemental_resistance_cap	75	float	Maximum elemental resistance per school (%). Same as max_resistance_cap default.	2026-04-18 08:09:30.487328+00
combat.attack_speed_base_divisor	100	float	attack_speed divisor. effectiveSwingMs = baseSwingMs / (1 + attack_speed/divisor).	2026-04-18 08:09:30.487328+00
combat.cast_speed_base_divisor	100	float	cast_speed divisor. effectiveCastMs = baseCastMs / (1 + cast_speed/divisor).	2026-04-18 08:09:30.487328+00
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
7	15	13	8	equip
8	1	3	3	equip
9	15	4	3	equip
10	2	17	5	equip
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
10	Skill Book	skill_book
\.


--
-- Data for Name: item_use_effects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item_use_effects (id, item_id, effect_slug, attribute_slug, value, is_instant, duration_seconds, tick_ms, cooldown_seconds) FROM stdin;
1	3	hp_restore_50	hp	50	t	0	0	30
2	4	bread_hot	hp	5	f	30	2000	60
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.items (id, name, slug, description, is_quest_item, item_type, weight, rarity_id, stack_max, is_container, is_durable, is_tradable, durability_max, vendor_price_buy, vendor_price_sell, equip_slot, level_requirement, is_equippable, is_harvest, is_usable, is_two_handed, mastery_slug) FROM stdin;
5	Ancient Artifact	ancient_artifact	A mysterious artifact for quests.	t	5	0.5	1	64	f	f	t	100	1	1	\N	0	f	f	f	f	\N
18	Tome of Shield Bash	tome_shield_bash	A worn training manual describing the technique of Shield Bash.	f	10	0.3	2	1	f	f	t	100	500	100	\N	5	f	f	t	f	\N
19	Tome of Whirlwind	tome_whirlwind	An ancient scroll detailing the devastating Whirlwind technique. Rare.	f	10	0.3	3	1	f	f	t	100	0	50	\N	10	f	f	t	f	\N
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
17	Wolf Skin	wolf_skin	A rough skin of a forest wolf. Milaya will know what to do with it.	t	6	0.5	1	10	f	f	f	100	5	2	\N	0	f	f	f	f	\N
16	Gold Coin	gold_coin	Universal currency of the realm. Used as payment for goods and services.	f	8	0.01	1	9999999	f	f	t	100	1	1	\N	0	f	f	f	f	\N
20	Tome of Iron Skin	tome_iron_skin	Teachings of hardening the body through relentless training.	f	10	0.3	2	1	f	f	t	100	400	80	\N	5	f	f	t	f	\N
21	Tome of Constitution Mastery	tome_constitution_mastery	A guide to unlocking the body's true enduring potential.	f	10	0.3	2	1	f	f	t	100	800	160	\N	8	f	f	t	f	\N
22	Tome of Frost Bolt	tome_frost_bolt	Basic arcane theory behind channelling cold into a bolt of frost.	f	10	0.3	2	1	f	f	t	100	500	100	\N	5	f	f	t	f	\N
23	Tome of Arcane Blast	tome_arcane_blast	Concentrated arcane theory on focusing raw magical energy into a blast.	f	10	0.3	2	1	f	f	t	100	900	180	\N	8	f	f	t	f	\N
24	Tome of Chain Lightning	tome_chain_lightning	A legendary scroll describing storm magic that arcs between enemies. Extremely rare.	f	10	0.3	4	1	f	f	t	100	0	250	\N	12	f	f	t	f	\N
25	Tome of Mana Shield	tome_mana_shield	Teachings on weaving mana into a protective aura.	f	10	0.3	2	1	f	f	t	100	600	120	\N	5	f	f	t	f	\N
26	Tome of Elemental Mastery	tome_elemental_mastery	A comprehensive guide to attaining mastery over elemental forces.	f	10	0.3	2	1	f	f	t	100	1200	240	\N	10	f	f	t	f	\N
15	Wooden Staff	wooden_staff	A simple wooden staff for apprentice mages.	f	1	2	1	64	f	t	t	80	30	12	6	1	t	f	f	f	staff_mastery
1	Iron Sword	iron_sworld	A sturdy iron sword.	f	1	5	1	64	f	t	t	100	50	20	6	1	t	f	f	f	sword_mastery
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
1	Small Fox	2	1	40	0	f	f	SmallFox	100	15	1	600	120	2.5	1.8	0.9	t	30	0	melee	f	f	0	\N	\N	0		beast
2	Grey Wolf	2	1	80	0	t	f	GreyWolf	100	20	1	700	120	2	2.2	1.1	f	30	0	melee	f	f	0	\N	\N	0		beast
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
\.


--
-- Data for Name: mob_stat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_stat (id, mob_id, attribute_id, flat_value, multiplier, exponent) FROM stdin;
137	1	1	40.00	\N	\N
138	1	2	0.00	\N	\N
139	1	12	6.00	\N	\N
140	1	13	0.00	\N	\N
141	1	6	2.00	\N	\N
142	1	7	0.00	\N	\N
143	1	8	3.00	\N	\N
144	1	9	200.00	\N	\N
145	1	14	4.00	\N	\N
146	1	15	8.00	\N	\N
147	1	16	0.00	\N	\N
148	1	17	0.00	\N	\N
149	1	10	0.50	\N	\N
150	1	11	0.00	\N	\N
151	1	18	6.50	\N	\N
152	1	19	5.00	\N	\N
153	1	20	0.00	\N	\N
154	1	3	3.00	\N	\N
155	1	4	1.00	\N	\N
156	1	27	3.00	\N	\N
157	1	28	1.00	\N	\N
158	1	29	8.00	\N	\N
159	1	30	0.00	\N	\N
160	1	31	0.00	\N	\N
161	1	32	0.00	\N	\N
162	1	33	0.00	\N	\N
163	1	34	0.00	\N	\N
164	1	35	0.00	\N	\N
165	2	1	80.00	\N	\N
166	2	2	0.00	\N	\N
167	2	12	10.00	\N	\N
168	2	13	0.00	\N	\N
169	2	6	5.00	\N	\N
170	2	7	2.00	\N	\N
171	2	8	5.00	\N	\N
172	2	9	200.00	\N	\N
173	2	14	6.00	\N	\N
174	2	15	4.00	\N	\N
175	2	16	0.00	\N	\N
176	2	17	0.00	\N	\N
177	2	10	1.00	\N	\N
178	2	11	0.00	\N	\N
179	2	18	5.00	\N	\N
180	2	19	5.00	\N	\N
181	2	20	0.00	\N	\N
182	2	3	6.00	\N	\N
183	2	4	2.00	\N	\N
184	2	27	6.00	\N	\N
185	2	28	2.00	\N	\N
186	2	29	5.00	\N	\N
187	2	30	0.00	\N	\N
188	2	31	2.00	\N	\N
189	2	32	0.00	\N	\N
190	2	33	0.00	\N	\N
191	2	34	0.00	\N	\N
192	2	35	0.00	\N	\N
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
3	Edrik	1	1	100	20	f	edrik	100	t	1	\N
2	Milaya	1	1	100	50	f	milaya	100	t	3	\N
4	Theron	1	5	500	100	f	theron	100	t	6	\N
5	Sylara	1	5	400	250	f	sylara	100	t	6	\N
6	ruins_dying_stranger	1	1	1	0	f	ruins_dying_stranger	300	t	1	\N
\.


--
-- Data for Name: npc_ambient_speech_configs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_ambient_speech_configs (id, npc_id, min_interval_sec, max_interval_sec) FROM stdin;
1	6	10	30
\.


--
-- Data for Name: npc_ambient_speech_lines; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_ambient_speech_lines (id, npc_id, line_key, trigger_type, trigger_radius, priority, weight, cooldown_sec, condition_group) FROM stdin;
1	6	npc.ruins_dying_stranger.ambient.another_one	periodic	400	0	10	15	\N
2	6	npc.ruins_dying_stranger.ambient.keep_coming	periodic	400	0	10	15	\N
3	6	npc.ruins_dying_stranger.ambient.come_closer	periodic	400	0	15	10	\N
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
8	4	1	500
9	4	2	100
10	5	1	400
11	5	2	250
12	6	1	50
13	6	2	0
\.


--
-- Data for Name: npc_dialogue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_dialogue (npc_id, dialogue_id, priority, condition_group) FROM stdin;
2	1	0	\N
1	2	0	\N
3	3	0	\N
4	4	0	\N
5	5	0	\N
6	6	0	\N
\.


--
-- Data for Name: npc_placements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_placements (id, npc_id, zone_id, x, y, z, rot_z) FROM stdin;
12	6	\N	19015.771701309946	-19022.024921248747	1490	0
2	2	1	2200	1120	200	-129.90160790888044
1	3	1	-634.6344847632645	2160.291891096793	200	-20.259205622535426
5	5	1	-220.51805190619052	1568.1504897981577	200	79.08751509189774
3	1	1	585	-3300	200	71.8812130187667
4	4	1	1200	-2800	200	176.85170827243957
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
-- Data for Name: npc_trainer_class; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_trainer_class (id, npc_id, class_id) FROM stdin;
1	4	2
2	5	1
\.


--
-- Data for Name: npc_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_type (id, name, slug) FROM stdin;
1	General	general
2	Vendor	vendor
3	Quest Giver	quest_giver
4	Blacksmith	blacksmith
5	Guard	guard
6	Trainer	trainer
\.


--
-- Data for Name: passive_skill_modifiers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.passive_skill_modifiers (id, skill_id, attribute_slug, modifier_type, value) FROM stdin;
1	6	physical_defense	flat	15
2	7	max_health	percent	8
3	11	max_mana	flat	200
4	12	magical_attack	percent	12
\.


--
-- Data for Name: player_active_effect; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_active_effect (id, player_id, status_effect_id, source_type, source_id, value, applied_at, expires_at, attribute_id, tick_ms, group_id) FROM stdin;
\.


--
-- Data for Name: player_flag; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_flag (player_id, flag_key, int_value, bool_value, updated_at) FROM stdin;
2	explored_fields	0	t	2026-03-17 18:56:09.931882+00
3	explored_wilderness	0	t	2026-03-16 16:46:29.756499+00
3	explored_fields	0	t	2026-03-21 18:18:49.109903+00
3	explored_village	0	t	2026-03-21 19:01:39.204408+00
3	ruins_dying_stranger.received_gift	0	t	2026-04-15 19:23:09.955401+00
2	explored_village	0	t	2026-03-20 19:31:36.562042+00
\.


--
-- Data for Name: player_inventory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_inventory (id, character_id, item_id, quantity, slot_index, durability_current, kill_count) FROM stdin;
221	3	1	8	\N	100	0
3	1	3	5	\N	\N	0
165	3	3	107	\N	\N	0
234	3	10	1	\N	\N	0
236	2	9	1	\N	\N	0
230	2	3	6	\N	\N	0
176	3	15	1	\N	36	42
169	3	16	9600	\N	\N	0
18	3	17	8	\N	\N	0
\.


--
-- Data for Name: player_quest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_quest (player_id, quest_id, state, current_step, progress, updated_at) FROM stdin;
3	1	completed	2	{"have": 2}	2026-04-19 19:35:47.709002+00
\.


--
-- Data for Name: player_skill_cooldown; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_skill_cooldown (character_id, skill_slug, cooldown_ends_at) FROM stdin;
2	blink_home	2026-04-20 16:08:16.068+00
\.


--
-- Data for Name: quest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quest (id, slug, min_level, repeatable, cooldown_sec, giver_npc_id, turnin_npc_id, client_quest_key, reputation_faction_slug, reputation_on_complete, reputation_on_fail) FROM stdin;
1	wolf_hunt_intro	1	t	600	2	2	quest.wolf_hunt_intro	\N	0	0
\.


--
-- Data for Name: quest_reward; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quest_reward (id, quest_id, reward_type, item_id, quantity, amount, is_hidden) FROM stdin;
2	1	exp	\N	0	300	f
1	1	item	3	5	5	f
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
-- Data for Name: skill_active_effects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_active_effects (id, skill_id, effect_slug, effect_type_slug, attribute_slug, value, duration_seconds, tick_ms) FROM stdin;
1	13	battle_cry_phys_atk	buff	physical_attack	25	30	0
\.


--
-- Data for Name: skill_damage_formulas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_damage_formulas (id, slug, effect_type_id) FROM stdin;
1	coeff	1
2	flat_add	1
3	passive_marker	2
4	heal_coeff	6
5	heal_flat	6
6	buff_marker	5
7	teleport_marker	7
\.


--
-- Data for Name: skill_damage_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_damage_types (id, slug) FROM stdin;
1	damage
3	dot
4	hot
2	passive
5	buff
6	heal
7	teleport_respawn
\.


--
-- Data for Name: skill_effect_instances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_effect_instances (id, skill_id, order_idx, target_type_id) FROM stdin;
1	1	1	1
2	2	1	1
3	3	1	1
4	4	1	1
5	5	1	1
6	6	1	1
7	7	1	1
8	8	1	1
9	9	1	1
10	10	1	1
11	11	1	1
12	12	1	1
13	13	1	1
14	14	1	1
15	14	2	1
16	15	1	1
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
7	4	1	1.4	1	0	0	\N
8	4	2	40	1	0	0	\N
9	5	1	1.2	1	0	0	\N
10	5	2	25	1	0	0	\N
11	6	3	0	1	0	0	\N
12	7	3	0	1	0	0	\N
13	8	1	1.6	1	0	0	\N
14	8	2	20	1	0	0	\N
15	9	1	2.0	1	0	0	\N
16	9	2	50	1	0	0	\N
17	10	1	1.5	1	0	0	\N
18	10	2	30	1	0	0	\N
19	11	3	0	1	0	0	\N
20	12	3	0	1	0	0	\N
21	13	6	0	1	0	0	\N
22	14	4	1.5	1	0	0	\N
23	15	5	80	1	0	0	\N
24	16	7	0	1	0	0	\N
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
9	3	1	6	15
10	1	1	3	500
8	3	1	4	4000
12	2	1	4	2000
15	4	1	2	5000
16	4	1	3	1000
18	4	1	5	30
19	4	1	6	2.5
21	5	1	2	12000
22	5	1	3	1000
24	5	1	5	50
25	5	1	6	3.0
26	5	1	7	4.0
28	8	1	2	7000
29	8	1	3	1000
30	8	1	4	2000
31	8	1	5	35
32	8	1	6	15
33	9	1	2	10000
34	9	1	3	1000
35	9	1	4	3000
36	9	1	5	55
37	9	1	6	12
38	10	1	2	15000
39	10	1	3	1000
40	10	1	4	2500
41	10	1	5	70
42	10	1	6	15
43	10	1	7	8.0
6	3	1	5	3
11	1	1	2	1000
17	4	1	4	1000
23	5	1	4	1000
50	10	1	8	100
49	9	1	8	100
48	8	1	8	100
27	5	1	8	100
20	4	1	8	100
46	2	1	8	100
44	1	1	8	1200
14	1	1	4	0
7	3	1	2	5000
13	3	1	3	500
47	3	1	8	300
51	13	1	2	60000
52	13	1	3	1500
53	13	1	4	0
54	13	1	5	30
55	13	1	8	500
56	14	1	2	15000
57	14	1	3	1500
58	14	1	4	2000
59	14	1	5	60
60	14	1	8	500
61	15	1	2	120000
62	15	1	3	1500
63	15	1	4	3000
64	15	1	5	20
65	15	1	8	500
\.


--
-- Data for Name: skill_scale_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_scale_type (id, name, slug) FROM stdin;
1	PhysAtk	physical_attack
2	MagAtk	magical_attack
3	None	none
\.


--
-- Data for Name: skill_school; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_school (id, name, slug) FROM stdin;
1	Physical	physical
2	Magical	magical
3	Fire	fire
4	Ice	ice
5	Nature	nature
6	Arcane	arcane
7	Holy	holy
8	Shadow	shadow
9	None	none
\.


--
-- Data for Name: skills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skills (id, name, slug, scale_stat_id, school_id, animation_name, is_passive) FROM stdin;
1	Basic Attack	basic_attack	1	1	\N	f
2	Power Slash	power_slash	1	1	\N	f
4	Shield Bash	shield_bash	1	1	\N	f
5	Whirlwind	whirlwind	1	1	\N	f
6	Iron Skin	iron_skin	1	1	\N	t
7	Constitution Mastery	constitution_mastery	1	1	\N	t
11	Mana Shield	mana_shield	2	2	\N	t
12	Elemental Mastery	elemental_mastery	2	2	\N	t
3	Fireball	fireball	2	3	\N	f
8	Frost Bolt	frost_bolt	2	4	\N	f
9	Arcane Blast	arcane_blast	2	6	\N	f
10	Chain Lightning	chain_lightning	2	6	\N	f
13	Battle Cry	battle_cry	1	1	\N	f
14	Healing Surge	healing_surge	2	7	\N	f
15	Blink Home	blink_home	3	9	\N	f
\.


--
-- Data for Name: spawn_zone_mobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spawn_zone_mobs (id, spawn_zone_id, mob_id, spawn_count, respawn_time) FROM stdin;
2	2	2	5	00:01:00
1	1	1	25	00:01:00
6	6	1	5	00:01:00
\.


--
-- Data for Name: spawn_zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spawn_zones (zone_id, zone_name, min_spawn_x, min_spawn_y, min_spawn_z, max_spawn_x, max_spawn_y, max_spawn_z, game_zone_id, shape_type, center_x, center_y, inner_radius, outer_radius, exclusion_game_zone_id) FROM stdin;
6	test_circle_spawn	-6368.6914109395075	10816.405407504659	400	-2832.4539132446735	12776.801441062467	800	2	CIRCLE	974.4140051920986	9629.849913509144	0	1025.3821742379987	\N
1	Foxes Nest	5549.27440860249	7606.171800291835	100	8549.27440860249	9106.171800291835	500	2	ANNULUS	-341.30448381723545	-895.4767832193684	5608.287819504758	8172.50264880794	\N
2	Wolf Place	-1347.7795661102573	11060.99297085309	100	719.674578427519	12560.99297085309	500	2	RECT	-314.05249384136914	11810.99297085309	0	0	\N
\.


--
-- Data for Name: status_effect_modifiers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.status_effect_modifiers (id, status_effect_id, attribute_id, modifier_type, value) FROM stdin;
1	1	\N	percent_all	-20
2	3	12	flat	25
\.


--
-- Data for Name: status_effects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.status_effects (id, slug, category, duration_sec) FROM stdin;
1	resurrection_sickness	debuff	120
2	bread_hot	hot	30
3	battle_cry_phys_atk	buff	30
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
-- Data for Name: title_definitions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.title_definitions (id, slug, display_name, description, earn_condition, bonuses, condition_params) FROM stdin;
1	wolf_slayer	Волкобой	Достиг максимального тира бестиария серого волка. Волки тебя не пугают.	bestiary	[{"value": 2.0, "attributeSlug": "physical_attack"}, {"value": 1.0, "attributeSlug": "move_speed"}]	{"minTier": 6, "mobSlug": "GreyWolf"}
2	wolf_hunter	Охотник на волков	Достиг 3-го тира бестиария серого волка. Ты знаешь их повадки.	bestiary	[{"value": 1.0, "attributeSlug": "physical_attack"}]	{"minTier": 3, "mobSlug": "GreyWolf"}
3	goblin_exterminator	Истребитель гоблинов	Достиг 4-го тира бестиария лесного гоблина. Гоблины боятся тебя.	bestiary	[{"value": 1.5, "attributeSlug": "physical_attack"}, {"value": 1.0, "attributeSlug": "physical_defense"}]	{"minTier": 4, "mobSlug": "ForestGoblin"}
4	swordsman	Мечник	Достиг 3-го тира мастерства меча. Клинок — твоё продолжение.	mastery	[{"value": 3.0, "attributeSlug": "physical_attack"}, {"value": 0.5, "attributeSlug": "crit_chance"}]	{"minTier": 3, "masterySlug": "sword_mastery"}
6	bowmaster	Мастер лука	Достиг 3-го тира мастерства лука. Стрелы не знают промаха.	mastery	[{"value": 1.0, "attributeSlug": "crit_chance"}, {"value": 2.0, "attributeSlug": "physical_attack"}]	{"minTier": 3, "masterySlug": "bow_mastery"}
7	friend_of_hunters	Союзник Гильдии Охотников	Достиг статуса союзника в Гильдии Охотников.	reputation	[{"value": 2.0, "attributeSlug": "move_speed"}, {"value": 1.0, "attributeSlug": "physical_attack"}]	{"factionSlug": "hunters", "minTierName": "ally"}
8	city_guardian	Страж Города	Достиг статуса союзника в Городской Страже.	reputation	[{"value": 3.0, "attributeSlug": "physical_defense"}, {"value": 15.0, "attributeSlug": "max_health"}]	{"factionSlug": "city_guard", "minTierName": "ally"}
9	bandit_friend	Свой среди чужих	Достиг статуса союзника в Братстве Бандитов.	reputation	[{"value": 3.0, "attributeSlug": "move_speed"}]	{"factionSlug": "bandits", "minTierName": "ally"}
10	seasoned_adventurer	Бывалый искатель приключений	Достиг 10-го уровня. Путь только начинается.	level	[{"value": 10.0, "attributeSlug": "max_health"}]	{"level": 10}
11	veteran	Ветеран	Достиг 25-го уровня. Опыт не купить за золото.	level	[{"value": 5.0, "attributeSlug": "physical_defense"}, {"value": 20.0, "attributeSlug": "max_health"}]	{"level": 25}
12	first_hunter	Первая охота	Завершил вводное задание по охоте на волков.	quest	[{"value": 1.0, "attributeSlug": "physical_attack"}]	{"questSlug": "wolf_hunt_intro"}
5	archmage	Архимаг	Достиг 4-го тира мастерства посоха. Магия послушна тебе.	mastery	[{"value": 5.0, "attributeSlug": "magical_attack"}]	{"minTier": 4, "masterySlug": "staff_mastery"}
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
1714	4	a2ca4dbb-4a95-48c1-9c6f-0122506025ae	\N	\N	2026-04-19 19:12:28.358783+00	2026-05-19 19:12:28.358783+00	\N
1719	3	10c16ecd-0619-41d9-b466-5b3cf08b2533	\N	\N	2026-04-19 19:35:33.830048+00	2026-05-19 19:35:33.830048+00	\N
1724	4	d29a8cd9-79e8-45ec-a0f4-923144583025	\N	\N	2026-04-19 19:41:59.300892+00	2026-05-19 19:41:59.300892+00	\N
1715	4	e956016a-ccc2-445c-8c4f-c1811cc4ff34	\N	\N	2026-04-19 19:13:13.380118+00	2026-05-19 19:13:13.380118+00	\N
1720	3	8d257410-2ec0-4cc7-9b2d-a8101a978cc1	\N	\N	2026-04-19 19:35:43.5596+00	2026-05-19 19:35:43.5596+00	\N
1725	4	26a9805a-ae6a-4d9b-bb7b-6edcd3235527	\N	\N	2026-04-19 19:42:24.043112+00	2026-05-19 19:42:24.043112+00	\N
1716	4	14afe164-ed0c-4102-ae72-f682e94b8661	\N	\N	2026-04-19 19:13:30.800018+00	2026-05-19 19:13:30.800018+00	\N
1721	4	e4f41eaa-eb8f-4dd8-995f-a433b2d337ed	\N	\N	2026-04-19 19:35:53.240536+00	2026-05-19 19:35:53.240536+00	\N
1717	4	48ba45c5-dea7-4e24-95c4-32c67ca3b72f	\N	\N	2026-04-19 19:27:28.752306+00	2026-05-19 19:27:28.752306+00	\N
1722	4	82210156-9894-4206-b81e-da21b28c5855	\N	\N	2026-04-19 19:36:15.088115+00	2026-05-19 19:36:15.088115+00	\N
1726	4	5a99fea0-2536-45ff-a084-1eb4dd801d75	\N	\N	2026-04-20 16:06:04.237349+00	2026-05-20 16:06:04.237349+00	\N
1718	4	42a1ca4b-ddf5-4fb2-86f5-f61b2620006f	\N	\N	2026-04-19 19:32:33.930978+00	2026-05-19 19:32:33.930978+00	\N
1723	4	699e50b7-b303-43ad-a577-c5e6bf48c49c	\N	\N	2026-04-19 19:37:01.654371+00	2026-05-19 19:37:01.654371+00	\N
1727	4	196e86b0-c043-4ba2-b291-538a0b089c6b	\N	\N	2026-04-20 16:06:29.175749+00	2026-05-20 16:06:29.175749+00	\N
1728	4	4b97bcf4-a584-4973-a2f6-d7d074cc89fb	\N	\N	2026-04-20 16:06:47.820417+00	2026-05-20 16:06:47.820417+00	\N
1713	4	47eadb3e-e8db-4ea2-b5bf-66b98b3d339f	\N	\N	2026-04-19 19:11:38.555448+00	2026-05-19 19:11:38.555448+00	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, login, password, last_login, email, role, created_at, is_active, failed_login_attempts, locked_until, last_login_ip, registration_ip, is_email_verified) FROM stdin;
5	test3	test3	2023-05-04 16:25:31.727922+00	\N	0	2026-03-03 16:16:54.618401+00	t	0	\N	\N	\N	f
3	test1	test1	2026-04-19 19:35:43.554508+00	\N	0	2026-03-03 16:16:54.618401+00	t	0	\N	127.0.0.1	\N	f
4	test2	test2	2026-04-20 16:06:47.814731+00	\N	0	2026-03-03 16:16:54.618401+00	t	0	\N	127.0.0.1	\N	f
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
6	2	18	-1	\N	0	-1	0	\N
7	2	20	-1	\N	0	-1	0	\N
8	2	21	-1	\N	0	-1	0	\N
9	3	22	-1	\N	0	-1	0	\N
10	3	23	-1	\N	0	-1	0	\N
11	3	25	-1	\N	0	-1	0	\N
12	3	26	-1	\N	0	-1	0	\N
\.


--
-- Data for Name: vendor_npc; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendor_npc (id, npc_id, markup_pct) FROM stdin;
1	1	10
2	4	0
3	5	0
\.


--
-- Data for Name: world_object_states; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.world_object_states (object_id, state, depleted_at) FROM stdin;
\.


--
-- Data for Name: world_objects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.world_objects (id, slug, name_key, object_type, scope, pos_x, pos_y, pos_z, rot_z, zone_id, dialogue_id, loot_table_id, required_item_id, interaction_radius, channel_time_sec, respawn_sec, is_active_by_default, min_level, condition_group) FROM stdin;
\.


--
-- Data for Name: zone_event_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zone_event_templates (id, slug, game_zone_id, trigger_type, duration_sec, loot_multiplier, spawn_rate_multiplier, mob_speed_multiplier, announce_key, interval_hours, random_chance_per_hour, has_invasion_wave, invasion_mob_template_id, invasion_wave_count, invasion_champion_template_id, invasion_champion_slug) FROM stdin;
1	wolf_hour	1	random	1200	1.5	1	1.3	event.wolf_hour.announce	0	0.15	f	\N	0	\N	\N
2	merchant_convoy	1	scheduled	900	1	1	1	event.merchant_convoy	6	0	f	\N	0	\N	\N
3	fog_of_twilight	\N	random	1800	1.2	1	0.8	event.fog_of_twilight	0	0.08	f	\N	0	\N	\N
\.


--
-- Data for Name: zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zones (id, slug, name, min_level, max_level, is_pvp, is_safe_zone, min_x, max_x, min_y, max_y, exploration_xp_reward, champion_threshold_kills, shape_type, center_x, center_y, inner_radius, outer_radius) FROM stdin;
5	test-annulus	test-annulus	1	999	f	f	-9397.597686836896	-6455.5758930071315	-4179.679412879304	-1389.2455690536517	100	100	ANNULUS	20950.722530349605	-17000.046904890885	5385.319887443037	7625.2081965622165
2	fields	Fields	1	20	f	f	-5438.206711468296	4555.443380622781	3054.1359757361442	7954.135975736144	100	100	ANNULUS	-440.5078918600502	-890.5384478275864	5314.343027676288	8586.163024291778
1	village	Village	1	10	f	t	-5440.2178821979505	4568.621024817196	-5471.3412259071965	3002.10848639096	100	100	CIRCLE	-368.6564432549312	-962.321990454137	0	4966.320930263775
\.


--
-- Name: character_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_attributes_id_seq', 183, true);


--
-- Name: character_attributes_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_attributes_id_seq1', 26, true);


--
-- Name: character_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_class_id_seq', 2, true);


--
-- Name: character_emotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_emotes_id_seq', 262, true);


--
-- Name: character_equipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_equipment_id_seq', 92, true);


--
-- Name: character_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_position_id_seq', 3, true);


--
-- Name: character_skills_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_skills_id_seq1', 20, true);


--
-- Name: characters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.characters_id_seq', 3, true);


--
-- Name: class_skill_tree_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.class_skill_tree_id_seq', 26, true);


--
-- Name: class_starter_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.class_starter_items_id_seq', 5, true);


--
-- Name: currency_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.currency_transactions_id_seq', 1, false);


--
-- Name: dialogue_edge_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dialogue_edge_id_seq', 144, true);


--
-- Name: dialogue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dialogue_id_seq', 6, true);


--
-- Name: dialogue_node_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dialogue_node_id_seq', 611, true);


--
-- Name: emote_definitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.emote_definitions_id_seq', 13, true);


--
-- Name: exp_for_level_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exp_for_level_id_seq', 10, true);


--
-- Name: factions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.factions_id_seq', 5, true);


--
-- Name: game_analytics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.game_analytics_id_seq', 150, true);


--
-- Name: gm_action_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gm_action_log_id_seq', 1, false);


--
-- Name: item_attributes_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_attributes_mapping_id_seq', 10, true);


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

SELECT pg_catalog.setval('public.item_types_id_seq', 10, true);


--
-- Name: item_use_effects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_use_effects_id_seq', 2, true);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.items_id_seq', 26, true);


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

SELECT pg_catalog.setval('public.mob_stat_id_seq', 192, true);


--
-- Name: npc_ambient_speech_configs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_ambient_speech_configs_id_seq', 1, true);


--
-- Name: npc_ambient_speech_lines_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_ambient_speech_lines_id_seq', 3, true);


--
-- Name: npc_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_attributes_id_seq', 13, true);


--
-- Name: npc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_id_seq', 6, true);


--
-- Name: npc_placements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_placements_id_seq', 12, true);


--
-- Name: npc_skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_skills_id_seq', 2, true);


--
-- Name: npc_trainer_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_trainer_class_id_seq', 2, true);


--
-- Name: npc_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_type_id_seq', 6, true);


--
-- Name: passive_skill_modifiers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.passive_skill_modifiers_id_seq', 1, false);


--
-- Name: player_active_effect_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.player_active_effect_id_seq', 1204, true);


--
-- Name: player_inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.player_inventory_id_seq', 236, true);


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
-- Name: skill_active_effects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_active_effects_id_seq', 1, true);


--
-- Name: skill_effect_instances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_effect_instances_id_seq', 3, true);


--
-- Name: skill_effects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_effects_id_seq', 7, true);


--
-- Name: skill_effects_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_effects_mapping_id_seq', 6, true);


--
-- Name: skill_effects_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_effects_type_id_seq', 7, true);


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

SELECT pg_catalog.setval('public.skills_attributes_mapping_id_seq', 50, true);


--
-- Name: skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skills_id_seq', 12, true);


--
-- Name: spawn_zone_mobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.spawn_zone_mobs_id_seq', 6, true);


--
-- Name: spawn_zones_zone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.spawn_zones_zone_id_seq', 6, true);


--
-- Name: status_effect_modifiers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.status_effect_modifiers_id_seq', 3, true);


--
-- Name: status_effects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.status_effects_id_seq', 4, true);


--
-- Name: target_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.target_type_id_seq', 6, true);


--
-- Name: timed_champion_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.timed_champion_templates_id_seq', 1, false);


--
-- Name: title_definitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.title_definitions_id_seq', 12, true);


--
-- Name: user_bans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_bans_id_seq', 1, false);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_sessions_id_seq', 1728, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 5, true);


--
-- Name: vendor_inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vendor_inventory_id_seq', 27, true);


--
-- Name: vendor_npc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vendor_npc_id_seq', 1, true);


--
-- Name: world_objects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.world_objects_id_seq', 1, false);


--
-- Name: zone_event_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zone_event_templates_id_seq', 3, true);


--
-- Name: zones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zones_id_seq', 5, true);


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
-- Name: character_emotes character_emotes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_emotes
    ADD CONSTRAINT character_emotes_pkey PRIMARY KEY (id);


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
-- Name: character_skill_bar character_skill_bar_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skill_bar
    ADD CONSTRAINT character_skill_bar_pkey PRIMARY KEY (character_id, slot_index);


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
-- Name: character_titles character_titles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_titles
    ADD CONSTRAINT character_titles_pkey PRIMARY KEY (character_id, title_slug);


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
-- Name: class_starter_items class_starter_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_starter_items
    ADD CONSTRAINT class_starter_items_pkey PRIMARY KEY (id);


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
-- Name: emote_definitions emote_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.emote_definitions
    ADD CONSTRAINT emote_definitions_pkey PRIMARY KEY (id);


--
-- Name: emote_definitions emote_definitions_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.emote_definitions
    ADD CONSTRAINT emote_definitions_slug_key UNIQUE (slug);


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
-- Name: game_analytics game_analytics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_analytics
    ADD CONSTRAINT game_analytics_pkey PRIMARY KEY (id);


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
-- Name: npc_ambient_speech_configs npc_ambient_speech_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_ambient_speech_configs
    ADD CONSTRAINT npc_ambient_speech_configs_pkey PRIMARY KEY (id);


--
-- Name: npc_ambient_speech_lines npc_ambient_speech_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_ambient_speech_lines
    ADD CONSTRAINT npc_ambient_speech_lines_pkey PRIMARY KEY (id);


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
-- Name: npc_trainer_class npc_trainer_class_npc_id_class_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_trainer_class
    ADD CONSTRAINT npc_trainer_class_npc_id_class_id_key UNIQUE (npc_id, class_id);


--
-- Name: npc_trainer_class npc_trainer_class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_trainer_class
    ADD CONSTRAINT npc_trainer_class_pkey PRIMARY KEY (id);


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
-- Name: player_skill_cooldown player_skill_cooldown_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_skill_cooldown
    ADD CONSTRAINT player_skill_cooldown_pkey PRIMARY KEY (character_id, skill_slug);


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
-- Name: skill_active_effects skill_active_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_active_effects
    ADD CONSTRAINT skill_active_effects_pkey PRIMARY KEY (id);


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
-- Name: title_definitions title_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.title_definitions
    ADD CONSTRAINT title_definitions_pkey PRIMARY KEY (id);


--
-- Name: title_definitions title_definitions_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.title_definitions
    ADD CONSTRAINT title_definitions_slug_key UNIQUE (slug);


--
-- Name: character_emotes uq_character_emote; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_emotes
    ADD CONSTRAINT uq_character_emote UNIQUE (character_id, emote_slug);


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
-- Name: npc_ambient_speech_configs uq_npc_ambient_config; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_ambient_speech_configs
    ADD CONSTRAINT uq_npc_ambient_config UNIQUE (npc_id);


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
-- Name: world_object_states world_object_states_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.world_object_states
    ADD CONSTRAINT world_object_states_pkey PRIMARY KEY (object_id);


--
-- Name: world_objects world_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.world_objects
    ADD CONSTRAINT world_objects_pkey PRIMARY KEY (id);


--
-- Name: world_objects world_objects_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.world_objects
    ADD CONSTRAINT world_objects_slug_key UNIQUE (slug);


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
-- Name: idx_ambient_lines_npc_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ambient_lines_npc_id ON public.npc_ambient_speech_lines USING btree (npc_id);


--
-- Name: idx_char_mastery_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_char_mastery_char ON public.character_skill_mastery USING btree (character_id);


--
-- Name: idx_char_rep_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_char_rep_char ON public.character_reputation USING btree (character_id);


--
-- Name: idx_char_titles_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_char_titles_char ON public.character_titles USING btree (character_id);


--
-- Name: idx_character_bestiary_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_character_bestiary_char ON public.character_bestiary USING btree (character_id);


--
-- Name: idx_character_emotes_character_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_character_emotes_character_id ON public.character_emotes USING btree (character_id);


--
-- Name: idx_character_pity_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_character_pity_char ON public.character_pity USING btree (character_id);


--
-- Name: idx_class_starter_items_class; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_class_starter_items_class ON public.class_starter_items USING btree (class_id);


--
-- Name: idx_ga_character; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ga_character ON public.game_analytics USING btree (character_id, created_at DESC);


--
-- Name: idx_ga_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ga_created_at ON public.game_analytics USING btree (created_at DESC);


--
-- Name: idx_ga_event_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ga_event_type ON public.game_analytics USING btree (event_type, created_at DESC);


--
-- Name: idx_ga_payload; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ga_payload ON public.game_analytics USING gin (payload);


--
-- Name: idx_ga_session; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ga_session ON public.game_analytics USING btree (session_id);


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
-- Name: idx_skill_bar_character; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_skill_bar_character ON public.character_skill_bar USING btree (character_id);


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
-- Name: idx_world_object_states_state; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_world_object_states_state ON public.world_object_states USING btree (state);


--
-- Name: idx_world_objects_type_scope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_world_objects_type_scope ON public.world_objects USING btree (object_type, scope);


--
-- Name: idx_world_objects_zone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_world_objects_zone ON public.world_objects USING btree (zone_id);


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
-- Name: ix_items_mastery_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_items_mastery_slug ON public.items USING btree (mastery_slug) WHERE (mastery_slug IS NOT NULL);


--
-- Name: ix_mob_active_effect_src_player; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_mob_active_effect_src_player ON public.mob_active_effect USING btree (source_player_id) WHERE (source_player_id IS NOT NULL);


--
-- Name: ix_mob_faction_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_mob_faction_slug ON public.mob USING btree (faction_slug) WHERE (faction_slug IS NOT NULL);


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
-- Name: ix_npc_dialogue_cond_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_npc_dialogue_cond_gin ON public.npc_dialogue USING gin (condition_group) WHERE (condition_group IS NOT NULL);


--
-- Name: ix_npc_faction_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_npc_faction_slug ON public.npc USING btree (faction_slug) WHERE (faction_slug IS NOT NULL);


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
-- Name: ix_psc_char; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_psc_char ON public.player_skill_cooldown USING btree (character_id);


--
-- Name: ix_quest_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_quest_slug ON public.quest USING btree (slug);


--
-- Name: ix_quest_step_q; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_quest_step_q ON public.quest_step USING btree (quest_id, step_index);


--
-- Name: ix_respawn_zones_default; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_respawn_zones_default ON public.respawn_zones USING btree (zone_id, is_default) WHERE (is_default = true);


--
-- Name: ix_respawn_zones_zone_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_respawn_zones_zone_id ON public.respawn_zones USING btree (zone_id);


--
-- Name: ix_timed_champion_mob_tpl; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_timed_champion_mob_tpl ON public.timed_champion_templates USING btree (mob_template_id);


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
-- Name: ix_zone_event_game_zone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_zone_event_game_zone ON public.zone_event_templates USING btree (game_zone_id) WHERE (game_zone_id IS NOT NULL);


--
-- Name: ix_zone_event_invasion_mob; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_zone_event_invasion_mob ON public.zone_event_templates USING btree (invasion_mob_template_id) WHERE (invasion_mob_template_id IS NOT NULL);


--
-- Name: ix_zone_event_trigger_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_zone_event_trigger_type ON public.zone_event_templates USING btree (trigger_type);


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
-- Name: character_emotes character_emotes_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_emotes
    ADD CONSTRAINT character_emotes_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_emotes character_emotes_emote_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_emotes
    ADD CONSTRAINT character_emotes_emote_slug_fkey FOREIGN KEY (emote_slug) REFERENCES public.emote_definitions(slug) ON DELETE CASCADE;


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
-- Name: character_reputation character_reputation_faction_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_reputation
    ADD CONSTRAINT character_reputation_faction_slug_fkey FOREIGN KEY (faction_slug) REFERENCES public.factions(slug);


--
-- Name: character_skill_bar character_skill_bar_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skill_bar
    ADD CONSTRAINT character_skill_bar_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_skill_mastery character_skill_mastery_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skill_mastery
    ADD CONSTRAINT character_skill_mastery_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_skill_mastery character_skill_mastery_mastery_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skill_mastery
    ADD CONSTRAINT character_skill_mastery_mastery_slug_fkey FOREIGN KEY (mastery_slug) REFERENCES public.mastery_definitions(slug);


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
-- Name: character_titles character_titles_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_titles
    ADD CONSTRAINT character_titles_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_titles character_titles_title_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_titles
    ADD CONSTRAINT character_titles_title_slug_fkey FOREIGN KEY (title_slug) REFERENCES public.title_definitions(slug) ON DELETE CASCADE;


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
-- Name: class_skill_tree class_skill_tree_prerequisite_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT class_skill_tree_prerequisite_skill_id_fkey FOREIGN KEY (prerequisite_skill_id) REFERENCES public.skills(id) ON DELETE SET NULL;


--
-- Name: class_skill_tree class_skill_tree_skill_book_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT class_skill_tree_skill_book_item_id_fkey FOREIGN KEY (skill_book_item_id) REFERENCES public.items(id) ON DELETE SET NULL;


--
-- Name: class_skill_tree class_skill_tree_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT class_skill_tree_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);


--
-- Name: class_starter_items class_starter_items_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_starter_items
    ADD CONSTRAINT class_starter_items_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id) ON DELETE CASCADE;


--
-- Name: class_starter_items class_starter_items_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_starter_items
    ADD CONSTRAINT class_starter_items_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


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
-- Name: users fk_users_role; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_role FOREIGN KEY (role) REFERENCES public.user_roles(id);


--
-- Name: game_analytics game_analytics_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_analytics
    ADD CONSTRAINT game_analytics_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE SET NULL;


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
-- Name: items items_mastery_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_mastery_slug_fkey FOREIGN KEY (mastery_slug) REFERENCES public.mastery_definitions(slug);


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
-- Name: mob_active_effect mob_active_effect_source_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_active_effect
    ADD CONSTRAINT mob_active_effect_source_player_id_fkey FOREIGN KEY (source_player_id) REFERENCES public.characters(id) ON DELETE SET NULL;


--
-- Name: mob mob_faction_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_faction_slug_fkey FOREIGN KEY (faction_slug) REFERENCES public.factions(slug);


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
-- Name: npc_ambient_speech_configs npc_ambient_speech_configs_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_ambient_speech_configs
    ADD CONSTRAINT npc_ambient_speech_configs_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: npc_ambient_speech_lines npc_ambient_speech_lines_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_ambient_speech_lines
    ADD CONSTRAINT npc_ambient_speech_lines_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


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
-- Name: npc npc_faction_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_faction_slug_fkey FOREIGN KEY (faction_slug) REFERENCES public.factions(slug);


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
-- Name: npc_trainer_class npc_trainer_class_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_trainer_class
    ADD CONSTRAINT npc_trainer_class_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id) ON DELETE CASCADE;


--
-- Name: npc_trainer_class npc_trainer_class_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_trainer_class
    ADD CONSTRAINT npc_trainer_class_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: passive_skill_modifiers passive_skill_modifiers_attribute_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passive_skill_modifiers
    ADD CONSTRAINT passive_skill_modifiers_attribute_slug_fkey FOREIGN KEY (attribute_slug) REFERENCES public.entity_attributes(slug);


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
-- Name: player_skill_cooldown player_skill_cooldown_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_skill_cooldown
    ADD CONSTRAINT player_skill_cooldown_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


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
-- Name: respawn_zones respawn_zones_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.respawn_zones
    ADD CONSTRAINT respawn_zones_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: skill_active_effects skill_active_effects_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_active_effects
    ADD CONSTRAINT skill_active_effects_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id) ON DELETE CASCADE;


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
-- Name: skills skills_scale_stat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_scale_stat_id_fkey FOREIGN KEY (scale_stat_id) REFERENCES public.skill_scale_type(id);


--
-- Name: skills skills_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.skill_school(id);


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
-- Name: spawn_zones spawn_zones_exclusion_game_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spawn_zones
    ADD CONSTRAINT spawn_zones_exclusion_game_zone_id_fkey FOREIGN KEY (exclusion_game_zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;


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
-- Name: timed_champion_templates timed_champion_templates_mob_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timed_champion_templates
    ADD CONSTRAINT timed_champion_templates_mob_template_id_fkey FOREIGN KEY (mob_template_id) REFERENCES public.mob(id);


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
-- Name: world_object_states world_object_states_object_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.world_object_states
    ADD CONSTRAINT world_object_states_object_id_fkey FOREIGN KEY (object_id) REFERENCES public.world_objects(id) ON DELETE CASCADE;


--
-- Name: world_objects world_objects_dialogue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.world_objects
    ADD CONSTRAINT world_objects_dialogue_id_fkey FOREIGN KEY (dialogue_id) REFERENCES public.dialogue(id) ON DELETE SET NULL;


--
-- Name: world_objects world_objects_required_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.world_objects
    ADD CONSTRAINT world_objects_required_item_id_fkey FOREIGN KEY (required_item_id) REFERENCES public.items(id) ON DELETE SET NULL;


--
-- Name: world_objects world_objects_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.world_objects
    ADD CONSTRAINT world_objects_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;


--
-- Name: zone_event_templates zone_event_templates_game_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zone_event_templates
    ADD CONSTRAINT zone_event_templates_game_zone_id_fkey FOREIGN KEY (game_zone_id) REFERENCES public.zones(id);


--
-- Name: zone_event_templates zone_event_templates_invasion_champion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zone_event_templates
    ADD CONSTRAINT zone_event_templates_invasion_champion_id_fkey FOREIGN KEY (invasion_champion_template_id) REFERENCES public.timed_champion_templates(id);


--
-- Name: zone_event_templates zone_event_templates_invasion_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zone_event_templates
    ADD CONSTRAINT zone_event_templates_invasion_mob_id_fkey FOREIGN KEY (invasion_mob_template_id) REFERENCES public.mob(id);


--
-- PostgreSQL database dump complete
--

