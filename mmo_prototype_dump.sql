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
-- Name: effect_modifier_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.effect_modifier_type AS ENUM (
    'flat',
    'percent',
    'percent_all'
);


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
-- Name: status_effect_category; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.status_effect_category AS ENUM (
    'buff',
    'debuff',
    'dot',
    'hot',
    'cc'
);


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
    slug character varying(100) NOT NULL,
    is_percentage boolean DEFAULT false NOT NULL
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
-- Name: character_bestiary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_bestiary (
    character_id integer NOT NULL,
    mob_template_id integer NOT NULL,
    kill_count integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE character_bestiary; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_bestiary IS 'Бестиарий персонажа: сколько раз игрок убил каждый шаблон моба. Используется для разблокировки записей бестиария и potential pity-механик.';


--
-- Name: COLUMN character_bestiary.character_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_bestiary.character_id IS 'FK → characters.id. Персонаж-владелец записи бестиария.';


--
-- Name: COLUMN character_bestiary.mob_template_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_bestiary.mob_template_id IS 'FK → mob.id. Шаблон моба (не runtime-инстанс).';


--
-- Name: COLUMN character_bestiary.kill_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_bestiary.kill_count IS 'Суммарное количество убийств данного моба персонажем.';


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
-- Name: character_emotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_emotes (
    id integer NOT NULL,
    character_id integer NOT NULL,
    emote_slug character varying(64) NOT NULL,
    unlocked_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE character_emotes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_emotes IS 'Per-character unlocked emotes; default emotes are seeded here too';


--
-- Name: character_emotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.character_emotes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: character_emotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.character_emotes_id_seq OWNED BY public.character_emotes.id;


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
-- Name: character_pity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_pity (
    character_id integer NOT NULL,
    item_id integer NOT NULL,
    kill_count integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE character_pity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_pity IS 'Pity-счётчики редких дропов. Хранит количество убийств без выпадения конкретного предмета, чтобы гарантировать дроп при превышении порога (гарантированный лут).';


--
-- Name: COLUMN character_pity.character_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_pity.character_id IS 'FK → characters.id. Персонаж.';


--
-- Name: COLUMN character_pity.item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_pity.item_id IS 'FK → items.id. Предмет с pity-механикой (редкий дроп).';


--
-- Name: COLUMN character_pity.kill_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_pity.kill_count IS 'Счётчик убийств без выпадения данного предмета. Сбрасывается в 0 после получения предмета.';


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
-- Name: character_reputation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_reputation (
    character_id integer NOT NULL,
    faction_slug character varying(60) NOT NULL,
    value integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE character_reputation; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_reputation IS 'Репутация персонажа у каждой фракции. Положительные значения = союзник, отрицательные = враг. Используется для диалоговых условий и доступа к контенту.';


--
-- Name: COLUMN character_reputation.character_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_reputation.character_id IS 'FK → characters.id. Персонаж.';


--
-- Name: COLUMN character_reputation.faction_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_reputation.faction_slug IS 'FK → factions.slug. Фракция.';


--
-- Name: COLUMN character_reputation.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_reputation.value IS 'Очки репутации. > 0 = союзник, < 0 = враг. Диапазон определяется дизайном.';


--
-- Name: character_skill_bar; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_skill_bar (
    character_id integer NOT NULL,
    slot_index smallint NOT NULL,
    skill_slug character varying(64) NOT NULL,
    CONSTRAINT character_skill_bar_slot_index_check CHECK (((slot_index >= 0) AND (slot_index < 12)))
);


--
-- Name: TABLE character_skill_bar; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_skill_bar IS 'Stores which skill slug is assigned to each hotbar slot per character. Absent rows = empty slot.';


--
-- Name: COLUMN character_skill_bar.slot_index; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_skill_bar.slot_index IS 'Zero-based hotbar slot index (0–11). Max 12 slots enforced by CHECK constraint.';


--
-- Name: COLUMN character_skill_bar.skill_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_skill_bar.skill_slug IS 'Slug of the skill assigned to this slot. Must be a known skill slug.';


--
-- Name: character_skill_mastery; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_skill_mastery (
    character_id integer NOT NULL,
    mastery_slug character varying(60) NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


--
-- Name: TABLE character_skill_mastery; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_skill_mastery IS 'Накопленные очки мастерства персонажа по типу оружия/школы. Например, sword_mastery растёт при ударах мечом и влияет на бонусы к урону.';


--
-- Name: COLUMN character_skill_mastery.character_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_skill_mastery.character_id IS 'FK → characters.id. Персонаж.';


--
-- Name: COLUMN character_skill_mastery.mastery_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_skill_mastery.mastery_slug IS 'FK → mastery_definitions.slug. Тип мастерства.';


--
-- Name: COLUMN character_skill_mastery.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_skill_mastery.value IS 'Текущие накопленные очки мастерства. Ограничены mastery_definitions.max_value.';


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
-- Name: character_titles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_titles (
    character_id integer NOT NULL,
    title_slug character varying(80) NOT NULL,
    equipped boolean DEFAULT false NOT NULL,
    earned_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE character_titles; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.character_titles IS 'Титулы, заработанные персонажем. equipped=true означает, что этот титул отображается над именем в мире. Только один может быть активным одновременно.';


--
-- Name: COLUMN character_titles.character_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_titles.character_id IS 'FK → characters.id. Персонаж.';


--
-- Name: COLUMN character_titles.title_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_titles.title_slug IS 'FK → title_definitions.slug. Полученный титул.';


--
-- Name: COLUMN character_titles.equipped; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_titles.equipped IS 'TRUE = этот титул отображается над именем персонажа в игровом мире.';


--
-- Name: COLUMN character_titles.earned_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.character_titles.earned_at IS 'Временная метка получения титула.';


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
    appearance jsonb,
    experience_debt integer DEFAULT 0 NOT NULL
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
    is_default boolean DEFAULT false NOT NULL,
    prerequisite_skill_id integer,
    skill_point_cost smallint DEFAULT 0 NOT NULL,
    gold_cost integer DEFAULT 0 NOT NULL,
    max_level smallint DEFAULT 1 NOT NULL,
    requires_book boolean DEFAULT false NOT NULL,
    skill_book_item_id integer
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
-- Name: COLUMN class_skill_tree.prerequisite_skill_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_skill_tree.prerequisite_skill_id IS 'Skill that must already be learned before this one becomes available. NULL = no prereq.';


--
-- Name: COLUMN class_skill_tree.skill_point_cost; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_skill_tree.skill_point_cost IS 'Skill points consumed when this skill is learned. 0 = free (default skills).';


--
-- Name: COLUMN class_skill_tree.gold_cost; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_skill_tree.gold_cost IS 'Gold (gold_coin quantity) required to learn this skill. 0 = no gold cost.';


--
-- Name: COLUMN class_skill_tree.max_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_skill_tree.max_level IS 'Maximum level to which this skill can be upgraded. 1 = cannot be upgraded.';


--
-- Name: COLUMN class_skill_tree.requires_book; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_skill_tree.requires_book IS 'If TRUE the player must have the skill_book_item_id item in inventory to learn.';


--
-- Name: COLUMN class_skill_tree.skill_book_item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.class_skill_tree.skill_book_item_id IS 'The skill book item that is consumed when learning this skill (if requires_book=TRUE).';


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
-- Name: damage_elements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.damage_elements (
    slug character varying(64) NOT NULL
);


--
-- Name: TABLE damage_elements; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.damage_elements IS 'Справочник элементов урона: fire, ice, physical, shadow, holy и т.д. PK — slug. Используется в mob_resistances и mob_weaknesses.';


--
-- Name: COLUMN damage_elements.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.damage_elements.slug IS 'PK. Уникальный код элемента урона: physical, fire, ice, shadow, holy, arcane и т.д.';


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
-- Name: emote_definitions; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: TABLE emote_definitions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.emote_definitions IS 'Static catalog of player emote / animation definitions';


--
-- Name: COLUMN emote_definitions.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.emote_definitions.slug IS 'Unique snake_case key used in packets, e.g. dance_silly';


--
-- Name: COLUMN emote_definitions.animation_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.emote_definitions.animation_name IS 'Name of the client-side animation clip to play';


--
-- Name: COLUMN emote_definitions.category; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.emote_definitions.category IS 'UI grouping: basic | social | dance | sit | ...';


--
-- Name: COLUMN emote_definitions.is_default; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.emote_definitions.is_default IS 'TRUE = all characters own this emote automatically';


--
-- Name: emote_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.emote_definitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emote_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.emote_definitions_id_seq OWNED BY public.emote_definitions.id;


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
-- Name: factions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.factions (
    id integer NOT NULL,
    slug character varying(60) NOT NULL,
    name character varying(120) NOT NULL
);


--
-- Name: TABLE factions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.factions IS 'Справочник фракций игрового мира. Мобы и NPC принадлежат фракции (faction_slug). Репутация персонажа ко фракции хранится в character_reputation.';


--
-- Name: COLUMN factions.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.factions.id IS 'Суррогатный PK.';


--
-- Name: COLUMN factions.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.factions.slug IS 'Уникальный код фракции. Используется как FK в mob, npc, character_reputation.';


--
-- Name: COLUMN factions.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.factions.name IS 'Отображаемое имя фракции.';


--
-- Name: factions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.factions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: factions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.factions_id_seq OWNED BY public.factions.id;


--
-- Name: game_analytics; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: TABLE game_analytics; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.game_analytics IS 'Append-only event log for playtest analytics. Written by Game Server; never updated or deleted manually.';


--
-- Name: COLUMN game_analytics.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_analytics.id IS 'Auto-increment primary key.';


--
-- Name: COLUMN game_analytics.event_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_analytics.event_type IS 'Type of event: session_start, session_end, level_up, player_death, quest_accept, quest_complete, quest_abandon, mob_killed, item_acquired, gold_change, skill_used, etc.';


--
-- Name: COLUMN game_analytics.character_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_analytics.character_id IS 'FK → characters.id. SET NULL on character deletion so historic rows are preserved.';


--
-- Name: COLUMN game_analytics.session_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_analytics.session_id IS 'Server-generated session token "sess_{characterId}_{unix_ms}". Generated once on joinGameCharacter and reused for every event in that play session.';


--
-- Name: COLUMN game_analytics.level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_analytics.level IS 'Character level at the moment the event occurred. Direct column (not in payload) for fast GROUP BY / filter queries.';


--
-- Name: COLUMN game_analytics.zone_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_analytics.zone_id IS 'Zone/chunk where the event occurred. 0 = unknown/global.';


--
-- Name: COLUMN game_analytics.payload; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_analytics.payload IS 'Event-specific JSONB. Schema varies by event_type — see analytics-system-plan.md.';


--
-- Name: COLUMN game_analytics.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_analytics.created_at IS 'Server-side UTC timestamp when the row was inserted.';


--
-- Name: game_analytics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_analytics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_analytics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_analytics_id_seq OWNED BY public.game_analytics.id;


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
-- Name: item_class_restrictions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_class_restrictions (
    item_id integer NOT NULL,
    class_id integer NOT NULL
);


--
-- Name: TABLE item_class_restrictions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.item_class_restrictions IS 'Ограничения предмета по классу персонажа. Если для предмета есть хотя бы одна запись — предмет может использовать только указанный класс.';


--
-- Name: COLUMN item_class_restrictions.item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_class_restrictions.item_id IS 'FK → items.id. Предмет с ограничением по классу.';


--
-- Name: COLUMN item_class_restrictions.class_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_class_restrictions.class_id IS 'FK → character_class.id. Класс, которому разрешён данный предмет.';


--
-- Name: item_set_bonuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_set_bonuses (
    id integer NOT NULL,
    set_id integer NOT NULL,
    pieces_required integer NOT NULL,
    attribute_id integer NOT NULL,
    bonus_value integer NOT NULL
);


--
-- Name: TABLE item_set_bonuses; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.item_set_bonuses IS 'Сетовые бонусы: бонус к атрибуту, который даётся при надевании pieces_required предметов из одного сета. Несколько строк на сет для разных порогов.';


--
-- Name: COLUMN item_set_bonuses.set_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_set_bonuses.set_id IS 'FK → item_sets.id. Набор, к которому относится бонус.';


--
-- Name: COLUMN item_set_bonuses.pieces_required; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_set_bonuses.pieces_required IS 'Минимальное количество предметов набора для активации этого бонуса.';


--
-- Name: COLUMN item_set_bonuses.attribute_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_set_bonuses.attribute_id IS 'FK → entity_attributes.id. Атрибут, к которому прибавляется бонус.';


--
-- Name: COLUMN item_set_bonuses.bonus_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_set_bonuses.bonus_value IS 'Величина прибавки к атрибуту при активации бонуса.';


--
-- Name: item_set_bonuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_set_bonuses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_set_bonuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_set_bonuses_id_seq OWNED BY public.item_set_bonuses.id;


--
-- Name: item_set_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_set_members (
    set_id integer NOT NULL,
    item_id integer NOT NULL
);


--
-- Name: TABLE item_set_members; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.item_set_members IS 'Состав сетов: какие предметы входят в набор. Один предмет может быть только в одном сете.';


--
-- Name: COLUMN item_set_members.set_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_set_members.set_id IS 'FK → item_sets.id. Набор.';


--
-- Name: COLUMN item_set_members.item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_set_members.item_id IS 'FK → items.id. Предмет, входящий в набор.';


--
-- Name: item_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_sets (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    slug character varying(128) NOT NULL
);


--
-- Name: TABLE item_sets; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.item_sets IS 'Именованные наборы предметов (сеты). Бонусы за сборку набора хранятся в item_set_bonuses.';


--
-- Name: COLUMN item_sets.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_sets.id IS 'Суррогатный PK.';


--
-- Name: COLUMN item_sets.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_sets.name IS 'Отображаемое имя набора.';


--
-- Name: COLUMN item_sets.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_sets.slug IS 'Уникальный код набора: используется в game-server и клиентском UI.';


--
-- Name: item_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_sets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_sets_id_seq OWNED BY public.item_sets.id;


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
-- Name: item_use_effects; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: TABLE item_use_effects; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.item_use_effects IS 'Эффекты, применяемые при использовании предмета (зелье, еда). is_instant=true → разовое мгновенное применение; false → эффект с длительностью и тиками.';


--
-- Name: COLUMN item_use_effects.item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_use_effects.item_id IS 'FK → items.id. Предмет, за которым закреплён эффект.';


--
-- Name: COLUMN item_use_effects.effect_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_use_effects.effect_slug IS 'Идентификатор эффекта (произвольный slug или ссылка на status_effects.slug).';


--
-- Name: COLUMN item_use_effects.attribute_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_use_effects.attribute_slug IS 'Атрибут-цель эффекта (ссылается на entity_attributes.slug).';


--
-- Name: COLUMN item_use_effects.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_use_effects.value IS 'Числовое значение изменения атрибута.';


--
-- Name: COLUMN item_use_effects.is_instant; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_use_effects.is_instant IS 'TRUE = мгновенное применение (зелье). FALSE = длительный эффект.';


--
-- Name: COLUMN item_use_effects.duration_seconds; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_use_effects.duration_seconds IS 'Продолжительность эффекта в секундах (0 для мгновенных).';


--
-- Name: COLUMN item_use_effects.tick_ms; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_use_effects.tick_ms IS 'Интервал тика в мс для периодических эффектов (0 для мгновенных).';


--
-- Name: COLUMN item_use_effects.cooldown_seconds; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.item_use_effects.cooldown_seconds IS 'Кулдаун предмета после использования в секундах.';


--
-- Name: item_use_effects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_use_effects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_use_effects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_use_effects_id_seq OWNED BY public.item_use_effects.id;


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
    is_usable boolean DEFAULT false NOT NULL,
    is_two_handed boolean DEFAULT false NOT NULL,
    mastery_slug character varying(60) DEFAULT NULL::character varying
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
-- Name: COLUMN items.mastery_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.items.mastery_slug IS 'FK → mastery_definitions.slug. Требуемый тип мастерства для использования/экипировки предмета. NULL = без требований к мастерству.';


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
-- Name: mastery_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mastery_definitions (
    slug character varying(60) NOT NULL,
    name character varying(120) NOT NULL,
    weapon_type_slug character varying(60) DEFAULT NULL::character varying,
    max_value double precision DEFAULT 100.0 NOT NULL
);


--
-- Name: TABLE mastery_definitions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mastery_definitions IS 'Справочник типов мастерства оружия/магии (sword, bow, fire_magic и т.д.). PK — slug. max_value задаёт капу накопления.';


--
-- Name: COLUMN mastery_definitions.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mastery_definitions.slug IS 'PK. Уникальный код типа мастерства: sword, bow, fire_magic и т.д.';


--
-- Name: COLUMN mastery_definitions.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mastery_definitions.name IS 'Отображаемое имя мастерства.';


--
-- Name: COLUMN mastery_definitions.weapon_type_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mastery_definitions.weapon_type_slug IS 'NULL = общая мастерства; иначе — привязана к конкретному типу оружия.';


--
-- Name: COLUMN mastery_definitions.max_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mastery_definitions.max_value IS 'Максимальный уровень накопления очков мастерства (капа).';


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

COMMENT ON COLUMN public.mob_active_effect.source_player_id IS 'FK → characters.id. Персонаж, наложивший эффект на моба. NULL = эффект от зоны, квеста или системы.';


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
    loot_tier character varying(32) DEFAULT 'common'::character varying NOT NULL,
    CONSTRAINT mob_loot_info_loot_tier_check CHECK (((loot_tier)::text = ANY ((ARRAY['common'::character varying, 'uncommon'::character varying, 'rare'::character varying, 'very_rare'::character varying])::text[]))),
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
-- Name: mob_resistances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mob_resistances (
    mob_id integer NOT NULL,
    element_slug character varying(64) NOT NULL
);


--
-- Name: TABLE mob_resistances; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mob_resistances IS 'Сопротивления моба к элементам урона. Значение сопротивления задаётся логикой combat_calculator в chunk-server согласно записи в этой таблице.';


--
-- Name: COLUMN mob_resistances.mob_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_resistances.mob_id IS 'FK → mob.id. Шаблон моба.';


--
-- Name: COLUMN mob_resistances.element_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_resistances.element_slug IS 'FK → damage_elements.slug. Элемент, к которому у моба есть сопротивление.';


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
-- Name: mob_weaknesses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mob_weaknesses (
    mob_id integer NOT NULL,
    element_slug character varying(64) NOT NULL
);


--
-- Name: TABLE mob_weaknesses; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mob_weaknesses IS 'Уязвимости моба к элементам урона. При попадании атакой уязвимого элемента chunk-server применяет множитель урона.';


--
-- Name: COLUMN mob_weaknesses.mob_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_weaknesses.mob_id IS 'FK → mob.id. Шаблон моба.';


--
-- Name: COLUMN mob_weaknesses.element_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mob_weaknesses.element_slug IS 'FK → damage_elements.slug. Элемент, к которому у моба есть уязвимость.';


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
    npc_type integer DEFAULT 1 NOT NULL,
    faction_slug character varying(60) DEFAULT NULL::character varying
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
-- Name: npc_ambient_speech_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.npc_ambient_speech_configs (
    id integer NOT NULL,
    npc_id integer NOT NULL,
    min_interval_sec integer DEFAULT 20 NOT NULL,
    max_interval_sec integer DEFAULT 60 NOT NULL
);


--
-- Name: TABLE npc_ambient_speech_configs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.npc_ambient_speech_configs IS 'Per-NPC ambient speech timing configuration.';


--
-- Name: COLUMN npc_ambient_speech_configs.npc_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_ambient_speech_configs.npc_id IS 'FK to npcs.id. One config per NPC.';


--
-- Name: COLUMN npc_ambient_speech_configs.min_interval_sec; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_ambient_speech_configs.min_interval_sec IS 'Minimum interval (seconds) between periodic lines on client.';


--
-- Name: COLUMN npc_ambient_speech_configs.max_interval_sec; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_ambient_speech_configs.max_interval_sec IS 'Maximum interval (seconds) between periodic lines on client.';


--
-- Name: npc_ambient_speech_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.npc_ambient_speech_configs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: npc_ambient_speech_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.npc_ambient_speech_configs_id_seq OWNED BY public.npc_ambient_speech_configs.id;


--
-- Name: npc_ambient_speech_lines; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: TABLE npc_ambient_speech_lines; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.npc_ambient_speech_lines IS 'Individual ambient speech lines for NPCs.';


--
-- Name: COLUMN npc_ambient_speech_lines.line_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.line_key IS 'Localisation key sent to client, e.g. npc.blacksmith.idle_1';


--
-- Name: COLUMN npc_ambient_speech_lines.trigger_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.trigger_type IS '"periodic" = fired by client timer; "proximity" = fired once on player approach.';


--
-- Name: COLUMN npc_ambient_speech_lines.trigger_radius; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.trigger_radius IS 'Trigger / display radius in world units (used for proximity trigger and UI culling).';


--
-- Name: COLUMN npc_ambient_speech_lines.priority; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.priority IS 'Highest-priority non-empty pool is used. Within a pool, lines are weighted-random.';


--
-- Name: COLUMN npc_ambient_speech_lines.weight; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.weight IS 'Relative weight for weighted-random selection within same priority group.';


--
-- Name: COLUMN npc_ambient_speech_lines.cooldown_sec; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.cooldown_sec IS 'Per-client cooldown (seconds) before this specific line may show again.';


--
-- Name: COLUMN npc_ambient_speech_lines.condition_group; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.npc_ambient_speech_lines.condition_group IS 'Optional JSONB condition tree compatible with DialogueConditionEvaluator. NULL = always show.';


--
-- Name: npc_ambient_speech_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.npc_ambient_speech_lines_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: npc_ambient_speech_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.npc_ambient_speech_lines_id_seq OWNED BY public.npc_ambient_speech_lines.id;


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
-- Name: npc_trainer_class; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.npc_trainer_class (
    id integer NOT NULL,
    npc_id integer NOT NULL,
    class_id integer NOT NULL
);


--
-- Name: TABLE npc_trainer_class; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.npc_trainer_class IS 'Maps trainer NPC ids to the class whose skills they can teach. Used by game-server to build setTrainerData payload sent to chunk-servers at startup.';


--
-- Name: npc_trainer_class_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.npc_trainer_class_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: npc_trainer_class_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.npc_trainer_class_id_seq OWNED BY public.npc_trainer_class.id;


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
-- Name: passive_skill_modifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.passive_skill_modifiers (
    id integer NOT NULL,
    skill_id integer NOT NULL,
    attribute_slug text NOT NULL,
    modifier_type text DEFAULT 'flat'::text NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT passive_skill_modifiers_modifier_type_check CHECK ((modifier_type = ANY (ARRAY['flat'::text, 'percent'::text])))
);


--
-- Name: TABLE passive_skill_modifiers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.passive_skill_modifiers IS 'Stat modifiers granted by passive skills. Loaded by game server on character join.';


--
-- Name: COLUMN passive_skill_modifiers.modifier_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.passive_skill_modifiers.modifier_type IS 'flat = additive delta; percent = percent of base value';


--
-- Name: COLUMN passive_skill_modifiers.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.passive_skill_modifiers.value IS 'Magnitude. Negative = penalty. Percent: -20 means -20 %.';


--
-- Name: passive_skill_modifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.passive_skill_modifiers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: passive_skill_modifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.passive_skill_modifiers_id_seq OWNED BY public.passive_skill_modifiers.id;


--
-- Name: player_active_effect; Type: TABLE; Schema: public; Owner: -
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
-- Name: COLUMN player_active_effect.status_effect_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_active_effect.status_effect_id IS 'FK to status_effects.id — the named status condition';


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
-- Name: COLUMN player_active_effect.group_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.player_active_effect.group_id IS 'Groups rows belonging to the same multi-attribute effect instance. NULL = single-row effect.';


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
    character_id bigint,
    item_id bigint NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    slot_index smallint,
    durability_current integer,
    kill_count integer DEFAULT 0 NOT NULL
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
    client_quest_key text,
    reputation_faction_slug character varying(64) DEFAULT NULL::character varying,
    reputation_on_complete integer DEFAULT 0 NOT NULL,
    reputation_on_fail integer DEFAULT 0 NOT NULL
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
    is_hidden boolean DEFAULT false NOT NULL,
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
-- Name: COLUMN quest_reward.is_hidden; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quest_reward.is_hidden IS 'TRUE = client displays "???" instead of item/amount until quest_turned_in. Revealed in the rewardsReceived array of the quest_turned_in notification.';


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
    completion_mode text DEFAULT 'auto'::text NOT NULL,
    CONSTRAINT quest_step_completion_mode_ck CHECK ((completion_mode = ANY (ARRAY['auto'::text, 'manual'::text]))),
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
-- Name: respawn_zones; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: TABLE respawn_zones; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.respawn_zones IS 'Точки возрождения персонажей в зонах. is_default=true — используется при первом входе или смерти без выбранной точки. Несколько точек на зону допустимо.';


--
-- Name: COLUMN respawn_zones.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.respawn_zones.id IS 'Суррогатный PK.';


--
-- Name: COLUMN respawn_zones.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.respawn_zones.name IS 'Отображаемое название точки возрождения.';


--
-- Name: COLUMN respawn_zones.x; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.respawn_zones.x IS 'X-координата точки возрождения.';


--
-- Name: COLUMN respawn_zones.y; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.respawn_zones.y IS 'Y-координата точки возрождения.';


--
-- Name: COLUMN respawn_zones.z; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.respawn_zones.z IS 'Z-координата точки возрождения.';


--
-- Name: COLUMN respawn_zones.zone_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.respawn_zones.zone_id IS 'FK → zones.id. Зона, к которой принадлежит точка возрождения.';


--
-- Name: COLUMN respawn_zones.is_default; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.respawn_zones.is_default IS 'TRUE = эта точка используется по умолчанию при первом входе или смерти без явно выбранной точки.';


--
-- Name: respawn_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.respawn_zones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: respawn_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.respawn_zones_id_seq OWNED BY public.respawn_zones.id;


--
-- Name: skill_damage_formulas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_damage_formulas (
    id integer NOT NULL,
    slug text NOT NULL,
    effect_type_id integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE skill_damage_formulas; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skill_damage_formulas IS 'Определения конкретных эффектов с типом и базовыми параметрами';


--
-- Name: skill_damage_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_damage_types (
    id integer NOT NULL,
    slug text NOT NULL
);


--
-- Name: TABLE skill_damage_types; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.skill_damage_types IS 'Категории эффектов скиллов (урон, исцеление, дебафф и т.д.)';


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

ALTER SEQUENCE public.skill_effects_id_seq OWNED BY public.skill_damage_formulas.id;


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

ALTER SEQUENCE public.skill_effects_type_id_seq OWNED BY public.skill_damage_types.id;


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
    school_id integer DEFAULT 1 NOT NULL,
    animation_name character varying(100) DEFAULT NULL::character varying,
    is_passive boolean DEFAULT false NOT NULL
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
-- Name: COLUMN skills.animation_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.animation_name IS 'Название анимационного клипа (Unity Animator state), проигрываемого на кастере при применении скилла. NULL = клиент использует дефолтную анимацию.';


--
-- Name: COLUMN skills.is_passive; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.is_passive IS 'TRUE = always-on passive; no hotbar slot, never cast actively.';


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

CREATE TYPE public.spawn_zone_shape AS ENUM ('RECT', 'CIRCLE', 'ANNULUS');

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
    shape_type public.spawn_zone_shape NOT NULL DEFAULT 'RECT',
    center_x double precision NOT NULL DEFAULT 0,
    center_y double precision NOT NULL DEFAULT 0,
    inner_radius double precision NOT NULL DEFAULT 0,
    outer_radius double precision NOT NULL DEFAULT 0,
    exclusion_game_zone_id integer
);


--
-- Name: TABLE spawn_zones; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.spawn_zones IS 'Геометрия зон спавна. Три варианта: RECT (AABB), CIRCLE (диск), ANNULUS (кольцо). Квоты мобов — в spawn_zone_mobs.';

COMMENT ON COLUMN public.spawn_zones.shape_type IS 'RECT = AABB (min/max corners); CIRCLE = filled disc (center_x/y + outer_radius); ANNULUS = ring (center_x/y + inner_radius + outer_radius).';
COMMENT ON COLUMN public.spawn_zones.center_x IS 'Центр зоны X. Обязателен для CIRCLE и ANNULUS. Для RECT вычисляется как (min+max)/2.';
COMMENT ON COLUMN public.spawn_zones.center_y IS 'Центр зоны Y.';
COMMENT ON COLUMN public.spawn_zones.inner_radius IS 'ANNULUS: внутренний радиус исключения. Спавн внутри этого радиуса запрещён.';
COMMENT ON COLUMN public.spawn_zones.outer_radius IS 'CIRCLE/ANNULUS: внешний радиус зоны спавна.';
COMMENT ON COLUMN public.spawn_zones.exclusion_game_zone_id IS 'FK → zones.id. Кандидаты на спавн внутри этой игровой зоны отклоняются (напр. безопасный центр деревни).';


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
-- Name: status_effect_modifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_effect_modifiers (
    id integer NOT NULL,
    status_effect_id integer NOT NULL,
    attribute_id integer,
    modifier_type public.effect_modifier_type NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT chk_sem_percent_all_no_attr CHECK (((modifier_type <> 'percent_all'::public.effect_modifier_type) OR (attribute_id IS NULL)))
);


--
-- Name: TABLE status_effect_modifiers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.status_effect_modifiers IS 'Stat modifiers attached to a status effect. One row per attribute (or one row with attribute_id=NULL for percent_all).';


--
-- Name: COLUMN status_effect_modifiers.modifier_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.status_effect_modifiers.modifier_type IS 'flat | percent | percent_all';


--
-- Name: COLUMN status_effect_modifiers.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.status_effect_modifiers.value IS 'Numeric magnitude. Negative = penalty. For percent types: -20 means -20%.';


--
-- Name: status_effect_modifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.status_effect_modifiers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: status_effect_modifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.status_effect_modifiers_id_seq OWNED BY public.status_effect_modifiers.id;


--
-- Name: status_effects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_effects (
    id integer NOT NULL,
    slug text NOT NULL,
    category public.status_effect_category NOT NULL,
    duration_sec integer
);


--
-- Name: TABLE status_effects; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.status_effects IS 'Catalog of named status conditions (buffs, debuffs, DoTs, CC). Not to be confused with skill_damage_formulas.';


--
-- Name: COLUMN status_effects.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.status_effects.slug IS 'Machine-readable identifier, e.g. resurrection_sickness, burning, blessed';


--
-- Name: COLUMN status_effects.category; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.status_effects.category IS 'buff | debuff | dot | hot | cc';


--
-- Name: COLUMN status_effects.duration_sec; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.status_effects.duration_sec IS 'Default duration in seconds; NULL = permanent. Chunk server uses this when applying the effect.';


--
-- Name: status_effects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.status_effects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: status_effects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.status_effects_id_seq OWNED BY public.status_effects.id;


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
-- Name: timed_champion_templates; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: TABLE timed_champion_templates; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.timed_champion_templates IS 'Шаблоны мировых чемпионов с таймером спавна. Чемпион — усиленный моб, появляется с заданным интервалом в указанной зоне. next_spawn_at — unix-timestamp следующего спавна.';


--
-- Name: COLUMN timed_champion_templates.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timed_champion_templates.id IS 'Суррогатный PK.';


--
-- Name: COLUMN timed_champion_templates.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timed_champion_templates.slug IS 'Уникальный код шаблона чемпиона.';


--
-- Name: COLUMN timed_champion_templates.zone_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timed_champion_templates.zone_id IS 'FK → zones.id. Зона, в которой появляется чемпион.';


--
-- Name: COLUMN timed_champion_templates.mob_template_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timed_champion_templates.mob_template_id IS 'FK → mob.id. Шаблон моба, на основе которого создаётся чемпион.';


--
-- Name: COLUMN timed_champion_templates.interval_hours; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timed_champion_templates.interval_hours IS 'Интервал между спавнами чемпиона в часах.';


--
-- Name: COLUMN timed_champion_templates.window_minutes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timed_champion_templates.window_minutes IS 'Временное окно (в минутах) в котором чемпион может появиться после истечения интервала.';


--
-- Name: COLUMN timed_champion_templates.next_spawn_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timed_champion_templates.next_spawn_at IS 'Unix timestamp (секунды) ближайшего возможного спавна. NULL = ещё не рассчитан.';


--
-- Name: COLUMN timed_champion_templates.last_killed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timed_champion_templates.last_killed_at IS 'Временная метка последнего убийства чемпиона.';


--
-- Name: COLUMN timed_champion_templates.announcement_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.timed_champion_templates.announcement_key IS 'Ключ строки анонса для клиентского UI при появлении чемпиона. NULL = без анонса.';


--
-- Name: timed_champion_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.timed_champion_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: timed_champion_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.timed_champion_templates_id_seq OWNED BY public.timed_champion_templates.id;


--
-- Name: title_definitions; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: TABLE title_definitions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.title_definitions IS 'Каталог титулов. earn_condition — строковый ключ для логики выдачи на game-server. bonuses — JSON-массив модификаторов атрибутов.';


--
-- Name: COLUMN title_definitions.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.title_definitions.id IS 'Суррогатный PK.';


--
-- Name: COLUMN title_definitions.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.title_definitions.slug IS 'Уникальный код титула. Используется как FK в character_titles.';


--
-- Name: COLUMN title_definitions.display_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.title_definitions.display_name IS 'Отображаемое имя титула в UI.';


--
-- Name: COLUMN title_definitions.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.title_definitions.description IS 'Описание способа получения/значения титула.';


--
-- Name: COLUMN title_definitions.earn_condition; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.title_definitions.earn_condition IS 'Строковый ключ условия получения. Обрабатывается логикой game-server (achievement_manager и т.п.).';


--
-- Name: COLUMN title_definitions.bonuses; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.title_definitions.bonuses IS 'JSON-массив бонусов: [{\"attribute\":\"slug\",\"value\":N}]. Применяются при активации титула.';


--
-- Name: COLUMN title_definitions.condition_params; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.title_definitions.condition_params IS 'Data-driven unlock params (JSONB). Fields depend on earn_condition:
     bestiary:   {"mobSlug":"GreyWolf","minTier":6}   — unlocked when bestiary tier >= minTier
     mastery:    {"masterySlug":"sword_mastery","minTier":3} — unlocked when mastery tier >= minTier (1-4)
     reputation: {"factionSlug":"hunters","minTierName":"ally"} — unlocked when faction tier == minTierName
     level:      {"level":10}                          — unlocked on exact level-up
     quest:      {"questSlug":"wolf_hunt_intro"}       — unlocked on quest turn-in';


--
-- Name: title_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.title_definitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: title_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.title_definitions_id_seq OWNED BY public.title_definitions.id;


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
    price_override bigint,
    restock_amount integer DEFAULT 0 NOT NULL,
    stock_max integer DEFAULT '-1'::integer NOT NULL,
    restock_interval_sec integer DEFAULT 3600 NOT NULL,
    last_restock_at timestamp with time zone
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
-- Name: world_object_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.world_object_states (
    object_id integer NOT NULL,
    state character varying(16) DEFAULT 'active'::character varying NOT NULL,
    depleted_at timestamp with time zone,
    CONSTRAINT world_object_states_state_check CHECK (((state)::text = ANY ((ARRAY['active'::character varying, 'depleted'::character varying, 'disabled'::character varying])::text[])))
);


--
-- Name: TABLE world_object_states; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.world_object_states IS 'Persisted runtime state for global-scope world objects. Per-player state is in player_flags (wio_interacted_<id>).';


--
-- Name: COLUMN world_object_states.object_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_object_states.object_id IS 'FK to world_objects.id (PK + cascade delete).';


--
-- Name: COLUMN world_object_states.state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_object_states.state IS 'Current state: active | depleted | disabled.';


--
-- Name: COLUMN world_object_states.depleted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_object_states.depleted_at IS 'Timestamp of last depletion. NULL if never depleted.';


--
-- Name: world_objects; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: TABLE world_objects; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.world_objects IS 'Static definitions of world interactive objects (WIO). Mesh binding is performed in UE5 by slug. Loaded by game-server at startup and forwarded to chunk-server.';


--
-- Name: COLUMN world_objects.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.id IS 'Primary key, auto-incremented.';


--
-- Name: COLUMN world_objects.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.slug IS 'Unique machine-readable identifier. UE5 uses this to look up the static mesh / blueprint asset at runtime.';


--
-- Name: COLUMN world_objects.name_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.name_key IS 'Localisation key forwarded to the client (e.g. wio.forest_tracks_01.name).';


--
-- Name: COLUMN world_objects.object_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.object_type IS 'Interaction type: examine | search | activate | use_with_item | channeled.';


--
-- Name: COLUMN world_objects.scope; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.scope IS 'State scope: per_player (stored in player_flags) or global (stored in world_object_states).';


--
-- Name: COLUMN world_objects.pos_x; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.pos_x IS 'World X position (Unreal Engine units).';


--
-- Name: COLUMN world_objects.pos_y; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.pos_y IS 'World Y position.';


--
-- Name: COLUMN world_objects.pos_z; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.pos_z IS 'World Z position.';


--
-- Name: COLUMN world_objects.rot_z; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.rot_z IS 'Yaw rotation around Z axis (degrees).';


--
-- Name: COLUMN world_objects.zone_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.zone_id IS 'FK to zones.id. NULL = global / not zone-specific.';


--
-- Name: COLUMN world_objects.dialogue_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.dialogue_id IS 'FK to dialogue.id. NULL = no dialogue.';


--
-- Name: COLUMN world_objects.loot_table_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.loot_table_id IS 'Synthetic mob_id for loot gen. No FK by design. NULL = no loot.';


--
-- Name: COLUMN world_objects.required_item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.required_item_id IS 'FK to items.id. NULL = no requirement.';


--
-- Name: COLUMN world_objects.interaction_radius; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.interaction_radius IS 'Max distance (UE units) for interaction trigger.';


--
-- Name: COLUMN world_objects.channel_time_sec; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.channel_time_sec IS 'Channeling duration in seconds. 0 = instant.';


--
-- Name: COLUMN world_objects.respawn_sec; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.respawn_sec IS 'Seconds before object resets after depletion. 0 = never.';


--
-- Name: COLUMN world_objects.is_active_by_default; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.is_active_by_default IS 'Initial enabled state when no state row exists yet.';


--
-- Name: COLUMN world_objects.min_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.min_level IS 'Minimum character level required. 0 = unrestricted.';


--
-- Name: COLUMN world_objects.condition_group; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.world_objects.condition_group IS 'JSONB condition tree (dialogue schema). null = always allowed.';


--
-- Name: world_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.world_objects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: world_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.world_objects_id_seq OWNED BY public.world_objects.id;


--
-- Name: zone_event_templates; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: TABLE zone_event_templates; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.zone_event_templates IS 'Шаблоны мировых событий (вторжения, праздники, осады). При срабатывании trigger_type chunk-server клонирует шаблон в активное событие. invasion_* поля задают волну мобов.';


--
-- Name: COLUMN zone_event_templates.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.id IS 'Суррогатный PK.';


--
-- Name: COLUMN zone_event_templates.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.slug IS 'Уникальный код шаблона события.';


--
-- Name: COLUMN zone_event_templates.game_zone_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.game_zone_id IS 'FK → zones.id. Зона, в которой происходит событие. NULL = глобальное событие.';


--
-- Name: COLUMN zone_event_templates.trigger_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.trigger_type IS 'Способ запуска: manual (GM-команда), timed (по расписанию), random (случайный по вероятности).';


--
-- Name: COLUMN zone_event_templates.duration_sec; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.duration_sec IS 'Продолжительность активного события в секундах.';


--
-- Name: COLUMN zone_event_templates.loot_multiplier; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.loot_multiplier IS 'Множитель вероятности дропа во время события (1.0 = норма).';


--
-- Name: COLUMN zone_event_templates.spawn_rate_multiplier; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.spawn_rate_multiplier IS 'Множитель скорости спавна мобов (1.0 = норма).';


--
-- Name: COLUMN zone_event_templates.mob_speed_multiplier; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.mob_speed_multiplier IS 'Множитель скорости движения мобов (1.0 = норма).';


--
-- Name: COLUMN zone_event_templates.announce_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.announce_key IS 'Ключ строки анонса для клиентского UI при старте события. NULL = без анонса.';


--
-- Name: COLUMN zone_event_templates.interval_hours; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.interval_hours IS 'Интервал повторения события в часах (0 = не повторяется). Применяется при trigger_type=timed.';


--
-- Name: COLUMN zone_event_templates.random_chance_per_hour; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.random_chance_per_hour IS 'Вероятность случайного запуска в час (0.0–1.0). Применяется при trigger_type=random.';


--
-- Name: COLUMN zone_event_templates.has_invasion_wave; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.has_invasion_wave IS 'TRUE = событие сопровождается волной вторжения мобов.';


--
-- Name: COLUMN zone_event_templates.invasion_mob_template_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.invasion_mob_template_id IS 'FK → mob.id. Шаблон моба-захватчика. NULL = нет вторжения.';


--
-- Name: COLUMN zone_event_templates.invasion_wave_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.invasion_wave_count IS 'Количество волн вторжения.';


--
-- Name: COLUMN zone_event_templates.invasion_champion_template_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.invasion_champion_template_id IS 'FK → timed_champion_templates.id. Чемпион, появляющийся в финальной волне. NULL = без чемпиона.';


--
-- Name: COLUMN zone_event_templates.invasion_champion_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.zone_event_templates.invasion_champion_slug IS 'Slug чемпиона (дублирует FK для runtime без JOIN). NULL = без чемпиона.';


--
-- Name: zone_event_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zone_event_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zone_event_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zone_event_templates_id_seq OWNED BY public.zone_event_templates.id;


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
    is_safe_zone boolean DEFAULT false NOT NULL,
    min_x double precision DEFAULT 0 NOT NULL,
    max_x double precision DEFAULT 0 NOT NULL,
    min_y double precision DEFAULT 0 NOT NULL,
    max_y double precision DEFAULT 0 NOT NULL,
    exploration_xp_reward integer DEFAULT 100 NOT NULL,
    champion_threshold_kills integer DEFAULT 100 NOT NULL,
    shape_type public.spawn_zone_shape NOT NULL DEFAULT 'RECT',
    center_x double precision NOT NULL DEFAULT 0,
    center_y double precision NOT NULL DEFAULT 0,
    inner_radius double precision NOT NULL DEFAULT 0,
    outer_radius double precision NOT NULL DEFAULT 0
);


--
-- Name: TABLE zones; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.zones IS 'Игровые зоны/карты. Поддерживаются формы RECT, CIRCLE, ANNULUS. Без zone_id координаты позиций теряют смысл';


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
-- Name: character_emotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_emotes ALTER COLUMN id SET DEFAULT nextval('public.character_emotes_id_seq'::regclass);


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
-- Name: emote_definitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emote_definitions ALTER COLUMN id SET DEFAULT nextval('public.emote_definitions_id_seq'::regclass);


--
-- Name: factions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factions ALTER COLUMN id SET DEFAULT nextval('public.factions_id_seq'::regclass);


--
-- Name: game_analytics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_analytics ALTER COLUMN id SET DEFAULT nextval('public.game_analytics_id_seq'::regclass);


--
-- Name: gm_action_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gm_action_log ALTER COLUMN id SET DEFAULT nextval('public.gm_action_log_id_seq'::regclass);


--
-- Name: item_set_bonuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_set_bonuses ALTER COLUMN id SET DEFAULT nextval('public.item_set_bonuses_id_seq'::regclass);


--
-- Name: item_sets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets ALTER COLUMN id SET DEFAULT nextval('public.item_sets_id_seq'::regclass);


--
-- Name: item_use_effects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_use_effects ALTER COLUMN id SET DEFAULT nextval('public.item_use_effects_id_seq'::regclass);


--
-- Name: mob_skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_skills ALTER COLUMN id SET DEFAULT nextval('public.mob_skills_id_seq'::regclass);


--
-- Name: npc_ambient_speech_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_ambient_speech_configs ALTER COLUMN id SET DEFAULT nextval('public.npc_ambient_speech_configs_id_seq'::regclass);


--
-- Name: npc_ambient_speech_lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_ambient_speech_lines ALTER COLUMN id SET DEFAULT nextval('public.npc_ambient_speech_lines_id_seq'::regclass);


--
-- Name: npc_placements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_placements ALTER COLUMN id SET DEFAULT nextval('public.npc_placements_id_seq'::regclass);


--
-- Name: npc_skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_skills ALTER COLUMN id SET DEFAULT nextval('public.npc_skills_id_seq'::regclass);


--
-- Name: npc_trainer_class id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_trainer_class ALTER COLUMN id SET DEFAULT nextval('public.npc_trainer_class_id_seq'::regclass);


--
-- Name: passive_skill_modifiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passive_skill_modifiers ALTER COLUMN id SET DEFAULT nextval('public.passive_skill_modifiers_id_seq'::regclass);


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
-- Name: respawn_zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.respawn_zones ALTER COLUMN id SET DEFAULT nextval('public.respawn_zones_id_seq'::regclass);


--
-- Name: skill_damage_formulas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_damage_formulas ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_id_seq'::regclass);


--
-- Name: skill_damage_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_damage_types ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_type_id_seq'::regclass);


--
-- Name: skill_effect_instances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effect_instances ALTER COLUMN id SET DEFAULT nextval('public.skill_effect_instances_id_seq'::regclass);


--
-- Name: skill_effects_mapping id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects_mapping ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_mapping_id_seq'::regclass);


--
-- Name: spawn_zone_mobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_zone_mobs ALTER COLUMN id SET DEFAULT nextval('public.spawn_zone_mobs_id_seq'::regclass);


--
-- Name: spawn_zones zone_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_zones ALTER COLUMN zone_id SET DEFAULT nextval('public.spawn_zones_zone_id_seq'::regclass);


--
-- Name: status_effect_modifiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_effect_modifiers ALTER COLUMN id SET DEFAULT nextval('public.status_effect_modifiers_id_seq'::regclass);


--
-- Name: status_effects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_effects ALTER COLUMN id SET DEFAULT nextval('public.status_effects_id_seq'::regclass);


--
-- Name: target_type id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_type ALTER COLUMN id SET DEFAULT nextval('public.target_type_id_seq'::regclass);


--
-- Name: timed_champion_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timed_champion_templates ALTER COLUMN id SET DEFAULT nextval('public.timed_champion_templates_id_seq'::regclass);


--
-- Name: title_definitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.title_definitions ALTER COLUMN id SET DEFAULT nextval('public.title_definitions_id_seq'::regclass);


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
-- Name: world_objects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_objects ALTER COLUMN id SET DEFAULT nextval('public.world_objects_id_seq'::regclass);


--
-- Name: zone_event_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_event_templates ALTER COLUMN id SET DEFAULT nextval('public.zone_event_templates_id_seq'::regclass);


--
-- Name: zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones ALTER COLUMN id SET DEFAULT nextval('public.zones_id_seq'::regclass);


--
-- Data for Name: character_bestiary; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.character_bestiary VALUES (2, 1, 3);
INSERT INTO public.character_bestiary VALUES (3, 1, 380);
INSERT INTO public.character_bestiary VALUES (3, 2, 18);


--
-- Data for Name: character_class; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.character_class OVERRIDING SYSTEM VALUE VALUES (1, 'Mage', NULL, NULL);
INSERT INTO public.character_class OVERRIDING SYSTEM VALUE VALUES (2, 'Warrior', NULL, NULL);


--
-- Data for Name: character_current_state; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.character_current_state VALUES (2, 207, 486, false, '2026-04-14 19:37:08.866237+00');
INSERT INTO public.character_current_state VALUES (3, 365, 477, false, '2026-04-15 20:17:37.866512+00');
INSERT INTO public.character_current_state VALUES (1, 197, 454, false, '2026-03-07 12:41:29.615005+00');


--
-- Data for Name: character_emotes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.character_emotes VALUES (4, 1, 'wave', '2026-04-13 08:53:40.211313+00');
INSERT INTO public.character_emotes VALUES (5, 2, 'wave', '2026-04-13 08:53:40.211313+00');
INSERT INTO public.character_emotes VALUES (6, 3, 'wave', '2026-04-13 08:53:40.211313+00');


--
-- Data for Name: character_equipment; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.character_equipment VALUES (80, 3, 6, 176, '2026-04-08 18:25:58.153336+00');


--
-- Data for Name: character_genders; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.character_genders VALUES (0, 'male', 'Male');
INSERT INTO public.character_genders VALUES (1, 'female', 'Female');
INSERT INTO public.character_genders VALUES (2, 'unknown', 'Unknown');


--
-- Data for Name: character_permanent_modifiers; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: character_pity; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.character_pity VALUES (3, 6, 0);
INSERT INTO public.character_pity VALUES (3, 17, 0);
INSERT INTO public.character_pity VALUES (3, 3, 0);


--
-- Data for Name: character_position; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.character_position OVERRIDING SYSTEM VALUE VALUES (3, 3, 18868.21, -15498.54, 1540.85, 1, 93.14946);
INSERT INTO public.character_position OVERRIDING SYSTEM VALUE VALUES (1, 1, -2000.00, 4000.00, 300.00, 2, 0);
INSERT INTO public.character_position OVERRIDING SYSTEM VALUE VALUES (2, 2, -204.10, -557.02, 87.15, 2, -130.249863);


--
-- Data for Name: character_reputation; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.character_reputation VALUES (3, 'hunters', 750);
INSERT INTO public.character_reputation VALUES (3, 'city_guard', 500);
INSERT INTO public.character_reputation VALUES (3, 'merchants', -200);


--
-- Data for Name: character_skill_bar; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.character_skill_bar VALUES (3, 0, 'basic_attack');
INSERT INTO public.character_skill_bar VALUES (3, 1, 'fireball');


--
-- Data for Name: character_skill_mastery; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: character_skills; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.character_skills VALUES (1, 1, 1, 1);
INSERT INTO public.character_skills VALUES (4, 2, 1, 1);
INSERT INTO public.character_skills VALUES (5, 3, 1, 1);
INSERT INTO public.character_skills VALUES (6, 3, 2, 1);
INSERT INTO public.character_skills VALUES (7, 3, 3, 1);
INSERT INTO public.character_skills VALUES (8, 3, 8, 1);
INSERT INTO public.character_skills VALUES (18, 3, 11, 1);


--
-- Data for Name: character_titles; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: characters; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.characters OVERRIDING SYSTEM VALUE VALUES (1, 'TetsMage1Player', 5, 1, 1, 57, 2, 100, 0, 0, 1, '2026-03-03 16:16:54.741947+00', NULL, NULL, 0, 1, 0, 0, 200, NULL, 0);
INSERT INTO public.characters OVERRIDING SYSTEM VALUE VALUES (3, 'TetsWarrior1Player', 3, 2, 1, 5730, 5, 100, 39, 0, 1, '2026-03-03 16:16:54.741947+00', NULL, NULL, 0, 1, 0, 0, 200, NULL, 3616);
INSERT INTO public.characters OVERRIDING SYSTEM VALUE VALUES (2, 'TetsMage2Player', 4, 1, 1, 1460, 3, 100, 0, 0, 1, '2026-03-03 16:16:54.741947+00', NULL, NULL, 0, 1, 0, 0, 200, NULL, 1752);


--
-- Data for Name: class_skill_tree; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.class_skill_tree VALUES (1, 1, 1, 1, true, NULL, 0, 0, 1, false, NULL);
INSERT INTO public.class_skill_tree VALUES (3, 2, 1, 1, true, NULL, 0, 0, 1, false, NULL);
INSERT INTO public.class_skill_tree VALUES (5, 2, 4, 5, false, NULL, 1, 150, 1, false, NULL);
INSERT INTO public.class_skill_tree VALUES (7, 2, 6, 5, false, NULL, 1, 120, 1, false, NULL);
INSERT INTO public.class_skill_tree VALUES (8, 2, 7, 8, false, 6, 1, 200, 1, false, NULL);
INSERT INTO public.class_skill_tree VALUES (4, 2, 2, 5, false, NULL, 1, 100, 1, false, NULL);
INSERT INTO public.class_skill_tree VALUES (13, 1, 8, 5, false, NULL, 1, 100, 1, false, NULL);
INSERT INTO public.class_skill_tree VALUES (14, 1, 9, 8, false, 8, 1, 200, 1, false, NULL);
INSERT INTO public.class_skill_tree VALUES (16, 1, 11, 5, false, NULL, 1, 150, 1, false, NULL);
INSERT INTO public.class_skill_tree VALUES (17, 1, 12, 10, false, 11, 1, 300, 1, false, NULL);
INSERT INTO public.class_skill_tree VALUES (2, 1, 3, 5, false, NULL, 1, 120, 1, false, NULL);
INSERT INTO public.class_skill_tree VALUES (6, 2, 5, 10, false, 4, 1, 300, 1, true, 19);
INSERT INTO public.class_skill_tree VALUES (15, 1, 10, 12, false, 9, 1, 400, 1, true, 24);


--
-- Data for Name: class_stat_formula; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.class_stat_formula VALUES (1, 3, 4.00, 0.6000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 4, 15.00, 2.5000, 1.0500);
INSERT INTO public.class_stat_formula VALUES (1, 27, 6.00, 0.8000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 28, 10.00, 2.0000, 1.0500);
INSERT INTO public.class_stat_formula VALUES (1, 29, 5.00, 0.5000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 1, 80.00, 8.0000, 1.1000);
INSERT INTO public.class_stat_formula VALUES (1, 2, 200.00, 25.0000, 1.1200);
INSERT INTO public.class_stat_formula VALUES (1, 12, 2.00, 0.5000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 13, 5.00, 1.8000, 1.0800);
INSERT INTO public.class_stat_formula VALUES (1, 6, 4.00, 1.0000, 1.0500);
INSERT INTO public.class_stat_formula VALUES (1, 7, 8.00, 2.0000, 1.0800);
INSERT INTO public.class_stat_formula VALUES (1, 8, 5.00, 0.3000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 9, 200.00, 0.0000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 14, 5.00, 0.5000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 15, 5.00, 0.5000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 16, 0.00, 0.0000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 17, 0.00, 0.0000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 10, 1.00, 0.2000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 11, 2.00, 0.8000, 1.0500);
INSERT INTO public.class_stat_formula VALUES (1, 18, 5.00, 0.0000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 19, 5.00, 0.2000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 20, 7.00, 0.4000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 30, 0.00, 0.3000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 31, 0.00, 0.3000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 32, 0.00, 0.3000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 33, 0.00, 0.3000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 34, 0.00, 0.3000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (1, 35, 0.00, 0.3000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 3, 12.00, 2.0000, 1.0800);
INSERT INTO public.class_stat_formula VALUES (2, 4, 5.00, 0.5000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 27, 10.00, 2.0000, 1.0800);
INSERT INTO public.class_stat_formula VALUES (2, 28, 4.00, 0.5000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 29, 6.00, 0.8000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 1, 150.00, 18.0000, 1.1500);
INSERT INTO public.class_stat_formula VALUES (2, 2, 50.00, 5.0000, 1.0500);
INSERT INTO public.class_stat_formula VALUES (2, 12, 10.00, 3.5000, 1.1000);
INSERT INTO public.class_stat_formula VALUES (2, 13, 2.00, 0.5000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 6, 15.00, 4.0000, 1.1200);
INSERT INTO public.class_stat_formula VALUES (2, 7, 5.00, 1.5000, 1.0500);
INSERT INTO public.class_stat_formula VALUES (2, 8, 5.00, 0.3000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 9, 200.00, 0.0000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 14, 5.00, 0.5000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 15, 3.00, 0.3000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 16, 10.00, 0.5000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 17, 3.00, 1.0000, 1.0500);
INSERT INTO public.class_stat_formula VALUES (2, 10, 1.00, 0.4000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 11, 0.50, 0.2000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 18, 5.00, 0.0000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 19, 5.00, 0.3000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 20, 3.00, 0.1000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 30, 0.00, 0.2000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 31, 0.00, 0.2000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 32, 0.00, 0.2000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 33, 0.00, 0.2000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 34, 0.00, 0.2000, 1.0000);
INSERT INTO public.class_stat_formula VALUES (2, 35, 0.00, 0.2000, 1.0000);


--
-- Data for Name: currency_transactions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: damage_elements; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.damage_elements VALUES ('physical');
INSERT INTO public.damage_elements VALUES ('fire');
INSERT INTO public.damage_elements VALUES ('water');
INSERT INTO public.damage_elements VALUES ('nature');
INSERT INTO public.damage_elements VALUES ('arcane');
INSERT INTO public.damage_elements VALUES ('holy');
INSERT INTO public.damage_elements VALUES ('shadow');
INSERT INTO public.damage_elements VALUES ('ice');


--
-- Data for Name: dialogue; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.dialogue VALUES (1, 'milaya_main', 1, 1);
INSERT INTO public.dialogue VALUES (2, 'varan_main', 1, 201);
INSERT INTO public.dialogue VALUES (3, 'edrik_main', 1, 301);
INSERT INTO public.dialogue VALUES (4, 'theron_main', 1, 400);
INSERT INTO public.dialogue VALUES (5, 'sylara_main', 1, 500);
INSERT INTO public.dialogue VALUES (6, 'ruins_dying_stranger_main', 1, 600);


--
-- Data for Name: dialogue_edge; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.dialogue_edge VALUES (23, 4, 7, 1, 'milaya.choice.quest_decline', '{"any": [{"slug": "wolf_hunt_intro", "type": "quest", "state": "not_started"}, {"slug": "wolf_hunt_intro", "type": "quest", "state": "turned_in"}, {"slug": "wolf_hunt_intro", "type": "quest", "state": "failed"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (41, 201, 202, 0, 'varan.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (42, 202, 203, 0, 'varan.choice.dangers', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (43, 202, 204, 1, 'varan.choice.road', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (44, 202, 205, 2, 'varan.choice.watch', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (46, 203, 202, 0, 'varan.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (47, 204, 202, 0, 'varan.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (48, 205, 202, 0, 'varan.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (49, 301, 302, 0, 'edrik.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (50, 302, 303, 0, 'edrik.choice.about_past', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (51, 302, 304, 1, 'edrik.choice.about_craft', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (52, 302, 305, 2, 'edrik.choice.about_village', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (53, 302, 306, 3, 'edrik.choice.advice', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (55, 303, 302, 0, 'edrik.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (56, 304, 302, 0, 'edrik.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (57, 305, 302, 0, 'edrik.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (58, 306, 302, 0, 'edrik.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (61, 15, 12, 0, 'milaya.choice.quest_abandon_yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (62, 15, 1, 1, 'milaya.choice.quest_abandon_no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (60, 4, 15, 5, 'milaya.choice.quest_abandon', '{"slug": "wolf_hunt_intro", "type": "quest", "state": "active"}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (33, 10, 11, 0, '', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (24, 4, 8, 2, 'milaya.choice.quest_status', '{"all": [{"slug": "wolf_hunt_intro", "type": "quest", "state": "active"}, {"slug": "wolf_hunt_intro", "step": 0, "type": "quest_step"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (39, 4, 103, 2, 'milaya.choice.quest_status', '{"all": [{"slug": "wolf_hunt_intro", "type": "quest", "state": "active"}, {"slug": "wolf_hunt_intro", "step": 2, "type": "quest_step"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (63, 4, 101, 2, 'milaya.choice.quest_report_wolves', '{"all": [{"slug": "wolf_hunt_intro", "type": "quest", "state": "active"}, {"slug": "wolf_hunt_intro", "step": 1, "type": "quest_step"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (35, 12, 13, 0, '', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (64, 101, 102, 0, '', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (20, 2, 1, 0, 'milaya.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (65, 102, 4, 0, 'milaya.choice.got_it', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (21, 3, 1, 0, 'milaya.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (66, 103, 4, 0, 'milaya.choice.got_it', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (16, 1, 2, 0, 'milaya.choice.about_village', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (17, 1, 3, 1, 'milaya.choice.about_self', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (34, 11, 4, 0, 'milaya.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (38, 100, 4, 0, 'milaya.choice.got_it', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (18, 1, 4, 2, 'milaya.choice.any_work', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (19, 1, 99, 3, 'milaya.choice.farewell', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (25, 4, 9, 3, 'milaya.choice.quest_turnin', '{"slug": "wolf_hunt_intro", "type": "quest", "state": "completed"}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (27, 5, 6, 0, '', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (31, 9, 10, 0, 'milaya.choice.give_wolves', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (32, 9, 12, 1, 'milaya.choice.wont_give', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (45, 202, 299, 5, 'varan.choice.farewell', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (67, 202, 299, 3, 'varan.choice.trade_buy', NULL, '{"actions": [{"mode": "buy", "type": "open_vendor_shop"}]}', false);
INSERT INTO public.dialogue_edge VALUES (68, 202, 299, 4, 'varan.choice.trade_sell', NULL, '{"actions": [{"mode": "sell", "type": "open_vendor_shop"}]}', false);
INSERT INTO public.dialogue_edge VALUES (54, 302, 399, 5, 'edrik.choice.farewell', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (69, 302, 399, 4, 'edrik.choice.repair', NULL, '{"actions": [{"type": "open_repair_shop"}]}', false);
INSERT INTO public.dialogue_edge VALUES (70, 400, 401, 0, 'theron.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (71, 401, 402, 0, 'theron.choice.learn_power_slash', '{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "power_slash", "type": "skill_not_learned"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (72, 401, 410, 1, 'theron.choice.learn_shield_bash', '{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "shield_bash", "type": "skill_not_learned"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (73, 401, 420, 2, 'theron.choice.learn_whirlwind', '{"all": [{"gte": 10, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "whirlwind", "type": "skill_not_learned"}, {"slug": "shield_bash", "type": "skill_learned"}, {"gte": 1, "type": "item", "item_id": 19}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (74, 401, 430, 3, 'theron.choice.learn_iron_skin', '{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "iron_skin", "type": "skill_not_learned"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (75, 401, 440, 4, 'theron.choice.learn_constitution_mastery', '{"all": [{"gte": 8, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "constitution_mastery", "type": "skill_not_learned"}, {"slug": "iron_skin", "type": "skill_learned"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (76, 401, 499, 5, 'theron.choice.open_shop', NULL, '{"actions": [{"type": "open_skill_shop"}]}', false);
INSERT INTO public.dialogue_edge VALUES (28, 6, 4, 0, 'milaya.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (30, 8, 4, 0, 'milaya.choice.got_it', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (29, 7, 1, 0, 'milaya.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (36, 13, 1, 0, 'milaya.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (37, 14, 1, 0, 'milaya.choice.back', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (26, 4, 14, 4, 'milaya.choice.quest_done', '{"slug": "wolf_hunt_intro", "type": "quest", "state": "turned_in"}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (22, 4, 5, 0, 'milaya.choice.quest_accept', '{"any": [{"slug": "wolf_hunt_intro", "type": "quest", "state": "not_started"}, {"slug": "wolf_hunt_intro", "type": "quest", "state": "turned_in"}, {"slug": "wolf_hunt_intro", "type": "quest", "state": "failed"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (77, 401, 499, 6, 'theron.choice.farewell', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (78, 402, 403, 0, 'theron.choice.yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (79, 402, 401, 1, 'theron.choice.no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (80, 403, 404, 0, 'theron.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (81, 404, 401, 0, 'theron.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (82, 410, 411, 0, 'theron.choice.yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (83, 410, 401, 1, 'theron.choice.no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (84, 411, 412, 0, 'theron.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (85, 412, 401, 0, 'theron.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (86, 420, 421, 0, 'theron.choice.yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (87, 420, 401, 1, 'theron.choice.no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (88, 421, 422, 0, 'theron.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (89, 422, 401, 0, 'theron.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (90, 430, 431, 0, 'theron.choice.yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (91, 430, 401, 1, 'theron.choice.no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (92, 431, 432, 0, 'theron.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (93, 432, 401, 0, 'theron.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (94, 440, 441, 0, 'theron.choice.yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (95, 440, 401, 1, 'theron.choice.no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (96, 441, 442, 0, 'theron.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (97, 442, 401, 0, 'theron.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (100, 500, 501, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (101, 501, 502, 0, 'sylara.choice.learn_fireball', '{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "fireball", "type": "skill_not_learned"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (102, 501, 510, 1, 'sylara.choice.learn_frost_bolt', '{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "frost_bolt", "type": "skill_not_learned"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (103, 501, 520, 2, 'sylara.choice.learn_arcane_blast', '{"all": [{"gte": 8, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "arcane_blast", "type": "skill_not_learned"}, {"slug": "frost_bolt", "type": "skill_learned"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (104, 501, 530, 3, 'sylara.choice.learn_chain_lightning', '{"all": [{"gte": 12, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "chain_lightning", "type": "skill_not_learned"}, {"slug": "arcane_blast", "type": "skill_learned"}, {"gte": 1, "type": "item", "item_id": 24}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (105, 501, 540, 4, 'sylara.choice.learn_mana_shield', '{"all": [{"gte": 5, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "mana_shield", "type": "skill_not_learned"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (106, 501, 550, 5, 'sylara.choice.learn_elemental_mastery', '{"all": [{"gte": 10, "type": "level"}, {"gte": 1, "type": "has_skill_points"}, {"slug": "elemental_mastery", "type": "skill_not_learned"}, {"slug": "mana_shield", "type": "skill_learned"}]}', NULL, true);
INSERT INTO public.dialogue_edge VALUES (108, 501, 599, 7, 'sylara.choice.farewell', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (110, 502, 503, 0, 'sylara.choice.yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (111, 502, 501, 1, 'sylara.choice.no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (112, 503, 504, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (113, 504, 501, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (114, 510, 511, 0, 'sylara.choice.yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (115, 510, 501, 1, 'sylara.choice.no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (116, 511, 512, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (117, 512, 501, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (118, 520, 521, 0, 'sylara.choice.yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (119, 520, 501, 1, 'sylara.choice.no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (120, 521, 522, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (121, 522, 501, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (122, 530, 531, 0, 'sylara.choice.yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (123, 530, 501, 1, 'sylara.choice.no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (124, 531, 532, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (125, 532, 501, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (126, 540, 541, 0, 'sylara.choice.yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (127, 540, 501, 1, 'sylara.choice.no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (128, 541, 542, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (129, 542, 501, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (130, 550, 551, 0, 'sylara.choice.yes', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (131, 550, 501, 1, 'sylara.choice.no', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (132, 551, 552, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (133, 552, 501, 0, 'sylara.choice.continue', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (107, 501, 599, 6, 'sylara.choice.open_shop', NULL, '{"actions": [{"type": "open_skill_shop"}]}', false);
INSERT INTO public.dialogue_edge VALUES (140, 605, 609, 0, 'ruins_dying_stranger.choice.farewell', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (137, 603, 605, 0, 'ruins_dying_stranger.choice.accept', '[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}, {"type": "class", "class_id": 2}]', '[{"type": "give_item", "item_id": 1, "quantity": 1}, {"type": "give_item", "item_id": 3, "quantity": 2}, {"key": "ruins_dying_stranger.received_gift", "type": "set_flag", "bool_value": true}]', true);
INSERT INTO public.dialogue_edge VALUES (141, 603, 605, 1, 'ruins_dying_stranger.choice.accept', '[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}, {"type": "class", "class_id": 1}]', '[{"type": "give_item", "item_id": 15, "quantity": 1}, {"type": "give_item", "item_id": 3, "quantity": 2}, {"key": "ruins_dying_stranger.received_gift", "type": "set_flag", "bool_value": true}]', true);
INSERT INTO public.dialogue_edge VALUES (134, 600, 601, 0, 'ruins_dying_stranger.choice.why_here', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (135, 601, 602, 0, 'ruins_dying_stranger.choice.i_will_try', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (143, 611, 609, 0, 'ruins_dying_stranger.choice.farewell', NULL, NULL, false);
INSERT INTO public.dialogue_edge VALUES (138, 603, 605, 2, 'ruins_dying_stranger.choice.decline', '[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}]', NULL, true);
INSERT INTO public.dialogue_edge VALUES (136, 602, 603, 0, 'ruins_dying_stranger.choice.what_can_i_do', '[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}]', NULL, true);
INSERT INTO public.dialogue_edge VALUES (144, 602, 611, 1, 'ruins_dying_stranger.choice.nothing_more', '[{"eq": true, "key": "ruins_dying_stranger.received_gift", "type": "flag"}]', NULL, true);


--
-- Data for Name: dialogue_node; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.dialogue_node VALUES (13, 1, 'line', 2, 'milaya.dialogue.quest_sad', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (14, 1, 'line', 2, 'milaya.dialogue.quest_done', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (99, 1, 'end', 2, '', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (100, 1, 'line', 2, 'milaya.dialogue.quest_step1_reminder', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (1, 1, 'line', 2, 'milaya.dialogue.greeting', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (2, 1, 'line', 2, 'milaya.dialogue.about_village', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (3, 1, 'line', 2, 'milaya.dialogue.about_self', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (4, 1, 'choice_hub', 2, 'milaya.dialogue.quest_hub', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (5, 1, 'action', 2, '', NULL, '{"actions": [{"slug": "wolf_hunt_intro", "type": "offer_quest"}]}', NULL);
INSERT INTO public.dialogue_node VALUES (6, 1, 'line', 2, 'milaya.dialogue.quest_accepted', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (7, 1, 'line', 2, 'milaya.dialogue.quest_decline', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (8, 1, 'line', 2, 'milaya.dialogue.quest_reminder', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (9, 1, 'line', 2, 'milaya.dialogue.quest_turnin_ask', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (10, 1, 'action', 2, '', NULL, '{"actions": [{"slug": "wolf_hunt_intro", "type": "turn_in_quest"}]}', NULL);
INSERT INTO public.dialogue_node VALUES (11, 1, 'line', 2, 'milaya.dialogue.quest_thanks', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (12, 1, 'action', 2, '', NULL, '{"actions": [{"slug": "wolf_hunt_intro", "type": "fail_quest"}]}', NULL);
INSERT INTO public.dialogue_node VALUES (15, 1, 'line', 2, 'milaya.dialogue.quest_abandon_confirm', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (101, 1, 'action', 2, '', NULL, '{"actions": [{"slug": "wolf_hunt_intro", "type": "advance_quest_step"}]}', NULL);
INSERT INTO public.dialogue_node VALUES (102, 1, 'line', 2, 'milaya.dialogue.next_task_skins', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (103, 1, 'line', 2, 'milaya.dialogue.quest_step2_reminder', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (400, 4, 'line', 4, 'theron.dialogue.greeting', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (401, 4, 'choice_hub', 4, 'theron.dialogue.skill_hub', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (402, 4, 'line', 4, 'theron.dialogue.confirm_power_slash', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (403, 4, 'action', 4, NULL, NULL, '{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 100, "skill_slug": "power_slash", "book_item_id": 0, "requires_book": false}]}', NULL);
INSERT INTO public.dialogue_node VALUES (404, 4, 'line', 4, 'theron.dialogue.learned_power_slash', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (410, 4, 'line', 4, 'theron.dialogue.confirm_shield_bash', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (411, 4, 'action', 4, NULL, NULL, '{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 150, "skill_slug": "shield_bash", "book_item_id": 0, "requires_book": false}]}', NULL);
INSERT INTO public.dialogue_node VALUES (412, 4, 'line', 4, 'theron.dialogue.learned_shield_bash', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (420, 4, 'line', 4, 'theron.dialogue.confirm_whirlwind', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (421, 4, 'action', 4, NULL, NULL, '{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 300, "skill_slug": "whirlwind", "book_item_id": 19, "requires_book": true}]}', NULL);
INSERT INTO public.dialogue_node VALUES (422, 4, 'line', 4, 'theron.dialogue.learned_whirlwind', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (430, 4, 'line', 4, 'theron.dialogue.confirm_iron_skin', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (431, 4, 'action', 4, NULL, NULL, '{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 120, "skill_slug": "iron_skin", "book_item_id": 0, "requires_book": false}]}', NULL);
INSERT INTO public.dialogue_node VALUES (432, 4, 'line', 4, 'theron.dialogue.learned_iron_skin', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (440, 4, 'line', 4, 'theron.dialogue.confirm_constitution_mastery', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (201, 2, 'line', 1, 'varan.dialogue.greeting', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (202, 2, 'choice_hub', 1, 'varan.dialogue.main_hub', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (203, 2, 'line', 1, 'varan.dialogue.about_dangers', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (204, 2, 'line', 1, 'varan.dialogue.about_road', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (205, 2, 'line', 1, 'varan.dialogue.about_watch', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (299, 2, 'end', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (301, 3, 'line', 3, 'edrik.dialogue.greeting', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (302, 3, 'choice_hub', 3, 'edrik.dialogue.main_hub', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (303, 3, 'line', 3, 'edrik.dialogue.about_past', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (304, 3, 'line', 3, 'edrik.dialogue.about_craft', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (305, 3, 'line', 3, 'edrik.dialogue.about_village', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (306, 3, 'line', 3, 'edrik.dialogue.advice', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (399, 3, 'end', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (441, 4, 'action', 4, NULL, NULL, '{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 200, "skill_slug": "constitution_mastery", "book_item_id": 0, "requires_book": false}]}', NULL);
INSERT INTO public.dialogue_node VALUES (442, 4, 'line', 4, 'theron.dialogue.learned_constitution_mastery', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (499, 4, 'end', 4, NULL, NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (500, 5, 'line', 5, 'sylara.dialogue.greeting', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (501, 5, 'choice_hub', 5, 'sylara.dialogue.skill_hub', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (502, 5, 'line', 5, 'sylara.dialogue.confirm_fireball', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (503, 5, 'action', 5, NULL, NULL, '{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 120, "skill_slug": "fireball", "book_item_id": 0, "requires_book": false}]}', NULL);
INSERT INTO public.dialogue_node VALUES (504, 5, 'line', 5, 'sylara.dialogue.learned_fireball', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (510, 5, 'line', 5, 'sylara.dialogue.confirm_frost_bolt', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (511, 5, 'action', 5, NULL, NULL, '{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 100, "skill_slug": "frost_bolt", "book_item_id": 0, "requires_book": false}]}', NULL);
INSERT INTO public.dialogue_node VALUES (512, 5, 'line', 5, 'sylara.dialogue.learned_frost_bolt', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (520, 5, 'line', 5, 'sylara.dialogue.confirm_arcane_blast', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (521, 5, 'action', 5, NULL, NULL, '{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 200, "skill_slug": "arcane_blast", "book_item_id": 0, "requires_book": false}]}', NULL);
INSERT INTO public.dialogue_node VALUES (522, 5, 'line', 5, 'sylara.dialogue.learned_arcane_blast', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (530, 5, 'line', 5, 'sylara.dialogue.confirm_chain_lightning', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (531, 5, 'action', 5, NULL, NULL, '{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 400, "skill_slug": "chain_lightning", "book_item_id": 24, "requires_book": true}]}', NULL);
INSERT INTO public.dialogue_node VALUES (532, 5, 'line', 5, 'sylara.dialogue.learned_chain_lightning', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (540, 5, 'line', 5, 'sylara.dialogue.confirm_mana_shield', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (541, 5, 'action', 5, NULL, NULL, '{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 150, "skill_slug": "mana_shield", "book_item_id": 0, "requires_book": false}]}', NULL);
INSERT INTO public.dialogue_node VALUES (542, 5, 'line', 5, 'sylara.dialogue.learned_mana_shield', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (550, 5, 'line', 5, 'sylara.dialogue.confirm_elemental_mastery', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (551, 5, 'action', 5, NULL, NULL, '{"actions": [{"type": "learn_skill", "sp_cost": 1, "gold_cost": 300, "skill_slug": "elemental_mastery", "book_item_id": 0, "requires_book": false}]}', NULL);
INSERT INTO public.dialogue_node VALUES (552, 5, 'line', 5, 'sylara.dialogue.learned_elemental_mastery', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (599, 5, 'end', 5, NULL, NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (600, 6, 'line', 6, 'npc.ruins_dying_stranger.place_wont_let_go', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (601, 6, 'line', 6, 'npc.ruins_dying_stranger.if_survive_go_exit', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (602, 6, 'line', 6, 'npc.ruins_dying_stranger.wont_escape_but_you_can', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (605, 6, 'line', 6, 'npc.ruins_dying_stranger.farewell', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (609, 6, 'end', 6, NULL, NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (611, 6, 'line', 6, 'npc.ruins_dying_stranger.nothing_more_reply', NULL, NULL, NULL);
INSERT INTO public.dialogue_node VALUES (603, 6, 'choice_hub', 6, 'npc.ruins_dying_stranger.take_this_with_you', NULL, NULL, NULL);


--
-- Data for Name: emote_definitions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.emote_definitions VALUES (7, 'salute', 'Козырять', 'emote_salute', 'social', false, 10, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (8, 'clap', 'Аплодировать', 'emote_clap', 'social', false, 11, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (9, 'shrug', 'Пожать плечами', 'emote_shrug', 'social', false, 12, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (10, 'taunt', 'Дразниться', 'emote_taunt', 'social', false, 13, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (11, 'dance_basic', 'Танцевать', 'emote_dance_basic', 'dance', false, 20, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (12, 'dance_wild', 'Дикий танец', 'emote_dance_wild', 'dance', false, 21, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (13, 'dance_slow', 'Медленный танец', 'emote_dance_slow', 'dance', false, 22, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (1, 'sit', 'Сесть', 'emote_sit', 'basic', false, 1, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (2, 'wave', 'Помахать рукой', 'emote_wave', 'basic', true, 2, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (3, 'bow', 'Поклониться', 'emote_bow', 'basic', false, 3, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (4, 'laugh', 'Смеяться', 'emote_laugh', 'social', false, 4, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (5, 'cry', 'Плакать', 'emote_cry', 'social', false, 5, '2026-04-13 08:53:40.207308+00');
INSERT INTO public.emote_definitions VALUES (6, 'point', 'Указать', 'emote_point', 'basic', false, 6, '2026-04-13 08:53:40.207308+00');


--
-- Data for Name: entity_attributes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (1, 'Maximum Health', 'max_health', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (2, 'Maximum Mana', 'max_mana', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (3, 'Strength', 'strength', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (4, 'Intelligence', 'intelligence', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (6, 'Physical Defense', 'physical_defense', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (7, 'Magical Defense', 'magical_defense', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (10, 'HP Regen /s', 'hp_regen_per_s', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (11, 'MP Regen /s', 'mp_regen_per_s', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (12, 'Physical Attack', 'physical_attack', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (13, 'Magical Attack', 'magical_attack', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (14, 'Accuracy', 'accuracy', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (15, 'Evasion', 'evasion', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (17, 'Block Value', 'block_value', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (18, 'Move Speed', 'move_speed', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (19, 'Attack Speed', 'attack_speed', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (20, 'Cast Speed', 'cast_speed', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (27, 'Constitution', 'constitution', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (28, 'Wisdom', 'wisdom', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (29, 'Agility', 'agility', false);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (8, 'Crit Chance', 'crit_chance', true);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (9, 'Crit Multiplier', 'crit_multiplier', true);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (16, 'Block Chance', 'block_chance', true);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (30, 'Fire Resistance', 'fire_resistance', true);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (31, 'Ice Resistance', 'ice_resistance', true);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (32, 'Nature Resistance', 'nature_resistance', true);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (33, 'Arcane Resistance', 'arcane_resistance', true);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (34, 'Holy Resistance', 'holy_resistance', true);
INSERT INTO public.entity_attributes OVERRIDING SYSTEM VALUE VALUES (35, 'Shadow Resistance', 'shadow_resistance', true);


--
-- Data for Name: equip_slot; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.equip_slot VALUES (1, 'head', 'Head');
INSERT INTO public.equip_slot VALUES (2, 'chest', 'Chest');
INSERT INTO public.equip_slot VALUES (3, 'legs', 'Legs');
INSERT INTO public.equip_slot VALUES (4, 'feet', 'Feet');
INSERT INTO public.equip_slot VALUES (5, 'hands', 'Hands');
INSERT INTO public.equip_slot VALUES (6, 'main_hand', 'Main Hand');
INSERT INTO public.equip_slot VALUES (7, 'off_hand', 'Off Hand');
INSERT INTO public.equip_slot VALUES (8, 'two_hand', 'Two-Handed');
INSERT INTO public.equip_slot VALUES (9, 'ring', 'Ring');
INSERT INTO public.equip_slot VALUES (10, 'neck', 'Neck');
INSERT INTO public.equip_slot VALUES (11, 'trinket', 'Trinket');


--
-- Data for Name: exp_for_level; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.exp_for_level OVERRIDING SYSTEM VALUE VALUES (1, 1, 100);
INSERT INTO public.exp_for_level OVERRIDING SYSTEM VALUE VALUES (2, 2, 500);
INSERT INTO public.exp_for_level OVERRIDING SYSTEM VALUE VALUES (3, 3, 1000);
INSERT INTO public.exp_for_level OVERRIDING SYSTEM VALUE VALUES (4, 4, 2000);
INSERT INTO public.exp_for_level OVERRIDING SYSTEM VALUE VALUES (5, 5, 4000);
INSERT INTO public.exp_for_level OVERRIDING SYSTEM VALUE VALUES (6, 6, 8000);
INSERT INTO public.exp_for_level OVERRIDING SYSTEM VALUE VALUES (7, 7, 15000);
INSERT INTO public.exp_for_level OVERRIDING SYSTEM VALUE VALUES (8, 8, 25000);
INSERT INTO public.exp_for_level OVERRIDING SYSTEM VALUE VALUES (9, 9, 40000);
INSERT INTO public.exp_for_level OVERRIDING SYSTEM VALUE VALUES (10, 10, 60000);


--
-- Data for Name: factions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.factions VALUES (1, 'hunters', 'Гильдия Охотников');
INSERT INTO public.factions VALUES (2, 'city_guard', 'Городская Стража');
INSERT INTO public.factions VALUES (3, 'bandits', 'Bandit Brotherhood');
INSERT INTO public.factions VALUES (4, 'merchants', 'Торговый Союз');
INSERT INTO public.factions VALUES (5, 'nature', 'Духи Природы');


--
-- Data for Name: game_analytics; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: game_config; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.game_config VALUES ('combat.defense_formula_k', '7.5', 'float', 'Коэффициент K в формуле убывающей доходности брони: DR = armor / (armor + K * targetLevel). Чем выше K, тем больше брони нужно для одного и того же % снижения урона. Значение 7.5: на lvl10 нужно 75 брони для 50% DR.', '2026-03-05 14:27:26.320486+00');
INSERT INTO public.game_config VALUES ('combat.defense_cap', '0.85', 'float', 'Максимальный процент снижения урона от физической/магической брони (0–1). Значение 0.85 = максимум 85% снижения. Не позволяет броне даровать полный иммунитет.', '2026-03-05 14:27:26.320486+00');
INSERT INTO public.game_config VALUES ('combat.damage_variance', '0.12', 'float', 'Симметричный разброс базового урона ±N (0–1). Значение 0.12 = каждый удар ±12% от расчётного. Предотвращает предсказуемость одиночного тика и монотонность DPS.', '2026-03-05 14:27:26.320486+00');
INSERT INTO public.game_config VALUES ('combat.level_diff_damage_per_level', '0.04', 'float', 'Бонус/штраф к урону за каждый уровень разницы (0–1). Значение 0.04 = ±4% урона за каждый уровень. Атака по цели выше уровнем = штраф; ниже уровнем = бонус.', '2026-03-05 14:27:26.320486+00');
INSERT INTO public.game_config VALUES ('combat.level_diff_hit_per_level', '0.02', 'float', 'Бонус/штраф к шансу попадания за каждый уровень разницы (0–1). Значение 0.02 = ±2% к hitChance за уровень.', '2026-03-05 14:27:26.320486+00');
INSERT INTO public.game_config VALUES ('combat.level_diff_cap', '10', 'int', 'Максимальная учитываемая разница уровней для штрафов/бонусов. Разница > cap трактуется как cap (не уходит в бесконечность).', '2026-03-05 14:27:26.320486+00');
INSERT INTO public.game_config VALUES ('combat.base_hit_chance', '0.95', 'float', 'Базовый шанс попадания до учёта accuracy/evasion (0–1). Финальный hitChance = base_hit_chance + (accuracy - evasion) * 0.01.', '2026-03-05 14:27:26.320486+00');
INSERT INTO public.game_config VALUES ('combat.hit_chance_min', '0.05', 'float', 'Минимальный возможный шанс попадания (0–1). Даже при огромном уклонении противника не менее N% ударов попадут.', '2026-03-05 14:27:26.320486+00');
INSERT INTO public.game_config VALUES ('combat.hit_chance_max', '0.95', 'float', 'Максимальный возможный шанс попадания (0–1). Даже при огромной точности не более N% ударов попадут.', '2026-03-05 14:27:26.320486+00');
INSERT INTO public.game_config VALUES ('aggro.base_radius', '500', 'int', 'Базовый радиус обнаружения игрока мобом (игровые единицы). Конкретный моб может иметь свой radius из таблицы mobs.', '2026-03-05 14:27:26.320486+00');
INSERT INTO public.game_config VALUES ('aggro.leash_distance', '2000', 'int', 'Дистанция от точки спавна, при превышении которой моб сбрасывает агро и возвращается назад (игровые единицы).', '2026-03-05 14:27:26.320486+00');
INSERT INTO public.game_config VALUES ('combat.max_resistance_cap', '75', 'float', 'Maximum resistance % a target can have for any school (0-100)', '2026-03-05 18:09:52.304703+00');
INSERT INTO public.game_config VALUES ('combat.dot_min_tick_ms', '500', 'float', 'Minimum allowed tick interval for DoT/HoT effects (ms)', '2026-03-05 18:29:09.000283+00');
INSERT INTO public.game_config VALUES ('combat.dot_max_ticks', '20', 'float', 'Maximum number of ticks a single DoT/HoT effect can have', '2026-03-05 18:29:09.000283+00');
INSERT INTO public.game_config VALUES ('combat.aoe_target_cap', '10', 'float', 'Maximum number of targets hit by a single AoE skill cast', '2026-03-05 18:49:40.6975+00');
INSERT INTO public.game_config VALUES ('economy.vendor_sell_tax_pct', '0.0', 'float', 'Global tax on items sold TO vendor (0–1). 0 = vendor pays full vendorPriceSell.', '2026-03-11 12:07:55.916948+00');
INSERT INTO public.game_config VALUES ('economy.vendor_buy_markup_pct', '0.0', 'float', 'Global markup on items bought FROM vendor (0–1). 0 = base vendorPriceBuy.', '2026-03-11 12:07:55.916948+00');
INSERT INTO public.game_config VALUES ('economy.trade_range', '5.0', 'float', 'Max distance (units) between two players for P2P trade to start.', '2026-03-11 12:07:55.916948+00');
INSERT INTO public.game_config VALUES ('durability.death_penalty_pct', '0.05', 'float', 'Fraction of durabilityMax lost on death for each equipped durable item (0–1).', '2026-03-11 12:07:55.916948+00');
INSERT INTO public.game_config VALUES ('durability.weapon_loss_per_hit', '1', 'int', 'Durability points weapon loses per successful attack.', '2026-03-11 12:07:55.916948+00');
INSERT INTO public.game_config VALUES ('durability.armor_loss_per_hit', '1', 'int', 'Durability points each armour piece loses when player receives a hit.', '2026-03-11 12:07:55.916948+00');
INSERT INTO public.game_config VALUES ('carry_weight.base', '50', 'int', 'Base carry weight limit before strength bonus.', '2026-03-11 12:07:56.000172+00');
INSERT INTO public.game_config VALUES ('carry_weight.per_strength', '3', 'float', 'Additional carry weight granted per point of the strength attribute.', '2026-03-11 12:07:56.000172+00');
INSERT INTO public.game_config VALUES ('carry_weight.overweight_speed_penalty', '0.30', 'float', 'Movement speed penalty (fraction 0-1) applied when the character is overweight. 0.30 = -30%.', '2026-03-11 12:07:56.000172+00');
INSERT INTO public.game_config VALUES ('regen.tickIntervalMs', '4000', 'float', NULL, '2026-03-13 19:16:56.542313+00');
INSERT INTO public.game_config VALUES ('regen.baseHpRegen', '2', 'float', NULL, '2026-03-13 19:16:56.542313+00');
INSERT INTO public.game_config VALUES ('regen.baseMpRegen', '1', 'float', NULL, '2026-03-13 19:16:56.542313+00');
INSERT INTO public.game_config VALUES ('regen.hpRegenConCoeff', '0.3', 'float', NULL, '2026-03-13 19:16:56.542313+00');
INSERT INTO public.game_config VALUES ('regen.mpRegenWisCoeff', '0.5', 'float', NULL, '2026-03-13 19:16:56.542313+00');
INSERT INTO public.game_config VALUES ('regen.disableInCombatMs', '8000', 'float', NULL, '2026-03-13 19:16:56.542313+00');
INSERT INTO public.game_config VALUES ('fellowship.bonus_pct', '0.07', 'float', 'Fellowship XP bonus fraction (0–1). Killer and fellows who attacked same mob within window each receive this % of base mob XP.', '2026-03-14 20:09:43.797621+00');
INSERT INTO public.game_config VALUES ('fellowship.attack_window_sec', '15', 'int', 'Time window (seconds) within which a co-attacker qualifies for the fellowship bonus.', '2026-03-14 20:09:43.797621+00');
INSERT INTO public.game_config VALUES ('item_soul.tier1_kills', '50', 'int', 'Kill count threshold for suffix [Veteran] and +1 attribute', '2026-03-14 20:09:43.80189+00');
INSERT INTO public.game_config VALUES ('item_soul.tier2_kills', '200', 'int', 'Kill count threshold for suffix [Bloody] and +2 attribute + 5% crit', '2026-03-14 20:09:43.80189+00');
INSERT INTO public.game_config VALUES ('item_soul.tier3_kills', '500', 'int', 'Kill count threshold for suffix [Legendary] and +3 attribute + 8% crit', '2026-03-14 20:09:43.80189+00');
INSERT INTO public.game_config VALUES ('item_soul.tier1_bonus_flat', '1', 'int', 'Flat attribute bonus at tier 1', '2026-03-14 20:09:43.80189+00');
INSERT INTO public.game_config VALUES ('item_soul.tier2_bonus_flat', '2', 'int', 'Flat attribute bonus at tier 2', '2026-03-14 20:09:43.80189+00');
INSERT INTO public.game_config VALUES ('item_soul.tier3_bonus_flat', '3', 'int', 'Flat attribute bonus at tier 3', '2026-03-14 20:09:43.80189+00');
INSERT INTO public.game_config VALUES ('item_soul.tier2_crit_pct', '0.05', 'float', 'Crit chance bonus at tier 2', '2026-03-14 20:09:43.80189+00');
INSERT INTO public.game_config VALUES ('item_soul.tier3_crit_pct', '0.08', 'float', 'Crit chance bonus at tier 3', '2026-03-14 20:09:43.80189+00');
INSERT INTO public.game_config VALUES ('item_soul.db_flush_every_kills', '5', 'float', NULL, '2026-03-14 20:09:48.042848+00');
INSERT INTO public.game_config VALUES ('exploration.default_xp_reward', '100', 'float', NULL, '2026-03-14 20:09:48.045159+00');
INSERT INTO public.game_config VALUES ('pity.soft_pity_kills', '300', 'int', 'Kill count from which soft pity starts boosting drop chance', '2026-03-15 07:40:02.83585+00');
INSERT INTO public.game_config VALUES ('pity.hard_pity_kills', '800', 'int', 'Kill count at which a guaranteed drop triggers (hard cap, resets counter)', '2026-03-15 07:40:02.83585+00');
INSERT INTO public.game_config VALUES ('pity.soft_bonus_per_kill', '0.00005', 'float', 'Additional flat drop chance per kill after soft_pity_kills threshold', '2026-03-15 07:40:02.83585+00');
INSERT INTO public.game_config VALUES ('combat.default_crit_multiplier', '200', 'float', 'Default crit multiplier as percentage (200 = x2.0). Used when attacker has no crit_multiplier attribute.', '2026-04-18 08:09:30.487328+00');
INSERT INTO public.game_config VALUES ('pity.hint_threshold_kills', '500', 'int', 'Kill count at which to send a pity_hint world notification to the player', '2026-03-15 07:40:02.83585+00');
INSERT INTO public.game_config VALUES ('bestiary.tier1_kills', '1', 'int', 'Kills to unlock tier 1: name, type, HP range, biome', '2026-03-15 07:40:02.83585+00');
INSERT INTO public.game_config VALUES ('bestiary.tier2_kills', '5', 'int', 'Kills to unlock tier 2: weaknesses and resistances', '2026-03-15 07:40:02.83585+00');
INSERT INTO public.game_config VALUES ('bestiary.tier3_kills', '15', 'int', 'Kills to unlock tier 3: common loot table', '2026-03-15 07:40:02.83585+00');
INSERT INTO public.game_config VALUES ('bestiary.tier4_kills', '30', 'int', 'Kills to unlock tier 4: uncommon loot table', '2026-03-15 07:40:02.83585+00');
INSERT INTO public.game_config VALUES ('bestiary.tier5_kills', '75', 'int', 'Kills to unlock tier 5: rare loot table', '2026-03-15 07:40:02.83585+00');
INSERT INTO public.game_config VALUES ('bestiary.tier6_kills', '150', 'int', 'Kills to unlock tier 6: very rare loot (approximate rate shown)', '2026-03-15 07:40:02.83585+00');
INSERT INTO public.game_config VALUES ('mastery.base_delta', '0.5', 'float', 'Base mastery gain per successful hit', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('mastery.db_flush_every_hits', '10', 'int', 'Write mastery to DB every N hits (debounce)', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('mastery.tier1_value', '20', 'float', 'Mastery tier 1 threshold', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('mastery.tier2_value', '50', 'float', 'Mastery tier 2 threshold', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('mastery.tier3_value', '80', 'float', 'Mastery tier 3 threshold (crit unlock)', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('mastery.tier4_value', '100', 'float', 'Mastery tier 4 threshold (parry unlock)', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('reputation.enemy_threshold', '-500', 'int', 'Below this: enemy tier', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('reputation.neutral_threshold', '0', 'int', 'Below this: stranger tier', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('reputation.friendly_threshold', '200', 'int', 'Below this: neutral tier', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('reputation.ally_threshold', '500', 'int', 'Below this: friendly tier', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('zone_event.pre_announce_sec', '300', 'int', 'Seconds before event to send pre-announcement', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('reputation.vendor_buy_discount', '0.05', 'float', 'Buy price reduction for friendly/ally', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('reputation.vendor_sell_bonus', '0.05', 'float', 'Sell price bonus for friendly/ally', '2026-03-15 10:36:42.853016+00');
INSERT INTO public.game_config VALUES ('durability.tier1_threshold_pct', '0.75', 'float', NULL, '2026-04-16 08:33:27.432886+00');
INSERT INTO public.game_config VALUES ('durability.tier1_penalty_pct', '0.05', 'float', NULL, '2026-04-16 08:33:27.432886+00');
INSERT INTO public.game_config VALUES ('durability.tier2_threshold_pct', '0.50', 'float', NULL, '2026-04-16 08:33:27.432886+00');
INSERT INTO public.game_config VALUES ('durability.tier2_penalty_pct', '0.15', 'float', NULL, '2026-04-16 08:33:27.432886+00');
INSERT INTO public.game_config VALUES ('durability.tier3_threshold_pct', '0.25', 'float', NULL, '2026-04-16 08:33:27.432886+00');
INSERT INTO public.game_config VALUES ('durability.tier3_penalty_pct', '0.30', 'float', NULL, '2026-04-16 08:33:27.432886+00');
INSERT INTO public.game_config VALUES ('combat.crit_chance_cap', '75', 'float', 'Maximum crit_chance (%). Prevents 100% crit builds.', '2026-04-18 08:09:30.487328+00');
INSERT INTO public.game_config VALUES ('combat.block_chance_cap', '75', 'float', 'Maximum block_chance (%). Prevents unkillable tank builds.', '2026-04-18 08:09:30.487328+00');
INSERT INTO public.game_config VALUES ('combat.evasion_cap', '75', 'float', 'Maximum evasion effectiveness (%). Prevents un-hittable builds.', '2026-04-18 08:09:30.487328+00');
INSERT INTO public.game_config VALUES ('combat.elemental_resistance_cap', '75', 'float', 'Maximum elemental resistance per school (%). Same as max_resistance_cap default.', '2026-04-18 08:09:30.487328+00');
INSERT INTO public.game_config VALUES ('combat.attack_speed_base_divisor', '100', 'float', 'attack_speed divisor. effectiveSwingMs = baseSwingMs / (1 + attack_speed/divisor).', '2026-04-18 08:09:30.487328+00');
INSERT INTO public.game_config VALUES ('combat.cast_speed_base_divisor', '100', 'float', 'cast_speed divisor. effectiveCastMs = baseCastMs / (1 + cast_speed/divisor).', '2026-04-18 08:09:30.487328+00');


--
-- Data for Name: gm_action_log; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: item_attributes_mapping; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (1, 1, 12, 10, 'equip');
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (2, 2, 6, 5, 'equip');
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (7, 15, 13, 8, 'equip');
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (8, 1, 3, 3, 'equip');
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (9, 15, 4, 3, 'equip');
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (10, 2, 17, 5, 'equip');


--
-- Data for Name: item_class_restrictions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: item_set_bonuses; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: item_set_members; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: item_sets; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: item_types; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.item_types OVERRIDING SYSTEM VALUE VALUES (1, 'Weapon', 'weapon');
INSERT INTO public.item_types OVERRIDING SYSTEM VALUE VALUES (2, 'Armor', 'armor');
INSERT INTO public.item_types OVERRIDING SYSTEM VALUE VALUES (3, 'Potion', 'potion');
INSERT INTO public.item_types OVERRIDING SYSTEM VALUE VALUES (4, 'Food', 'food');
INSERT INTO public.item_types OVERRIDING SYSTEM VALUE VALUES (5, 'Quest Item', 'quest_item');
INSERT INTO public.item_types OVERRIDING SYSTEM VALUE VALUES (6, 'Resource', 'resource');
INSERT INTO public.item_types OVERRIDING SYSTEM VALUE VALUES (7, 'Accessory', 'accessory');
INSERT INTO public.item_types OVERRIDING SYSTEM VALUE VALUES (8, 'Currency', 'currency');
INSERT INTO public.item_types OVERRIDING SYSTEM VALUE VALUES (9, 'Container', 'container');
INSERT INTO public.item_types OVERRIDING SYSTEM VALUE VALUES (10, 'Skill Book', 'skill_book');


--
-- Data for Name: item_use_effects; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.item_use_effects VALUES (1, 3, 'hp_restore_50', 'hp', 50, true, 0, 0, 30);
INSERT INTO public.item_use_effects VALUES (2, 4, 'bread_hot', 'hp', 5, false, 30, 2000, 60);


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (5, 'Ancient Artifact', 'ancient_artifact', 'A mysterious artifact for quests.', true, 5, 0.5, 1, 64, false, false, true, 100, 1, 1, NULL, 0, false, false, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (18, 'Tome of Shield Bash', 'tome_shield_bash', 'A worn training manual describing the technique of Shield Bash.', false, 10, 0.3, 2, 1, false, false, true, 100, 500, 100, NULL, 5, false, false, true, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (19, 'Tome of Whirlwind', 'tome_whirlwind', 'An ancient scroll detailing the devastating Whirlwind technique. Rare.', false, 10, 0.3, 3, 1, false, false, true, 100, 0, 50, NULL, 10, false, false, true, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (2, 'Wooden Shield', 'wooden_shield', 'A basic wooden shield.', false, 2, 3, 1, 64, false, true, true, 100, 40, 15, 7, 1, true, false, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (3, 'Health Potion', 'health_potion', 'Restores 50 health points.', false, 3, 0.5, 1, 64, false, false, true, 100, 10, 4, NULL, 0, false, false, true, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (4, 'Bread', 'bread', 'A loaf of bread to restore hunger.', false, 4, 0.1, 1, 64, false, false, true, 100, 3, 1, NULL, 0, false, false, true, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (6, 'Iron Ore', 'iron_ore', 'A piece of iron ore, useful for crafting.', false, 6, 2, 1, 64, false, false, true, 100, 5, 2, NULL, 0, false, false, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (9, 'Small Animal Skin', 'small_animal_skin', 'A basic skin of small animal.', false, 6, 0.3, 1, 64, false, false, true, 100, 8, 3, NULL, 0, false, true, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (10, 'Animal Fat', 'animal_fat', 'Fat extracted from animal.', false, 6, 0.2, 1, 64, false, false, true, 100, 4, 2, NULL, 0, false, true, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (11, 'Animal Blood', 'animal_blood', 'Blood extracted from animal.', false, 6, 0.5, 1, 64, false, false, true, 100, 4, 1, NULL, 0, false, true, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (12, 'Animal Meat', 'animal_meet', 'Meat extracted from animal.', false, 6, 1, 1, 64, false, false, true, 100, 5, 2, NULL, 0, false, true, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (13, 'Animal Fang', 'animal_fang', 'Fang extracted from animal.', false, 6, 0.2, 1, 64, false, false, true, 100, 6, 3, NULL, 0, false, true, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (14, 'Animal Eye', 'animal_eye', 'Eye extracted from animal.', false, 6, 0.1, 1, 64, false, false, true, 100, 5, 2, NULL, 0, false, true, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (7, 'Small Animal Bone', 'small_animal_bone', 'A small bones of small animal.', false, 6, 0.5, 1, 64, false, false, true, 100, 3, 1, NULL, 0, false, true, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (17, 'Wolf Skin', 'wolf_skin', 'A rough skin of a forest wolf. Milaya will know what to do with it.', true, 6, 0.5, 1, 10, false, false, false, 100, 5, 2, NULL, 0, false, false, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (16, 'Gold Coin', 'gold_coin', 'Universal currency of the realm. Used as payment for goods and services.', false, 8, 0.01, 1, 9999999, false, false, true, 100, 1, 1, NULL, 0, false, false, false, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (20, 'Tome of Iron Skin', 'tome_iron_skin', 'Teachings of hardening the body through relentless training.', false, 10, 0.3, 2, 1, false, false, true, 100, 400, 80, NULL, 5, false, false, true, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (21, 'Tome of Constitution Mastery', 'tome_constitution_mastery', 'A guide to unlocking the body''s true enduring potential.', false, 10, 0.3, 2, 1, false, false, true, 100, 800, 160, NULL, 8, false, false, true, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (22, 'Tome of Frost Bolt', 'tome_frost_bolt', 'Basic arcane theory behind channelling cold into a bolt of frost.', false, 10, 0.3, 2, 1, false, false, true, 100, 500, 100, NULL, 5, false, false, true, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (23, 'Tome of Arcane Blast', 'tome_arcane_blast', 'Concentrated arcane theory on focusing raw magical energy into a blast.', false, 10, 0.3, 2, 1, false, false, true, 100, 900, 180, NULL, 8, false, false, true, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (24, 'Tome of Chain Lightning', 'tome_chain_lightning', 'A legendary scroll describing storm magic that arcs between enemies. Extremely rare.', false, 10, 0.3, 4, 1, false, false, true, 100, 0, 250, NULL, 12, false, false, true, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (25, 'Tome of Mana Shield', 'tome_mana_shield', 'Teachings on weaving mana into a protective aura.', false, 10, 0.3, 2, 1, false, false, true, 100, 600, 120, NULL, 5, false, false, true, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (26, 'Tome of Elemental Mastery', 'tome_elemental_mastery', 'A comprehensive guide to attaining mastery over elemental forces.', false, 10, 0.3, 2, 1, false, false, true, 100, 1200, 240, NULL, 10, false, false, true, false, NULL);
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (15, 'Wooden Staff', 'wooden_staff', 'A simple wooden staff for apprentice mages.', false, 1, 2, 1, 64, false, true, true, 80, 30, 12, 6, 1, true, false, false, false, 'staff_mastery');
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (1, 'Iron Sword', 'iron_sworld', 'A sturdy iron sword.', false, 1, 5, 1, 64, false, true, true, 100, 50, 20, 6, 1, true, false, false, false, 'sword_mastery');


--
-- Data for Name: items_rarity; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.items_rarity VALUES (1, 'Common', '#FFFFFF', 'common');
INSERT INTO public.items_rarity VALUES (2, 'Uncommon', '#1EFF00', 'uncommon');
INSERT INTO public.items_rarity VALUES (3, 'Rare', '#0070DD', 'rare');
INSERT INTO public.items_rarity VALUES (4, 'Epic', '#A335EE', 'epic');
INSERT INTO public.items_rarity VALUES (5, 'Legendary', '#FF8000', 'legendary');


--
-- Data for Name: mastery_definitions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.mastery_definitions VALUES ('sword_mastery', 'Мастерство меча', 'sword', 100);
INSERT INTO public.mastery_definitions VALUES ('axe_mastery', 'Мастерство топора', 'axe', 100);
INSERT INTO public.mastery_definitions VALUES ('staff_mastery', 'Мастерство посоха', 'staff', 100);
INSERT INTO public.mastery_definitions VALUES ('bow_mastery', 'Мастерство лука', 'bow', 100);
INSERT INTO public.mastery_definitions VALUES ('unarmed_mastery', 'Рукопашный бой', NULL, 100);


--
-- Data for Name: mob; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.mob OVERRIDING SYSTEM VALUE VALUES (1, 'Small Fox', 2, 1, 40, 0, false, false, 'SmallFox', 100, 15, 1, 600, 120, 2.5, 1.8, 0.9, true, 30, 0, 'melee', false, false, 0, NULL, NULL, 0, '', 'beast');
INSERT INTO public.mob OVERRIDING SYSTEM VALUE VALUES (2, 'Grey Wolf', 2, 1, 80, 0, true, false, 'GreyWolf', 100, 20, 1, 700, 120, 2, 2.2, 1.1, false, 30, 0, 'melee', false, false, 0, NULL, NULL, 0, '', 'beast');


--
-- Data for Name: mob_active_effect; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: mob_loot_info; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (10, 1, 3, 0.10, false, 1, 1, 'common');
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (11, 1, 9, 0.60, true, 1, 1, 'common');
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (12, 1, 10, 0.30, true, 1, 1, 'common');
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (13, 1, 11, 0.20, true, 1, 2, 'common');
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (14, 1, 12, 0.15, true, 1, 1, 'common');
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (15, 2, 6, 0.15, false, 1, 2, 'common');
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (16, 2, 9, 0.50, true, 1, 1, 'common');
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (17, 2, 11, 0.30, true, 1, 1, 'common');
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (18, 2, 12, 0.15, true, 1, 1, 'common');
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (19, 2, 13, 0.20, true, 1, 1, 'common');
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (35, 2, 17, 0.40, false, 1, 1, 'common');


--
-- Data for Name: mob_position; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: mob_race; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.mob_race OVERRIDING SYSTEM VALUE VALUES (1, 'Goblin');
INSERT INTO public.mob_race OVERRIDING SYSTEM VALUE VALUES (2, 'Animal');
INSERT INTO public.mob_race OVERRIDING SYSTEM VALUE VALUES (3, 'Troll');


--
-- Data for Name: mob_ranks; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.mob_ranks VALUES (1, 'normal', 1.00);
INSERT INTO public.mob_ranks VALUES (2, 'pack', 0.60);
INSERT INTO public.mob_ranks VALUES (3, 'strong', 1.50);
INSERT INTO public.mob_ranks VALUES (4, 'elite', 2.20);
INSERT INTO public.mob_ranks VALUES (5, 'miniboss', 5.00);
INSERT INTO public.mob_ranks VALUES (6, 'boss', 20.00);


--
-- Data for Name: mob_resistances; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: mob_skills; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.mob_skills VALUES (1, 1, 1, 1);
INSERT INTO public.mob_skills VALUES (2, 2, 1, 1);


--
-- Data for Name: mob_stat; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (137, 1, 1, 40.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (138, 1, 2, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (139, 1, 12, 6.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (140, 1, 13, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (141, 1, 6, 2.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (142, 1, 7, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (143, 1, 8, 3.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (144, 1, 9, 200.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (145, 1, 14, 4.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (146, 1, 15, 8.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (147, 1, 16, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (148, 1, 17, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (149, 1, 10, 0.50, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (150, 1, 11, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (151, 1, 18, 6.50, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (152, 1, 19, 5.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (153, 1, 20, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (154, 1, 3, 3.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (155, 1, 4, 1.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (156, 1, 27, 3.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (157, 1, 28, 1.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (158, 1, 29, 8.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (159, 1, 30, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (160, 1, 31, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (161, 1, 32, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (162, 1, 33, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (163, 1, 34, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (164, 1, 35, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (165, 2, 1, 80.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (166, 2, 2, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (167, 2, 12, 10.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (168, 2, 13, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (169, 2, 6, 5.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (170, 2, 7, 2.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (171, 2, 8, 5.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (172, 2, 9, 200.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (173, 2, 14, 6.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (174, 2, 15, 4.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (175, 2, 16, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (176, 2, 17, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (177, 2, 10, 1.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (178, 2, 11, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (179, 2, 18, 5.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (180, 2, 19, 5.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (181, 2, 20, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (182, 2, 3, 6.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (183, 2, 4, 2.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (184, 2, 27, 6.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (185, 2, 28, 2.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (186, 2, 29, 5.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (187, 2, 30, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (188, 2, 31, 2.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (189, 2, 32, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (190, 2, 33, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (191, 2, 34, 0.00, NULL, NULL);
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (192, 2, 35, 0.00, NULL, NULL);


--
-- Data for Name: mob_weaknesses; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: npc; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.npc OVERRIDING SYSTEM VALUE VALUES (1, 'Varan', 1, 1, 100, 10, false, 'varan', 100, true, 1, NULL);
INSERT INTO public.npc OVERRIDING SYSTEM VALUE VALUES (3, 'Edrik', 1, 1, 100, 20, false, 'edrik', 100, true, 1, NULL);
INSERT INTO public.npc OVERRIDING SYSTEM VALUE VALUES (2, 'Milaya', 1, 1, 100, 50, false, 'milaya', 100, true, 3, NULL);
INSERT INTO public.npc OVERRIDING SYSTEM VALUE VALUES (4, 'Theron', 1, 5, 500, 100, false, 'theron', 100, true, 6, NULL);
INSERT INTO public.npc OVERRIDING SYSTEM VALUE VALUES (5, 'Sylara', 1, 5, 400, 250, false, 'sylara', 100, true, 6, NULL);
INSERT INTO public.npc OVERRIDING SYSTEM VALUE VALUES (6, 'ruins_dying_stranger', 1, 1, 1, 0, false, 'ruins_dying_stranger', 300, true, 1, NULL);


--
-- Data for Name: npc_ambient_speech_configs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.npc_ambient_speech_configs VALUES (1, 6, 10, 30);


--
-- Data for Name: npc_ambient_speech_lines; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.npc_ambient_speech_lines VALUES (1, 6, 'npc.ruins_dying_stranger.ambient.another_one', 'periodic', 400, 0, 10, 15, NULL);
INSERT INTO public.npc_ambient_speech_lines VALUES (2, 6, 'npc.ruins_dying_stranger.ambient.keep_coming', 'periodic', 400, 0, 10, 15, NULL);
INSERT INTO public.npc_ambient_speech_lines VALUES (3, 6, 'npc.ruins_dying_stranger.ambient.come_closer', 'periodic', 400, 0, 15, 10, NULL);


--
-- Data for Name: npc_attributes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (1, 1, 1, 100);
INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (2, 1, 2, 10);
INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (3, 2, 1, 100);
INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (4, 2, 2, 50);
INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (5, 3, 1, 100);
INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (7, 3, 2, 50);
INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (8, 4, 1, 500);
INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (9, 4, 2, 100);
INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (10, 5, 1, 400);
INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (11, 5, 2, 250);
INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (12, 6, 1, 50);
INSERT INTO public.npc_attributes OVERRIDING SYSTEM VALUE VALUES (13, 6, 2, 0);


--
-- Data for Name: npc_dialogue; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.npc_dialogue VALUES (2, 1, 0, NULL);
INSERT INTO public.npc_dialogue VALUES (1, 2, 0, NULL);
INSERT INTO public.npc_dialogue VALUES (3, 3, 0, NULL);
INSERT INTO public.npc_dialogue VALUES (4, 4, 0, NULL);
INSERT INTO public.npc_dialogue VALUES (5, 5, 0, NULL);
INSERT INTO public.npc_dialogue VALUES (6, 6, 0, NULL);


--
-- Data for Name: npc_placements; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.npc_placements VALUES (2, 2, 1, 2200, 1120, 200, 145);
INSERT INTO public.npc_placements VALUES (3, 1, 1, 585, -3300, 200, -40);
INSERT INTO public.npc_placements VALUES (4, 4, 1, 1200, -2800, 200, 90);
INSERT INTO public.npc_placements VALUES (5, 5, 1, -400, 1600, 200, -90);
INSERT INTO public.npc_placements VALUES (6, 4, 1, 1200, -2800, 200, 90);
INSERT INTO public.npc_placements VALUES (7, 5, 1, -400, 1600, 200, -90);
INSERT INTO public.npc_placements VALUES (8, 4, 1, 1200, -2800, 200, 90);
INSERT INTO public.npc_placements VALUES (9, 5, 1, -400, 1600, 200, -90);
INSERT INTO public.npc_placements VALUES (11, 5, 1, -400, 1600, 200, -90);
INSERT INTO public.npc_placements VALUES (1, 3, 1, -707.9418710891405, 2225.290678878562, 200, -135);
INSERT INTO public.npc_placements VALUES (12, 6, NULL, 19227.884269950428, -19046.866788016774, 1490, 180);


--
-- Data for Name: npc_position; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.npc_position OVERRIDING SYSTEM VALUE VALUES (2, 3, -720.00, 2250.00, 200.00, -135.00, NULL);
INSERT INTO public.npc_position OVERRIDING SYSTEM VALUE VALUES (3, 2, 2200.00, 1120.00, 200.00, 145.00, NULL);
INSERT INTO public.npc_position OVERRIDING SYSTEM VALUE VALUES (1, 1, 585.00, -3300.00, 200.00, -40.00, NULL);
INSERT INTO public.npc_position OVERRIDING SYSTEM VALUE VALUES (6, 4, 1200.00, -2800.00, 200.00, 90.00, NULL);
INSERT INTO public.npc_position OVERRIDING SYSTEM VALUE VALUES (7, 5, -400.00, 1600.00, 200.00, -90.00, NULL);
INSERT INTO public.npc_position OVERRIDING SYSTEM VALUE VALUES (8, 6, 18870.00, -15430.00, 1490.00, 180.00, NULL);


--
-- Data for Name: npc_skills; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.npc_skills VALUES (1, 1, 1, 1);
INSERT INTO public.npc_skills VALUES (2, 2, 1, 1);
INSERT INTO public.npc_skills VALUES (3, 3, 1, 1);


--
-- Data for Name: npc_trainer_class; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.npc_trainer_class VALUES (1, 4, 2);
INSERT INTO public.npc_trainer_class VALUES (2, 5, 1);


--
-- Data for Name: npc_type; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.npc_type OVERRIDING SYSTEM VALUE VALUES (1, 'General', 'general');
INSERT INTO public.npc_type OVERRIDING SYSTEM VALUE VALUES (2, 'Vendor', 'vendor');
INSERT INTO public.npc_type OVERRIDING SYSTEM VALUE VALUES (3, 'Quest Giver', 'quest_giver');
INSERT INTO public.npc_type OVERRIDING SYSTEM VALUE VALUES (4, 'Blacksmith', 'blacksmith');
INSERT INTO public.npc_type OVERRIDING SYSTEM VALUE VALUES (5, 'Guard', 'guard');
INSERT INTO public.npc_type OVERRIDING SYSTEM VALUE VALUES (6, 'Trainer', 'trainer');


--
-- Data for Name: passive_skill_modifiers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.passive_skill_modifiers VALUES (1, 6, 'physical_defense', 'flat', 15);
INSERT INTO public.passive_skill_modifiers VALUES (2, 7, 'max_health', 'percent', 8);
INSERT INTO public.passive_skill_modifiers VALUES (3, 11, 'max_mana', 'flat', 200);
INSERT INTO public.passive_skill_modifiers VALUES (4, 12, 'magical_attack', 'percent', 12);


--
-- Data for Name: player_active_effect; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: player_flag; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.player_flag VALUES (2, 'explored_fields', 0, true, '2026-03-17 18:56:09.931882+00');
INSERT INTO public.player_flag VALUES (3, 'explored_wilderness', 0, true, '2026-03-16 16:46:29.756499+00');
INSERT INTO public.player_flag VALUES (3, 'explored_fields', 0, true, '2026-03-21 18:18:49.109903+00');
INSERT INTO public.player_flag VALUES (3, 'explored_village', 0, true, '2026-03-21 19:01:39.204408+00');
INSERT INTO public.player_flag VALUES (3, 'ruins_dying_stranger.received_gift', 0, true, '2026-04-15 19:23:09.955401+00');
INSERT INTO public.player_flag VALUES (2, 'explored_village', 0, true, '2026-03-20 19:31:36.562042+00');


--
-- Data for Name: player_inventory; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.player_inventory OVERRIDING SYSTEM VALUE VALUES (221, 3, 1, 8, NULL, 100, 0);
INSERT INTO public.player_inventory OVERRIDING SYSTEM VALUE VALUES (3, 1, 3, 5, NULL, NULL, 0);
INSERT INTO public.player_inventory OVERRIDING SYSTEM VALUE VALUES (165, 3, 3, 107, NULL, NULL, 0);
INSERT INTO public.player_inventory OVERRIDING SYSTEM VALUE VALUES (176, 3, 15, 1, NULL, 36, 42);
INSERT INTO public.player_inventory OVERRIDING SYSTEM VALUE VALUES (234, 3, 10, 1, NULL, NULL, 0);
INSERT INTO public.player_inventory OVERRIDING SYSTEM VALUE VALUES (169, 3, 16, 9600, NULL, NULL, 0);
INSERT INTO public.player_inventory OVERRIDING SYSTEM VALUE VALUES (230, 2, 3, 6, NULL, NULL, 0);
INSERT INTO public.player_inventory OVERRIDING SYSTEM VALUE VALUES (18, 3, 17, 8, NULL, NULL, 0);


--
-- Data for Name: player_quest; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.player_quest VALUES (3, 1, 'completed', 2, '{"have": 2}', '2026-04-15 20:17:37.869024+00');


--
-- Data for Name: quest; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.quest VALUES (1, 'wolf_hunt_intro', 1, true, 600, 2, 2, 'quest.wolf_hunt_intro', NULL, 0, 0);


--
-- Data for Name: quest_reward; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.quest_reward VALUES (2, 1, 'exp', NULL, 0, 300, false);
INSERT INTO public.quest_reward VALUES (1, 1, 'item', 3, 5, 5, false);


--
-- Data for Name: quest_step; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.quest_step VALUES (1, 1, 0, 'kill', '{"count": 5, "mob_id": 2}', 'quest.wolf_hunt_intro.kill_wolves', 'auto');
INSERT INTO public.quest_step VALUES (4, 1, 2, 'collect', '{"count": 2, "item_id": 17}', 'quest.wolf_hunt_intro.collect_wolf_skins', 'auto');
INSERT INTO public.quest_step VALUES (3, 1, 1, 'custom', '{}', 'quest.wolf_hunt_intro.report_to_milaya', 'manual');


--
-- Data for Name: race; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.race OVERRIDING SYSTEM VALUE VALUES (1, 'Human', 'human');
INSERT INTO public.race OVERRIDING SYSTEM VALUE VALUES (2, 'Elf', 'elf');


--
-- Data for Name: respawn_zones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.respawn_zones VALUES (1, 'Starting Village', 0, 0, 200, 1, true);


--
-- Data for Name: skill_damage_formulas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.skill_damage_formulas VALUES (1, 'coeff', 1);
INSERT INTO public.skill_damage_formulas VALUES (2, 'flat_add', 1);
INSERT INTO public.skill_damage_formulas VALUES (3, 'passive_marker', 2);


--
-- Data for Name: skill_damage_types; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.skill_damage_types VALUES (1, 'damage');
INSERT INTO public.skill_damage_types VALUES (3, 'dot');
INSERT INTO public.skill_damage_types VALUES (4, 'hot');
INSERT INTO public.skill_damage_types VALUES (2, 'passive');


--
-- Data for Name: skill_effect_instances; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.skill_effect_instances VALUES (1, 1, 1, 1);
INSERT INTO public.skill_effect_instances VALUES (2, 2, 1, 1);
INSERT INTO public.skill_effect_instances VALUES (3, 3, 1, 1);
INSERT INTO public.skill_effect_instances VALUES (4, 4, 1, 1);
INSERT INTO public.skill_effect_instances VALUES (5, 5, 1, 1);
INSERT INTO public.skill_effect_instances VALUES (6, 6, 1, 1);
INSERT INTO public.skill_effect_instances VALUES (7, 7, 1, 1);
INSERT INTO public.skill_effect_instances VALUES (8, 8, 1, 1);
INSERT INTO public.skill_effect_instances VALUES (9, 9, 1, 1);
INSERT INTO public.skill_effect_instances VALUES (10, 10, 1, 1);
INSERT INTO public.skill_effect_instances VALUES (11, 11, 1, 1);
INSERT INTO public.skill_effect_instances VALUES (12, 12, 1, 1);


--
-- Data for Name: skill_effects_mapping; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.skill_effects_mapping VALUES (1, 1, 1, 1.0, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (2, 2, 1, 1.8, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (3, 2, 2, 30, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (4, 3, 1, 2.2, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (5, 1, 2, 1, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (6, 3, 2, 20, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (7, 4, 1, 1.4, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (8, 4, 2, 40, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (9, 5, 1, 1.2, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (10, 5, 2, 25, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (11, 6, 3, 0, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (12, 7, 3, 0, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (13, 8, 1, 1.6, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (14, 8, 2, 20, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (15, 9, 1, 2.0, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (16, 9, 2, 50, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (17, 10, 1, 1.5, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (18, 10, 2, 30, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (19, 11, 3, 0, 1, 0, 0, NULL);
INSERT INTO public.skill_effects_mapping VALUES (20, 12, 3, 0, 1, 0, 0, NULL);


--
-- Data for Name: skill_properties; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.skill_properties OVERRIDING SYSTEM VALUE VALUES (2, 'Cooldown (ms)', 'cooldown_ms');
INSERT INTO public.skill_properties OVERRIDING SYSTEM VALUE VALUES (4, 'Cast (ms)', 'cast_ms');
INSERT INTO public.skill_properties OVERRIDING SYSTEM VALUE VALUES (5, 'Cost MP', 'cost_mp');
INSERT INTO public.skill_properties OVERRIDING SYSTEM VALUE VALUES (6, 'Max Range', 'max_range');
INSERT INTO public.skill_properties OVERRIDING SYSTEM VALUE VALUES (3, 'Global Cooldown (ms)', 'gcd_ms');
INSERT INTO public.skill_properties OVERRIDING SYSTEM VALUE VALUES (7, 'Area Radius', 'area_radius');
INSERT INTO public.skill_properties OVERRIDING SYSTEM VALUE VALUES (8, 'Swing Duration (ms)', 'swing_ms');


--
-- Data for Name: skill_properties_mapping; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (1, 1, 1, 6, 2.5);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (2, 2, 1, 5, 20);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (3, 2, 1, 2, 6000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (4, 2, 1, 3, 1000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (5, 2, 1, 6, 2.5);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (9, 3, 1, 6, 15);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (10, 1, 1, 3, 500);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (8, 3, 1, 4, 4000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (12, 2, 1, 4, 2000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (15, 4, 1, 2, 5000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (16, 4, 1, 3, 1000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (18, 4, 1, 5, 30);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (19, 4, 1, 6, 2.5);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (21, 5, 1, 2, 12000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (22, 5, 1, 3, 1000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (24, 5, 1, 5, 50);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (25, 5, 1, 6, 3.0);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (26, 5, 1, 7, 4.0);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (28, 8, 1, 2, 7000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (29, 8, 1, 3, 1000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (30, 8, 1, 4, 2000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (31, 8, 1, 5, 35);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (32, 8, 1, 6, 15);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (33, 9, 1, 2, 10000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (34, 9, 1, 3, 1000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (35, 9, 1, 4, 3000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (36, 9, 1, 5, 55);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (37, 9, 1, 6, 12);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (38, 10, 1, 2, 15000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (39, 10, 1, 3, 1000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (40, 10, 1, 4, 2500);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (41, 10, 1, 5, 70);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (42, 10, 1, 6, 15);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (43, 10, 1, 7, 8.0);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (6, 3, 1, 5, 3);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (11, 1, 1, 2, 1000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (17, 4, 1, 4, 1000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (23, 5, 1, 4, 1000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (50, 10, 1, 8, 100);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (49, 9, 1, 8, 100);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (48, 8, 1, 8, 100);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (27, 5, 1, 8, 100);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (20, 4, 1, 8, 100);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (46, 2, 1, 8, 100);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (44, 1, 1, 8, 1200);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (14, 1, 1, 4, 0);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (7, 3, 1, 2, 5000);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (13, 3, 1, 3, 500);
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES (47, 3, 1, 8, 300);


--
-- Data for Name: skill_scale_type; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.skill_scale_type OVERRIDING SYSTEM VALUE VALUES (1, 'PhysAtk', 'physical_attack');
INSERT INTO public.skill_scale_type OVERRIDING SYSTEM VALUE VALUES (2, 'MagAtk', 'magical_attack');


--
-- Data for Name: skill_school; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.skill_school OVERRIDING SYSTEM VALUE VALUES (1, 'Physical', 'physical');
INSERT INTO public.skill_school OVERRIDING SYSTEM VALUE VALUES (2, 'Magical', 'magical');
INSERT INTO public.skill_school OVERRIDING SYSTEM VALUE VALUES (3, 'Fire', 'fire');
INSERT INTO public.skill_school OVERRIDING SYSTEM VALUE VALUES (4, 'Ice', 'ice');
INSERT INTO public.skill_school OVERRIDING SYSTEM VALUE VALUES (5, 'Nature', 'nature');
INSERT INTO public.skill_school OVERRIDING SYSTEM VALUE VALUES (6, 'Arcane', 'arcane');
INSERT INTO public.skill_school OVERRIDING SYSTEM VALUE VALUES (7, 'Holy', 'holy');
INSERT INTO public.skill_school OVERRIDING SYSTEM VALUE VALUES (8, 'Shadow', 'shadow');


--
-- Data for Name: skills; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (1, 'Basic Attack', 'basic_attack', 1, 1, NULL, false);
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (2, 'Power Slash', 'power_slash', 1, 1, NULL, false);
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (4, 'Shield Bash', 'shield_bash', 1, 1, NULL, false);
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (5, 'Whirlwind', 'whirlwind', 1, 1, NULL, false);
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (6, 'Iron Skin', 'iron_skin', 1, 1, NULL, true);
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (7, 'Constitution Mastery', 'constitution_mastery', 1, 1, NULL, true);
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (11, 'Mana Shield', 'mana_shield', 2, 2, NULL, true);
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (12, 'Elemental Mastery', 'elemental_mastery', 2, 2, NULL, true);
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (3, 'Fireball', 'fireball', 2, 3, NULL, false);
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (8, 'Frost Bolt', 'frost_bolt', 2, 4, NULL, false);
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (9, 'Arcane Blast', 'arcane_blast', 2, 6, NULL, false);
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES (10, 'Chain Lightning', 'chain_lightning', 2, 6, NULL, false);


--
-- Data for Name: spawn_zone_mobs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.spawn_zone_mobs VALUES (1, 1, 1, 3, '00:01:00');
INSERT INTO public.spawn_zone_mobs VALUES (2, 2, 2, 5, '00:01:00');


--
-- Data for Name: spawn_zones; Type: TABLE DATA; Schema: public; Owner: -
--

-- zone_id, zone_name, min_spawn_x, min_spawn_y, min_spawn_z, max_spawn_x, max_spawn_y, max_spawn_z, game_zone_id, shape_type, center_x, center_y, inner_radius, outer_radius, exclusion_game_zone_id
INSERT INTO public.spawn_zones VALUES (1, 'Foxes Nest',        773.2522063107463, 3443.7282472654915, 100, 3773.2522063107463, 4943.7282472654915, 500, 2, 'RECT',    2273.252, 4193.728, 0, 0, NULL);
INSERT INTO public.spawn_zones VALUES (2, 'Wolf Place',        -1500, 3500, 100, 0, 5000, 500, 2, 'RECT',   -750,  4250, 0, 0, NULL);
INSERT INTO public.spawn_zones VALUES (3, 'Wolf Pack Zone',    -4000, 5500, 100, -2000, 7000, 500, 2, 'RECT', -3000,  6250, 0, 0, NULL);
INSERT INTO public.spawn_zones VALUES (4, 'Old Wolf Territory',-6500, 3000, 100, -4500, 5000, 500, 2, 'RECT', -5500,  4000, 0, 0, NULL);
INSERT INTO public.spawn_zones VALUES (5, 'Goblin Area',       -8000, 2000, 100, -5500, 4500, 500, 2, 'RECT', -6750,  3250, 0, 0, NULL);


--
-- Data for Name: status_effect_modifiers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.status_effect_modifiers VALUES (1, 1, NULL, 'percent_all', -20);


--
-- Data for Name: status_effects; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.status_effects VALUES (1, 'resurrection_sickness', 'debuff', 120);
INSERT INTO public.status_effects VALUES (2, 'bread_hot', 'hot', 30);


--
-- Data for Name: target_type; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.target_type VALUES (1, 'enemy');
INSERT INTO public.target_type VALUES (2, 'ally');
INSERT INTO public.target_type VALUES (3, 'self');


--
-- Data for Name: timed_champion_templates; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: title_definitions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.title_definitions VALUES (1, 'wolf_slayer', 'Волкобой', 'Достиг максимального тира бестиария серого волка. Волки тебя не пугают.', 'bestiary', '[{"value": 2.0, "attributeSlug": "physical_attack"}, {"value": 1.0, "attributeSlug": "move_speed"}]', '{"minTier": 6, "mobSlug": "GreyWolf"}');
INSERT INTO public.title_definitions VALUES (2, 'wolf_hunter', 'Охотник на волков', 'Достиг 3-го тира бестиария серого волка. Ты знаешь их повадки.', 'bestiary', '[{"value": 1.0, "attributeSlug": "physical_attack"}]', '{"minTier": 3, "mobSlug": "GreyWolf"}');
INSERT INTO public.title_definitions VALUES (3, 'goblin_exterminator', 'Истребитель гоблинов', 'Достиг 4-го тира бестиария лесного гоблина. Гоблины боятся тебя.', 'bestiary', '[{"value": 1.5, "attributeSlug": "physical_attack"}, {"value": 1.0, "attributeSlug": "physical_defense"}]', '{"minTier": 4, "mobSlug": "ForestGoblin"}');
INSERT INTO public.title_definitions VALUES (4, 'swordsman', 'Мечник', 'Достиг 3-го тира мастерства меча. Клинок — твоё продолжение.', 'mastery', '[{"value": 3.0, "attributeSlug": "physical_attack"}, {"value": 0.5, "attributeSlug": "crit_chance"}]', '{"minTier": 3, "masterySlug": "sword_mastery"}');
INSERT INTO public.title_definitions VALUES (6, 'bowmaster', 'Мастер лука', 'Достиг 3-го тира мастерства лука. Стрелы не знают промаха.', 'mastery', '[{"value": 1.0, "attributeSlug": "crit_chance"}, {"value": 2.0, "attributeSlug": "physical_attack"}]', '{"minTier": 3, "masterySlug": "bow_mastery"}');
INSERT INTO public.title_definitions VALUES (7, 'friend_of_hunters', 'Союзник Гильдии Охотников', 'Достиг статуса союзника в Гильдии Охотников.', 'reputation', '[{"value": 2.0, "attributeSlug": "move_speed"}, {"value": 1.0, "attributeSlug": "physical_attack"}]', '{"factionSlug": "hunters", "minTierName": "ally"}');
INSERT INTO public.title_definitions VALUES (8, 'city_guardian', 'Страж Города', 'Достиг статуса союзника в Городской Страже.', 'reputation', '[{"value": 3.0, "attributeSlug": "physical_defense"}, {"value": 15.0, "attributeSlug": "max_health"}]', '{"factionSlug": "city_guard", "minTierName": "ally"}');
INSERT INTO public.title_definitions VALUES (9, 'bandit_friend', 'Свой среди чужих', 'Достиг статуса союзника в Братстве Бандитов.', 'reputation', '[{"value": 3.0, "attributeSlug": "move_speed"}]', '{"factionSlug": "bandits", "minTierName": "ally"}');
INSERT INTO public.title_definitions VALUES (10, 'seasoned_adventurer', 'Бывалый искатель приключений', 'Достиг 10-го уровня. Путь только начинается.', 'level', '[{"value": 10.0, "attributeSlug": "max_health"}]', '{"level": 10}');
INSERT INTO public.title_definitions VALUES (11, 'veteran', 'Ветеран', 'Достиг 25-го уровня. Опыт не купить за золото.', 'level', '[{"value": 5.0, "attributeSlug": "physical_defense"}, {"value": 20.0, "attributeSlug": "max_health"}]', '{"level": 25}');
INSERT INTO public.title_definitions VALUES (12, 'first_hunter', 'Первая охота', 'Завершил вводное задание по охоте на волков.', 'quest', '[{"value": 1.0, "attributeSlug": "physical_attack"}]', '{"questSlug": "wolf_hunt_intro"}');
INSERT INTO public.title_definitions VALUES (5, 'archmage', 'Архимаг', 'Достиг 4-го тира мастерства посоха. Магия послушна тебе.', 'mastery', '[{"value": 5.0, "attributeSlug": "magical_attack"}]', '{"minTier": 4, "masterySlug": "staff_mastery"}');


--
-- Data for Name: user_bans; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.user_roles VALUES (1, 'gm', 'GM', true);
INSERT INTO public.user_roles VALUES (0, 'player', 'Player', false);
INSERT INTO public.user_roles VALUES (2, 'admin', 'Admin', true);


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.user_sessions VALUES (1, 3, '99a2ff2c-71d0-44af-8551-228eaa9f321b', NULL, NULL, '2026-03-07 17:32:24.180671+00', '2026-04-06 17:32:24.180671+00', NULL);
INSERT INTO public.user_sessions VALUES (2, 3, '3beef1a4-83f3-4470-a080-ec36c73f7329', NULL, NULL, '2026-03-07 17:35:18.853984+00', '2026-04-06 17:35:18.853984+00', NULL);
INSERT INTO public.user_sessions VALUES (3, 3, '15b5e388-89bd-46de-812d-212cb12bd4bb', NULL, NULL, '2026-03-07 17:35:29.616026+00', '2026-04-06 17:35:29.616026+00', NULL);
INSERT INTO public.user_sessions VALUES (4, 3, 'c4d1996f-b00d-4803-b072-43fde712d71c', NULL, NULL, '2026-03-07 17:36:57.808504+00', '2026-04-06 17:36:57.808504+00', NULL);
INSERT INTO public.user_sessions VALUES (5, 3, 'd07b0ebf-ee41-4332-8bfb-bf8df4de3d86', NULL, NULL, '2026-03-07 17:37:32.135309+00', '2026-04-06 17:37:32.135309+00', NULL);
INSERT INTO public.user_sessions VALUES (6, 3, '9a2fd7dc-71c9-45b1-8a16-9a067740b6b9', NULL, NULL, '2026-03-07 17:37:48.307715+00', '2026-04-06 17:37:48.307715+00', NULL);
INSERT INTO public.user_sessions VALUES (7, 3, '291f7369-457f-4049-b5ee-f6c3f8e84412', NULL, NULL, '2026-03-07 17:43:11.963798+00', '2026-04-06 17:43:11.963798+00', NULL);
INSERT INTO public.user_sessions VALUES (8, 3, 'eaa869fd-bebe-48b2-b443-ae529f153774', NULL, NULL, '2026-03-07 17:44:59.536453+00', '2026-04-06 17:44:59.536453+00', NULL);
INSERT INTO public.user_sessions VALUES (9, 3, '8733615c-6153-4b9d-b694-2375a4ab01dc', NULL, NULL, '2026-03-07 17:46:14.328222+00', '2026-04-06 17:46:14.328222+00', NULL);
INSERT INTO public.user_sessions VALUES (10, 3, '25ef102c-1712-4dd4-961d-ce952714bf59', NULL, NULL, '2026-03-07 17:49:46.110537+00', '2026-04-06 17:49:46.110537+00', NULL);
INSERT INTO public.user_sessions VALUES (11, 3, '4316baa8-e2f1-45f0-a335-bce06d8a60f3', NULL, NULL, '2026-03-07 18:13:50.800143+00', '2026-04-06 18:13:50.800143+00', NULL);
INSERT INTO public.user_sessions VALUES (12, 3, '82d35e77-850b-4da0-97a5-4e97b0e76a85', NULL, NULL, '2026-03-07 18:17:28.423213+00', '2026-04-06 18:17:28.423213+00', NULL);
INSERT INTO public.user_sessions VALUES (13, 3, '9928dd7f-3a80-42cd-92e8-17d830fd3dd0', NULL, NULL, '2026-03-07 18:40:56.794183+00', '2026-04-06 18:40:56.794183+00', NULL);
INSERT INTO public.user_sessions VALUES (14, 3, '4ad6e2b5-e035-4a2c-913d-956f172075f5', NULL, NULL, '2026-03-07 18:43:16.799234+00', '2026-04-06 18:43:16.799234+00', NULL);
INSERT INTO public.user_sessions VALUES (15, 4, '1073d1dc-7c5d-4fb2-9381-a8a17e688abf', NULL, NULL, '2026-03-07 18:44:18.705858+00', '2026-04-06 18:44:18.705858+00', NULL);
INSERT INTO public.user_sessions VALUES (16, 3, '33395bfc-1373-451c-b2c3-01fec658df46', NULL, NULL, '2026-03-07 18:44:57.723866+00', '2026-04-06 18:44:57.723866+00', NULL);
INSERT INTO public.user_sessions VALUES (17, 3, '6336607d-a11f-40ad-b4cb-aa3fda4f4854', NULL, NULL, '2026-03-07 18:45:42.046647+00', '2026-04-06 18:45:42.046647+00', NULL);
INSERT INTO public.user_sessions VALUES (18, 3, 'fe1639fe-4cbd-43e7-bc9c-d16d09aab99d', NULL, NULL, '2026-03-07 18:46:34.56956+00', '2026-04-06 18:46:34.56956+00', NULL);
INSERT INTO public.user_sessions VALUES (19, 3, '8db64948-97dd-4dd6-b84f-16e59f8e15b5', NULL, NULL, '2026-03-07 18:47:41.753275+00', '2026-04-06 18:47:41.753275+00', NULL);
INSERT INTO public.user_sessions VALUES (20, 3, '38a6d692-5a1e-422d-a376-89734c2d5aee', NULL, NULL, '2026-03-07 18:50:17.381839+00', '2026-04-06 18:50:17.381839+00', NULL);
INSERT INTO public.user_sessions VALUES (21, 3, '6c6a4227-4065-4c84-8f0c-8523fd5182ee', NULL, NULL, '2026-03-07 18:55:25.887149+00', '2026-04-06 18:55:25.887149+00', NULL);
INSERT INTO public.user_sessions VALUES (22, 3, 'afcc993c-20e3-4b1b-8eda-b294cdb0a0e8', NULL, NULL, '2026-03-07 20:05:49.534365+00', '2026-04-06 20:05:49.534365+00', NULL);
INSERT INTO public.user_sessions VALUES (23, 3, 'b183d94a-d7de-4d24-b994-52f3adb51a70', NULL, NULL, '2026-03-07 20:07:01.210666+00', '2026-04-06 20:07:01.210666+00', NULL);
INSERT INTO public.user_sessions VALUES (24, 3, '89e9cd9e-323d-46d0-9a8e-2c10f8be93b1', NULL, NULL, '2026-03-08 09:21:10.828375+00', '2026-04-07 09:21:10.828375+00', NULL);
INSERT INTO public.user_sessions VALUES (25, 3, '5ba7d305-5a2d-45f5-b7a8-6a3948b7f886', NULL, NULL, '2026-03-08 09:24:08.11083+00', '2026-04-07 09:24:08.11083+00', NULL);
INSERT INTO public.user_sessions VALUES (26, 3, '7ac3a53e-691f-4f28-a0f6-0acece443c08', NULL, NULL, '2026-03-08 10:27:01.454244+00', '2026-04-07 10:27:01.454244+00', NULL);
INSERT INTO public.user_sessions VALUES (27, 3, '8463894c-454f-4aa8-96c2-083a695dd54c', NULL, NULL, '2026-03-08 10:29:19.361399+00', '2026-04-07 10:29:19.361399+00', NULL);
INSERT INTO public.user_sessions VALUES (28, 3, 'd978a1dd-0c46-433f-92ac-418c31727b2b', NULL, NULL, '2026-03-08 10:33:36.916101+00', '2026-04-07 10:33:36.916101+00', NULL);
INSERT INTO public.user_sessions VALUES (29, 3, '1c7f07e0-5da4-48b4-a9fb-e28a8e6cbc8e', NULL, NULL, '2026-03-08 14:21:24.659531+00', '2026-04-07 14:21:24.659531+00', NULL);
INSERT INTO public.user_sessions VALUES (30, 3, '63edbc34-3f3a-464d-81e9-9abdf579f34f', NULL, NULL, '2026-03-08 14:22:51.344094+00', '2026-04-07 14:22:51.344094+00', NULL);
INSERT INTO public.user_sessions VALUES (31, 3, '870e4e34-e219-4379-8752-a42e26fbbefb', NULL, NULL, '2026-03-08 14:29:13.84404+00', '2026-04-07 14:29:13.84404+00', NULL);
INSERT INTO public.user_sessions VALUES (32, 3, '48021151-c4bc-4e7f-9325-bbccb84d6485', NULL, NULL, '2026-03-08 14:29:31.487557+00', '2026-04-07 14:29:31.487557+00', NULL);
INSERT INTO public.user_sessions VALUES (33, 3, '6490826d-ca88-464a-8286-7c530c1c2184', NULL, NULL, '2026-03-08 14:30:11.492025+00', '2026-04-07 14:30:11.492025+00', NULL);
INSERT INTO public.user_sessions VALUES (34, 3, '2865734b-c55b-4917-bcdd-f5165d927901', NULL, NULL, '2026-03-08 14:30:33.934546+00', '2026-04-07 14:30:33.934546+00', NULL);
INSERT INTO public.user_sessions VALUES (35, 3, 'b059f69a-9323-4949-a39f-b34f8f949670', NULL, NULL, '2026-03-08 14:33:21.903579+00', '2026-04-07 14:33:21.903579+00', NULL);
INSERT INTO public.user_sessions VALUES (36, 3, 'b40f4781-5de8-4cfe-9cc1-7fb38fed04d4', NULL, NULL, '2026-03-08 14:51:55.302306+00', '2026-04-07 14:51:55.302306+00', NULL);
INSERT INTO public.user_sessions VALUES (37, 3, '99fde917-af68-49db-bfc5-2c26d23f0e8d', NULL, NULL, '2026-03-08 15:02:25.782403+00', '2026-04-07 15:02:25.782403+00', NULL);
INSERT INTO public.user_sessions VALUES (38, 3, '5b25687b-e8c8-4561-af51-fd2aa6fedb73', NULL, NULL, '2026-03-08 15:03:56.906006+00', '2026-04-07 15:03:56.906006+00', NULL);
INSERT INTO public.user_sessions VALUES (39, 3, '73858f8a-85a4-4bf7-ae97-5520ad181399', NULL, NULL, '2026-03-08 15:04:19.572953+00', '2026-04-07 15:04:19.572953+00', NULL);
INSERT INTO public.user_sessions VALUES (40, 3, '1b3bb862-a15f-4f07-8ba2-5aae0d34b933', NULL, NULL, '2026-03-08 15:46:03.154305+00', '2026-04-07 15:46:03.154305+00', NULL);
INSERT INTO public.user_sessions VALUES (41, 3, 'd4b005ce-350d-47e6-9bb4-a0ebcb533b58', NULL, NULL, '2026-03-08 15:50:04.158063+00', '2026-04-07 15:50:04.158063+00', NULL);
INSERT INTO public.user_sessions VALUES (42, 3, 'bb32be05-9da9-4d2e-b740-0bf0f5159872', NULL, NULL, '2026-03-08 15:54:03.974247+00', '2026-04-07 15:54:03.974247+00', NULL);
INSERT INTO public.user_sessions VALUES (43, 3, '4b85fe33-ce3c-44b4-bfc9-a578cc94269e', NULL, NULL, '2026-03-08 15:56:21.221204+00', '2026-04-07 15:56:21.221204+00', NULL);
INSERT INTO public.user_sessions VALUES (44, 3, '541c4b9c-adfc-4682-8d50-e92aa172a13b', NULL, NULL, '2026-03-08 16:00:40.782595+00', '2026-04-07 16:00:40.782595+00', NULL);
INSERT INTO public.user_sessions VALUES (45, 3, '72c5320f-4528-4f89-885f-7391c3188c75', NULL, NULL, '2026-03-08 16:24:02.692169+00', '2026-04-07 16:24:02.692169+00', NULL);
INSERT INTO public.user_sessions VALUES (46, 3, 'ac513e50-f15c-4f05-9334-b9738969e51e', NULL, NULL, '2026-03-08 16:24:28.274504+00', '2026-04-07 16:24:28.274504+00', NULL);
INSERT INTO public.user_sessions VALUES (47, 3, 'c295d34e-0cd3-4458-974d-3dc2dc737232', NULL, NULL, '2026-03-08 16:28:40.965602+00', '2026-04-07 16:28:40.965602+00', NULL);
INSERT INTO public.user_sessions VALUES (48, 3, '43a54ca5-6619-48c8-a0c3-3d4748933a91', NULL, NULL, '2026-03-08 16:51:25.660727+00', '2026-04-07 16:51:25.660727+00', NULL);
INSERT INTO public.user_sessions VALUES (49, 3, 'f56f0699-5748-479b-96d3-3058eded9417', NULL, NULL, '2026-03-08 16:58:20.525678+00', '2026-04-07 16:58:20.525678+00', NULL);
INSERT INTO public.user_sessions VALUES (50, 3, '13b162d7-f584-4d48-b893-6d7c035a02fc', NULL, NULL, '2026-03-08 17:08:10.439094+00', '2026-04-07 17:08:10.439094+00', NULL);
INSERT INTO public.user_sessions VALUES (51, 3, 'a28e8643-1f21-455d-9241-777eb59c5648', NULL, NULL, '2026-03-08 17:08:41.86904+00', '2026-04-07 17:08:41.86904+00', NULL);
INSERT INTO public.user_sessions VALUES (52, 3, '26a3685e-7215-45fe-842b-9caa989e6e40', NULL, NULL, '2026-03-08 17:13:42.689669+00', '2026-04-07 17:13:42.689669+00', NULL);
INSERT INTO public.user_sessions VALUES (53, 3, '90ed6556-69a9-4bc1-83aa-f9e10729c09e', NULL, NULL, '2026-03-08 17:19:28.029076+00', '2026-04-07 17:19:28.029076+00', NULL);
INSERT INTO public.user_sessions VALUES (54, 3, 'b8ae4c2f-3642-4d50-9e7f-d46e7883b3e6', NULL, NULL, '2026-03-08 17:51:37.977366+00', '2026-04-07 17:51:37.977366+00', NULL);
INSERT INTO public.user_sessions VALUES (55, 3, '00067616-e5ed-4249-a32d-d98d5e26247f', NULL, NULL, '2026-03-08 17:52:01.6138+00', '2026-04-07 17:52:01.6138+00', NULL);
INSERT INTO public.user_sessions VALUES (56, 3, '02c8a2c7-92de-45c6-8700-f5114c629f5b', NULL, NULL, '2026-03-08 18:25:14.022881+00', '2026-04-07 18:25:14.022881+00', NULL);
INSERT INTO public.user_sessions VALUES (59, 3, '40b4ffe3-a1af-4e5f-858d-54109ce28a57', NULL, NULL, '2026-03-08 18:43:22.516677+00', '2026-04-07 18:43:22.516677+00', NULL);
INSERT INTO public.user_sessions VALUES (60, 3, 'e6bf4c5a-7094-4f2b-8435-a1996456693b', NULL, NULL, '2026-03-08 19:05:16.984555+00', '2026-04-07 19:05:16.984555+00', NULL);
INSERT INTO public.user_sessions VALUES (61, 3, '38222b59-d471-408e-aa80-f9f2ec0048be', NULL, NULL, '2026-03-08 19:08:22.010048+00', '2026-04-07 19:08:22.010048+00', NULL);
INSERT INTO public.user_sessions VALUES (64, 3, '134ff92d-b12c-4ca4-a3d7-10dc10f23ffd', NULL, NULL, '2026-03-08 19:23:06.872366+00', '2026-04-07 19:23:06.872366+00', NULL);
INSERT INTO public.user_sessions VALUES (65, 3, '3ca99682-a0c3-403b-b899-6ae19d2d0ea5', NULL, NULL, '2026-03-08 19:26:54.8865+00', '2026-04-07 19:26:54.8865+00', NULL);
INSERT INTO public.user_sessions VALUES (66, 3, '26439c47-651b-46f3-bc5b-1ec5b3fd7ea3', NULL, NULL, '2026-03-08 19:27:42.440225+00', '2026-04-07 19:27:42.440225+00', NULL);
INSERT INTO public.user_sessions VALUES (69, 3, '8678cedf-062f-4356-9ee7-f1701316a1d3', NULL, NULL, '2026-03-08 19:30:12.054986+00', '2026-04-07 19:30:12.054986+00', NULL);
INSERT INTO public.user_sessions VALUES (70, 3, 'b063f607-aabd-4c02-8c3a-96ecd7bf8661', NULL, NULL, '2026-03-08 19:30:24.807742+00', '2026-04-07 19:30:24.807742+00', NULL);
INSERT INTO public.user_sessions VALUES (71, 3, '31094d56-ad6a-4747-9168-d2437835142f', NULL, NULL, '2026-03-08 19:31:18.188108+00', '2026-04-07 19:31:18.188108+00', NULL);
INSERT INTO public.user_sessions VALUES (74, 3, '46b8cf87-f250-4f0f-8bfe-482345ecf8d5', NULL, NULL, '2026-03-08 19:37:11.374791+00', '2026-04-07 19:37:11.374791+00', NULL);
INSERT INTO public.user_sessions VALUES (75, 3, '027b23ea-fce4-45a8-b70a-fdc02598179a', NULL, NULL, '2026-03-08 19:39:04.673443+00', '2026-04-07 19:39:04.673443+00', NULL);
INSERT INTO public.user_sessions VALUES (76, 3, 'e241c74f-fb49-4b9e-b925-043947101493', NULL, NULL, '2026-03-08 19:41:21.96586+00', '2026-04-07 19:41:21.96586+00', NULL);
INSERT INTO public.user_sessions VALUES (79, 3, '3b2defe8-1957-42c2-a1a5-aee9a3f643ad', NULL, NULL, '2026-03-08 19:53:27.461945+00', '2026-04-07 19:53:27.461945+00', NULL);
INSERT INTO public.user_sessions VALUES (80, 3, '7e115df9-ff70-4d2f-a533-b782344d3d7c', NULL, NULL, '2026-03-08 20:03:00.02722+00', '2026-04-07 20:03:00.02722+00', NULL);
INSERT INTO public.user_sessions VALUES (81, 3, 'd276e50a-4fff-4a41-a432-081f7d28f2f1', NULL, NULL, '2026-03-08 20:25:08.445133+00', '2026-04-07 20:25:08.445133+00', NULL);
INSERT INTO public.user_sessions VALUES (57, 3, '74bb8b73-c272-4fae-9403-221c38e31203', NULL, NULL, '2026-03-08 18:26:53.15476+00', '2026-04-07 18:26:53.15476+00', NULL);
INSERT INTO public.user_sessions VALUES (62, 3, '0df60d46-d4c8-46f0-88d5-2c54b5a30bfa', NULL, NULL, '2026-03-08 19:11:51.525327+00', '2026-04-07 19:11:51.525327+00', NULL);
INSERT INTO public.user_sessions VALUES (67, 3, '98e654a5-0195-4ffc-ac44-5e35d469a75f', NULL, NULL, '2026-03-08 19:29:35.326028+00', '2026-04-07 19:29:35.326028+00', NULL);
INSERT INTO public.user_sessions VALUES (72, 3, 'bab0ffa9-daae-469b-9b0a-7aa397782b5e', NULL, NULL, '2026-03-08 19:31:38.663579+00', '2026-04-07 19:31:38.663579+00', NULL);
INSERT INTO public.user_sessions VALUES (77, 3, '4f08a117-422c-4e7c-b8a3-04f433ddc4d7', NULL, NULL, '2026-03-08 19:41:46.16963+00', '2026-04-07 19:41:46.16963+00', NULL);
INSERT INTO public.user_sessions VALUES (82, 3, '2436244e-e8dd-465c-b2d2-8a9e193b2ad4', NULL, NULL, '2026-03-08 20:26:45.369475+00', '2026-04-07 20:26:45.369475+00', NULL);
INSERT INTO public.user_sessions VALUES (58, 3, 'c37ba991-352d-4028-bb30-ea5a6f473ef6', NULL, NULL, '2026-03-08 18:27:44.820534+00', '2026-04-07 18:27:44.820534+00', NULL);
INSERT INTO public.user_sessions VALUES (63, 3, 'add75591-9bee-4385-9417-7c120e280bdd', NULL, NULL, '2026-03-08 19:20:54.361689+00', '2026-04-07 19:20:54.361689+00', NULL);
INSERT INTO public.user_sessions VALUES (68, 3, 'fb352fce-3243-40d7-89f2-7142dc3ba2b9', NULL, NULL, '2026-03-08 19:30:03.61446+00', '2026-04-07 19:30:03.61446+00', NULL);
INSERT INTO public.user_sessions VALUES (73, 3, '37edd5d6-ae8d-4374-95c2-3643f6e5fca9', NULL, NULL, '2026-03-08 19:32:22.517913+00', '2026-04-07 19:32:22.517913+00', NULL);
INSERT INTO public.user_sessions VALUES (78, 3, '858b1242-f138-41fe-80d9-0d99d74ee864', NULL, NULL, '2026-03-08 19:52:38.228018+00', '2026-04-07 19:52:38.228018+00', NULL);
INSERT INTO public.user_sessions VALUES (83, 3, '80c1426b-e4c6-4ca4-855f-f133a1dc2f76', NULL, NULL, '2026-03-09 08:06:43.519587+00', '2026-04-08 08:06:43.519587+00', NULL);
INSERT INTO public.user_sessions VALUES (84, 3, '2754787f-dbbd-46f1-a362-02a21ca1ce95', NULL, NULL, '2026-03-09 08:11:22.477041+00', '2026-04-08 08:11:22.477041+00', NULL);
INSERT INTO public.user_sessions VALUES (85, 3, '27f95da3-b2ca-4f91-9318-b7676819a673', NULL, NULL, '2026-03-09 08:11:44.074101+00', '2026-04-08 08:11:44.074101+00', NULL);
INSERT INTO public.user_sessions VALUES (86, 3, 'fcb32f21-e7d2-46e2-9995-6b33f8eecfb6', NULL, NULL, '2026-03-09 08:12:35.84911+00', '2026-04-08 08:12:35.84911+00', NULL);
INSERT INTO public.user_sessions VALUES (87, 3, '18f43a4e-b536-447f-b9cb-74abe8eb8365', NULL, NULL, '2026-03-09 08:23:12.672829+00', '2026-04-08 08:23:12.672829+00', NULL);
INSERT INTO public.user_sessions VALUES (88, 3, 'b89ae3f1-f84f-424c-9975-b4c227efa0ae', NULL, NULL, '2026-03-09 09:50:50.72924+00', '2026-04-08 09:50:50.72924+00', NULL);
INSERT INTO public.user_sessions VALUES (89, 3, '0e2da033-a93f-4b38-b855-11f6ee671205', NULL, NULL, '2026-03-09 10:10:41.591981+00', '2026-04-08 10:10:41.591981+00', NULL);
INSERT INTO public.user_sessions VALUES (90, 3, '570c6c50-cf5f-4642-b2e7-a80ed6ba4a0f', NULL, NULL, '2026-03-09 10:22:01.64965+00', '2026-04-08 10:22:01.64965+00', NULL);
INSERT INTO public.user_sessions VALUES (91, 3, 'e3031ea7-7e52-4278-8d76-b2bdc9e84740', NULL, NULL, '2026-03-09 16:03:35.672752+00', '2026-04-08 16:03:35.672752+00', NULL);
INSERT INTO public.user_sessions VALUES (92, 3, '6d8c5586-8805-461a-9af2-ffb2b2503d7c', NULL, NULL, '2026-03-09 16:04:47.95676+00', '2026-04-08 16:04:47.95676+00', NULL);
INSERT INTO public.user_sessions VALUES (93, 3, '0b6defcb-8c47-444a-aed8-0e47678bdfbd', NULL, NULL, '2026-03-09 16:05:03.758118+00', '2026-04-08 16:05:03.758118+00', NULL);
INSERT INTO public.user_sessions VALUES (94, 3, '16a9a3aa-15c3-4b64-98ed-7dc573b74509', NULL, NULL, '2026-03-09 17:47:42.08931+00', '2026-04-08 17:47:42.08931+00', NULL);
INSERT INTO public.user_sessions VALUES (95, 3, '1abe7973-dc7a-4c0c-bbbc-95a40d693069', NULL, NULL, '2026-03-09 17:48:00.218843+00', '2026-04-08 17:48:00.218843+00', NULL);
INSERT INTO public.user_sessions VALUES (96, 3, '7838fa48-ba19-40ab-b9db-60eac24fd929', NULL, NULL, '2026-03-09 17:49:32.3317+00', '2026-04-08 17:49:32.3317+00', NULL);
INSERT INTO public.user_sessions VALUES (97, 3, '062ef930-db83-4ad0-8b51-375ae9fdce97', NULL, NULL, '2026-03-09 17:54:09.760053+00', '2026-04-08 17:54:09.760053+00', NULL);
INSERT INTO public.user_sessions VALUES (98, 3, '029944b4-d27e-4779-89bb-5c6fe13858c7', NULL, NULL, '2026-03-09 17:58:16.799055+00', '2026-04-08 17:58:16.799055+00', NULL);
INSERT INTO public.user_sessions VALUES (99, 3, '3256d654-66c4-4732-b6e1-789e17d8f21c', NULL, NULL, '2026-03-09 18:02:12.270953+00', '2026-04-08 18:02:12.270953+00', NULL);
INSERT INTO public.user_sessions VALUES (100, 3, 'e7af4af2-77ff-4a2f-b547-db8348196609', NULL, NULL, '2026-03-09 18:06:15.50633+00', '2026-04-08 18:06:15.50633+00', NULL);
INSERT INTO public.user_sessions VALUES (101, 3, '71d1f84e-a361-4439-9cbb-e60394ee6560', NULL, NULL, '2026-03-09 18:09:40.875107+00', '2026-04-08 18:09:40.875107+00', NULL);
INSERT INTO public.user_sessions VALUES (102, 3, '5586a9a9-2717-4513-9ecc-49d081c2c171', NULL, NULL, '2026-03-09 18:20:46.182198+00', '2026-04-08 18:20:46.182198+00', NULL);
INSERT INTO public.user_sessions VALUES (103, 3, '808429e4-93ea-45d6-aa3f-23a5d83be28d', NULL, NULL, '2026-03-09 18:21:52.92545+00', '2026-04-08 18:21:52.92545+00', NULL);
INSERT INTO public.user_sessions VALUES (104, 3, '236629e6-5e0c-4763-a086-5950b5d979b8', NULL, NULL, '2026-03-09 18:22:44.179227+00', '2026-04-08 18:22:44.179227+00', NULL);
INSERT INTO public.user_sessions VALUES (105, 3, '94e7c32d-055e-4057-93ad-a57bbf4a1711', NULL, NULL, '2026-03-09 18:23:16.960616+00', '2026-04-08 18:23:16.960616+00', NULL);
INSERT INTO public.user_sessions VALUES (106, 3, 'd717e830-7c93-430b-b3b7-eeaf7978f98e', NULL, NULL, '2026-03-09 18:44:52.141847+00', '2026-04-08 18:44:52.141847+00', NULL);
INSERT INTO public.user_sessions VALUES (107, 3, 'dee3e1f3-d2f9-4403-9c1c-d06254e24e40', NULL, NULL, '2026-03-09 18:52:05.287588+00', '2026-04-08 18:52:05.287588+00', NULL);
INSERT INTO public.user_sessions VALUES (108, 3, 'c8912c42-c58a-4dd5-b965-8c019e12aee8', NULL, NULL, '2026-03-09 19:04:29.238877+00', '2026-04-08 19:04:29.238877+00', NULL);
INSERT INTO public.user_sessions VALUES (109, 3, '3ae1331b-7a01-4860-a090-39683a4ad2bd', NULL, NULL, '2026-03-09 19:08:44.108048+00', '2026-04-08 19:08:44.108048+00', NULL);
INSERT INTO public.user_sessions VALUES (110, 3, '6a563e22-a56c-4503-83ae-2e6c08f85178', NULL, NULL, '2026-03-09 19:16:43.639591+00', '2026-04-08 19:16:43.639591+00', NULL);
INSERT INTO public.user_sessions VALUES (111, 3, '7f08235d-c7c8-4815-a0e9-b67b6326bd40', NULL, NULL, '2026-03-09 19:20:08.248232+00', '2026-04-08 19:20:08.248232+00', NULL);
INSERT INTO public.user_sessions VALUES (112, 3, 'b4834ac3-8b84-49c7-9e81-425ca7d6ca76', NULL, NULL, '2026-03-09 19:20:59.973776+00', '2026-04-08 19:20:59.973776+00', NULL);
INSERT INTO public.user_sessions VALUES (113, 3, '5c844d8b-d031-4317-b4c4-0f4cb73bec35', NULL, NULL, '2026-03-09 19:23:58.965263+00', '2026-04-08 19:23:58.965263+00', NULL);
INSERT INTO public.user_sessions VALUES (114, 3, '486ed61a-d67a-4e56-b0cb-c9aeb42cf171', NULL, NULL, '2026-03-09 19:25:09.944509+00', '2026-04-08 19:25:09.944509+00', NULL);
INSERT INTO public.user_sessions VALUES (115, 3, 'f2c9cd52-15a1-434b-997d-3cdcc0c9f28b', NULL, NULL, '2026-03-09 19:27:48.347753+00', '2026-04-08 19:27:48.347753+00', NULL);
INSERT INTO public.user_sessions VALUES (116, 3, 'b01a787a-3132-4a0c-8b22-50b99bb53489', NULL, NULL, '2026-03-09 19:28:14.797283+00', '2026-04-08 19:28:14.797283+00', NULL);
INSERT INTO public.user_sessions VALUES (117, 3, '12af5b40-f414-4130-b9f7-f9f3964a322d', NULL, NULL, '2026-03-09 19:41:39.46046+00', '2026-04-08 19:41:39.46046+00', NULL);
INSERT INTO public.user_sessions VALUES (118, 3, 'e76ae09d-710c-49f5-ae9e-7ba35f0e5dd4', NULL, NULL, '2026-03-09 19:51:59.683616+00', '2026-04-08 19:51:59.683616+00', NULL);
INSERT INTO public.user_sessions VALUES (119, 3, 'a3affaa6-8669-46be-8125-c107d6e11302', NULL, NULL, '2026-03-09 19:53:36.693247+00', '2026-04-08 19:53:36.693247+00', NULL);
INSERT INTO public.user_sessions VALUES (120, 3, '56026d50-6629-49b7-ad10-93d60bc9f65c', NULL, NULL, '2026-03-09 20:00:45.263402+00', '2026-04-08 20:00:45.263402+00', NULL);
INSERT INTO public.user_sessions VALUES (121, 3, 'bb342708-96de-4c10-b471-58861cdc63dc', NULL, NULL, '2026-03-09 20:03:14.442108+00', '2026-04-08 20:03:14.442108+00', NULL);
INSERT INTO public.user_sessions VALUES (122, 3, 'f8ffbd00-0747-4e37-90cd-1366e6385256', NULL, NULL, '2026-03-09 20:03:28.589505+00', '2026-04-08 20:03:28.589505+00', NULL);
INSERT INTO public.user_sessions VALUES (123, 3, '35ba743c-1ec5-44de-bd73-51059924b89b', NULL, NULL, '2026-03-09 20:04:15.225563+00', '2026-04-08 20:04:15.225563+00', NULL);
INSERT INTO public.user_sessions VALUES (124, 3, '01c149e6-59b0-4291-a8e7-3d045b5bd878', NULL, NULL, '2026-03-09 20:08:00.588534+00', '2026-04-08 20:08:00.588534+00', NULL);
INSERT INTO public.user_sessions VALUES (125, 3, '7e5105c2-1d00-4e0d-9892-d2c498b41d6e', NULL, NULL, '2026-03-10 09:06:54.583085+00', '2026-04-09 09:06:54.583085+00', NULL);
INSERT INTO public.user_sessions VALUES (126, 3, '62fdab86-ed55-4ced-962a-6cbe3416832f', NULL, NULL, '2026-03-10 09:10:59.804577+00', '2026-04-09 09:10:59.804577+00', NULL);
INSERT INTO public.user_sessions VALUES (127, 3, 'cb773dc9-c18b-4378-a290-fb02f8862427', NULL, NULL, '2026-03-10 09:16:09.247462+00', '2026-04-09 09:16:09.247462+00', NULL);
INSERT INTO public.user_sessions VALUES (128, 3, '290b42f0-6a9e-4e55-b283-f8f85a7e0642', NULL, NULL, '2026-03-10 09:17:48.136181+00', '2026-04-09 09:17:48.136181+00', NULL);
INSERT INTO public.user_sessions VALUES (129, 3, '0e8b0d0a-9654-48fa-95fd-7934224730c4', NULL, NULL, '2026-03-10 09:41:48.235585+00', '2026-04-09 09:41:48.235585+00', NULL);
INSERT INTO public.user_sessions VALUES (130, 3, '4b47b8de-ae46-407b-970a-37149efe7a04', NULL, NULL, '2026-03-10 09:52:28.712149+00', '2026-04-09 09:52:28.712149+00', NULL);
INSERT INTO public.user_sessions VALUES (131, 3, '83c59fc7-6065-44a3-af39-b45f50a4ad5a', NULL, NULL, '2026-03-10 09:53:17.304707+00', '2026-04-09 09:53:17.304707+00', NULL);
INSERT INTO public.user_sessions VALUES (132, 3, '4198f99b-d58f-4131-b247-66bf28910f8c', NULL, NULL, '2026-03-10 09:58:58.57772+00', '2026-04-09 09:58:58.57772+00', NULL);
INSERT INTO public.user_sessions VALUES (133, 3, 'de2a52ea-dc5d-4cc7-942e-179ab227af67', NULL, NULL, '2026-03-10 14:25:01.318949+00', '2026-04-09 14:25:01.318949+00', NULL);
INSERT INTO public.user_sessions VALUES (134, 3, 'd23ebbf3-9702-4a9b-be4f-51e3c3a4ee41', NULL, NULL, '2026-03-10 14:25:15.819574+00', '2026-04-09 14:25:15.819574+00', NULL);
INSERT INTO public.user_sessions VALUES (135, 3, '5c453792-8967-4324-8aa4-ed7c73ed01e5', NULL, NULL, '2026-03-10 16:32:14.079977+00', '2026-04-09 16:32:14.079977+00', NULL);
INSERT INTO public.user_sessions VALUES (136, 3, 'edf7d176-2e8f-4a2b-8a84-337f411495ae', NULL, NULL, '2026-03-10 16:38:48.448323+00', '2026-04-09 16:38:48.448323+00', NULL);
INSERT INTO public.user_sessions VALUES (137, 3, '1ea55b93-3461-4c0d-9c0f-cc5f40c899c0', NULL, NULL, '2026-03-10 16:44:36.628311+00', '2026-04-09 16:44:36.628311+00', NULL);
INSERT INTO public.user_sessions VALUES (138, 3, '90b85236-445a-4747-aebd-a3513eaad454', NULL, NULL, '2026-03-10 16:52:47.494064+00', '2026-04-09 16:52:47.494064+00', NULL);
INSERT INTO public.user_sessions VALUES (139, 3, 'b24f3bbf-7df2-4952-b2bb-340505ba9c17', NULL, NULL, '2026-03-10 19:27:09.688359+00', '2026-04-09 19:27:09.688359+00', NULL);
INSERT INTO public.user_sessions VALUES (140, 3, 'f01c1d80-deaa-4b3f-a61b-cf65122c044f', NULL, NULL, '2026-03-10 19:41:10.218566+00', '2026-04-09 19:41:10.218566+00', NULL);
INSERT INTO public.user_sessions VALUES (141, 3, '5e212fef-2062-4084-a054-437a56445c1a', NULL, NULL, '2026-03-10 20:04:00.370053+00', '2026-04-09 20:04:00.370053+00', NULL);
INSERT INTO public.user_sessions VALUES (142, 3, '3820e609-3456-4905-b206-f43630b22655', NULL, NULL, '2026-03-11 14:16:46.051776+00', '2026-04-10 14:16:46.051776+00', NULL);
INSERT INTO public.user_sessions VALUES (143, 3, 'dcf073b6-ec28-42c3-a955-c9a0836412b0', NULL, NULL, '2026-03-11 14:16:59.996268+00', '2026-04-10 14:16:59.996268+00', NULL);
INSERT INTO public.user_sessions VALUES (144, 3, '7ee927a9-411a-4cf1-8c49-e9e63a0df624', NULL, NULL, '2026-03-11 15:32:13.585216+00', '2026-04-10 15:32:13.585216+00', NULL);
INSERT INTO public.user_sessions VALUES (145, 3, 'a58bc4f6-da9b-4e3f-a6bb-1e9fcf40fb2c', NULL, NULL, '2026-03-11 15:35:23.846296+00', '2026-04-10 15:35:23.846296+00', NULL);
INSERT INTO public.user_sessions VALUES (146, 3, 'b1fe0278-9823-4f81-8326-d7d165694fd7', NULL, NULL, '2026-03-11 16:12:08.387658+00', '2026-04-10 16:12:08.387658+00', NULL);
INSERT INTO public.user_sessions VALUES (147, 3, 'dd515293-e762-46d2-b0ef-952206361271', NULL, NULL, '2026-03-11 17:28:18.110236+00', '2026-04-10 17:28:18.110236+00', NULL);
INSERT INTO public.user_sessions VALUES (148, 3, '004844da-1a0f-4c5a-a9d9-ea957a28a487', NULL, NULL, '2026-03-11 18:09:48.940148+00', '2026-04-10 18:09:48.940148+00', NULL);
INSERT INTO public.user_sessions VALUES (149, 3, '1073275e-bf22-451c-aa53-463b377b650b', NULL, NULL, '2026-03-11 18:11:02.642779+00', '2026-04-10 18:11:02.642779+00', NULL);
INSERT INTO public.user_sessions VALUES (150, 3, '9faa4825-df0c-41ad-93b3-3c51ace8b1c0', NULL, NULL, '2026-03-11 18:14:15.064291+00', '2026-04-10 18:14:15.064291+00', NULL);
INSERT INTO public.user_sessions VALUES (151, 3, '6bde7feb-ff62-4896-8e3c-a7c77f2c3eac', NULL, NULL, '2026-03-11 18:14:52.94146+00', '2026-04-10 18:14:52.94146+00', NULL);
INSERT INTO public.user_sessions VALUES (152, 3, '5a5a5364-8fcf-4fe9-8fe9-e7b67aeaa3c7', NULL, NULL, '2026-03-11 18:19:26.488204+00', '2026-04-10 18:19:26.488204+00', NULL);
INSERT INTO public.user_sessions VALUES (153, 3, '08657c64-b00c-4642-9038-b9afd32978e4', NULL, NULL, '2026-03-11 18:21:23.603881+00', '2026-04-10 18:21:23.603881+00', NULL);
INSERT INTO public.user_sessions VALUES (154, 3, '654d6d24-d85c-4929-8e59-56c56ab7df25', NULL, NULL, '2026-03-11 18:22:52.977836+00', '2026-04-10 18:22:52.977836+00', NULL);
INSERT INTO public.user_sessions VALUES (155, 3, 'db8a6af5-03dc-4e8b-b542-6a544431fdc8', NULL, NULL, '2026-03-11 18:33:05.223759+00', '2026-04-10 18:33:05.223759+00', NULL);
INSERT INTO public.user_sessions VALUES (156, 3, '06744d2d-d2fc-493f-bff6-ac5dca0da13e', NULL, NULL, '2026-03-11 18:35:18.255818+00', '2026-04-10 18:35:18.255818+00', NULL);
INSERT INTO public.user_sessions VALUES (157, 3, 'dc8c7a43-1322-4c5d-b02d-4a661bb61b38', NULL, NULL, '2026-03-11 18:35:25.027119+00', '2026-04-10 18:35:25.027119+00', NULL);
INSERT INTO public.user_sessions VALUES (158, 3, '00b6155c-cc41-4dfd-a1ab-986a41b869fb', NULL, NULL, '2026-03-11 18:36:18.720394+00', '2026-04-10 18:36:18.720394+00', NULL);
INSERT INTO public.user_sessions VALUES (159, 3, '69017818-55e2-4343-8290-2c5b26750f6c', NULL, NULL, '2026-03-11 18:36:30.664861+00', '2026-04-10 18:36:30.664861+00', NULL);
INSERT INTO public.user_sessions VALUES (164, 3, 'bdb3971b-1942-4013-a534-de750ef9108d', NULL, NULL, '2026-03-11 20:28:09.584425+00', '2026-04-10 20:28:09.584425+00', NULL);
INSERT INTO public.user_sessions VALUES (160, 3, 'f2c2ca6f-a44d-4bb3-880c-2d9a136fe077', NULL, NULL, '2026-03-11 18:49:44.895645+00', '2026-04-10 18:49:44.895645+00', NULL);
INSERT INTO public.user_sessions VALUES (161, 3, '147a5c00-60e1-4c20-b735-37df4bf4a5ad', NULL, NULL, '2026-03-11 18:49:51.746887+00', '2026-04-10 18:49:51.746887+00', NULL);
INSERT INTO public.user_sessions VALUES (162, 3, 'e05cec08-fb9b-4fca-b33e-3a472ad6f1bf', NULL, NULL, '2026-03-11 18:59:19.803221+00', '2026-04-10 18:59:19.803221+00', NULL);
INSERT INTO public.user_sessions VALUES (163, 3, '13abd57c-70c2-4594-9fe4-39cda2b510c5', NULL, NULL, '2026-03-11 18:59:50.70104+00', '2026-04-10 18:59:50.70104+00', NULL);
INSERT INTO public.user_sessions VALUES (165, 3, 'd0bb9b62-f1f5-4f62-b127-cba371b3da4c', NULL, NULL, '2026-03-12 10:00:08.487635+00', '2026-04-11 10:00:08.487635+00', NULL);
INSERT INTO public.user_sessions VALUES (166, 3, 'de51e61a-6293-4275-a3e0-349bf1276daa', NULL, NULL, '2026-03-12 10:00:28.701581+00', '2026-04-11 10:00:28.701581+00', NULL);
INSERT INTO public.user_sessions VALUES (167, 3, 'e6a0a96f-c7ae-41be-9b06-195cd7400aca', NULL, NULL, '2026-03-12 10:00:38.083142+00', '2026-04-11 10:00:38.083142+00', NULL);
INSERT INTO public.user_sessions VALUES (168, 3, '25b886ed-80ce-4cbe-87b9-54e50b1aee9a', NULL, NULL, '2026-03-12 10:03:18.78144+00', '2026-04-11 10:03:18.78144+00', NULL);
INSERT INTO public.user_sessions VALUES (169, 3, '2a2a43e1-f7a8-48f3-a855-64fc0410e690', NULL, NULL, '2026-03-12 10:13:03.562675+00', '2026-04-11 10:13:03.562675+00', NULL);
INSERT INTO public.user_sessions VALUES (170, 3, '9cb6018b-aa85-4952-a623-6a2b93df2132', NULL, NULL, '2026-03-12 10:13:35.833822+00', '2026-04-11 10:13:35.833822+00', NULL);
INSERT INTO public.user_sessions VALUES (171, 3, '71fbf901-48e1-41c0-bc08-9675959d5755', NULL, NULL, '2026-03-12 10:19:04.06523+00', '2026-04-11 10:19:04.06523+00', NULL);
INSERT INTO public.user_sessions VALUES (172, 3, '85e7450f-3575-4ba2-aa1c-0f3651f31b23', NULL, NULL, '2026-03-12 10:31:57.437643+00', '2026-04-11 10:31:57.437643+00', NULL);
INSERT INTO public.user_sessions VALUES (173, 3, '79e31b04-c15f-4311-b328-1ac1444be752', NULL, NULL, '2026-03-12 10:33:25.347789+00', '2026-04-11 10:33:25.347789+00', NULL);
INSERT INTO public.user_sessions VALUES (174, 3, '085b1f57-795f-4f03-884a-f0c1da3dfb30', NULL, NULL, '2026-03-12 10:37:50.219486+00', '2026-04-11 10:37:50.219486+00', NULL);
INSERT INTO public.user_sessions VALUES (175, 3, 'e3b810a3-2ee3-48ca-8bfe-f180ffcdd84e', NULL, NULL, '2026-03-12 10:40:47.584575+00', '2026-04-11 10:40:47.584575+00', NULL);
INSERT INTO public.user_sessions VALUES (176, 3, 'd7eefa40-3805-4aa7-8441-bdd1c9a4d61d', NULL, NULL, '2026-03-12 11:15:35.406336+00', '2026-04-11 11:15:35.406336+00', NULL);
INSERT INTO public.user_sessions VALUES (177, 3, 'ca1c7216-fd53-4f33-8d46-f32221bb503b', NULL, NULL, '2026-03-12 11:18:56.402774+00', '2026-04-11 11:18:56.402774+00', NULL);
INSERT INTO public.user_sessions VALUES (178, 3, 'dfdd9043-f0dc-4434-94ff-85fee1cb99ab', NULL, NULL, '2026-03-12 11:58:23.105527+00', '2026-04-11 11:58:23.105527+00', NULL);
INSERT INTO public.user_sessions VALUES (179, 3, '94487b5c-75d5-410f-b390-62e6362cc216', NULL, NULL, '2026-03-12 11:58:33.867681+00', '2026-04-11 11:58:33.867681+00', NULL);
INSERT INTO public.user_sessions VALUES (180, 3, '90f59399-fcf1-4b07-bde3-35bbbb5d78a4', NULL, NULL, '2026-03-12 11:58:41.594301+00', '2026-04-11 11:58:41.594301+00', NULL);
INSERT INTO public.user_sessions VALUES (181, 3, 'd47e591b-1924-4f78-bf1c-9beb1c704687', NULL, NULL, '2026-03-12 11:58:51.457583+00', '2026-04-11 11:58:51.457583+00', NULL);
INSERT INTO public.user_sessions VALUES (182, 3, '9a17612a-fe9c-4281-b696-69488d2f5d47', NULL, NULL, '2026-03-12 12:02:03.645454+00', '2026-04-11 12:02:03.645454+00', NULL);
INSERT INTO public.user_sessions VALUES (183, 3, '3cc69432-ae22-46aa-8e4e-7e04fae9594f', NULL, NULL, '2026-03-12 12:15:14.572886+00', '2026-04-11 12:15:14.572886+00', NULL);
INSERT INTO public.user_sessions VALUES (184, 3, '8f485949-227d-4023-9d02-ad2ee1c36256', NULL, NULL, '2026-03-12 12:21:30.28872+00', '2026-04-11 12:21:30.28872+00', NULL);
INSERT INTO public.user_sessions VALUES (185, 3, '3bbbb7e8-f7ee-4463-af92-5d00000d662e', NULL, NULL, '2026-03-12 12:41:26.669672+00', '2026-04-11 12:41:26.669672+00', NULL);
INSERT INTO public.user_sessions VALUES (186, 3, '59f964d5-24bc-47ba-9bde-736a65e6823c', NULL, NULL, '2026-03-12 12:46:29.223748+00', '2026-04-11 12:46:29.223748+00', NULL);
INSERT INTO public.user_sessions VALUES (187, 3, 'c4bab473-ed64-4650-a5c8-e98f03b43591', NULL, NULL, '2026-03-12 12:55:11.081648+00', '2026-04-11 12:55:11.081648+00', NULL);
INSERT INTO public.user_sessions VALUES (188, 3, 'ac6eeb46-f7fc-471d-b24d-02f87ef50e71', NULL, NULL, '2026-03-12 12:56:08.321505+00', '2026-04-11 12:56:08.321505+00', NULL);
INSERT INTO public.user_sessions VALUES (189, 3, '744f6c71-343a-4067-83c8-b84509ba4347', NULL, NULL, '2026-03-12 12:59:52.081972+00', '2026-04-11 12:59:52.081972+00', NULL);
INSERT INTO public.user_sessions VALUES (190, 3, 'e565c479-351b-4689-815c-d9bd10d89dbf', NULL, NULL, '2026-03-12 14:48:46.706382+00', '2026-04-11 14:48:46.706382+00', NULL);
INSERT INTO public.user_sessions VALUES (191, 3, '2ef1fdcf-b514-4b63-90ec-e6e52ccf33ce', NULL, NULL, '2026-03-12 19:29:02.692784+00', '2026-04-11 19:29:02.692784+00', NULL);
INSERT INTO public.user_sessions VALUES (192, 3, 'e6f31d5f-2b1d-4809-8661-b5fff2b46814', NULL, NULL, '2026-03-12 20:08:12.231609+00', '2026-04-11 20:08:12.231609+00', NULL);
INSERT INTO public.user_sessions VALUES (193, 3, 'b910828f-2890-4cc3-a209-f4454acbab8b', NULL, NULL, '2026-03-12 20:19:39.90663+00', '2026-04-11 20:19:39.90663+00', NULL);
INSERT INTO public.user_sessions VALUES (194, 3, 'ded193e1-4004-495e-846d-e8711fd9075d', NULL, NULL, '2026-03-12 20:21:46.80838+00', '2026-04-11 20:21:46.80838+00', NULL);
INSERT INTO public.user_sessions VALUES (195, 3, '3170cd5a-495a-4b10-8e51-fcbf33732149', NULL, NULL, '2026-03-12 20:24:54.012823+00', '2026-04-11 20:24:54.012823+00', NULL);
INSERT INTO public.user_sessions VALUES (196, 3, 'e8075721-c235-48e5-86d7-30c03693444a', NULL, NULL, '2026-03-12 20:29:19.394024+00', '2026-04-11 20:29:19.394024+00', NULL);
INSERT INTO public.user_sessions VALUES (197, 3, '96c181a3-af6f-4597-a130-b13747ad6ff4', NULL, NULL, '2026-03-12 20:35:21.438222+00', '2026-04-11 20:35:21.438222+00', NULL);
INSERT INTO public.user_sessions VALUES (198, 3, '06acbbbc-75fa-43d7-a481-9cc7a9d9328f', NULL, NULL, '2026-03-12 20:36:08.804504+00', '2026-04-11 20:36:08.804504+00', NULL);
INSERT INTO public.user_sessions VALUES (199, 3, '74a8a13c-a94d-4638-a1d0-3e4b37765ebe', NULL, NULL, '2026-03-12 20:37:19.6653+00', '2026-04-11 20:37:19.6653+00', NULL);
INSERT INTO public.user_sessions VALUES (200, 3, '4fc30252-cb10-4b7a-82dd-207d6950db99', NULL, NULL, '2026-03-12 20:38:38.372948+00', '2026-04-11 20:38:38.372948+00', NULL);
INSERT INTO public.user_sessions VALUES (201, 3, '251d680f-74c9-4521-9928-f0b72efa0e06', NULL, NULL, '2026-03-12 20:46:50.278823+00', '2026-04-11 20:46:50.278823+00', NULL);
INSERT INTO public.user_sessions VALUES (202, 3, '21c59636-5718-4b93-b869-72f6bf262556', NULL, NULL, '2026-03-12 20:52:50.418251+00', '2026-04-11 20:52:50.418251+00', NULL);
INSERT INTO public.user_sessions VALUES (203, 3, '3030c7ef-8caa-49d9-ac4b-ccf54b3e639b', NULL, NULL, '2026-03-13 10:51:19.387062+00', '2026-04-12 10:51:19.387062+00', NULL);
INSERT INTO public.user_sessions VALUES (204, 3, '9a5ee74d-2290-4c09-b116-05bc3530f006', NULL, NULL, '2026-03-13 12:08:45.672244+00', '2026-04-12 12:08:45.672244+00', NULL);
INSERT INTO public.user_sessions VALUES (205, 3, '0fa84fd5-ae92-4cfd-b800-cf97af8810aa', NULL, NULL, '2026-03-13 12:09:34.87981+00', '2026-04-12 12:09:34.87981+00', NULL);
INSERT INTO public.user_sessions VALUES (206, 3, 'e829d842-937b-4ac7-b80f-b1c89fa1aaab', NULL, NULL, '2026-03-13 12:57:30.086514+00', '2026-04-12 12:57:30.086514+00', NULL);
INSERT INTO public.user_sessions VALUES (207, 3, 'b4ab440e-0d6b-4b36-913e-4dc092e09ded', NULL, NULL, '2026-03-13 12:59:40.26498+00', '2026-04-12 12:59:40.26498+00', NULL);
INSERT INTO public.user_sessions VALUES (208, 3, 'f0926099-8772-489e-a810-1566fdfb4243', NULL, NULL, '2026-03-13 13:00:32.231385+00', '2026-04-12 13:00:32.231385+00', NULL);
INSERT INTO public.user_sessions VALUES (209, 3, '009ed353-5f79-42fc-b9b6-4d43c6c0ec2d', NULL, NULL, '2026-03-13 13:01:41.939685+00', '2026-04-12 13:01:41.939685+00', NULL);
INSERT INTO public.user_sessions VALUES (210, 3, 'b3c28588-0486-45b8-bc6f-248e4b19234f', NULL, NULL, '2026-03-13 13:18:28.965938+00', '2026-04-12 13:18:28.965938+00', NULL);
INSERT INTO public.user_sessions VALUES (211, 3, '5343feb2-0ed5-44f7-aa0e-cb13f1458bab', NULL, NULL, '2026-03-13 13:51:07.272363+00', '2026-04-12 13:51:07.272363+00', NULL);
INSERT INTO public.user_sessions VALUES (212, 3, '29b917e3-be12-4cb9-aaf6-c0040aa633a6', NULL, NULL, '2026-03-13 13:51:18.592809+00', '2026-04-12 13:51:18.592809+00', NULL);
INSERT INTO public.user_sessions VALUES (213, 3, '11072172-a8d9-497c-995e-4ed7a08978a4', NULL, NULL, '2026-03-13 14:02:43.00115+00', '2026-04-12 14:02:43.00115+00', NULL);
INSERT INTO public.user_sessions VALUES (214, 3, '7f5be4ba-7fe7-428e-85f6-cfbb2e8c2a09', NULL, NULL, '2026-03-13 14:15:07.095778+00', '2026-04-12 14:15:07.095778+00', NULL);
INSERT INTO public.user_sessions VALUES (215, 3, 'd35da487-3f64-4a29-ba0c-d02d457f2198', NULL, NULL, '2026-03-13 14:15:34.14289+00', '2026-04-12 14:15:34.14289+00', NULL);
INSERT INTO public.user_sessions VALUES (216, 3, 'e3570fd5-0663-4ed5-ae75-a97da6c660d2', NULL, NULL, '2026-03-13 14:33:54.143887+00', '2026-04-12 14:33:54.143887+00', NULL);
INSERT INTO public.user_sessions VALUES (217, 4, '970a9506-7765-407c-8c63-ca875bf93f6a', NULL, NULL, '2026-03-13 14:34:21.566454+00', '2026-04-12 14:34:21.566454+00', NULL);
INSERT INTO public.user_sessions VALUES (218, 3, '6260f1c5-91c4-4e95-b4a2-045d048d17cf', NULL, NULL, '2026-03-13 15:03:26.296184+00', '2026-04-12 15:03:26.296184+00', NULL);
INSERT INTO public.user_sessions VALUES (219, 3, 'ab0f6195-c900-4279-bb04-9e87a666936c', NULL, NULL, '2026-03-13 15:07:00.5383+00', '2026-04-12 15:07:00.5383+00', NULL);
INSERT INTO public.user_sessions VALUES (220, 3, '462e711a-89e1-43d2-9307-b71e9b26116c', NULL, NULL, '2026-03-13 15:34:47.899348+00', '2026-04-12 15:34:47.899348+00', NULL);
INSERT INTO public.user_sessions VALUES (221, 3, '2801f2d3-a488-41bb-af89-bb04c35a75bd', NULL, NULL, '2026-03-13 15:36:32.482425+00', '2026-04-12 15:36:32.482425+00', NULL);
INSERT INTO public.user_sessions VALUES (222, 3, 'f86edde0-b913-44cf-9272-a3be7e806c61', NULL, NULL, '2026-03-13 15:39:53.815996+00', '2026-04-12 15:39:53.815996+00', NULL);
INSERT INTO public.user_sessions VALUES (223, 3, '77d820ed-3bf4-4054-85ef-6890152834d6', NULL, NULL, '2026-03-13 15:40:50.622854+00', '2026-04-12 15:40:50.622854+00', NULL);
INSERT INTO public.user_sessions VALUES (224, 3, '9cf23170-bf71-4f9b-9716-acda7e60da2a', NULL, NULL, '2026-03-13 15:41:14.160413+00', '2026-04-12 15:41:14.160413+00', NULL);
INSERT INTO public.user_sessions VALUES (225, 3, 'ba11c0b8-445d-400e-bb1a-9d50a4341071', NULL, NULL, '2026-03-13 15:47:14.654721+00', '2026-04-12 15:47:14.654721+00', NULL);
INSERT INTO public.user_sessions VALUES (226, 3, 'd983b013-dcff-47d6-bc36-4fc89e13e851', NULL, NULL, '2026-03-13 15:47:50.759516+00', '2026-04-12 15:47:50.759516+00', NULL);
INSERT INTO public.user_sessions VALUES (227, 3, '10b9130f-6daf-4c1e-9457-851cbfa546fc', NULL, NULL, '2026-03-13 15:49:00.397694+00', '2026-04-12 15:49:00.397694+00', NULL);
INSERT INTO public.user_sessions VALUES (228, 3, '4a30688d-4a94-463f-814e-5cf078a152e7', NULL, NULL, '2026-03-13 15:53:16.510293+00', '2026-04-12 15:53:16.510293+00', NULL);
INSERT INTO public.user_sessions VALUES (229, 3, '2c6293b6-915b-427e-8dd2-e56e9528367f', NULL, NULL, '2026-03-13 15:55:07.949396+00', '2026-04-12 15:55:07.949396+00', NULL);
INSERT INTO public.user_sessions VALUES (230, 3, 'b0bfb3e8-9a27-4b94-a68f-313c5d58b4fd', NULL, NULL, '2026-03-13 15:55:54.936664+00', '2026-04-12 15:55:54.936664+00', NULL);
INSERT INTO public.user_sessions VALUES (231, 3, 'f8aae373-9d4d-4c45-b590-87c664fe52e3', NULL, NULL, '2026-03-13 15:57:04.937297+00', '2026-04-12 15:57:04.937297+00', NULL);
INSERT INTO public.user_sessions VALUES (232, 3, 'c90bf3b1-8611-41ea-bb95-aaa337023912', NULL, NULL, '2026-03-13 15:59:22.470085+00', '2026-04-12 15:59:22.470085+00', NULL);
INSERT INTO public.user_sessions VALUES (233, 3, '09fff33b-9957-4516-8a21-348806b24903', NULL, NULL, '2026-03-13 16:00:10.836311+00', '2026-04-12 16:00:10.836311+00', NULL);
INSERT INTO public.user_sessions VALUES (234, 3, 'dd540db3-bc86-4437-9f1b-4fcd70138268', NULL, NULL, '2026-03-13 17:06:24.419902+00', '2026-04-12 17:06:24.419902+00', NULL);
INSERT INTO public.user_sessions VALUES (235, 3, '086cd11d-1086-411f-8969-9f11fa505328', NULL, NULL, '2026-03-13 17:08:27.832523+00', '2026-04-12 17:08:27.832523+00', NULL);
INSERT INTO public.user_sessions VALUES (236, 3, '311e90c4-6ae9-45de-9ae1-1197445e1688', NULL, NULL, '2026-03-13 17:09:06.226429+00', '2026-04-12 17:09:06.226429+00', NULL);
INSERT INTO public.user_sessions VALUES (237, 3, 'c1d3aa75-7ac9-444f-87f9-5dcc80f8cb49', NULL, NULL, '2026-03-13 17:24:39.561696+00', '2026-04-12 17:24:39.561696+00', NULL);
INSERT INTO public.user_sessions VALUES (238, 3, 'eddfe6d2-ea07-45ea-a33e-744773077f4a', NULL, NULL, '2026-03-13 17:25:36.06491+00', '2026-04-12 17:25:36.06491+00', NULL);
INSERT INTO public.user_sessions VALUES (239, 3, '8f8d017f-8a4a-4634-a152-2b21d694d586', NULL, NULL, '2026-03-13 17:25:47.724971+00', '2026-04-12 17:25:47.724971+00', NULL);
INSERT INTO public.user_sessions VALUES (240, 3, 'f09a1c47-98a5-4dda-81f7-ddc7a7ddfeed', NULL, NULL, '2026-03-13 17:26:43.113273+00', '2026-04-12 17:26:43.113273+00', NULL);
INSERT INTO public.user_sessions VALUES (241, 3, 'ce70c4e5-ee44-4c7d-8d0c-14df6742154c', NULL, NULL, '2026-03-13 17:27:19.660868+00', '2026-04-12 17:27:19.660868+00', NULL);
INSERT INTO public.user_sessions VALUES (242, 3, '5a997f8f-72ef-4d15-944b-9476eda5bc6b', NULL, NULL, '2026-03-13 17:43:20.631613+00', '2026-04-12 17:43:20.631613+00', NULL);
INSERT INTO public.user_sessions VALUES (243, 3, '4bd41591-2986-4375-8c65-cf53c9f70254', NULL, NULL, '2026-03-13 17:44:05.986676+00', '2026-04-12 17:44:05.986676+00', NULL);
INSERT INTO public.user_sessions VALUES (244, 3, '9ad7105b-8ce2-4776-b978-dafb80a731d3', NULL, NULL, '2026-03-13 17:44:47.905865+00', '2026-04-12 17:44:47.905865+00', NULL);
INSERT INTO public.user_sessions VALUES (245, 3, '0c0d8337-0cb2-4458-afae-e8c1df70cdec', NULL, NULL, '2026-03-13 17:50:47.282597+00', '2026-04-12 17:50:47.282597+00', NULL);
INSERT INTO public.user_sessions VALUES (250, 3, '44095eed-a38f-4fce-b1a0-d0b14eb5cd92', NULL, NULL, '2026-03-13 18:20:59.431654+00', '2026-04-12 18:20:59.431654+00', NULL);
INSERT INTO public.user_sessions VALUES (246, 3, 'ba07a704-2757-4861-8a23-804c72cf7b5b', NULL, NULL, '2026-03-13 17:53:15.18251+00', '2026-04-12 17:53:15.18251+00', NULL);
INSERT INTO public.user_sessions VALUES (251, 3, '5910d4b7-85be-4a39-a331-31418288e409', NULL, NULL, '2026-03-13 20:22:32.539933+00', '2026-04-12 20:22:32.539933+00', NULL);
INSERT INTO public.user_sessions VALUES (247, 3, 'd5d697f6-d12e-4585-8f24-0990f3509178', NULL, NULL, '2026-03-13 17:59:14.560418+00', '2026-04-12 17:59:14.560418+00', NULL);
INSERT INTO public.user_sessions VALUES (248, 3, 'e6a7d0d3-cec4-4859-a44f-a1f62258eefb', NULL, NULL, '2026-03-13 18:02:06.441508+00', '2026-04-12 18:02:06.441508+00', NULL);
INSERT INTO public.user_sessions VALUES (249, 3, '3bac065a-ffc8-4b09-a352-2122534fe5b1', NULL, NULL, '2026-03-13 18:12:07.67246+00', '2026-04-12 18:12:07.67246+00', NULL);
INSERT INTO public.user_sessions VALUES (252, 3, 'fc1100ba-b71f-40a5-96d7-27a16aa6238a', NULL, NULL, '2026-03-14 11:12:56.364339+00', '2026-04-13 11:12:56.364339+00', NULL);
INSERT INTO public.user_sessions VALUES (253, 3, '27a00820-7311-4c18-9fbe-8c46ab64c7c2', NULL, NULL, '2026-03-14 11:14:53.958429+00', '2026-04-13 11:14:53.958429+00', NULL);
INSERT INTO public.user_sessions VALUES (254, 3, '8da698d7-8678-4a63-a67d-5438524fba67', NULL, NULL, '2026-03-14 11:15:38.094052+00', '2026-04-13 11:15:38.094052+00', NULL);
INSERT INTO public.user_sessions VALUES (255, 3, 'e5849902-b180-4d12-8a3f-9f9dab292735', NULL, NULL, '2026-03-14 11:16:03.153966+00', '2026-04-13 11:16:03.153966+00', NULL);
INSERT INTO public.user_sessions VALUES (256, 3, 'fff264eb-b99a-4562-9620-05daabf31689', NULL, NULL, '2026-03-14 11:18:03.130025+00', '2026-04-13 11:18:03.130025+00', NULL);
INSERT INTO public.user_sessions VALUES (257, 3, 'acce7bd0-a1ba-43c9-bda3-1213db16c70a', NULL, NULL, '2026-03-14 11:46:50.796113+00', '2026-04-13 11:46:50.796113+00', NULL);
INSERT INTO public.user_sessions VALUES (258, 3, '31f315a9-500c-4b66-a3ea-e83cc3692b64', NULL, NULL, '2026-03-14 11:48:57.083049+00', '2026-04-13 11:48:57.083049+00', NULL);
INSERT INTO public.user_sessions VALUES (259, 3, 'fd0fdcfc-5f5b-4c03-b41f-f34140a3a308', NULL, NULL, '2026-03-14 11:50:46.883915+00', '2026-04-13 11:50:46.883915+00', NULL);
INSERT INTO public.user_sessions VALUES (260, 3, '08d5f155-43c7-471b-ab2b-16bdccd24596', NULL, NULL, '2026-03-14 11:56:49.295898+00', '2026-04-13 11:56:49.295898+00', NULL);
INSERT INTO public.user_sessions VALUES (261, 3, '81b65381-8743-4601-bf0b-697b30eab69f', NULL, NULL, '2026-03-14 11:57:17.902291+00', '2026-04-13 11:57:17.902291+00', NULL);
INSERT INTO public.user_sessions VALUES (262, 3, '33b60dab-8f97-4338-8737-9473d14d0028', NULL, NULL, '2026-03-14 11:57:35.6456+00', '2026-04-13 11:57:35.6456+00', NULL);
INSERT INTO public.user_sessions VALUES (263, 3, '8d01e80f-e1d0-4dfb-8743-7609d1602d2d', NULL, NULL, '2026-03-14 11:59:40.359989+00', '2026-04-13 11:59:40.359989+00', NULL);
INSERT INTO public.user_sessions VALUES (264, 3, '779d7964-5e27-4f78-93f7-978c3ddedd78', NULL, NULL, '2026-03-14 12:01:41.780799+00', '2026-04-13 12:01:41.780799+00', NULL);
INSERT INTO public.user_sessions VALUES (265, 3, '2bcb8353-5119-4d90-8710-fe1f2245309f', NULL, NULL, '2026-03-14 12:08:31.041424+00', '2026-04-13 12:08:31.041424+00', NULL);
INSERT INTO public.user_sessions VALUES (266, 3, '39f14fb2-b60f-46af-80fb-ffc14d1d3847', NULL, NULL, '2026-03-14 12:09:43.887379+00', '2026-04-13 12:09:43.887379+00', NULL);
INSERT INTO public.user_sessions VALUES (267, 3, 'dc4472d6-a323-4643-ba33-330c69c5ab2d', NULL, NULL, '2026-03-14 12:10:54.23336+00', '2026-04-13 12:10:54.23336+00', NULL);
INSERT INTO public.user_sessions VALUES (268, 3, '5682fd12-97b2-40c5-ae28-d88598c4fe4d', NULL, NULL, '2026-03-14 12:11:43.26716+00', '2026-04-13 12:11:43.26716+00', NULL);
INSERT INTO public.user_sessions VALUES (269, 3, '4b1e35cc-1332-4c1f-bb3e-a10f87518242', NULL, NULL, '2026-03-14 12:27:46.628055+00', '2026-04-13 12:27:46.628055+00', NULL);
INSERT INTO public.user_sessions VALUES (270, 3, 'fada169e-81fb-4145-ad51-9f6259c07b91', NULL, NULL, '2026-03-14 12:52:03.107445+00', '2026-04-13 12:52:03.107445+00', NULL);
INSERT INTO public.user_sessions VALUES (271, 3, 'd7c2f135-f7b9-4f05-91b5-5a70959cbb0a', NULL, NULL, '2026-03-14 12:52:39.738964+00', '2026-04-13 12:52:39.738964+00', NULL);
INSERT INTO public.user_sessions VALUES (272, 3, '5170cec8-9670-4a0c-9536-68ce978c9a9b', NULL, NULL, '2026-03-14 12:57:30.233773+00', '2026-04-13 12:57:30.233773+00', NULL);
INSERT INTO public.user_sessions VALUES (273, 3, 'b2043c52-ea3b-4d3a-a21e-436cdf7001f9', NULL, NULL, '2026-03-14 12:59:32.827945+00', '2026-04-13 12:59:32.827945+00', NULL);
INSERT INTO public.user_sessions VALUES (274, 3, '2f579857-d0dc-4cb7-8802-30d0b51e1e75', NULL, NULL, '2026-03-14 13:05:13.478676+00', '2026-04-13 13:05:13.478676+00', NULL);
INSERT INTO public.user_sessions VALUES (275, 3, 'c0a20db5-e936-4f95-96f2-42e1c8606cc2', NULL, NULL, '2026-03-14 13:05:26.463117+00', '2026-04-13 13:05:26.463117+00', NULL);
INSERT INTO public.user_sessions VALUES (276, 3, '17b6e141-9ace-44ed-9875-a2a8af427bff', NULL, NULL, '2026-03-14 13:15:51.573653+00', '2026-04-13 13:15:51.573653+00', NULL);
INSERT INTO public.user_sessions VALUES (277, 3, 'f48d91fe-57c1-42b8-956f-1c5b28af1d88', NULL, NULL, '2026-03-14 13:17:39.474219+00', '2026-04-13 13:17:39.474219+00', NULL);
INSERT INTO public.user_sessions VALUES (278, 3, '7c6d5194-7a21-4f15-b38c-b4271d462de1', NULL, NULL, '2026-03-14 13:25:00.385933+00', '2026-04-13 13:25:00.385933+00', NULL);
INSERT INTO public.user_sessions VALUES (279, 3, '14b9a5a6-06b4-42cb-9e79-ec74f955780c', NULL, NULL, '2026-03-14 13:25:18.98747+00', '2026-04-13 13:25:18.98747+00', NULL);
INSERT INTO public.user_sessions VALUES (280, 3, '0253674a-766c-4ab1-9adb-8af9d35ff8f5', NULL, NULL, '2026-03-14 13:26:09.57735+00', '2026-04-13 13:26:09.57735+00', NULL);
INSERT INTO public.user_sessions VALUES (281, 3, '77cebfb1-75e3-4904-9574-58261d7e9b20', NULL, NULL, '2026-03-14 13:36:54.244624+00', '2026-04-13 13:36:54.244624+00', NULL);
INSERT INTO public.user_sessions VALUES (282, 3, 'dec985f9-d1b9-49a1-9f7d-7b90bb78d02b', NULL, NULL, '2026-03-14 13:39:16.640125+00', '2026-04-13 13:39:16.640125+00', NULL);
INSERT INTO public.user_sessions VALUES (283, 3, '1dcbc5a7-730a-4722-a768-a5ddeb60820c', NULL, NULL, '2026-03-14 13:41:25.450458+00', '2026-04-13 13:41:25.450458+00', NULL);
INSERT INTO public.user_sessions VALUES (284, 3, '92f730fe-f60e-4a00-965c-89bba8ff96fd', NULL, NULL, '2026-03-14 13:43:31.137683+00', '2026-04-13 13:43:31.137683+00', NULL);
INSERT INTO public.user_sessions VALUES (285, 3, '7cbf0c24-e8a4-43ab-afb1-f01616d2cf74', NULL, NULL, '2026-03-14 13:45:17.7281+00', '2026-04-13 13:45:17.7281+00', NULL);
INSERT INTO public.user_sessions VALUES (286, 3, '4a485cc3-3bf3-48dc-9bef-8d118afbc5d3', NULL, NULL, '2026-03-14 13:46:45.465894+00', '2026-04-13 13:46:45.465894+00', NULL);
INSERT INTO public.user_sessions VALUES (287, 3, '2f32a3e9-11b5-4396-b73f-11de772b09b2', NULL, NULL, '2026-03-14 16:45:48.978623+00', '2026-04-13 16:45:48.978623+00', NULL);
INSERT INTO public.user_sessions VALUES (288, 3, '73bdf823-f765-4b39-8843-8dfd0d104378', NULL, NULL, '2026-03-14 16:48:11.692529+00', '2026-04-13 16:48:11.692529+00', NULL);
INSERT INTO public.user_sessions VALUES (289, 3, '9b2e8617-b432-4733-bbd2-29fd35cd1634', NULL, NULL, '2026-03-14 16:56:17.38203+00', '2026-04-13 16:56:17.38203+00', NULL);
INSERT INTO public.user_sessions VALUES (290, 3, 'e26f3231-8fa2-4776-b9be-d36694ea588e', NULL, NULL, '2026-03-15 18:37:08.529576+00', '2026-04-14 18:37:08.529576+00', NULL);
INSERT INTO public.user_sessions VALUES (291, 3, '2b068e8f-8671-47f7-9269-83c80a56a7f7', NULL, NULL, '2026-03-15 18:38:39.230643+00', '2026-04-14 18:38:39.230643+00', NULL);
INSERT INTO public.user_sessions VALUES (292, 3, 'b1c2b997-e9b7-44f6-974f-3c29009287e2', NULL, NULL, '2026-03-15 18:48:46.254273+00', '2026-04-14 18:48:46.254273+00', NULL);
INSERT INTO public.user_sessions VALUES (293, 3, '0f30a08c-8a06-4c45-96d1-40324721d891', NULL, NULL, '2026-03-15 20:28:19.984736+00', '2026-04-14 20:28:19.984736+00', NULL);
INSERT INTO public.user_sessions VALUES (294, 3, 'a9373268-4bc6-482c-906a-748d067ad2d3', NULL, NULL, '2026-03-16 09:53:36.630612+00', '2026-04-15 09:53:36.630612+00', NULL);
INSERT INTO public.user_sessions VALUES (295, 3, '091c31da-8c8b-4d75-abc5-a796adf68be8', NULL, NULL, '2026-03-16 09:54:00.299684+00', '2026-04-15 09:54:00.299684+00', NULL);
INSERT INTO public.user_sessions VALUES (296, 3, '951ecc94-04cf-404d-a6d0-224a3cd8b139', NULL, NULL, '2026-03-16 09:54:24.462791+00', '2026-04-15 09:54:24.462791+00', NULL);
INSERT INTO public.user_sessions VALUES (297, 3, 'ccc06f16-2adc-4d8d-8d94-64b5da2ca60d', NULL, NULL, '2026-03-16 09:58:47.673935+00', '2026-04-15 09:58:47.673935+00', NULL);
INSERT INTO public.user_sessions VALUES (298, 3, 'a4c523eb-72fe-42fd-9b81-9fd2841cffce', NULL, NULL, '2026-03-16 10:01:58.520431+00', '2026-04-15 10:01:58.520431+00', NULL);
INSERT INTO public.user_sessions VALUES (299, 3, '03385cbc-7c93-416e-8be7-7ccc8b34dbfe', NULL, NULL, '2026-03-16 10:11:37.587917+00', '2026-04-15 10:11:37.587917+00', NULL);
INSERT INTO public.user_sessions VALUES (300, 3, '43328ac9-1bce-498d-a132-f3cc7cfdfbd4', NULL, NULL, '2026-03-16 10:12:52.888572+00', '2026-04-15 10:12:52.888572+00', NULL);
INSERT INTO public.user_sessions VALUES (301, 3, 'bd191cc9-7a8b-4b89-8be1-4febdf1e7012', NULL, NULL, '2026-03-16 10:13:52.130271+00', '2026-04-15 10:13:52.130271+00', NULL);
INSERT INTO public.user_sessions VALUES (302, 3, '6c414938-656f-4358-99ac-d0271332c0b8', NULL, NULL, '2026-03-16 11:07:13.851148+00', '2026-04-15 11:07:13.851148+00', NULL);
INSERT INTO public.user_sessions VALUES (303, 3, 'b23c6205-5d94-409e-a228-9dd1eef2a156', NULL, NULL, '2026-03-16 11:10:51.123798+00', '2026-04-15 11:10:51.123798+00', NULL);
INSERT INTO public.user_sessions VALUES (304, 3, 'b0b4b18e-b8f9-443a-8fbc-5b780e7ed74b', NULL, NULL, '2026-03-16 11:29:01.533457+00', '2026-04-15 11:29:01.533457+00', NULL);
INSERT INTO public.user_sessions VALUES (305, 3, 'c9559eff-f010-462e-ba23-6b0084e3308e', NULL, NULL, '2026-03-16 11:56:32.256655+00', '2026-04-15 11:56:32.256655+00', NULL);
INSERT INTO public.user_sessions VALUES (306, 3, 'c74cd9b0-710c-4521-9caf-bd03df5ba94f', NULL, NULL, '2026-03-16 12:08:29.776175+00', '2026-04-15 12:08:29.776175+00', NULL);
INSERT INTO public.user_sessions VALUES (307, 3, '1761192d-529c-4c56-846b-77c2124c9765', NULL, NULL, '2026-03-16 12:21:19.695028+00', '2026-04-15 12:21:19.695028+00', NULL);
INSERT INTO public.user_sessions VALUES (308, 3, '94f8dd0f-2848-4b17-8de2-9eec4de9562f', NULL, NULL, '2026-03-16 12:38:39.957121+00', '2026-04-15 12:38:39.957121+00', NULL);
INSERT INTO public.user_sessions VALUES (309, 3, '9517e915-39d9-4d25-9bd2-07fb78980b83', NULL, NULL, '2026-03-16 12:39:51.399036+00', '2026-04-15 12:39:51.399036+00', NULL);
INSERT INTO public.user_sessions VALUES (310, 3, '446f4a9e-5ee4-48c6-a7ff-fa37a6cd7bdf', NULL, NULL, '2026-03-16 12:47:02.535381+00', '2026-04-15 12:47:02.535381+00', NULL);
INSERT INTO public.user_sessions VALUES (311, 3, '9af83fa0-6371-4d67-80d2-7b3262610e9b', NULL, NULL, '2026-03-16 12:47:35.896846+00', '2026-04-15 12:47:35.896846+00', NULL);
INSERT INTO public.user_sessions VALUES (312, 3, '3735b33c-d14e-4445-9538-f7f71cae1e4e', NULL, NULL, '2026-03-16 12:53:54.566645+00', '2026-04-15 12:53:54.566645+00', NULL);
INSERT INTO public.user_sessions VALUES (313, 3, '4712d6a0-676f-48ec-b8bd-126a03a9af20', NULL, NULL, '2026-03-16 12:54:09.859557+00', '2026-04-15 12:54:09.859557+00', NULL);
INSERT INTO public.user_sessions VALUES (314, 3, 'e4102752-8b1f-4ad5-9e1b-778b44f6e575', NULL, NULL, '2026-03-16 13:30:46.749943+00', '2026-04-15 13:30:46.749943+00', NULL);
INSERT INTO public.user_sessions VALUES (315, 3, '3ffe713b-7254-4447-900b-b427d0232c46', NULL, NULL, '2026-03-16 13:32:24.744072+00', '2026-04-15 13:32:24.744072+00', NULL);
INSERT INTO public.user_sessions VALUES (316, 3, 'cb433ebf-2321-4b8f-bf99-5fb5258a0313', NULL, NULL, '2026-03-16 13:33:08.187791+00', '2026-04-15 13:33:08.187791+00', NULL);
INSERT INTO public.user_sessions VALUES (317, 3, '82f284fb-b14f-4e89-b027-28d790c65bba', NULL, NULL, '2026-03-16 14:24:39.448176+00', '2026-04-15 14:24:39.448176+00', NULL);
INSERT INTO public.user_sessions VALUES (318, 3, '1fe9789e-a256-4f31-9931-7dd558aac664', NULL, NULL, '2026-03-16 14:29:38.650207+00', '2026-04-15 14:29:38.650207+00', NULL);
INSERT INTO public.user_sessions VALUES (319, 3, 'e7c48f80-4416-4d9b-b3ac-70d7b1f613e6', NULL, NULL, '2026-03-16 14:49:56.346495+00', '2026-04-15 14:49:56.346495+00', NULL);
INSERT INTO public.user_sessions VALUES (320, 3, '69456c68-5af3-4756-8faf-860ece2a4bc2', NULL, NULL, '2026-03-16 14:53:27.607424+00', '2026-04-15 14:53:27.607424+00', NULL);
INSERT INTO public.user_sessions VALUES (321, 3, 'd64c1f54-a41b-4881-96c0-eafdb658e425', NULL, NULL, '2026-03-16 14:54:24.296505+00', '2026-04-15 14:54:24.296505+00', NULL);
INSERT INTO public.user_sessions VALUES (322, 3, '2c3d4465-3920-4a70-8362-187dde9f0097', NULL, NULL, '2026-03-16 14:56:11.873894+00', '2026-04-15 14:56:11.873894+00', NULL);
INSERT INTO public.user_sessions VALUES (323, 3, 'cdd682aa-bc2e-47a4-9165-05f6f012993a', NULL, NULL, '2026-03-16 14:56:25.591654+00', '2026-04-15 14:56:25.591654+00', NULL);
INSERT INTO public.user_sessions VALUES (324, 3, 'dc5fb68f-ba29-48c2-b6a3-57a3eea3bd80', NULL, NULL, '2026-03-16 14:58:15.093779+00', '2026-04-15 14:58:15.093779+00', NULL);
INSERT INTO public.user_sessions VALUES (325, 3, '7d83d749-c1e5-4a7e-81bf-0427be7c5a9d', NULL, NULL, '2026-03-16 14:58:58.189741+00', '2026-04-15 14:58:58.189741+00', NULL);
INSERT INTO public.user_sessions VALUES (326, 3, '667e7117-e31c-4940-ac6c-5c876b3f786a', NULL, NULL, '2026-03-16 14:59:18.206282+00', '2026-04-15 14:59:18.206282+00', NULL);
INSERT INTO public.user_sessions VALUES (327, 3, '0f78a511-f81c-4013-b7f6-239008ac9164', NULL, NULL, '2026-03-16 15:00:00.906455+00', '2026-04-15 15:00:00.906455+00', NULL);
INSERT INTO public.user_sessions VALUES (328, 3, '873d8071-0607-4634-853c-0f293fc139ed', NULL, NULL, '2026-03-16 15:02:31.699864+00', '2026-04-15 15:02:31.699864+00', NULL);
INSERT INTO public.user_sessions VALUES (329, 3, 'c21804b0-0cf2-4beb-8ae8-9f37695ced64', NULL, NULL, '2026-03-16 15:05:31.854156+00', '2026-04-15 15:05:31.854156+00', NULL);
INSERT INTO public.user_sessions VALUES (330, 3, '3f33a200-9841-4739-8440-3397bd66d5bd', NULL, NULL, '2026-03-16 15:05:49.202794+00', '2026-04-15 15:05:49.202794+00', NULL);
INSERT INTO public.user_sessions VALUES (331, 3, 'abe01d01-6fd5-45ae-acae-ff5154b31f8a', NULL, NULL, '2026-03-16 15:06:42.71422+00', '2026-04-15 15:06:42.71422+00', NULL);
INSERT INTO public.user_sessions VALUES (332, 3, '77e69f7d-7411-4dd4-a7b4-6f7f71b56c2d', NULL, NULL, '2026-03-16 15:10:26.153263+00', '2026-04-15 15:10:26.153263+00', NULL);
INSERT INTO public.user_sessions VALUES (337, 3, '2c7c43df-deb0-4928-a536-391175d6ddc9', NULL, NULL, '2026-03-16 16:03:39.768101+00', '2026-04-15 16:03:39.768101+00', NULL);
INSERT INTO public.user_sessions VALUES (342, 3, '480091f4-a444-4821-a40d-f1db5e4bf647', NULL, NULL, '2026-03-16 16:37:13.883051+00', '2026-04-15 16:37:13.883051+00', NULL);
INSERT INTO public.user_sessions VALUES (347, 3, 'fe0fb04c-4c4f-4ca5-8132-48e9ced9f56c', NULL, NULL, '2026-03-16 16:44:06.151872+00', '2026-04-15 16:44:06.151872+00', NULL);
INSERT INTO public.user_sessions VALUES (352, 3, '28abf219-abad-4e42-8c5c-a235d0077267', NULL, NULL, '2026-03-16 16:47:20.630069+00', '2026-04-15 16:47:20.630069+00', NULL);
INSERT INTO public.user_sessions VALUES (357, 3, '687e5371-3f51-42bc-a21e-f69183d0a1a1', NULL, NULL, '2026-03-16 17:01:41.747555+00', '2026-04-15 17:01:41.747555+00', NULL);
INSERT INTO public.user_sessions VALUES (362, 3, 'af9a89a1-ec39-45ae-812a-f5f973c1b27a', NULL, NULL, '2026-03-16 19:54:47.307665+00', '2026-04-15 19:54:47.307665+00', NULL);
INSERT INTO public.user_sessions VALUES (333, 3, 'c59b4ff8-361d-469b-bab4-d6b114b05fbb', NULL, NULL, '2026-03-16 15:10:49.176216+00', '2026-04-15 15:10:49.176216+00', NULL);
INSERT INTO public.user_sessions VALUES (338, 3, 'c1990416-7c9f-408a-88f5-e4cb89a05553', NULL, NULL, '2026-03-16 16:32:36.711649+00', '2026-04-15 16:32:36.711649+00', NULL);
INSERT INTO public.user_sessions VALUES (343, 3, '6992babf-c49a-4e6d-a48f-8146f4c62054', NULL, NULL, '2026-03-16 16:37:26.460806+00', '2026-04-15 16:37:26.460806+00', NULL);
INSERT INTO public.user_sessions VALUES (348, 3, '0b3c5274-0bb7-48d5-84cc-c54447673ebd', NULL, NULL, '2026-03-16 16:44:28.749119+00', '2026-04-15 16:44:28.749119+00', NULL);
INSERT INTO public.user_sessions VALUES (353, 3, '6e764bc1-f301-48a5-a1ce-787f1513d421', NULL, NULL, '2026-03-16 16:48:10.75812+00', '2026-04-15 16:48:10.75812+00', NULL);
INSERT INTO public.user_sessions VALUES (358, 3, 'a0de4cf4-b47f-45eb-83fe-5de521f0b25a', NULL, NULL, '2026-03-16 17:02:02.853894+00', '2026-04-15 17:02:02.853894+00', NULL);
INSERT INTO public.user_sessions VALUES (334, 3, 'b0458209-b452-4929-8f1e-138f2bbf820d', NULL, NULL, '2026-03-16 15:11:00.243908+00', '2026-04-15 15:11:00.243908+00', NULL);
INSERT INTO public.user_sessions VALUES (339, 3, '9743fc3e-934a-4680-a441-f0d84f8658cd', NULL, NULL, '2026-03-16 16:35:41.467158+00', '2026-04-15 16:35:41.467158+00', NULL);
INSERT INTO public.user_sessions VALUES (344, 3, '60ce9122-b3ea-4326-b73d-9c16e953dcf9', NULL, NULL, '2026-03-16 16:39:24.009916+00', '2026-04-15 16:39:24.009916+00', NULL);
INSERT INTO public.user_sessions VALUES (349, 3, '680c5761-1228-49fe-aa01-d5c22fa791f6', NULL, NULL, '2026-03-16 16:45:11.493866+00', '2026-04-15 16:45:11.493866+00', NULL);
INSERT INTO public.user_sessions VALUES (354, 3, 'df40901b-1ccd-43f0-86ba-81947eae8f97', NULL, NULL, '2026-03-16 16:49:20.703241+00', '2026-04-15 16:49:20.703241+00', NULL);
INSERT INTO public.user_sessions VALUES (359, 3, 'a5dc166d-8d3c-4a71-bd0a-b87a325154e0', NULL, NULL, '2026-03-16 17:02:30.550106+00', '2026-04-15 17:02:30.550106+00', NULL);
INSERT INTO public.user_sessions VALUES (335, 3, '0305a193-654f-4d41-adeb-b5b26f78bbad', NULL, NULL, '2026-03-16 15:17:35.971063+00', '2026-04-15 15:17:35.971063+00', NULL);
INSERT INTO public.user_sessions VALUES (340, 3, '14969cdb-0f62-4ca0-adea-b0be79590e26', NULL, NULL, '2026-03-16 16:36:17.80467+00', '2026-04-15 16:36:17.80467+00', NULL);
INSERT INTO public.user_sessions VALUES (345, 3, 'a2c8819c-8689-49fb-be19-012e696bd035', NULL, NULL, '2026-03-16 16:41:52.728598+00', '2026-04-15 16:41:52.728598+00', NULL);
INSERT INTO public.user_sessions VALUES (350, 3, '01002996-dbf8-4c05-82e2-4751c7b39804', NULL, NULL, '2026-03-16 16:46:26.459576+00', '2026-04-15 16:46:26.459576+00', NULL);
INSERT INTO public.user_sessions VALUES (355, 3, 'b59c5f93-5617-436a-94a2-0437b3aefd9e', NULL, NULL, '2026-03-16 16:58:04.783069+00', '2026-04-15 16:58:04.783069+00', NULL);
INSERT INTO public.user_sessions VALUES (360, 3, 'd40425df-969a-473e-930d-26ce76859bb8', NULL, NULL, '2026-03-16 19:52:50.592671+00', '2026-04-15 19:52:50.592671+00', NULL);
INSERT INTO public.user_sessions VALUES (336, 3, '53b55501-e3c0-47fd-8d60-73e20837e4e3', NULL, NULL, '2026-03-16 16:03:05.127033+00', '2026-04-15 16:03:05.127033+00', NULL);
INSERT INTO public.user_sessions VALUES (341, 3, '71f24323-ee0f-4efe-bbfd-8e33b277b2fa', NULL, NULL, '2026-03-16 16:36:46.58458+00', '2026-04-15 16:36:46.58458+00', NULL);
INSERT INTO public.user_sessions VALUES (346, 3, 'c8601c13-07ea-4478-b38e-0da4063619a6', NULL, NULL, '2026-03-16 16:43:15.78236+00', '2026-04-15 16:43:15.78236+00', NULL);
INSERT INTO public.user_sessions VALUES (351, 3, 'cf51e7da-3e8b-444c-b273-0f29cc48ff9b', NULL, NULL, '2026-03-16 16:46:55.47281+00', '2026-04-15 16:46:55.47281+00', NULL);
INSERT INTO public.user_sessions VALUES (356, 3, 'ef74e788-5741-48ea-8886-436088c430b2', NULL, NULL, '2026-03-16 17:00:25.485892+00', '2026-04-15 17:00:25.485892+00', NULL);
INSERT INTO public.user_sessions VALUES (361, 3, '4a05334d-023e-4681-9c23-0825b6f940b6', NULL, NULL, '2026-03-16 19:53:46.458029+00', '2026-04-15 19:53:46.458029+00', NULL);
INSERT INTO public.user_sessions VALUES (363, 3, 'dc48c477-3ed5-4fd9-9288-8bba5974d173', NULL, NULL, '2026-03-17 14:26:40.19121+00', '2026-04-16 14:26:40.19121+00', NULL);
INSERT INTO public.user_sessions VALUES (364, 3, '247116b8-78df-4475-bded-1c88db037e78', NULL, NULL, '2026-03-17 14:33:42.479679+00', '2026-04-16 14:33:42.479679+00', NULL);
INSERT INTO public.user_sessions VALUES (365, 3, '031cc1fc-4add-4b79-8983-9c946b2e24ba', NULL, NULL, '2026-03-17 14:36:14.991907+00', '2026-04-16 14:36:14.991907+00', NULL);
INSERT INTO public.user_sessions VALUES (366, 3, 'cd603f5e-1c03-4890-b995-f9254bd54c16', NULL, NULL, '2026-03-17 14:44:07.518952+00', '2026-04-16 14:44:07.518952+00', NULL);
INSERT INTO public.user_sessions VALUES (367, 3, '3ef283b2-3281-46a5-b943-a3f574dd7fba', NULL, NULL, '2026-03-17 14:46:55.99598+00', '2026-04-16 14:46:55.99598+00', NULL);
INSERT INTO public.user_sessions VALUES (368, 3, 'ad5c5c18-557a-4145-862d-4b6c5b6b840a', NULL, NULL, '2026-03-17 14:53:54.831245+00', '2026-04-16 14:53:54.831245+00', NULL);
INSERT INTO public.user_sessions VALUES (369, 3, 'a9b51580-b63f-4e2c-8183-c274461eb175', NULL, NULL, '2026-03-17 15:11:51.807812+00', '2026-04-16 15:11:51.807812+00', NULL);
INSERT INTO public.user_sessions VALUES (370, 3, '6355abce-3c6d-4ac8-9a26-c33c7a688b74', NULL, NULL, '2026-03-17 16:21:28.75378+00', '2026-04-16 16:21:28.75378+00', NULL);
INSERT INTO public.user_sessions VALUES (371, 3, 'd76b8fb4-e1ba-4a1a-a1bf-58a9b5f9dfcf', NULL, NULL, '2026-03-17 16:24:54.773377+00', '2026-04-16 16:24:54.773377+00', NULL);
INSERT INTO public.user_sessions VALUES (372, 3, 'd448cbd0-4be7-4968-9cee-478887a699b0', NULL, NULL, '2026-03-17 16:26:53.655119+00', '2026-04-16 16:26:53.655119+00', NULL);
INSERT INTO public.user_sessions VALUES (373, 3, '8df6408b-37b4-4d55-b5b0-403d9f9c1fb6', NULL, NULL, '2026-03-17 17:17:39.635062+00', '2026-04-16 17:17:39.635062+00', NULL);
INSERT INTO public.user_sessions VALUES (374, 3, '24c563c8-abb8-4e54-923e-85479e1c1582', NULL, NULL, '2026-03-17 17:32:27.760895+00', '2026-04-16 17:32:27.760895+00', NULL);
INSERT INTO public.user_sessions VALUES (375, 3, '3d4a9f6d-c9a6-4815-b6b3-ca73524305ff', NULL, NULL, '2026-03-17 17:37:13.069081+00', '2026-04-16 17:37:13.069081+00', NULL);
INSERT INTO public.user_sessions VALUES (376, 4, 'e7da6960-f13e-45ba-ad71-1bbfb7f0a47d', NULL, NULL, '2026-03-17 17:37:18.361457+00', '2026-04-16 17:37:18.361457+00', NULL);
INSERT INTO public.user_sessions VALUES (377, 3, '25ed3c71-631c-4152-8eb6-61ae002d8809', NULL, NULL, '2026-03-17 17:50:13.827001+00', '2026-04-16 17:50:13.827001+00', NULL);
INSERT INTO public.user_sessions VALUES (378, 4, '8bd8b2a3-dd5d-4e78-bea2-f12541d4d5ae', NULL, NULL, '2026-03-17 17:50:38.961756+00', '2026-04-16 17:50:38.961756+00', NULL);
INSERT INTO public.user_sessions VALUES (379, 3, '364f52dc-56f7-4ea4-bf5b-4abb7028302f', NULL, NULL, '2026-03-17 18:12:24.664812+00', '2026-04-16 18:12:24.664812+00', NULL);
INSERT INTO public.user_sessions VALUES (380, 4, 'f09d4ab7-d242-42b7-85c6-eca59c702f99', NULL, NULL, '2026-03-17 18:14:05.034+00', '2026-04-16 18:14:05.034+00', NULL);
INSERT INTO public.user_sessions VALUES (381, 3, '7c6ff501-f325-45ac-ab4c-9302a443dcef', NULL, NULL, '2026-03-17 18:19:23.703928+00', '2026-04-16 18:19:23.703928+00', NULL);
INSERT INTO public.user_sessions VALUES (382, 3, 'b8dd1f3b-3884-4cbb-a19a-107b9ec54f89', NULL, NULL, '2026-03-17 18:19:53.988454+00', '2026-04-16 18:19:53.988454+00', NULL);
INSERT INTO public.user_sessions VALUES (383, 3, '3753db32-84e7-4da8-9d89-89f07ddc863c', NULL, NULL, '2026-03-17 18:20:15.63696+00', '2026-04-16 18:20:15.63696+00', NULL);
INSERT INTO public.user_sessions VALUES (384, 3, 'db92c11a-b413-487f-8f6a-e632f589e0af', NULL, NULL, '2026-03-17 18:37:04.272466+00', '2026-04-16 18:37:04.272466+00', NULL);
INSERT INTO public.user_sessions VALUES (385, 3, '7ab11566-1a0b-4896-9224-90e3e2b973d8', NULL, NULL, '2026-03-17 18:40:34.017208+00', '2026-04-16 18:40:34.017208+00', NULL);
INSERT INTO public.user_sessions VALUES (386, 3, '97ec838f-890d-470b-9781-9020356347f3', NULL, NULL, '2026-03-17 18:44:39.766547+00', '2026-04-16 18:44:39.766547+00', NULL);
INSERT INTO public.user_sessions VALUES (387, 3, 'c4621f63-7f99-45b9-b9f7-61bf0db145bd', NULL, NULL, '2026-03-17 18:52:11.364302+00', '2026-04-16 18:52:11.364302+00', NULL);
INSERT INTO public.user_sessions VALUES (388, 4, '71459c12-9552-4b45-8f19-2cbdcc9123fb', NULL, NULL, '2026-03-17 18:56:06.552732+00', '2026-04-16 18:56:06.552732+00', NULL);
INSERT INTO public.user_sessions VALUES (389, 3, '87684d18-dcc7-4529-8f8b-9c4a62d5414d', NULL, NULL, '2026-03-17 19:04:05.807771+00', '2026-04-16 19:04:05.807771+00', NULL);
INSERT INTO public.user_sessions VALUES (390, 3, '81f3560a-f54f-490c-b310-a5e08755da41', NULL, NULL, '2026-03-17 19:06:19.170874+00', '2026-04-16 19:06:19.170874+00', NULL);
INSERT INTO public.user_sessions VALUES (391, 4, '4a5d46a1-e252-4d12-9d3e-d6f7ec0d23b9', NULL, NULL, '2026-03-17 19:21:18.94617+00', '2026-04-16 19:21:18.94617+00', NULL);
INSERT INTO public.user_sessions VALUES (392, 3, '4471d2ad-8ef7-429b-a734-bec8aa467de3', NULL, NULL, '2026-03-17 19:24:29.679935+00', '2026-04-16 19:24:29.679935+00', NULL);
INSERT INTO public.user_sessions VALUES (393, 3, 'a967d4ac-22c6-4e35-a92f-2ab0833b1931', NULL, NULL, '2026-03-17 19:24:34.669435+00', '2026-04-16 19:24:34.669435+00', NULL);
INSERT INTO public.user_sessions VALUES (394, 4, '4267bc36-cbd8-4b4d-be36-b25c854efe5d', NULL, NULL, '2026-03-17 19:24:54.234717+00', '2026-04-16 19:24:54.234717+00', NULL);
INSERT INTO public.user_sessions VALUES (395, 3, '02155290-8aeb-458c-8ecf-8ba82241a194', NULL, NULL, '2026-03-17 19:24:56.732938+00', '2026-04-16 19:24:56.732938+00', NULL);
INSERT INTO public.user_sessions VALUES (396, 3, '51e99178-8649-495c-b5cf-4a48a61fdffc', NULL, NULL, '2026-03-17 19:27:27.342857+00', '2026-04-16 19:27:27.342857+00', NULL);
INSERT INTO public.user_sessions VALUES (397, 3, '771202af-63b5-4ebf-831c-03a8aa16282e', NULL, NULL, '2026-03-17 19:30:30.18748+00', '2026-04-16 19:30:30.18748+00', NULL);
INSERT INTO public.user_sessions VALUES (398, 3, 'eabfc0c1-ac9e-435d-a65a-72e5c326fbab', NULL, NULL, '2026-03-17 19:30:53.380582+00', '2026-04-16 19:30:53.380582+00', NULL);
INSERT INTO public.user_sessions VALUES (399, 4, '83ba4ce6-c948-43fe-822f-149e6ae0ab52', NULL, NULL, '2026-03-17 19:32:57.241846+00', '2026-04-16 19:32:57.241846+00', NULL);
INSERT INTO public.user_sessions VALUES (400, 3, '8d669f9e-04ed-49cd-abb0-3ee0e0e5d8ca', NULL, NULL, '2026-03-17 19:44:50.448148+00', '2026-04-16 19:44:50.448148+00', NULL);
INSERT INTO public.user_sessions VALUES (401, 3, 'b5a9fe90-be7b-4aae-b346-6c55da70fe52', NULL, NULL, '2026-03-17 19:49:47.251146+00', '2026-04-16 19:49:47.251146+00', NULL);
INSERT INTO public.user_sessions VALUES (402, 3, '257e52d1-364a-4f28-96a0-07c6b986b66d', NULL, NULL, '2026-03-17 20:13:46.158077+00', '2026-04-16 20:13:46.158077+00', NULL);
INSERT INTO public.user_sessions VALUES (403, 3, 'a84d9a41-799b-4c30-b789-70d658c3f448', NULL, NULL, '2026-03-18 10:21:39.307016+00', '2026-04-17 10:21:39.307016+00', NULL);
INSERT INTO public.user_sessions VALUES (404, 3, 'fd8977ee-c6ca-42e2-8f37-9eb774389c43', NULL, NULL, '2026-03-18 13:55:43.326525+00', '2026-04-17 13:55:43.326525+00', NULL);
INSERT INTO public.user_sessions VALUES (405, 3, '1ef92b20-e27e-4ee3-867a-4567b15d4099', NULL, NULL, '2026-03-18 13:58:36.005411+00', '2026-04-17 13:58:36.005411+00', NULL);
INSERT INTO public.user_sessions VALUES (406, 3, 'e0b87fb2-3833-4365-ab50-7f01b8161c79', NULL, NULL, '2026-03-18 13:58:45.758251+00', '2026-04-17 13:58:45.758251+00', NULL);
INSERT INTO public.user_sessions VALUES (407, 3, '667dcda3-4135-44dc-abd5-b5093e9a6fbf', NULL, NULL, '2026-03-18 14:02:17.302065+00', '2026-04-17 14:02:17.302065+00', NULL);
INSERT INTO public.user_sessions VALUES (408, 3, '8a180819-a269-42a5-969a-cc5e4b3825e1', NULL, NULL, '2026-03-18 19:54:51.442727+00', '2026-04-17 19:54:51.442727+00', NULL);
INSERT INTO public.user_sessions VALUES (409, 3, '68454628-8412-4d5e-abf1-031324798ab3', NULL, NULL, '2026-03-18 19:57:44.803902+00', '2026-04-17 19:57:44.803902+00', NULL);
INSERT INTO public.user_sessions VALUES (410, 3, '134c78ab-01a1-4ca1-9275-a3ad4d4c7ca0', NULL, NULL, '2026-03-18 20:00:45.621574+00', '2026-04-17 20:00:45.621574+00', NULL);
INSERT INTO public.user_sessions VALUES (411, 3, '7e1964db-dcca-406f-8eac-43dd48b53c22', NULL, NULL, '2026-03-18 20:02:58.329641+00', '2026-04-17 20:02:58.329641+00', NULL);
INSERT INTO public.user_sessions VALUES (412, 3, '293fce57-dcd7-44c2-8bc3-e404224dd404', NULL, NULL, '2026-03-18 20:04:55.375771+00', '2026-04-17 20:04:55.375771+00', NULL);
INSERT INTO public.user_sessions VALUES (413, 3, '2278402d-bcab-4b3a-b613-031add416804', NULL, NULL, '2026-03-18 20:07:02.703138+00', '2026-04-17 20:07:02.703138+00', NULL);
INSERT INTO public.user_sessions VALUES (414, 3, 'd4e2e0be-51be-4b07-a27e-746e7da44c85', NULL, NULL, '2026-03-18 20:09:17.256657+00', '2026-04-17 20:09:17.256657+00', NULL);
INSERT INTO public.user_sessions VALUES (415, 3, '3c1098cd-3cbe-46b6-ad4c-8e71d3d2308f', NULL, NULL, '2026-03-18 20:19:13.074127+00', '2026-04-17 20:19:13.074127+00', NULL);
INSERT INTO public.user_sessions VALUES (416, 3, '714313fa-f391-41e3-9442-48cc61452f2a', NULL, NULL, '2026-03-18 20:23:17.381383+00', '2026-04-17 20:23:17.381383+00', NULL);
INSERT INTO public.user_sessions VALUES (417, 3, '7acf8734-104d-4e7a-95a0-d7dd35ee8184', NULL, NULL, '2026-03-18 20:33:35.830066+00', '2026-04-17 20:33:35.830066+00', NULL);
INSERT INTO public.user_sessions VALUES (418, 3, 'c40b7e4a-effc-4164-bc45-9ed546af0b98', NULL, NULL, '2026-03-18 20:35:29.45764+00', '2026-04-17 20:35:29.45764+00', NULL);
INSERT INTO public.user_sessions VALUES (419, 3, '66783e41-4aaa-4278-9a9c-415ee54f8653', NULL, NULL, '2026-03-19 06:43:00.765179+00', '2026-04-18 06:43:00.765179+00', NULL);
INSERT INTO public.user_sessions VALUES (420, 3, '161437d4-4975-48e4-9871-d3ba92098dd0', NULL, NULL, '2026-03-19 06:48:10.575219+00', '2026-04-18 06:48:10.575219+00', NULL);
INSERT INTO public.user_sessions VALUES (421, 3, '881ca3cf-4288-40a9-a2aa-59fcdc0f3802', NULL, NULL, '2026-03-19 07:03:08.285284+00', '2026-04-18 07:03:08.285284+00', NULL);
INSERT INTO public.user_sessions VALUES (422, 3, '542794f2-3d45-409f-9d8c-9b94e73b8eab', NULL, NULL, '2026-03-19 07:04:27.775297+00', '2026-04-18 07:04:27.775297+00', NULL);
INSERT INTO public.user_sessions VALUES (423, 3, '784e27ff-1776-4b0d-b28f-3ce9e64c2a6a', NULL, NULL, '2026-03-19 07:21:55.076661+00', '2026-04-18 07:21:55.076661+00', NULL);
INSERT INTO public.user_sessions VALUES (424, 3, 'd0a6638f-3053-4dd5-a990-6ea1564295bc', NULL, NULL, '2026-03-19 07:36:01.061186+00', '2026-04-18 07:36:01.061186+00', NULL);
INSERT INTO public.user_sessions VALUES (425, 3, 'f39c33d7-8ee5-4a8a-838b-ba9ef4e7ddcf', NULL, NULL, '2026-03-19 07:39:03.786049+00', '2026-04-18 07:39:03.786049+00', NULL);
INSERT INTO public.user_sessions VALUES (426, 3, '81ea0b57-11a8-4fa8-a8b0-f172e8ad1be9', NULL, NULL, '2026-03-19 07:52:56.051812+00', '2026-04-18 07:52:56.051812+00', NULL);
INSERT INTO public.user_sessions VALUES (427, 3, 'e5023b3e-bdf0-4e3c-b5a0-6fa0ad74aa52', NULL, NULL, '2026-03-19 08:30:10.714666+00', '2026-04-18 08:30:10.714666+00', NULL);
INSERT INTO public.user_sessions VALUES (428, 3, 'beb39eee-a60d-435c-a8b8-2d0805c0b832', NULL, NULL, '2026-03-19 09:50:21.12557+00', '2026-04-18 09:50:21.12557+00', NULL);
INSERT INTO public.user_sessions VALUES (429, 3, 'c0b87843-6e59-4c53-9c11-80fec0203c48', NULL, NULL, '2026-03-19 10:16:05.329482+00', '2026-04-18 10:16:05.329482+00', NULL);
INSERT INTO public.user_sessions VALUES (430, 3, '2a2206dd-c7d4-46d8-a67a-0233f90f6c55', NULL, NULL, '2026-03-19 10:29:45.968747+00', '2026-04-18 10:29:45.968747+00', NULL);
INSERT INTO public.user_sessions VALUES (431, 3, 'fb865842-304d-4e35-9dca-7c919e3d86a8', NULL, NULL, '2026-03-19 10:42:14.878186+00', '2026-04-18 10:42:14.878186+00', NULL);
INSERT INTO public.user_sessions VALUES (432, 3, '5e0c7947-635e-49b4-8f86-dca0ffd42374', NULL, NULL, '2026-03-19 10:58:36.048683+00', '2026-04-18 10:58:36.048683+00', NULL);
INSERT INTO public.user_sessions VALUES (433, 3, 'a570c74a-5761-49f4-9110-6f4193df69f5', NULL, NULL, '2026-03-19 11:15:39.848782+00', '2026-04-18 11:15:39.848782+00', NULL);
INSERT INTO public.user_sessions VALUES (434, 3, '3dd06a66-f2e7-4a6d-bc7f-d558562fd3cf', NULL, NULL, '2026-03-19 11:21:01.271722+00', '2026-04-18 11:21:01.271722+00', NULL);
INSERT INTO public.user_sessions VALUES (435, 3, '04cc56b4-7a79-4baa-a1ae-3efee369b12b', NULL, NULL, '2026-03-19 11:21:54.425868+00', '2026-04-18 11:21:54.425868+00', NULL);
INSERT INTO public.user_sessions VALUES (436, 3, 'e8728a1e-25cf-47fb-89cc-c9b85a0db3f8', NULL, NULL, '2026-03-19 11:22:01.237789+00', '2026-04-18 11:22:01.237789+00', NULL);
INSERT INTO public.user_sessions VALUES (437, 3, 'd13a4b79-fb0c-47e6-b8e0-b6c05fd29110', NULL, NULL, '2026-03-19 11:31:58.5937+00', '2026-04-18 11:31:58.5937+00', NULL);
INSERT INTO public.user_sessions VALUES (438, 3, 'aadc35f0-7b2e-41fd-8b8c-bcf8a6667ad4', NULL, NULL, '2026-03-19 11:41:19.005072+00', '2026-04-18 11:41:19.005072+00', NULL);
INSERT INTO public.user_sessions VALUES (443, 3, '9c163835-7de5-452a-84fb-631f6a39aa23', NULL, NULL, '2026-03-19 13:55:53.157378+00', '2026-04-18 13:55:53.157378+00', NULL);
INSERT INTO public.user_sessions VALUES (448, 3, '81480869-b424-4d04-86a4-f3a398146bb0', NULL, NULL, '2026-03-19 14:27:02.243476+00', '2026-04-18 14:27:02.243476+00', NULL);
INSERT INTO public.user_sessions VALUES (453, 3, 'dffafdbd-93ad-4cdf-99ab-eab391b53815', NULL, NULL, '2026-03-19 14:36:20.604567+00', '2026-04-18 14:36:20.604567+00', NULL);
INSERT INTO public.user_sessions VALUES (458, 3, '30f1a293-25f0-45ce-bc8e-1ee917c2454a', NULL, NULL, '2026-03-19 14:47:12.670773+00', '2026-04-18 14:47:12.670773+00', NULL);
INSERT INTO public.user_sessions VALUES (463, 3, '5410a0a4-100e-405f-a2dc-ae4492a10ea6', NULL, NULL, '2026-03-19 14:52:19.973412+00', '2026-04-18 14:52:19.973412+00', NULL);
INSERT INTO public.user_sessions VALUES (468, 3, '816aeb34-ede7-406b-9989-8501c0498f4c', NULL, NULL, '2026-03-19 17:03:24.401364+00', '2026-04-18 17:03:24.401364+00', NULL);
INSERT INTO public.user_sessions VALUES (473, 3, '523fb752-6ed4-4243-afc0-7c9d6555ac85', NULL, NULL, '2026-03-19 17:44:44.831149+00', '2026-04-18 17:44:44.831149+00', NULL);
INSERT INTO public.user_sessions VALUES (478, 3, '144e57b5-e9ae-4475-90bb-1d1b555d222e', NULL, NULL, '2026-03-19 19:00:38.638417+00', '2026-04-18 19:00:38.638417+00', NULL);
INSERT INTO public.user_sessions VALUES (483, 3, 'e67014b6-ae47-4f1d-aa08-886ad6b4ae6a', NULL, NULL, '2026-03-19 19:54:20.914112+00', '2026-04-18 19:54:20.914112+00', NULL);
INSERT INTO public.user_sessions VALUES (439, 3, '77ec7eed-b2f4-4781-9eb0-9251e744956d', NULL, NULL, '2026-03-19 11:50:17.547444+00', '2026-04-18 11:50:17.547444+00', NULL);
INSERT INTO public.user_sessions VALUES (444, 3, '7c927b3a-fbf8-4b34-91d6-0b05de20a260', NULL, NULL, '2026-03-19 14:01:13.122673+00', '2026-04-18 14:01:13.122673+00', NULL);
INSERT INTO public.user_sessions VALUES (449, 3, '76d18b56-020d-40c8-bd5a-b94291d0af40', NULL, NULL, '2026-03-19 14:30:22.121223+00', '2026-04-18 14:30:22.121223+00', NULL);
INSERT INTO public.user_sessions VALUES (454, 3, '257c1340-480e-41e6-a3dd-6d11b55db3f4', NULL, NULL, '2026-03-19 14:37:14.178758+00', '2026-04-18 14:37:14.178758+00', NULL);
INSERT INTO public.user_sessions VALUES (459, 3, '5a4aaa28-20df-4a5a-abeb-9f060c31e8fa', NULL, NULL, '2026-03-19 14:48:01.874943+00', '2026-04-18 14:48:01.874943+00', NULL);
INSERT INTO public.user_sessions VALUES (464, 3, '577431b1-9e7c-4bf1-b96b-b7d512bf5963', NULL, NULL, '2026-03-19 15:11:11.224475+00', '2026-04-18 15:11:11.224475+00', NULL);
INSERT INTO public.user_sessions VALUES (469, 3, '99a4ef6c-36ec-4e91-8117-4b868d688a33', NULL, NULL, '2026-03-19 17:30:42.746729+00', '2026-04-18 17:30:42.746729+00', NULL);
INSERT INTO public.user_sessions VALUES (474, 3, '98389465-20bc-4b1a-b625-fb723152a963', NULL, NULL, '2026-03-19 18:36:08.082133+00', '2026-04-18 18:36:08.082133+00', NULL);
INSERT INTO public.user_sessions VALUES (479, 3, 'ff8a6f28-b74f-47f0-840b-bf484d7b4774', NULL, NULL, '2026-03-19 19:44:42.019789+00', '2026-04-18 19:44:42.019789+00', NULL);
INSERT INTO public.user_sessions VALUES (440, 3, '58b0706d-9f79-4a6a-b620-f02089ba67f2', NULL, NULL, '2026-03-19 12:26:00.977087+00', '2026-04-18 12:26:00.977087+00', NULL);
INSERT INTO public.user_sessions VALUES (445, 3, '6d4807ae-976c-4353-9b4d-5623e38bdee7', NULL, NULL, '2026-03-19 14:11:47.724784+00', '2026-04-18 14:11:47.724784+00', NULL);
INSERT INTO public.user_sessions VALUES (450, 3, 'ed8cf9e7-5287-4b27-bea6-ff0ad17f01c8', NULL, NULL, '2026-03-19 14:32:33.870588+00', '2026-04-18 14:32:33.870588+00', NULL);
INSERT INTO public.user_sessions VALUES (455, 3, '19e86722-1e7e-4a2c-b49b-26c4ab361b2e', NULL, NULL, '2026-03-19 14:40:00.129138+00', '2026-04-18 14:40:00.129138+00', NULL);
INSERT INTO public.user_sessions VALUES (460, 3, 'f4c8f0ef-86ee-46c1-b4c5-952cf63f0cf7', NULL, NULL, '2026-03-19 14:49:13.66381+00', '2026-04-18 14:49:13.66381+00', NULL);
INSERT INTO public.user_sessions VALUES (465, 3, '4d83fae9-2be7-4273-b09a-ede9ed9ca486', NULL, NULL, '2026-03-19 15:25:52.047518+00', '2026-04-18 15:25:52.047518+00', NULL);
INSERT INTO public.user_sessions VALUES (470, 3, '1f73ddea-75ed-47a9-a2c1-c3e84c864406', NULL, NULL, '2026-03-19 17:33:40.419863+00', '2026-04-18 17:33:40.419863+00', NULL);
INSERT INTO public.user_sessions VALUES (475, 3, '2d6ca301-85c2-4fa1-8691-fb296633a07d', NULL, NULL, '2026-03-19 18:37:04.842458+00', '2026-04-18 18:37:04.842458+00', NULL);
INSERT INTO public.user_sessions VALUES (480, 3, '9bbf4cad-85e6-477a-bb4b-2fb6e98af6cf', NULL, NULL, '2026-03-19 19:45:49.493977+00', '2026-04-18 19:45:49.493977+00', NULL);
INSERT INTO public.user_sessions VALUES (441, 3, '3fc6f86b-4e81-482f-b9c7-0ad7d0ee7a75', NULL, NULL, '2026-03-19 13:52:21.273117+00', '2026-04-18 13:52:21.273117+00', NULL);
INSERT INTO public.user_sessions VALUES (446, 3, '8287d55d-269e-4b50-9d1f-a4e3fb4cafba', NULL, NULL, '2026-03-19 14:23:51.680415+00', '2026-04-18 14:23:51.680415+00', NULL);
INSERT INTO public.user_sessions VALUES (451, 3, 'c87eb025-e138-4aa0-8e3d-c151ef59b06a', NULL, NULL, '2026-03-19 14:34:46.490324+00', '2026-04-18 14:34:46.490324+00', NULL);
INSERT INTO public.user_sessions VALUES (456, 3, 'b8f224d7-1e08-49f8-b4f0-73e205986d6e', NULL, NULL, '2026-03-19 14:42:51.665795+00', '2026-04-18 14:42:51.665795+00', NULL);
INSERT INTO public.user_sessions VALUES (461, 3, 'c82133d3-6078-48ad-8c9e-9311a4125fb5', NULL, NULL, '2026-03-19 14:50:13.31971+00', '2026-04-18 14:50:13.31971+00', NULL);
INSERT INTO public.user_sessions VALUES (466, 3, 'f7ca37b2-e36d-4163-b9ae-3c6b54f8ec9d', NULL, NULL, '2026-03-19 16:51:25.222694+00', '2026-04-18 16:51:25.222694+00', NULL);
INSERT INTO public.user_sessions VALUES (471, 3, 'a54772b4-0e6d-4fc9-8882-13d172b8797e', NULL, NULL, '2026-03-19 17:34:32.407059+00', '2026-04-18 17:34:32.407059+00', NULL);
INSERT INTO public.user_sessions VALUES (476, 3, 'ae8a08d2-5890-4c03-b74c-2802df84055b', NULL, NULL, '2026-03-19 18:50:11.342522+00', '2026-04-18 18:50:11.342522+00', NULL);
INSERT INTO public.user_sessions VALUES (481, 3, '0e390781-3008-4a18-b6a4-10678f5a2997', NULL, NULL, '2026-03-19 19:47:31.596873+00', '2026-04-18 19:47:31.596873+00', NULL);
INSERT INTO public.user_sessions VALUES (442, 4, '38828f8b-3395-4a34-8a26-bfa7d3271732', NULL, NULL, '2026-03-19 13:52:44.891378+00', '2026-04-18 13:52:44.891378+00', NULL);
INSERT INTO public.user_sessions VALUES (447, 3, 'ea96e541-c57a-453b-9160-d1d64a546b04', NULL, NULL, '2026-03-19 14:24:50.488968+00', '2026-04-18 14:24:50.488968+00', NULL);
INSERT INTO public.user_sessions VALUES (452, 3, 'e7459153-8748-4477-acf5-6abd5b153a0c', NULL, NULL, '2026-03-19 14:35:30.298721+00', '2026-04-18 14:35:30.298721+00', NULL);
INSERT INTO public.user_sessions VALUES (457, 3, 'e5e591e2-bcf3-4d7b-9786-4fd66299a82a', NULL, NULL, '2026-03-19 14:44:56.716992+00', '2026-04-18 14:44:56.716992+00', NULL);
INSERT INTO public.user_sessions VALUES (462, 3, '08dc533e-21af-4309-91ff-7d752201b16f', NULL, NULL, '2026-03-19 14:52:01.94884+00', '2026-04-18 14:52:01.94884+00', NULL);
INSERT INTO public.user_sessions VALUES (467, 3, '1896a23f-9121-43c5-a329-c85346da97de', NULL, NULL, '2026-03-19 16:52:42.855044+00', '2026-04-18 16:52:42.855044+00', NULL);
INSERT INTO public.user_sessions VALUES (472, 3, 'b95d3162-fe3a-45ac-8316-7acb87e11209', NULL, NULL, '2026-03-19 17:44:04.431234+00', '2026-04-18 17:44:04.431234+00', NULL);
INSERT INTO public.user_sessions VALUES (477, 3, '9680c74a-2a7c-4291-b2cc-66e6287146c0', NULL, NULL, '2026-03-19 19:00:24.768743+00', '2026-04-18 19:00:24.768743+00', NULL);
INSERT INTO public.user_sessions VALUES (482, 3, 'cb2727f9-6b1b-49c1-9cb1-fa3325e7ef0d', NULL, NULL, '2026-03-19 19:54:07.577516+00', '2026-04-18 19:54:07.577516+00', NULL);
INSERT INTO public.user_sessions VALUES (484, 3, '8cce52a1-5267-4e67-a695-c7e6103252d1', NULL, NULL, '2026-03-20 08:22:31.528767+00', '2026-04-19 08:22:31.528767+00', NULL);
INSERT INTO public.user_sessions VALUES (485, 3, '2dcecc77-5386-415a-961c-46ddfda3ca3f', NULL, NULL, '2026-03-20 08:46:53.275802+00', '2026-04-19 08:46:53.275802+00', NULL);
INSERT INTO public.user_sessions VALUES (486, 3, 'ab9531e5-b514-4356-8afb-f66b08df738c', NULL, NULL, '2026-03-20 08:50:52.759482+00', '2026-04-19 08:50:52.759482+00', NULL);
INSERT INTO public.user_sessions VALUES (487, 3, 'fd306800-e51c-4ade-8437-94af9659d7bc', NULL, NULL, '2026-03-20 08:51:57.684371+00', '2026-04-19 08:51:57.684371+00', NULL);
INSERT INTO public.user_sessions VALUES (488, 3, '298bd4a3-0fa7-43ce-8ffe-b08a5aa437e1', NULL, NULL, '2026-03-20 08:54:58.122662+00', '2026-04-19 08:54:58.122662+00', NULL);
INSERT INTO public.user_sessions VALUES (489, 3, '3bd0c42a-397b-487c-b0de-0aac8b164fcb', NULL, NULL, '2026-03-20 09:03:26.457449+00', '2026-04-19 09:03:26.457449+00', NULL);
INSERT INTO public.user_sessions VALUES (490, 3, '50779961-5b45-4f15-a7aa-f38d7be15540', NULL, NULL, '2026-03-20 09:05:16.367438+00', '2026-04-19 09:05:16.367438+00', NULL);
INSERT INTO public.user_sessions VALUES (491, 3, '8eb81fbb-0f73-4f8a-b9b9-2869a49b18ff', NULL, NULL, '2026-03-20 09:14:16.167975+00', '2026-04-19 09:14:16.167975+00', NULL);
INSERT INTO public.user_sessions VALUES (492, 3, 'c71241a9-9b55-454a-9ec2-29283433f6e3', NULL, NULL, '2026-03-20 09:21:48.722256+00', '2026-04-19 09:21:48.722256+00', NULL);
INSERT INTO public.user_sessions VALUES (493, 3, '76081a4b-2a8c-42f2-8fd2-be887dff013d', NULL, NULL, '2026-03-20 09:40:17.930758+00', '2026-04-19 09:40:17.930758+00', NULL);
INSERT INTO public.user_sessions VALUES (494, 3, '5a4543df-ade0-4a26-b6d1-fb086e2ac606', NULL, NULL, '2026-03-20 09:56:18.831804+00', '2026-04-19 09:56:18.831804+00', NULL);
INSERT INTO public.user_sessions VALUES (495, 3, '45e44b3d-a974-41d7-a4aa-5abe1bf5c80b', NULL, NULL, '2026-03-20 10:02:04.270037+00', '2026-04-19 10:02:04.270037+00', NULL);
INSERT INTO public.user_sessions VALUES (496, 3, '307beb52-33ad-46be-8514-e429c63be84c', NULL, NULL, '2026-03-20 10:21:08.017367+00', '2026-04-19 10:21:08.017367+00', NULL);
INSERT INTO public.user_sessions VALUES (497, 3, '1b135fc8-6a5a-45ec-a92f-306e40b92993', NULL, NULL, '2026-03-20 10:22:01.810061+00', '2026-04-19 10:22:01.810061+00', NULL);
INSERT INTO public.user_sessions VALUES (498, 3, 'a822afb6-f0f8-45c3-b4d0-9e15a954e417', NULL, NULL, '2026-03-20 10:23:13.349715+00', '2026-04-19 10:23:13.349715+00', NULL);
INSERT INTO public.user_sessions VALUES (499, 3, '554b8b50-13da-4146-ab75-1a9fc4d05848', NULL, NULL, '2026-03-20 10:27:46.543422+00', '2026-04-19 10:27:46.543422+00', NULL);
INSERT INTO public.user_sessions VALUES (500, 3, '27a75068-60c4-4793-9be2-e4d4ea18f52b', NULL, NULL, '2026-03-20 10:28:31.054605+00', '2026-04-19 10:28:31.054605+00', NULL);
INSERT INTO public.user_sessions VALUES (501, 3, '28ce8246-8d66-4f40-a616-8867bcc3c9c4', NULL, NULL, '2026-03-20 10:31:46.457581+00', '2026-04-19 10:31:46.457581+00', NULL);
INSERT INTO public.user_sessions VALUES (502, 3, '066c9d40-ebf8-45b3-bde8-4a7b3d8aaf0a', NULL, NULL, '2026-03-20 10:32:59.374626+00', '2026-04-19 10:32:59.374626+00', NULL);
INSERT INTO public.user_sessions VALUES (503, 3, '84e3e232-6f9f-41aa-8580-da1e9854501e', NULL, NULL, '2026-03-20 10:34:46.886034+00', '2026-04-19 10:34:46.886034+00', NULL);
INSERT INTO public.user_sessions VALUES (504, 3, '4e1e6377-bc53-4868-8a76-dfd4e3b614ed', NULL, NULL, '2026-03-20 11:02:59.398838+00', '2026-04-19 11:02:59.398838+00', NULL);
INSERT INTO public.user_sessions VALUES (505, 3, 'a53ac3e5-eb22-454a-866d-de7b00bb8443', NULL, NULL, '2026-03-20 11:40:34.519233+00', '2026-04-19 11:40:34.519233+00', NULL);
INSERT INTO public.user_sessions VALUES (506, 3, '1820169e-712b-4629-8bce-a60944c71aa1', NULL, NULL, '2026-03-20 11:40:47.369723+00', '2026-04-19 11:40:47.369723+00', NULL);
INSERT INTO public.user_sessions VALUES (507, 3, '0f19f151-04bc-42df-994f-8265644014c5', NULL, NULL, '2026-03-20 11:45:40.575535+00', '2026-04-19 11:45:40.575535+00', NULL);
INSERT INTO public.user_sessions VALUES (508, 3, '85dc3dca-55de-46e4-af0d-8fb4c393f9cd', NULL, NULL, '2026-03-20 12:03:45.069742+00', '2026-04-19 12:03:45.069742+00', NULL);
INSERT INTO public.user_sessions VALUES (509, 3, '14d6500b-418a-4d91-bd48-dd523e218dd2', NULL, NULL, '2026-03-20 12:08:19.815816+00', '2026-04-19 12:08:19.815816+00', NULL);
INSERT INTO public.user_sessions VALUES (510, 3, 'aefecd88-3cb8-41bf-8c6c-c61d9adadf07', NULL, NULL, '2026-03-20 12:15:35.112396+00', '2026-04-19 12:15:35.112396+00', NULL);
INSERT INTO public.user_sessions VALUES (511, 3, '51da04ff-145e-45fe-8a68-6a160b692b19', NULL, NULL, '2026-03-20 12:26:37.333834+00', '2026-04-19 12:26:37.333834+00', NULL);
INSERT INTO public.user_sessions VALUES (512, 3, '5a58f5bd-13fb-45fa-8060-4764e87eb4d3', NULL, NULL, '2026-03-20 12:27:53.180713+00', '2026-04-19 12:27:53.180713+00', NULL);
INSERT INTO public.user_sessions VALUES (513, 3, '2e27279c-1462-4e2d-96f4-7d50e44a0ff2', NULL, NULL, '2026-03-20 13:00:26.466951+00', '2026-04-19 13:00:26.466951+00', NULL);
INSERT INTO public.user_sessions VALUES (514, 3, '175b5117-a0df-445c-ad3b-b5f3b391e580', NULL, NULL, '2026-03-20 13:06:12.389132+00', '2026-04-19 13:06:12.389132+00', NULL);
INSERT INTO public.user_sessions VALUES (515, 3, '03fb7e49-3d87-4528-a6e7-3a79bea530de', NULL, NULL, '2026-03-20 13:22:36.159584+00', '2026-04-19 13:22:36.159584+00', NULL);
INSERT INTO public.user_sessions VALUES (516, 3, '8f4b9bfa-b7e0-4fb4-a19c-eaba53c6e601', NULL, NULL, '2026-03-20 13:39:58.450857+00', '2026-04-19 13:39:58.450857+00', NULL);
INSERT INTO public.user_sessions VALUES (517, 3, 'aae7879c-9682-493b-b60a-741576530c32', NULL, NULL, '2026-03-20 13:49:09.670989+00', '2026-04-19 13:49:09.670989+00', NULL);
INSERT INTO public.user_sessions VALUES (518, 3, '42e7fc90-930e-460f-a6d7-9fac8bc6305f', NULL, NULL, '2026-03-20 14:02:23.243728+00', '2026-04-19 14:02:23.243728+00', NULL);
INSERT INTO public.user_sessions VALUES (519, 3, '2817a67a-994a-4e69-8c71-b0bd487b31fc', NULL, NULL, '2026-03-20 14:25:56.430208+00', '2026-04-19 14:25:56.430208+00', NULL);
INSERT INTO public.user_sessions VALUES (520, 3, '831a5040-9bc5-4545-b213-048aae0e3d76', NULL, NULL, '2026-03-20 14:34:24.842795+00', '2026-04-19 14:34:24.842795+00', NULL);
INSERT INTO public.user_sessions VALUES (521, 3, '4c720fe3-9893-4ef7-95d7-08dc728e417b', NULL, NULL, '2026-03-20 14:47:00.867574+00', '2026-04-19 14:47:00.867574+00', NULL);
INSERT INTO public.user_sessions VALUES (522, 3, '61602d84-5df2-4fa8-a94f-5919e5c97c72', NULL, NULL, '2026-03-20 14:48:31.906294+00', '2026-04-19 14:48:31.906294+00', NULL);
INSERT INTO public.user_sessions VALUES (523, 3, 'a4dea179-4133-42b6-b163-62d8ec62cd2b', NULL, NULL, '2026-03-20 14:50:39.080953+00', '2026-04-19 14:50:39.080953+00', NULL);
INSERT INTO public.user_sessions VALUES (524, 3, '55d5bacf-00f6-4b9f-8126-8337aaba5c84', NULL, NULL, '2026-03-20 14:55:49.448888+00', '2026-04-19 14:55:49.448888+00', NULL);
INSERT INTO public.user_sessions VALUES (525, 3, 'a203a4d0-d3f9-4313-9e7d-8e7dfdf34a5f', NULL, NULL, '2026-03-20 15:43:06.001176+00', '2026-04-19 15:43:06.001176+00', NULL);
INSERT INTO public.user_sessions VALUES (526, 3, '51966b3c-8dee-4696-a7cd-63e539cf4a22', NULL, NULL, '2026-03-20 18:11:20.570288+00', '2026-04-19 18:11:20.570288+00', NULL);
INSERT INTO public.user_sessions VALUES (527, 3, '797aefbd-0cb3-45ea-ae2a-96ee4c48f8ff', NULL, NULL, '2026-03-20 18:15:05.113211+00', '2026-04-19 18:15:05.113211+00', NULL);
INSERT INTO public.user_sessions VALUES (528, 4, '3ed2ab2c-d64b-4e78-a1cc-eb83fe5147cc', NULL, NULL, '2026-03-20 18:15:09.502217+00', '2026-04-19 18:15:09.502217+00', NULL);
INSERT INTO public.user_sessions VALUES (529, 3, '4bcc9ed2-981d-4c47-82bd-6665333480f3', NULL, NULL, '2026-03-20 18:56:14.484323+00', '2026-04-19 18:56:14.484323+00', NULL);
INSERT INTO public.user_sessions VALUES (530, 3, 'd2822602-a29a-400b-a555-9681b46f1c7c', NULL, NULL, '2026-03-20 19:28:21.926831+00', '2026-04-19 19:28:21.926831+00', NULL);
INSERT INTO public.user_sessions VALUES (531, 3, 'f80c2415-5660-4bfb-b5a6-625f7e028262', NULL, NULL, '2026-03-20 19:31:27.321281+00', '2026-04-19 19:31:27.321281+00', NULL);
INSERT INTO public.user_sessions VALUES (532, 4, '364c0c61-f889-4310-b399-e464c1922ebe', NULL, NULL, '2026-03-20 19:31:30.577073+00', '2026-04-19 19:31:30.577073+00', NULL);
INSERT INTO public.user_sessions VALUES (533, 3, 'f92689b2-0f8d-4fb2-9ef2-3b0013529ccd', NULL, NULL, '2026-03-20 19:42:29.215274+00', '2026-04-19 19:42:29.215274+00', NULL);
INSERT INTO public.user_sessions VALUES (534, 3, '2389fe04-f652-4517-a4f2-85f7e6bdbda4', NULL, NULL, '2026-03-20 20:11:19.357968+00', '2026-04-19 20:11:19.357968+00', NULL);
INSERT INTO public.user_sessions VALUES (535, 3, 'adfb5e0a-42a4-4059-a4cc-052725f4e428', NULL, NULL, '2026-03-20 20:24:10.250384+00', '2026-04-19 20:24:10.250384+00', NULL);
INSERT INTO public.user_sessions VALUES (536, 3, 'c27223a6-f19b-4287-b5c4-b6a44003ddf7', NULL, NULL, '2026-03-20 20:25:10.5833+00', '2026-04-19 20:25:10.5833+00', NULL);
INSERT INTO public.user_sessions VALUES (537, 3, 'a123934c-6021-4fbc-b366-8b2d811d5131', NULL, NULL, '2026-03-20 20:44:29.11235+00', '2026-04-19 20:44:29.11235+00', NULL);
INSERT INTO public.user_sessions VALUES (538, 3, '085c9271-b746-412b-ac1f-fb26c087f723', NULL, NULL, '2026-03-20 20:46:56.369237+00', '2026-04-19 20:46:56.369237+00', NULL);
INSERT INTO public.user_sessions VALUES (539, 3, 'bd20946c-52f7-49cb-bb5e-53f3bce8831e', NULL, NULL, '2026-03-20 20:53:02.344744+00', '2026-04-19 20:53:02.344744+00', NULL);
INSERT INTO public.user_sessions VALUES (540, 3, 'cae2dead-6a3d-4035-bdd5-bd1c099ad53f', NULL, NULL, '2026-03-20 20:59:13.845379+00', '2026-04-19 20:59:13.845379+00', NULL);
INSERT INTO public.user_sessions VALUES (541, 3, 'f639d652-8dc5-4058-a2d8-5000211fb19b', NULL, NULL, '2026-03-20 21:02:49.754342+00', '2026-04-19 21:02:49.754342+00', NULL);
INSERT INTO public.user_sessions VALUES (542, 3, '59c5667d-cc94-45b5-994e-9627d01d2985', NULL, NULL, '2026-03-20 21:04:32.812728+00', '2026-04-19 21:04:32.812728+00', NULL);
INSERT INTO public.user_sessions VALUES (543, 3, '5b9f658f-eafc-46e8-882b-8ddf3ab38a33', NULL, NULL, '2026-03-20 21:07:23.007753+00', '2026-04-19 21:07:23.007753+00', NULL);
INSERT INTO public.user_sessions VALUES (544, 3, 'b63bc60c-0cb0-4126-b251-afc325bd55da', NULL, NULL, '2026-03-20 21:08:33.22896+00', '2026-04-19 21:08:33.22896+00', NULL);
INSERT INTO public.user_sessions VALUES (545, 3, 'f152fc22-2829-4f53-8c5b-06599657ffce', NULL, NULL, '2026-03-20 21:12:46.235911+00', '2026-04-19 21:12:46.235911+00', NULL);
INSERT INTO public.user_sessions VALUES (546, 3, '1b758148-769f-45a7-8e11-86aba5fc3109', NULL, NULL, '2026-03-20 21:13:29.483659+00', '2026-04-19 21:13:29.483659+00', NULL);
INSERT INTO public.user_sessions VALUES (547, 3, '2c1e12f5-4452-4cf1-b05b-09300f1b4f87', NULL, NULL, '2026-03-20 21:14:20.963312+00', '2026-04-19 21:14:20.963312+00', NULL);
INSERT INTO public.user_sessions VALUES (548, 3, 'ae40644b-3b33-49e4-9b6f-31bd6c4a600e', NULL, NULL, '2026-03-20 21:19:35.247596+00', '2026-04-19 21:19:35.247596+00', NULL);
INSERT INTO public.user_sessions VALUES (549, 3, '84dab826-1e63-4140-92a6-dec245eb7f14', NULL, NULL, '2026-03-20 21:24:19.044098+00', '2026-04-19 21:24:19.044098+00', NULL);
INSERT INTO public.user_sessions VALUES (550, 3, '4b027a8c-402c-41de-83cb-b3e368004193', NULL, NULL, '2026-03-20 21:26:45.538362+00', '2026-04-19 21:26:45.538362+00', NULL);
INSERT INTO public.user_sessions VALUES (551, 3, '5a83b051-3749-4638-8ddb-e65c7b532a10', NULL, NULL, '2026-03-20 21:27:29.088443+00', '2026-04-19 21:27:29.088443+00', NULL);
INSERT INTO public.user_sessions VALUES (552, 3, '933e4495-2e95-4795-b78a-f6e5f9683249', NULL, NULL, '2026-03-20 21:30:59.527872+00', '2026-04-19 21:30:59.527872+00', NULL);
INSERT INTO public.user_sessions VALUES (553, 3, 'e76c1970-8833-42f4-925e-18aef3ab0b3a', NULL, NULL, '2026-03-20 21:33:59.829466+00', '2026-04-19 21:33:59.829466+00', NULL);
INSERT INTO public.user_sessions VALUES (554, 3, '09c1c476-5d18-4d46-9386-b1c2c271a89c', NULL, NULL, '2026-03-20 21:56:25.408595+00', '2026-04-19 21:56:25.408595+00', NULL);
INSERT INTO public.user_sessions VALUES (555, 3, '47fb5441-8d1a-4b57-b96d-5ae3f0f33eee', NULL, NULL, '2026-03-21 10:14:04.528373+00', '2026-04-20 10:14:04.528373+00', NULL);
INSERT INTO public.user_sessions VALUES (556, 3, 'c45648a3-14ef-48c2-878e-19dc0ed3bcef', NULL, NULL, '2026-03-21 11:11:52.10351+00', '2026-04-20 11:11:52.10351+00', NULL);
INSERT INTO public.user_sessions VALUES (557, 3, 'fc7de574-a1ad-4102-84e3-1fe880600a50', NULL, NULL, '2026-03-21 11:28:49.886813+00', '2026-04-20 11:28:49.886813+00', NULL);
INSERT INTO public.user_sessions VALUES (558, 3, '2d33cbaa-442a-4d70-bc3f-740d204443b6', NULL, NULL, '2026-03-21 11:40:22.299195+00', '2026-04-20 11:40:22.299195+00', NULL);
INSERT INTO public.user_sessions VALUES (559, 3, '6b71eb4e-74f4-402e-b547-fb76f18ff55c', NULL, NULL, '2026-03-21 11:53:38.692062+00', '2026-04-20 11:53:38.692062+00', NULL);
INSERT INTO public.user_sessions VALUES (560, 3, '1b975ed2-c2aa-490e-ae08-8dce100b5a0a', NULL, NULL, '2026-03-21 11:56:08.281807+00', '2026-04-20 11:56:08.281807+00', NULL);
INSERT INTO public.user_sessions VALUES (561, 3, '53a93e9b-c2ea-4814-91eb-2020fd7c0615', NULL, NULL, '2026-03-21 12:15:49.779325+00', '2026-04-20 12:15:49.779325+00', NULL);
INSERT INTO public.user_sessions VALUES (562, 3, 'c4f298b4-903c-47ae-b28a-b5afb15082f0', NULL, NULL, '2026-03-21 14:45:09.042817+00', '2026-04-20 14:45:09.042817+00', NULL);
INSERT INTO public.user_sessions VALUES (563, 3, '730d2c78-9ff1-437b-93cd-1730f99e8aff', NULL, NULL, '2026-03-21 14:48:27.114799+00', '2026-04-20 14:48:27.114799+00', NULL);
INSERT INTO public.user_sessions VALUES (564, 3, 'da0ee0d1-c7c5-4a47-80ab-d27ddfc1b5fe', NULL, NULL, '2026-03-21 14:50:32.273685+00', '2026-04-20 14:50:32.273685+00', NULL);
INSERT INTO public.user_sessions VALUES (565, 3, 'bb227234-33e1-411f-90e2-9bd53944d63f', NULL, NULL, '2026-03-21 14:58:11.147274+00', '2026-04-20 14:58:11.147274+00', NULL);
INSERT INTO public.user_sessions VALUES (566, 3, 'ec08f8f0-f0e9-4230-a5bf-214bde3d89a6', NULL, NULL, '2026-03-21 15:06:32.425992+00', '2026-04-20 15:06:32.425992+00', NULL);
INSERT INTO public.user_sessions VALUES (567, 3, '10d73463-205c-4af0-a2fc-595ebc15f268', NULL, NULL, '2026-03-21 15:11:53.803839+00', '2026-04-20 15:11:53.803839+00', NULL);
INSERT INTO public.user_sessions VALUES (568, 3, '65ca1eb8-c0b3-49d1-ae51-b9d5f0d80f10', NULL, NULL, '2026-03-21 15:37:06.727425+00', '2026-04-20 15:37:06.727425+00', NULL);
INSERT INTO public.user_sessions VALUES (569, 3, '81309a3b-d955-461e-9b6d-97c2fcaccb75', NULL, NULL, '2026-03-21 15:42:12.662461+00', '2026-04-20 15:42:12.662461+00', NULL);
INSERT INTO public.user_sessions VALUES (570, 3, '366118b1-8d34-4244-832b-f0a673e184eb', NULL, NULL, '2026-03-21 15:49:14.149471+00', '2026-04-20 15:49:14.149471+00', NULL);
INSERT INTO public.user_sessions VALUES (571, 3, 'def1c164-f7f7-423e-9cd7-2e9a9fc7ae51', NULL, NULL, '2026-03-21 15:57:56.845361+00', '2026-04-20 15:57:56.845361+00', NULL);
INSERT INTO public.user_sessions VALUES (572, 3, '948c2153-0e6a-479f-ae08-13db319c841a', NULL, NULL, '2026-03-21 16:00:22.508309+00', '2026-04-20 16:00:22.508309+00', NULL);
INSERT INTO public.user_sessions VALUES (573, 3, 'bc3e672b-a24a-428a-8b59-b0456677f1de', NULL, NULL, '2026-03-21 16:08:59.597514+00', '2026-04-20 16:08:59.597514+00', NULL);
INSERT INTO public.user_sessions VALUES (574, 3, 'b14bbe6f-783a-455e-b6c2-35626ed98c0c', NULL, NULL, '2026-03-21 16:36:15.506586+00', '2026-04-20 16:36:15.506586+00', NULL);
INSERT INTO public.user_sessions VALUES (575, 3, '548ff7c8-b984-4872-967e-0aedf09aa5b9', NULL, NULL, '2026-03-21 16:42:43.512414+00', '2026-04-20 16:42:43.512414+00', NULL);
INSERT INTO public.user_sessions VALUES (576, 3, '47cb6d47-8e38-4f96-bcad-d66bea6ec111', NULL, NULL, '2026-03-21 16:58:40.01734+00', '2026-04-20 16:58:40.01734+00', NULL);
INSERT INTO public.user_sessions VALUES (577, 3, 'd1251a4a-149b-4a93-a80a-b081ae67b6a5', NULL, NULL, '2026-03-21 17:09:16.704023+00', '2026-04-20 17:09:16.704023+00', NULL);
INSERT INTO public.user_sessions VALUES (578, 3, '67c95c81-cc1d-4cb3-9ef1-c951534b952f', NULL, NULL, '2026-03-21 17:10:56.933466+00', '2026-04-20 17:10:56.933466+00', NULL);
INSERT INTO public.user_sessions VALUES (579, 3, '2c36b959-18dc-4dc0-852f-5724f6cf200f', NULL, NULL, '2026-03-21 17:12:16.474894+00', '2026-04-20 17:12:16.474894+00', NULL);
INSERT INTO public.user_sessions VALUES (580, 3, 'dec3a6e7-a8f0-4947-af75-df55866ddb91', NULL, NULL, '2026-03-21 17:55:58.190241+00', '2026-04-20 17:55:58.190241+00', NULL);
INSERT INTO public.user_sessions VALUES (581, 3, 'c4823f8d-b840-4aa2-941f-79d8beddc4b2', NULL, NULL, '2026-03-21 17:57:32.379153+00', '2026-04-20 17:57:32.379153+00', NULL);
INSERT INTO public.user_sessions VALUES (582, 3, '90cda738-9cb0-45e8-9fce-971b09528345', NULL, NULL, '2026-03-21 18:02:34.946974+00', '2026-04-20 18:02:34.946974+00', NULL);
INSERT INTO public.user_sessions VALUES (583, 3, '89d4cc20-38d8-452d-a52b-2314cda9836e', NULL, NULL, '2026-03-21 18:03:48.28036+00', '2026-04-20 18:03:48.28036+00', NULL);
INSERT INTO public.user_sessions VALUES (584, 3, '8013e585-71b3-4e44-9820-37bc15b65cf0', NULL, NULL, '2026-03-21 18:08:06.029795+00', '2026-04-20 18:08:06.029795+00', NULL);
INSERT INTO public.user_sessions VALUES (585, 3, 'f6acac3c-52a0-487c-86e0-c3d25d8acc2f', NULL, NULL, '2026-03-21 18:14:47.483916+00', '2026-04-20 18:14:47.483916+00', NULL);
INSERT INTO public.user_sessions VALUES (586, 3, '6573fde3-e9f1-4d95-bd95-d10c5715843e', NULL, NULL, '2026-03-21 18:17:26.624812+00', '2026-04-20 18:17:26.624812+00', NULL);
INSERT INTO public.user_sessions VALUES (587, 3, 'bf4f8118-a47f-4718-89c5-4af1d36760b5', NULL, NULL, '2026-03-21 18:17:56.287137+00', '2026-04-20 18:17:56.287137+00', NULL);
INSERT INTO public.user_sessions VALUES (588, 3, 'cb6a8120-2d67-4a88-b424-5f9ebc285525', NULL, NULL, '2026-03-21 18:18:34.55446+00', '2026-04-20 18:18:34.55446+00', NULL);
INSERT INTO public.user_sessions VALUES (589, 3, 'a4657025-6196-4abd-89d7-3dfa093eda46', NULL, NULL, '2026-03-21 18:18:45.921841+00', '2026-04-20 18:18:45.921841+00', NULL);
INSERT INTO public.user_sessions VALUES (590, 3, '3ba96e9a-a9c8-4600-882f-30f35557db0f', NULL, NULL, '2026-03-21 18:54:30.307264+00', '2026-04-20 18:54:30.307264+00', NULL);
INSERT INTO public.user_sessions VALUES (591, 3, '4fb70469-e978-43ed-a3aa-ea8d3cadca88', NULL, NULL, '2026-03-21 18:54:44.378315+00', '2026-04-20 18:54:44.378315+00', NULL);
INSERT INTO public.user_sessions VALUES (592, 3, '09f7d4ca-6b8c-4b73-99a9-8adf002460bf', NULL, NULL, '2026-03-21 18:55:00.897277+00', '2026-04-20 18:55:00.897277+00', NULL);
INSERT INTO public.user_sessions VALUES (593, 3, '2d3aa230-b8e5-4119-9a61-4b003b5dfc65', NULL, NULL, '2026-03-21 18:55:11.306963+00', '2026-04-20 18:55:11.306963+00', NULL);
INSERT INTO public.user_sessions VALUES (594, 3, '673730b7-7666-4c48-be4b-c352b4ce1021', NULL, NULL, '2026-03-21 19:00:54.413076+00', '2026-04-20 19:00:54.413076+00', NULL);
INSERT INTO public.user_sessions VALUES (595, 3, '436df7bf-1fd6-448c-b18e-7bad33bb3ff4', NULL, NULL, '2026-03-21 19:01:03.534909+00', '2026-04-20 19:01:03.534909+00', NULL);
INSERT INTO public.user_sessions VALUES (596, 3, 'a278c4a9-72d1-4a0a-8e2f-40cf588e6fbf', NULL, NULL, '2026-03-21 19:01:34.70414+00', '2026-04-20 19:01:34.70414+00', NULL);
INSERT INTO public.user_sessions VALUES (597, 3, 'c5f25960-8837-4185-b035-a9e3d0fe7e28', NULL, NULL, '2026-03-21 19:08:24.169684+00', '2026-04-20 19:08:24.169684+00', NULL);
INSERT INTO public.user_sessions VALUES (598, 3, '1af9b2d6-1cf5-448b-9d8f-f7734c48cc0e', NULL, NULL, '2026-03-21 19:08:32.489944+00', '2026-04-20 19:08:32.489944+00', NULL);
INSERT INTO public.user_sessions VALUES (599, 3, '20fdf120-ded4-4305-a207-086a3145a95d', NULL, NULL, '2026-03-21 20:28:41.942386+00', '2026-04-20 20:28:41.942386+00', NULL);
INSERT INTO public.user_sessions VALUES (600, 4, '2c832601-3c09-4528-a106-dea8fd68420c', NULL, NULL, '2026-03-21 20:29:40.422782+00', '2026-04-20 20:29:40.422782+00', NULL);
INSERT INTO public.user_sessions VALUES (601, 3, '7e47c715-6de3-48b0-8084-09b67f812006', NULL, NULL, '2026-03-21 20:35:13.068044+00', '2026-04-20 20:35:13.068044+00', NULL);
INSERT INTO public.user_sessions VALUES (602, 4, '0b57ea8a-6ee6-42ee-baa4-128e99875ef8', NULL, NULL, '2026-03-21 20:35:16.360458+00', '2026-04-20 20:35:16.360458+00', NULL);
INSERT INTO public.user_sessions VALUES (603, 3, '176677dd-89cf-4701-bb71-e1c6f61e4ff4', NULL, NULL, '2026-03-21 20:38:56.543229+00', '2026-04-20 20:38:56.543229+00', NULL);
INSERT INTO public.user_sessions VALUES (604, 4, 'c21dbe55-d254-4db7-8095-18a727f3508c', NULL, NULL, '2026-03-21 20:39:24.728014+00', '2026-04-20 20:39:24.728014+00', NULL);
INSERT INTO public.user_sessions VALUES (605, 3, '4d893150-014f-442d-af3a-dacc8b8708a5', NULL, NULL, '2026-03-21 20:43:45.649871+00', '2026-04-20 20:43:45.649871+00', NULL);
INSERT INTO public.user_sessions VALUES (606, 3, '05d3c086-55a2-4476-b164-78d97a80f686', NULL, NULL, '2026-03-21 20:46:02.851541+00', '2026-04-20 20:46:02.851541+00', NULL);
INSERT INTO public.user_sessions VALUES (607, 3, 'f13cbb30-7502-44aa-aa2e-7bd3db40f885', NULL, NULL, '2026-03-21 20:55:33.883921+00', '2026-04-20 20:55:33.883921+00', NULL);
INSERT INTO public.user_sessions VALUES (608, 3, '0355d422-ea2f-490b-afc8-2da5bcc79b26', NULL, NULL, '2026-03-21 21:06:59.167067+00', '2026-04-20 21:06:59.167067+00', NULL);
INSERT INTO public.user_sessions VALUES (609, 3, 'b9327191-a52c-4556-9694-cd1724db3755', NULL, NULL, '2026-03-21 21:08:55.096857+00', '2026-04-20 21:08:55.096857+00', NULL);
INSERT INTO public.user_sessions VALUES (610, 3, 'fe917c44-a76a-471a-ae9e-de512e73f4cb', NULL, NULL, '2026-03-21 21:09:15.247574+00', '2026-04-20 21:09:15.247574+00', NULL);
INSERT INTO public.user_sessions VALUES (611, 3, '373ae5cf-4464-4778-8628-f1f8600d0c04', NULL, NULL, '2026-03-21 21:17:24.003011+00', '2026-04-20 21:17:24.003011+00', NULL);
INSERT INTO public.user_sessions VALUES (612, 3, 'c36ddd0e-372b-4f0b-9a57-fda9f0478f1e', NULL, NULL, '2026-03-21 21:26:51.093807+00', '2026-04-20 21:26:51.093807+00', NULL);
INSERT INTO public.user_sessions VALUES (613, 4, '3d1a4566-534d-40b7-8b53-4419021e6093', NULL, NULL, '2026-03-21 21:28:03.107301+00', '2026-04-20 21:28:03.107301+00', NULL);
INSERT INTO public.user_sessions VALUES (614, 3, 'c15a24ad-3a32-4a2e-868b-099d5cdf170b', NULL, NULL, '2026-03-21 21:29:49.22615+00', '2026-04-20 21:29:49.22615+00', NULL);
INSERT INTO public.user_sessions VALUES (615, 3, '5be0effc-6cea-4a4e-9eca-47f3a1818a4c', NULL, NULL, '2026-03-21 21:33:50.477916+00', '2026-04-20 21:33:50.477916+00', NULL);
INSERT INTO public.user_sessions VALUES (616, 3, '84946024-e407-4aef-a3e4-2e46d0843ec3', NULL, NULL, '2026-03-21 21:54:58.055136+00', '2026-04-20 21:54:58.055136+00', NULL);
INSERT INTO public.user_sessions VALUES (617, 3, 'f5619d95-0ec3-4247-9d66-ab430aea36bc', NULL, NULL, '2026-03-21 21:59:06.065917+00', '2026-04-20 21:59:06.065917+00', NULL);
INSERT INTO public.user_sessions VALUES (618, 3, '39ed9f45-f9c4-4d92-b553-6792f2e04efe', NULL, NULL, '2026-03-21 22:01:56.172321+00', '2026-04-20 22:01:56.172321+00', NULL);
INSERT INTO public.user_sessions VALUES (619, 3, '1a75befe-511d-4a3c-b96a-31d72e5c000f', NULL, NULL, '2026-03-21 22:10:39.76154+00', '2026-04-20 22:10:39.76154+00', NULL);
INSERT INTO public.user_sessions VALUES (620, 3, 'e33b85bd-7b33-45b9-b73f-26d53202d4b1', NULL, NULL, '2026-03-21 22:14:38.337022+00', '2026-04-20 22:14:38.337022+00', NULL);
INSERT INTO public.user_sessions VALUES (621, 4, '912b8cf7-4a13-4e30-a583-259a3a1da521', NULL, NULL, '2026-03-21 22:15:30.709133+00', '2026-04-20 22:15:30.709133+00', NULL);
INSERT INTO public.user_sessions VALUES (622, 3, '5015ed5b-a923-4b65-9f37-dda53c0f0924', NULL, NULL, '2026-03-21 22:54:50.488951+00', '2026-04-20 22:54:50.488951+00', NULL);
INSERT INTO public.user_sessions VALUES (623, 3, '5cffa1bd-dee7-4b40-86a8-33d8d37eda20', NULL, NULL, '2026-03-21 23:03:11.527549+00', '2026-04-20 23:03:11.527549+00', NULL);
INSERT INTO public.user_sessions VALUES (624, 3, '9771db1e-6b33-4723-b0d3-374c94a90539', NULL, NULL, '2026-03-21 23:03:45.271129+00', '2026-04-20 23:03:45.271129+00', NULL);
INSERT INTO public.user_sessions VALUES (625, 3, '0b469ca7-9545-4e13-99c2-acb5a5d53eee', NULL, NULL, '2026-03-21 23:10:52.710692+00', '2026-04-20 23:10:52.710692+00', NULL);
INSERT INTO public.user_sessions VALUES (626, 3, '8e7a0a46-d43e-4c7b-9a0e-b703b17126d8', NULL, NULL, '2026-03-21 23:13:10.237324+00', '2026-04-20 23:13:10.237324+00', NULL);
INSERT INTO public.user_sessions VALUES (627, 3, '5236e6e9-72fe-4c04-adc2-4f5ed2e72aad', NULL, NULL, '2026-03-21 23:15:12.44735+00', '2026-04-20 23:15:12.44735+00', NULL);
INSERT INTO public.user_sessions VALUES (628, 3, 'ab2a32ba-3503-4ba0-b870-834a1afa6110', NULL, NULL, '2026-03-21 23:20:37.008643+00', '2026-04-20 23:20:37.008643+00', NULL);
INSERT INTO public.user_sessions VALUES (629, 3, 'de1a0295-30ca-43a0-9334-9ded5fb2551e', NULL, NULL, '2026-03-21 23:22:56.87104+00', '2026-04-20 23:22:56.87104+00', NULL);
INSERT INTO public.user_sessions VALUES (630, 3, '6f97e702-35d0-4da0-9a74-c609cc3ceb3d', NULL, NULL, '2026-03-22 09:07:57.692522+00', '2026-04-21 09:07:57.692522+00', NULL);
INSERT INTO public.user_sessions VALUES (631, 3, 'cbce6506-0f53-4e8f-8094-ef23fce5f5ae', NULL, NULL, '2026-03-22 09:19:11.811483+00', '2026-04-21 09:19:11.811483+00', NULL);
INSERT INTO public.user_sessions VALUES (632, 3, '7bff86a0-166e-46c0-b107-2df6af35f3ef', NULL, NULL, '2026-03-22 09:22:38.71469+00', '2026-04-21 09:22:38.71469+00', NULL);
INSERT INTO public.user_sessions VALUES (633, 3, '9ce8df59-83d2-45ff-a0ce-88fda43f7193', NULL, NULL, '2026-03-22 09:24:51.338226+00', '2026-04-21 09:24:51.338226+00', NULL);
INSERT INTO public.user_sessions VALUES (634, 3, '6a969012-cec4-4256-bcc0-760e5fb3c795', NULL, NULL, '2026-03-22 09:25:22.116072+00', '2026-04-21 09:25:22.116072+00', NULL);
INSERT INTO public.user_sessions VALUES (635, 3, 'e0c9b094-be2b-4789-bb6b-b57500b00eb2', NULL, NULL, '2026-03-22 09:26:14.083017+00', '2026-04-21 09:26:14.083017+00', NULL);
INSERT INTO public.user_sessions VALUES (636, 3, '56da413a-0d06-41db-bec9-ecf53f2fc3ba', NULL, NULL, '2026-03-22 09:26:41.286746+00', '2026-04-21 09:26:41.286746+00', NULL);
INSERT INTO public.user_sessions VALUES (637, 3, '49585bbe-a8bb-43ac-af6b-2d4c2cba44dd', NULL, NULL, '2026-03-22 09:28:26.661354+00', '2026-04-21 09:28:26.661354+00', NULL);
INSERT INTO public.user_sessions VALUES (642, 3, 'a198b595-d2d4-4073-b66a-99f47808e128', NULL, NULL, '2026-03-22 09:34:10.322865+00', '2026-04-21 09:34:10.322865+00', NULL);
INSERT INTO public.user_sessions VALUES (647, 4, '1c93bc43-903f-46cf-a19f-a37d0d832b78', NULL, NULL, '2026-03-22 10:12:38.745814+00', '2026-04-21 10:12:38.745814+00', NULL);
INSERT INTO public.user_sessions VALUES (652, 3, '3ee0100f-622c-4158-85d9-51418cc5eb2f', NULL, NULL, '2026-03-22 10:16:46.963447+00', '2026-04-21 10:16:46.963447+00', NULL);
INSERT INTO public.user_sessions VALUES (657, 4, '49c70356-187f-4612-94fa-0acf0f5d2364', NULL, NULL, '2026-03-22 10:18:50.117285+00', '2026-04-21 10:18:50.117285+00', NULL);
INSERT INTO public.user_sessions VALUES (662, 4, 'd0e3ec9a-d6a2-4419-9084-1264bb680bf4', NULL, NULL, '2026-03-22 10:27:35.278528+00', '2026-04-21 10:27:35.278528+00', NULL);
INSERT INTO public.user_sessions VALUES (667, 3, 'e309a737-6f7e-4386-b709-0ff909db078e', NULL, NULL, '2026-03-22 10:58:45.003744+00', '2026-04-21 10:58:45.003744+00', NULL);
INSERT INTO public.user_sessions VALUES (672, 3, '71c18f4e-3d27-4c84-8b77-84468ca28a78', NULL, NULL, '2026-03-22 13:47:17.500042+00', '2026-04-21 13:47:17.500042+00', NULL);
INSERT INTO public.user_sessions VALUES (677, 3, 'a9e785ea-32e2-4bfe-a0c6-a5790a6a95c7', NULL, NULL, '2026-03-22 14:53:20.749838+00', '2026-04-21 14:53:20.749838+00', NULL);
INSERT INTO public.user_sessions VALUES (682, 3, '66475ace-d653-473b-8a8f-15bbe75e94b7', NULL, NULL, '2026-03-22 15:41:59.416368+00', '2026-04-21 15:41:59.416368+00', NULL);
INSERT INTO public.user_sessions VALUES (687, 3, '3760f5b9-1436-4a64-959e-be62baf7f4d4', NULL, NULL, '2026-03-22 17:24:07.353241+00', '2026-04-21 17:24:07.353241+00', NULL);
INSERT INTO public.user_sessions VALUES (638, 3, '1e7922a7-69f7-4967-a66d-a74529fd0fc1', NULL, NULL, '2026-03-22 09:28:41.698454+00', '2026-04-21 09:28:41.698454+00', NULL);
INSERT INTO public.user_sessions VALUES (643, 4, 'e7ed8b91-cbf1-43e0-820f-2d3f9d98140f', NULL, NULL, '2026-03-22 09:34:13.094294+00', '2026-04-21 09:34:13.094294+00', NULL);
INSERT INTO public.user_sessions VALUES (648, 3, 'b60b44f6-d97a-483a-8a31-571e9ed1be4e', NULL, NULL, '2026-03-22 10:14:08.036536+00', '2026-04-21 10:14:08.036536+00', NULL);
INSERT INTO public.user_sessions VALUES (653, 4, '9625c311-106f-4cc1-bd61-ee4dd2e43c5e', NULL, NULL, '2026-03-22 10:16:49.579376+00', '2026-04-21 10:16:49.579376+00', NULL);
INSERT INTO public.user_sessions VALUES (658, 3, 'c1454df0-7212-479b-bff6-fb2d7e964a16', NULL, NULL, '2026-03-22 10:22:57.439316+00', '2026-04-21 10:22:57.439316+00', NULL);
INSERT INTO public.user_sessions VALUES (663, 3, '607ff9f5-c16b-4647-9e26-b594ee209511', NULL, NULL, '2026-03-22 10:28:09.064811+00', '2026-04-21 10:28:09.064811+00', NULL);
INSERT INTO public.user_sessions VALUES (668, 3, 'dc62a612-7e24-4be9-b76c-486e878ba9bf', NULL, NULL, '2026-03-22 11:54:42.548413+00', '2026-04-21 11:54:42.548413+00', NULL);
INSERT INTO public.user_sessions VALUES (673, 3, '91879bf1-4b98-4ced-a78b-baf0f38a6f9b', NULL, NULL, '2026-03-22 13:56:36.387141+00', '2026-04-21 13:56:36.387141+00', NULL);
INSERT INTO public.user_sessions VALUES (678, 4, '9541c9f9-a80f-48f3-ab6d-fec093115894', NULL, NULL, '2026-03-22 14:54:16.970161+00', '2026-04-21 14:54:16.970161+00', NULL);
INSERT INTO public.user_sessions VALUES (683, 3, '6efc544b-4d2d-4843-9dec-3f17f92a7a89', NULL, NULL, '2026-03-22 15:50:52.465573+00', '2026-04-21 15:50:52.465573+00', NULL);
INSERT INTO public.user_sessions VALUES (688, 3, '38f7fc40-4dd7-4fd2-a0f4-0cd3ea254771', NULL, NULL, '2026-03-22 18:57:15.243635+00', '2026-04-21 18:57:15.243635+00', NULL);
INSERT INTO public.user_sessions VALUES (639, 4, '471d8c89-4ba9-4b3b-94df-f4ab225e2031', NULL, NULL, '2026-03-22 09:30:28.992457+00', '2026-04-21 09:30:28.992457+00', NULL);
INSERT INTO public.user_sessions VALUES (644, 3, 'd765cfae-a357-4e2f-8923-d5955ddcf7b4', NULL, NULL, '2026-03-22 10:05:17.680131+00', '2026-04-21 10:05:17.680131+00', NULL);
INSERT INTO public.user_sessions VALUES (649, 4, 'b8472656-9eea-4c1e-ac0b-7efc72dc7da5', NULL, NULL, '2026-03-22 10:14:13.430055+00', '2026-04-21 10:14:13.430055+00', NULL);
INSERT INTO public.user_sessions VALUES (654, 3, '38fb3eda-c6a4-41a7-86f1-63b8b3f28930', NULL, NULL, '2026-03-22 10:17:59.732293+00', '2026-04-21 10:17:59.732293+00', NULL);
INSERT INTO public.user_sessions VALUES (659, 3, '098982b6-82b6-4ce7-917e-2d483e7bc80d', NULL, NULL, '2026-03-22 10:25:03.216949+00', '2026-04-21 10:25:03.216949+00', NULL);
INSERT INTO public.user_sessions VALUES (664, 4, 'c6762371-39ec-46b1-8b8e-6aef6b3f5e5b', NULL, NULL, '2026-03-22 10:28:11.419072+00', '2026-04-21 10:28:11.419072+00', NULL);
INSERT INTO public.user_sessions VALUES (669, 3, '16b73b4d-6d52-4eff-868c-94c17fa17d57', NULL, NULL, '2026-03-22 12:57:54.149547+00', '2026-04-21 12:57:54.149547+00', NULL);
INSERT INTO public.user_sessions VALUES (674, 3, '34a0c01f-6049-4b2c-85c4-cc8979399ea3', NULL, NULL, '2026-03-22 13:57:37.193916+00', '2026-04-21 13:57:37.193916+00', NULL);
INSERT INTO public.user_sessions VALUES (679, 3, 'd5aa9732-b434-4dc6-8435-649f6d324c3f', NULL, NULL, '2026-03-22 14:58:30.299865+00', '2026-04-21 14:58:30.299865+00', NULL);
INSERT INTO public.user_sessions VALUES (684, 3, 'f65bb32c-6eee-4e8b-99e1-d0907b7d1235', NULL, NULL, '2026-03-22 17:10:45.087339+00', '2026-04-21 17:10:45.087339+00', NULL);
INSERT INTO public.user_sessions VALUES (689, 4, 'd0883ca6-9aa7-4415-ae9d-406e8976871b', NULL, NULL, '2026-03-22 19:01:28.915941+00', '2026-04-21 19:01:28.915941+00', NULL);
INSERT INTO public.user_sessions VALUES (640, 3, 'ccfc89d0-0e41-4322-9264-f49744123d2a', NULL, NULL, '2026-03-22 09:31:17.42134+00', '2026-04-21 09:31:17.42134+00', NULL);
INSERT INTO public.user_sessions VALUES (645, 3, 'b9a84617-76cb-47f9-916c-a8b95d634e0b', NULL, NULL, '2026-03-22 10:05:30.277419+00', '2026-04-21 10:05:30.277419+00', NULL);
INSERT INTO public.user_sessions VALUES (650, 3, '776ed9b3-6ff7-4a5c-80dc-11c1f1cba2bb', NULL, NULL, '2026-03-22 10:14:42.755962+00', '2026-04-21 10:14:42.755962+00', NULL);
INSERT INTO public.user_sessions VALUES (655, 4, 'dec6ec41-6053-430a-a6de-4b838835a47c', NULL, NULL, '2026-03-22 10:18:02.642997+00', '2026-04-21 10:18:02.642997+00', NULL);
INSERT INTO public.user_sessions VALUES (660, 3, '035d730a-47be-46cf-9024-2ba4aa016737', NULL, NULL, '2026-03-22 10:26:28.691134+00', '2026-04-21 10:26:28.691134+00', NULL);
INSERT INTO public.user_sessions VALUES (665, 3, 'ad011a93-3d48-4193-ae37-79b3aa9b9b58', NULL, NULL, '2026-03-22 10:56:12.982663+00', '2026-04-21 10:56:12.982663+00', NULL);
INSERT INTO public.user_sessions VALUES (670, 3, '4da6f2b5-5cb0-46b7-a75a-f749827a74f6', NULL, NULL, '2026-03-22 13:00:47.989477+00', '2026-04-21 13:00:47.989477+00', NULL);
INSERT INTO public.user_sessions VALUES (675, 3, '4a09a5d6-762f-4caf-bd37-0b634d503946', NULL, NULL, '2026-03-22 14:03:21.95241+00', '2026-04-21 14:03:21.95241+00', NULL);
INSERT INTO public.user_sessions VALUES (680, 3, '48865eda-143e-49df-a1ba-47a3bf0c6836', NULL, NULL, '2026-03-22 15:37:48.393033+00', '2026-04-21 15:37:48.393033+00', NULL);
INSERT INTO public.user_sessions VALUES (685, 3, 'e6b2ace4-daa7-4dc3-a6b9-57a89d1ee409', NULL, NULL, '2026-03-22 17:14:45.250999+00', '2026-04-21 17:14:45.250999+00', NULL);
INSERT INTO public.user_sessions VALUES (641, 4, '2fbb9f16-8a25-4073-9197-61ea38ac9e6c', NULL, NULL, '2026-03-22 09:31:20.444147+00', '2026-04-21 09:31:20.444147+00', NULL);
INSERT INTO public.user_sessions VALUES (646, 3, '8c89b044-7947-4281-9f1a-116e55dc7c88', NULL, NULL, '2026-03-22 10:12:35.418551+00', '2026-04-21 10:12:35.418551+00', NULL);
INSERT INTO public.user_sessions VALUES (651, 4, '8e081589-04bc-414f-a2f5-ae15773367c4', NULL, NULL, '2026-03-22 10:14:45.647739+00', '2026-04-21 10:14:45.647739+00', NULL);
INSERT INTO public.user_sessions VALUES (656, 3, '257f1056-5994-4468-af44-8ca1dc39aae1', NULL, NULL, '2026-03-22 10:18:47.302174+00', '2026-04-21 10:18:47.302174+00', NULL);
INSERT INTO public.user_sessions VALUES (661, 3, 'd393b413-2b92-4af2-936a-e98451e179b0', NULL, NULL, '2026-03-22 10:27:32.594284+00', '2026-04-21 10:27:32.594284+00', NULL);
INSERT INTO public.user_sessions VALUES (666, 3, 'a910d9c9-a628-45bf-94c3-e5bfd197b5d7', NULL, NULL, '2026-03-22 10:57:13.895894+00', '2026-04-21 10:57:13.895894+00', NULL);
INSERT INTO public.user_sessions VALUES (671, 3, '7aaaa46a-e37b-4931-9d82-07de331ca004', NULL, NULL, '2026-03-22 13:39:40.858577+00', '2026-04-21 13:39:40.858577+00', NULL);
INSERT INTO public.user_sessions VALUES (676, 3, 'a47825c0-01e3-4095-838f-43c32750a315', NULL, NULL, '2026-03-22 14:14:14.067288+00', '2026-04-21 14:14:14.067288+00', NULL);
INSERT INTO public.user_sessions VALUES (681, 3, 'b50dbf4e-1d71-4e86-b460-d144a651431a', NULL, NULL, '2026-03-22 15:39:13.556205+00', '2026-04-21 15:39:13.556205+00', NULL);
INSERT INTO public.user_sessions VALUES (686, 3, '6a6a2566-1de6-4496-a3d1-e63648b6b770', NULL, NULL, '2026-03-22 17:21:51.419128+00', '2026-04-21 17:21:51.419128+00', NULL);
INSERT INTO public.user_sessions VALUES (690, 3, '76180d92-10b5-465d-8815-197c6dcc8cb9', NULL, NULL, '2026-03-23 10:24:48.00279+00', '2026-04-22 10:24:48.00279+00', NULL);
INSERT INTO public.user_sessions VALUES (691, 3, '54219d1c-175d-4e83-80fb-20c731920e67', NULL, NULL, '2026-03-23 10:49:53.386206+00', '2026-04-22 10:49:53.386206+00', NULL);
INSERT INTO public.user_sessions VALUES (692, 3, '0feb184d-d8b2-4140-9770-7290ca5c2281', NULL, NULL, '2026-03-23 10:51:45.356568+00', '2026-04-22 10:51:45.356568+00', NULL);
INSERT INTO public.user_sessions VALUES (693, 3, 'f94fa261-4c3b-4c1c-8b14-75c98769c635', NULL, NULL, '2026-03-23 11:40:13.602147+00', '2026-04-22 11:40:13.602147+00', NULL);
INSERT INTO public.user_sessions VALUES (694, 3, '10aec37c-ece4-455f-beb3-2bce7e6fc345', NULL, NULL, '2026-03-23 11:41:25.610154+00', '2026-04-22 11:41:25.610154+00', NULL);
INSERT INTO public.user_sessions VALUES (695, 3, '942d8c45-4a10-4763-8a40-d082e6001164', NULL, NULL, '2026-03-23 11:48:19.4004+00', '2026-04-22 11:48:19.4004+00', NULL);
INSERT INTO public.user_sessions VALUES (696, 3, '2df0251e-07a3-4fcf-939d-6882eed9661b', NULL, NULL, '2026-03-23 12:27:02.360856+00', '2026-04-22 12:27:02.360856+00', NULL);
INSERT INTO public.user_sessions VALUES (697, 3, 'e4bbc7e9-2059-449e-b727-4d2ea402e842', NULL, NULL, '2026-03-23 12:32:25.849739+00', '2026-04-22 12:32:25.849739+00', NULL);
INSERT INTO public.user_sessions VALUES (698, 3, '8a4548e8-8f09-4e8f-8d98-ab5066daaa34', NULL, NULL, '2026-03-23 12:39:36.702425+00', '2026-04-22 12:39:36.702425+00', NULL);
INSERT INTO public.user_sessions VALUES (699, 3, 'fe9285f8-7b7d-4ec4-abdd-37e8207a1caf', NULL, NULL, '2026-03-23 12:43:09.003406+00', '2026-04-22 12:43:09.003406+00', NULL);
INSERT INTO public.user_sessions VALUES (700, 3, 'c0f1f908-b4d6-4a43-93d5-70b4e46b21a0', NULL, NULL, '2026-03-23 12:44:36.791531+00', '2026-04-22 12:44:36.791531+00', NULL);
INSERT INTO public.user_sessions VALUES (701, 3, '2e9059d9-074e-4152-a1e4-2074a75bfb77', NULL, NULL, '2026-03-23 13:07:26.628939+00', '2026-04-22 13:07:26.628939+00', NULL);
INSERT INTO public.user_sessions VALUES (702, 3, 'e42ba574-3c90-4883-ae9e-0b09dda0a3cd', NULL, NULL, '2026-03-23 13:12:15.105857+00', '2026-04-22 13:12:15.105857+00', NULL);
INSERT INTO public.user_sessions VALUES (703, 3, 'a33afac2-36d9-4e67-960a-514d5ce1f91f', NULL, NULL, '2026-03-23 13:14:57.919775+00', '2026-04-22 13:14:57.919775+00', NULL);
INSERT INTO public.user_sessions VALUES (704, 3, '42390d98-3017-407c-96cc-a06f77c4df92', NULL, NULL, '2026-03-23 13:18:10.225333+00', '2026-04-22 13:18:10.225333+00', NULL);
INSERT INTO public.user_sessions VALUES (705, 3, 'd7e9db5d-bb51-4e37-8938-92d076e97a05', NULL, NULL, '2026-03-23 13:20:17.056695+00', '2026-04-22 13:20:17.056695+00', NULL);
INSERT INTO public.user_sessions VALUES (706, 3, '93a0c27a-2050-440a-8423-79ea8b89a73e', NULL, NULL, '2026-03-23 13:46:25.026058+00', '2026-04-22 13:46:25.026058+00', NULL);
INSERT INTO public.user_sessions VALUES (707, 3, '415f7c15-f5b1-4221-b333-977818335007', NULL, NULL, '2026-03-23 13:59:38.315039+00', '2026-04-22 13:59:38.315039+00', NULL);
INSERT INTO public.user_sessions VALUES (708, 3, 'cdf6c681-f241-4f98-b9d2-39e1123c19be', NULL, NULL, '2026-03-23 14:05:12.522226+00', '2026-04-22 14:05:12.522226+00', NULL);
INSERT INTO public.user_sessions VALUES (709, 3, '4a33091d-46f4-49cc-822e-24a6f38291be', NULL, NULL, '2026-03-23 14:09:47.861182+00', '2026-04-22 14:09:47.861182+00', NULL);
INSERT INTO public.user_sessions VALUES (710, 3, 'e2bec7d8-8f7c-4334-b8c8-2828882ba3ea', NULL, NULL, '2026-03-23 15:20:02.977653+00', '2026-04-22 15:20:02.977653+00', NULL);
INSERT INTO public.user_sessions VALUES (711, 3, '24f4a600-6a14-4699-bdc7-da36f3925d1a', NULL, NULL, '2026-03-23 15:33:34.820703+00', '2026-04-22 15:33:34.820703+00', NULL);
INSERT INTO public.user_sessions VALUES (712, 3, '5ab732a3-2977-433c-8260-7b86947d8b2f', NULL, NULL, '2026-03-23 15:38:10.779196+00', '2026-04-22 15:38:10.779196+00', NULL);
INSERT INTO public.user_sessions VALUES (713, 3, 'f677d437-a129-4b55-8f09-b72227b27f39', NULL, NULL, '2026-03-23 15:46:34.02249+00', '2026-04-22 15:46:34.02249+00', NULL);
INSERT INTO public.user_sessions VALUES (714, 3, '76e2104c-413b-4b97-b439-fe08c5730360', NULL, NULL, '2026-03-23 15:50:05.288206+00', '2026-04-22 15:50:05.288206+00', NULL);
INSERT INTO public.user_sessions VALUES (715, 3, 'fcbd2fae-6c61-4cc5-abfd-014610e6f74f', NULL, NULL, '2026-03-23 15:54:50.233705+00', '2026-04-22 15:54:50.233705+00', NULL);
INSERT INTO public.user_sessions VALUES (716, 3, 'bf3020f5-095d-45c2-b080-09cd24750e6b', NULL, NULL, '2026-03-23 16:00:38.979253+00', '2026-04-22 16:00:38.979253+00', NULL);
INSERT INTO public.user_sessions VALUES (717, 3, '21b4e21e-de37-4b15-a33f-7375fdd907df', NULL, NULL, '2026-03-23 16:08:02.763113+00', '2026-04-22 16:08:02.763113+00', NULL);
INSERT INTO public.user_sessions VALUES (718, 3, '438f00d1-76f3-4263-8cf5-74be637569f7', NULL, NULL, '2026-03-23 16:09:31.957715+00', '2026-04-22 16:09:31.957715+00', NULL);
INSERT INTO public.user_sessions VALUES (719, 3, '661dd50d-a0cb-41d8-b2ab-eb12a235d5de', NULL, NULL, '2026-03-23 16:12:45.477327+00', '2026-04-22 16:12:45.477327+00', NULL);
INSERT INTO public.user_sessions VALUES (720, 3, 'f2c02b53-9805-4051-a674-091a5be86a45', NULL, NULL, '2026-03-23 16:23:17.227045+00', '2026-04-22 16:23:17.227045+00', NULL);
INSERT INTO public.user_sessions VALUES (721, 3, 'a1cfd9a1-ae24-4635-ae18-f957ce83786d', NULL, NULL, '2026-03-23 17:18:13.226293+00', '2026-04-22 17:18:13.226293+00', NULL);
INSERT INTO public.user_sessions VALUES (722, 3, '8822ab8f-6517-4657-a972-b3e170ec5d8b', NULL, NULL, '2026-03-23 18:46:05.77053+00', '2026-04-22 18:46:05.77053+00', NULL);
INSERT INTO public.user_sessions VALUES (723, 3, '58ac81e4-c0a1-490a-8a1e-d9bfc63b2cd9', NULL, NULL, '2026-03-23 18:46:40.802107+00', '2026-04-22 18:46:40.802107+00', NULL);
INSERT INTO public.user_sessions VALUES (724, 3, 'e7e80ff1-6a4f-412b-9caa-d5ed5fc496bd', NULL, NULL, '2026-03-23 18:49:24.068794+00', '2026-04-22 18:49:24.068794+00', NULL);
INSERT INTO public.user_sessions VALUES (725, 3, '81cbfc7d-636d-4f4e-a098-471a9cae5f56', NULL, NULL, '2026-03-24 11:38:23.830965+00', '2026-04-23 11:38:23.830965+00', NULL);
INSERT INTO public.user_sessions VALUES (726, 3, '0152777f-bc18-424d-824c-b180f70fe093', NULL, NULL, '2026-03-24 11:44:37.603427+00', '2026-04-23 11:44:37.603427+00', NULL);
INSERT INTO public.user_sessions VALUES (727, 3, '1110411d-6cc9-43b3-80bf-2e83ff9bc939', NULL, NULL, '2026-03-24 11:45:07.193154+00', '2026-04-23 11:45:07.193154+00', NULL);
INSERT INTO public.user_sessions VALUES (728, 3, '3c3dabdc-b08a-48a6-8342-cfc24deafbc4', NULL, NULL, '2026-03-24 11:49:38.42942+00', '2026-04-23 11:49:38.42942+00', NULL);
INSERT INTO public.user_sessions VALUES (729, 3, '472ae9b6-6a41-4c9b-952d-9d46db7a01d7', NULL, NULL, '2026-03-24 11:51:36.981135+00', '2026-04-23 11:51:36.981135+00', NULL);
INSERT INTO public.user_sessions VALUES (730, 3, '580fbd34-b184-4530-8c9f-57d46eddc3a2', NULL, NULL, '2026-03-24 11:52:42.028054+00', '2026-04-23 11:52:42.028054+00', NULL);
INSERT INTO public.user_sessions VALUES (731, 3, 'fbf5b79c-fb4a-42e7-9fbf-1f8d1849c011', NULL, NULL, '2026-03-24 11:59:39.678599+00', '2026-04-23 11:59:39.678599+00', NULL);
INSERT INTO public.user_sessions VALUES (732, 3, '7cd8f290-7139-49aa-adb2-61251c4fc661', NULL, NULL, '2026-03-24 12:04:49.011169+00', '2026-04-23 12:04:49.011169+00', NULL);
INSERT INTO public.user_sessions VALUES (733, 3, 'b4180486-c8b1-43c9-9649-f2bb46b1531c', NULL, NULL, '2026-03-24 12:08:12.603005+00', '2026-04-23 12:08:12.603005+00', NULL);
INSERT INTO public.user_sessions VALUES (734, 3, 'e29fe08c-b0da-466b-88ed-69081fe9cb6d', NULL, NULL, '2026-03-24 12:08:37.144826+00', '2026-04-23 12:08:37.144826+00', NULL);
INSERT INTO public.user_sessions VALUES (735, 3, '497ef70b-f7b6-416d-8f83-5d8e10ce9e5b', NULL, NULL, '2026-03-24 12:11:05.328053+00', '2026-04-23 12:11:05.328053+00', NULL);
INSERT INTO public.user_sessions VALUES (736, 3, '6537724f-769a-4945-9366-a037c5c62638', NULL, NULL, '2026-03-24 12:22:11.620527+00', '2026-04-23 12:22:11.620527+00', NULL);
INSERT INTO public.user_sessions VALUES (737, 3, 'f4c21877-b174-4bcf-82b1-d4fcbcde8085', NULL, NULL, '2026-03-24 12:27:12.078758+00', '2026-04-23 12:27:12.078758+00', NULL);
INSERT INTO public.user_sessions VALUES (738, 3, '44af3a7a-081a-41be-9fe0-b9c92ac74be1', NULL, NULL, '2026-03-24 15:41:47.788632+00', '2026-04-23 15:41:47.788632+00', NULL);
INSERT INTO public.user_sessions VALUES (739, 3, '44729a26-25aa-4e94-a298-fb8d57ee4456', NULL, NULL, '2026-03-24 16:47:34.539485+00', '2026-04-23 16:47:34.539485+00', NULL);
INSERT INTO public.user_sessions VALUES (740, 3, '4df588db-acb1-4d17-891f-08c6f8c54ce5', NULL, NULL, '2026-03-24 18:36:39.881912+00', '2026-04-23 18:36:39.881912+00', NULL);
INSERT INTO public.user_sessions VALUES (741, 3, 'db0ca2d7-a3ee-4914-a560-53f0fb6ee52a', NULL, NULL, '2026-03-24 18:42:00.310922+00', '2026-04-23 18:42:00.310922+00', NULL);
INSERT INTO public.user_sessions VALUES (742, 3, '21fb54b3-3834-41dc-861c-1e77763e892b', NULL, NULL, '2026-03-24 18:42:31.969179+00', '2026-04-23 18:42:31.969179+00', NULL);
INSERT INTO public.user_sessions VALUES (743, 3, '0fe19cc8-4ea0-4a39-9169-4c226c01cc42', NULL, NULL, '2026-03-24 18:43:32.390341+00', '2026-04-23 18:43:32.390341+00', NULL);
INSERT INTO public.user_sessions VALUES (744, 3, '952e4215-724f-4b1d-a2ea-5f0f9d138233', NULL, NULL, '2026-03-24 18:44:33.310493+00', '2026-04-23 18:44:33.310493+00', NULL);
INSERT INTO public.user_sessions VALUES (745, 3, '2821834d-558e-40d8-a521-720696eddf33', NULL, NULL, '2026-03-24 18:46:55.322641+00', '2026-04-23 18:46:55.322641+00', NULL);
INSERT INTO public.user_sessions VALUES (746, 3, 'd07fb04e-4ac7-4548-a1a2-18663de82017', NULL, NULL, '2026-03-24 19:35:56.538483+00', '2026-04-23 19:35:56.538483+00', NULL);
INSERT INTO public.user_sessions VALUES (747, 3, '0639ca76-d41f-480d-a393-85c13cebcad4', NULL, NULL, '2026-03-24 19:37:09.751056+00', '2026-04-23 19:37:09.751056+00', NULL);
INSERT INTO public.user_sessions VALUES (748, 3, '03a07e33-fb62-4cfa-9019-fb9ae24531e4', NULL, NULL, '2026-03-24 19:43:21.987939+00', '2026-04-23 19:43:21.987939+00', NULL);
INSERT INTO public.user_sessions VALUES (749, 3, 'e8fee5f5-6d4f-4bf0-88d0-391fffa92592', NULL, NULL, '2026-03-26 17:23:02.772693+00', '2026-04-25 17:23:02.772693+00', NULL);
INSERT INTO public.user_sessions VALUES (750, 3, '6df4a139-76bb-4e60-b07f-4f215e2cd843', NULL, NULL, '2026-03-26 17:23:38.673565+00', '2026-04-25 17:23:38.673565+00', NULL);
INSERT INTO public.user_sessions VALUES (751, 3, '801caba0-ef28-4aa8-8e84-4cf59b82c1f1', NULL, NULL, '2026-03-26 17:38:15.738801+00', '2026-04-25 17:38:15.738801+00', NULL);
INSERT INTO public.user_sessions VALUES (752, 3, '851a6933-a51c-46e7-8334-311f39177271', NULL, NULL, '2026-03-26 17:45:14.718499+00', '2026-04-25 17:45:14.718499+00', NULL);
INSERT INTO public.user_sessions VALUES (753, 3, '565f9186-1182-48d1-a666-8856b1837782', NULL, NULL, '2026-03-26 17:56:19.680511+00', '2026-04-25 17:56:19.680511+00', NULL);
INSERT INTO public.user_sessions VALUES (754, 3, '2face066-6867-4e46-ac76-fb933eefe6cc', NULL, NULL, '2026-03-26 17:57:32.441384+00', '2026-04-25 17:57:32.441384+00', NULL);
INSERT INTO public.user_sessions VALUES (755, 3, 'e6aa31bd-3312-4755-9552-dda3bb073a76', NULL, NULL, '2026-03-26 18:08:25.240769+00', '2026-04-25 18:08:25.240769+00', NULL);
INSERT INTO public.user_sessions VALUES (756, 3, '1c4670f6-ec8d-4e57-af9f-24eaf7ededd4', NULL, NULL, '2026-03-26 18:15:16.268442+00', '2026-04-25 18:15:16.268442+00', NULL);
INSERT INTO public.user_sessions VALUES (757, 3, '1cf3c087-decd-45b5-a09a-53d5672090c6', NULL, NULL, '2026-03-26 18:22:43.031623+00', '2026-04-25 18:22:43.031623+00', NULL);
INSERT INTO public.user_sessions VALUES (758, 3, 'c6ab781d-8a3b-4f8b-9f4e-2a99d18da028', NULL, NULL, '2026-03-26 18:30:31.317657+00', '2026-04-25 18:30:31.317657+00', NULL);
INSERT INTO public.user_sessions VALUES (759, 3, '0302d8cf-bda2-4394-979a-70bc58afbe72', NULL, NULL, '2026-03-26 18:39:52.44172+00', '2026-04-25 18:39:52.44172+00', NULL);
INSERT INTO public.user_sessions VALUES (760, 3, 'b7756929-c7fb-4cc4-a61f-9e9795be924f', NULL, NULL, '2026-03-26 18:59:09.968442+00', '2026-04-25 18:59:09.968442+00', NULL);
INSERT INTO public.user_sessions VALUES (761, 3, '556a2076-6b22-4374-a654-73589b3f93b3', NULL, NULL, '2026-03-26 19:03:06.821009+00', '2026-04-25 19:03:06.821009+00', NULL);
INSERT INTO public.user_sessions VALUES (766, 3, '45de83aa-742d-43b5-b9e5-b60c1784fcc0', NULL, NULL, '2026-03-26 19:30:00.123978+00', '2026-04-25 19:30:00.123978+00', NULL);
INSERT INTO public.user_sessions VALUES (762, 3, 'f4247ef4-2548-46c4-b091-ead48f1ad26e', NULL, NULL, '2026-03-26 19:09:29.92621+00', '2026-04-25 19:09:29.92621+00', NULL);
INSERT INTO public.user_sessions VALUES (767, 3, '1bbe294a-3683-4977-bb36-731b2922f481', NULL, NULL, '2026-03-26 19:42:12.476592+00', '2026-04-25 19:42:12.476592+00', NULL);
INSERT INTO public.user_sessions VALUES (763, 3, '96f0ff17-b036-4086-bb6b-c111d44a99bd', NULL, NULL, '2026-03-26 19:10:45.135236+00', '2026-04-25 19:10:45.135236+00', NULL);
INSERT INTO public.user_sessions VALUES (768, 3, 'd1e8d6dd-9a62-4812-9c87-bc3d9df44e1b', NULL, NULL, '2026-03-26 19:46:25.52911+00', '2026-04-25 19:46:25.52911+00', NULL);
INSERT INTO public.user_sessions VALUES (764, 3, '4e81c2f7-4ea5-4db3-bfca-906df1223ce7', NULL, NULL, '2026-03-26 19:18:35.461706+00', '2026-04-25 19:18:35.461706+00', NULL);
INSERT INTO public.user_sessions VALUES (769, 3, '89af718f-1025-45ad-993d-416c36cb5ed6', NULL, NULL, '2026-03-26 19:51:16.537287+00', '2026-04-25 19:51:16.537287+00', NULL);
INSERT INTO public.user_sessions VALUES (765, 3, '286a4f3f-b253-4032-aa42-d0225c584e93', NULL, NULL, '2026-03-26 19:29:33.790139+00', '2026-04-25 19:29:33.790139+00', NULL);
INSERT INTO public.user_sessions VALUES (770, 3, 'd3c69b83-3461-4351-acce-747b11d7dfd1', NULL, NULL, '2026-03-26 20:37:44.964453+00', '2026-04-25 20:37:44.964453+00', NULL);
INSERT INTO public.user_sessions VALUES (771, 3, 'b3c52a9e-b980-4438-9335-24b2ed616614', NULL, NULL, '2026-03-27 07:27:33.466602+00', '2026-04-26 07:27:33.466602+00', NULL);
INSERT INTO public.user_sessions VALUES (772, 3, 'e1603b60-600f-4a36-8d4d-17b0db143f4b', NULL, NULL, '2026-03-27 07:28:11.529335+00', '2026-04-26 07:28:11.529335+00', NULL);
INSERT INTO public.user_sessions VALUES (773, 3, '9ff5b26e-9834-489b-9238-4c2440efdcf6', NULL, NULL, '2026-03-27 08:04:57.317051+00', '2026-04-26 08:04:57.317051+00', NULL);
INSERT INTO public.user_sessions VALUES (774, 3, 'df0e2467-aad1-4322-bd73-3f0fb4f30264', NULL, NULL, '2026-03-27 08:15:15.860086+00', '2026-04-26 08:15:15.860086+00', NULL);
INSERT INTO public.user_sessions VALUES (775, 3, '02c873b1-e6ea-4280-86e8-bdd2505afb18', NULL, NULL, '2026-03-27 08:18:24.05183+00', '2026-04-26 08:18:24.05183+00', NULL);
INSERT INTO public.user_sessions VALUES (776, 3, '251abb85-2a27-4007-9bc2-bc688435735c', NULL, NULL, '2026-03-27 08:27:24.478076+00', '2026-04-26 08:27:24.478076+00', NULL);
INSERT INTO public.user_sessions VALUES (777, 3, 'b70520a6-8f27-4053-92f1-51e93be43e5b', NULL, NULL, '2026-03-27 08:29:07.948203+00', '2026-04-26 08:29:07.948203+00', NULL);
INSERT INTO public.user_sessions VALUES (778, 4, '2096c7ed-d71c-46fb-9b9d-db4aa0d9fbe8', NULL, NULL, '2026-03-27 08:31:09.11784+00', '2026-04-26 08:31:09.11784+00', NULL);
INSERT INTO public.user_sessions VALUES (779, 3, '47f6bfab-6568-4ed3-b2d4-32a0326d8444', NULL, NULL, '2026-03-27 08:31:31.357493+00', '2026-04-26 08:31:31.357493+00', NULL);
INSERT INTO public.user_sessions VALUES (780, 4, '22831f9c-35d1-4191-8986-11d8c4c8395c', NULL, NULL, '2026-03-27 08:31:35.538367+00', '2026-04-26 08:31:35.538367+00', NULL);
INSERT INTO public.user_sessions VALUES (781, 3, '8eddae3a-f473-483b-bc2f-bd73dcbf636e', NULL, NULL, '2026-03-27 08:33:42.844236+00', '2026-04-26 08:33:42.844236+00', NULL);
INSERT INTO public.user_sessions VALUES (782, 4, '60582cae-b9b3-4c96-b1a7-5bea92d5e52f', NULL, NULL, '2026-03-27 08:33:47.089257+00', '2026-04-26 08:33:47.089257+00', NULL);
INSERT INTO public.user_sessions VALUES (783, 3, 'b60a8ae0-de94-4fa0-a646-2dd23f75f791', NULL, NULL, '2026-03-27 08:56:33.537382+00', '2026-04-26 08:56:33.537382+00', NULL);
INSERT INTO public.user_sessions VALUES (784, 4, 'a2a71987-d660-4f4d-a6e9-61e0dc01ffa0', NULL, NULL, '2026-03-27 08:56:39.963367+00', '2026-04-26 08:56:39.963367+00', NULL);
INSERT INTO public.user_sessions VALUES (785, 3, '7d381f0f-4cca-4d06-8213-9c5302e985c2', NULL, NULL, '2026-03-27 08:57:06.498344+00', '2026-04-26 08:57:06.498344+00', NULL);
INSERT INTO public.user_sessions VALUES (786, 4, '6f10202f-a81c-44ca-a478-39941074471e', NULL, NULL, '2026-03-27 08:57:10.422473+00', '2026-04-26 08:57:10.422473+00', NULL);
INSERT INTO public.user_sessions VALUES (787, 3, '361731fe-354a-42e7-b2b7-153352555554', NULL, NULL, '2026-03-27 09:03:39.81397+00', '2026-04-26 09:03:39.81397+00', NULL);
INSERT INTO public.user_sessions VALUES (788, 4, '8f0af41f-71ca-4685-9d70-d92375023e0e', NULL, NULL, '2026-03-27 09:03:45.493222+00', '2026-04-26 09:03:45.493222+00', NULL);
INSERT INTO public.user_sessions VALUES (789, 3, '100b4692-7197-4871-b2a4-ecef9c9b0e46', NULL, NULL, '2026-03-27 09:04:57.855654+00', '2026-04-26 09:04:57.855654+00', NULL);
INSERT INTO public.user_sessions VALUES (790, 4, '35212010-f8f0-45ec-9615-08a4f04fd6fe', NULL, NULL, '2026-03-27 09:07:43.701501+00', '2026-04-26 09:07:43.701501+00', NULL);
INSERT INTO public.user_sessions VALUES (791, 3, '20b131d8-480a-4ec1-99a3-d1af82985d81', NULL, NULL, '2026-03-27 09:08:13.044223+00', '2026-04-26 09:08:13.044223+00', NULL);
INSERT INTO public.user_sessions VALUES (792, 4, '0f64b88e-972c-4fe1-8176-e4902c559520', NULL, NULL, '2026-03-27 09:08:16.564059+00', '2026-04-26 09:08:16.564059+00', NULL);
INSERT INTO public.user_sessions VALUES (793, 3, 'a13c6b46-0b15-4d26-ba85-4ba63caf89c6', NULL, NULL, '2026-03-27 09:10:07.787134+00', '2026-04-26 09:10:07.787134+00', NULL);
INSERT INTO public.user_sessions VALUES (794, 3, '7c720b38-bd6f-4fc8-b373-efbe9fe39b8c', NULL, NULL, '2026-03-27 09:10:45.296051+00', '2026-04-26 09:10:45.296051+00', NULL);
INSERT INTO public.user_sessions VALUES (795, 3, '32436728-b692-4868-b279-d095132bb134', NULL, NULL, '2026-03-27 09:11:35.516333+00', '2026-04-26 09:11:35.516333+00', NULL);
INSERT INTO public.user_sessions VALUES (796, 3, '34ab359e-4a8a-47e1-93bd-649da150cc6f', NULL, NULL, '2026-03-27 09:11:57.645976+00', '2026-04-26 09:11:57.645976+00', NULL);
INSERT INTO public.user_sessions VALUES (797, 3, '3a0fcb55-c5cb-4b59-aa61-777bd6cf7e33', NULL, NULL, '2026-03-27 09:12:23.873669+00', '2026-04-26 09:12:23.873669+00', NULL);
INSERT INTO public.user_sessions VALUES (798, 3, '62481bdc-e30f-42e8-9592-03c5cf1b0734', NULL, NULL, '2026-03-27 09:13:50.607174+00', '2026-04-26 09:13:50.607174+00', NULL);
INSERT INTO public.user_sessions VALUES (799, 3, 'a3a0e533-6347-4d2e-ac5f-6b50422c8a33', NULL, NULL, '2026-03-27 09:14:52.875975+00', '2026-04-26 09:14:52.875975+00', NULL);
INSERT INTO public.user_sessions VALUES (800, 4, '8834a655-6c5f-4914-9b26-8f6a21313cfb', NULL, NULL, '2026-03-27 09:15:11.191114+00', '2026-04-26 09:15:11.191114+00', NULL);
INSERT INTO public.user_sessions VALUES (801, 3, '4dbab78c-73ec-4c07-9a8b-09a2dc76bff8', NULL, NULL, '2026-03-27 09:16:54.889516+00', '2026-04-26 09:16:54.889516+00', NULL);
INSERT INTO public.user_sessions VALUES (802, 3, 'ab8c5cb5-ccca-4656-838c-f1db864bba5f', NULL, NULL, '2026-03-27 09:19:25.002823+00', '2026-04-26 09:19:25.002823+00', NULL);
INSERT INTO public.user_sessions VALUES (803, 3, '2ca0b7ed-98c2-44f0-8711-c5783f95c770', NULL, NULL, '2026-03-27 09:28:33.983026+00', '2026-04-26 09:28:33.983026+00', NULL);
INSERT INTO public.user_sessions VALUES (804, 4, '68435de1-ad8b-40b4-a615-2729e7ca49b3', NULL, NULL, '2026-03-27 09:28:55.235826+00', '2026-04-26 09:28:55.235826+00', NULL);
INSERT INTO public.user_sessions VALUES (805, 3, 'ee93e5fb-9870-4e88-a88b-af4418906f3f', NULL, NULL, '2026-03-27 10:07:52.33284+00', '2026-04-26 10:07:52.33284+00', NULL);
INSERT INTO public.user_sessions VALUES (806, 3, 'b8097db2-30bf-42ce-9cd2-9a76b8f13c22', NULL, NULL, '2026-03-27 10:09:24.454426+00', '2026-04-26 10:09:24.454426+00', NULL);
INSERT INTO public.user_sessions VALUES (807, 3, '22db5352-1fde-4f84-abfa-5f688898837c', NULL, NULL, '2026-03-27 11:34:03.357108+00', '2026-04-26 11:34:03.357108+00', NULL);
INSERT INTO public.user_sessions VALUES (808, 3, '551d9fd9-1719-4846-8ec4-466100178071', NULL, NULL, '2026-03-27 11:40:36.928091+00', '2026-04-26 11:40:36.928091+00', NULL);
INSERT INTO public.user_sessions VALUES (809, 3, 'e8b3ff20-e7e0-4afd-bf15-415eb690aaba', NULL, NULL, '2026-03-27 11:50:13.030135+00', '2026-04-26 11:50:13.030135+00', NULL);
INSERT INTO public.user_sessions VALUES (810, 3, 'cb74b6e3-5502-468c-bed3-cb3dac598d63', NULL, NULL, '2026-03-27 12:13:37.284388+00', '2026-04-26 12:13:37.284388+00', NULL);
INSERT INTO public.user_sessions VALUES (811, 3, '22e3cc05-9d3e-43b3-9f60-efaafee282a0', NULL, NULL, '2026-03-27 12:17:06.748181+00', '2026-04-26 12:17:06.748181+00', NULL);
INSERT INTO public.user_sessions VALUES (812, 3, 'e0ac3110-1c4a-474d-97c5-e7e9b7afe940', NULL, NULL, '2026-03-27 12:38:45.948893+00', '2026-04-26 12:38:45.948893+00', NULL);
INSERT INTO public.user_sessions VALUES (813, 3, '428a36e8-a706-40fe-a884-e171778a299f', NULL, NULL, '2026-03-27 12:40:41.797891+00', '2026-04-26 12:40:41.797891+00', NULL);
INSERT INTO public.user_sessions VALUES (814, 3, '6f658744-695e-4bed-8ecb-2ad80b9728dc', NULL, NULL, '2026-03-27 12:45:34.034144+00', '2026-04-26 12:45:34.034144+00', NULL);
INSERT INTO public.user_sessions VALUES (815, 3, '1b668292-14c2-42ba-a79d-7c8e6882b76a', NULL, NULL, '2026-03-27 12:46:07.689001+00', '2026-04-26 12:46:07.689001+00', NULL);
INSERT INTO public.user_sessions VALUES (816, 3, 'f1302d18-d0af-4bd7-8cd9-602f61bc3287', NULL, NULL, '2026-03-27 12:47:25.745506+00', '2026-04-26 12:47:25.745506+00', NULL);
INSERT INTO public.user_sessions VALUES (817, 3, '57d24996-c161-47ff-9a09-151a35ad1d49', NULL, NULL, '2026-03-27 12:49:39.731163+00', '2026-04-26 12:49:39.731163+00', NULL);
INSERT INTO public.user_sessions VALUES (818, 3, 'bc3792a8-464d-4ef4-bd79-5ebbc3e4d901', NULL, NULL, '2026-03-27 12:51:50.512141+00', '2026-04-26 12:51:50.512141+00', NULL);
INSERT INTO public.user_sessions VALUES (819, 3, '81fce659-d99f-438a-bb9b-65a9e1583080', NULL, NULL, '2026-03-27 12:52:39.568194+00', '2026-04-26 12:52:39.568194+00', NULL);
INSERT INTO public.user_sessions VALUES (820, 3, '11587a00-e606-438f-9886-48f0b54822b3', NULL, NULL, '2026-03-27 12:53:15.442849+00', '2026-04-26 12:53:15.442849+00', NULL);
INSERT INTO public.user_sessions VALUES (821, 3, '45e9c7a3-5c0f-4315-8816-ff929fa73fab', NULL, NULL, '2026-03-27 13:06:49.755957+00', '2026-04-26 13:06:49.755957+00', NULL);
INSERT INTO public.user_sessions VALUES (822, 3, '5e6b861e-6aee-4b8a-9944-bac915e01bf0', NULL, NULL, '2026-03-27 15:39:13.49446+00', '2026-04-26 15:39:13.49446+00', NULL);
INSERT INTO public.user_sessions VALUES (823, 3, '126d76e4-7d9e-426d-871c-7502e76348c0', NULL, NULL, '2026-03-27 17:09:47.8998+00', '2026-04-26 17:09:47.8998+00', NULL);
INSERT INTO public.user_sessions VALUES (824, 3, 'bf03b3f6-60e0-49f8-8140-6e4b9b019cf2', NULL, NULL, '2026-03-28 11:27:34.586916+00', '2026-04-27 11:27:34.586916+00', NULL);
INSERT INTO public.user_sessions VALUES (825, 3, 'a72791ab-8236-43ab-9057-5f027c7ee4fe', NULL, NULL, '2026-03-28 11:38:42.30042+00', '2026-04-27 11:38:42.30042+00', NULL);
INSERT INTO public.user_sessions VALUES (826, 3, '40a9431a-6a93-4c66-b674-c3130d1b6dd8', NULL, NULL, '2026-03-28 11:40:39.643177+00', '2026-04-27 11:40:39.643177+00', NULL);
INSERT INTO public.user_sessions VALUES (827, 3, '407e1703-a6cc-45a9-b911-ee97bf5808ac', NULL, NULL, '2026-03-28 12:06:35.758158+00', '2026-04-27 12:06:35.758158+00', NULL);
INSERT INTO public.user_sessions VALUES (828, 3, '77d63758-8483-48fa-964a-90592b6c34ed', NULL, NULL, '2026-03-28 12:10:22.884852+00', '2026-04-27 12:10:22.884852+00', NULL);
INSERT INTO public.user_sessions VALUES (829, 3, '29a462c3-567a-4e81-bc95-eab89f4bb49b', NULL, NULL, '2026-03-28 12:15:18.380692+00', '2026-04-27 12:15:18.380692+00', NULL);
INSERT INTO public.user_sessions VALUES (830, 3, '44c9920e-3cf1-4056-acc6-7ed08b3c44da', NULL, NULL, '2026-03-28 12:33:09.861943+00', '2026-04-27 12:33:09.861943+00', NULL);
INSERT INTO public.user_sessions VALUES (831, 3, 'db5a3aa4-cce1-4251-be24-6ca5eef34e23', NULL, NULL, '2026-03-28 12:49:03.766836+00', '2026-04-27 12:49:03.766836+00', NULL);
INSERT INTO public.user_sessions VALUES (832, 3, 'd1c557b0-c711-4473-8280-31fba1345be3', NULL, NULL, '2026-03-28 12:51:29.822581+00', '2026-04-27 12:51:29.822581+00', NULL);
INSERT INTO public.user_sessions VALUES (833, 3, 'a59125be-d65f-4c54-9395-37b465c9491c', NULL, NULL, '2026-03-28 12:53:29.793206+00', '2026-04-27 12:53:29.793206+00', NULL);
INSERT INTO public.user_sessions VALUES (834, 3, '90187ac6-9e6a-4bce-a3be-835acbe4277b', NULL, NULL, '2026-03-28 12:56:12.628074+00', '2026-04-27 12:56:12.628074+00', NULL);
INSERT INTO public.user_sessions VALUES (835, 3, '45f1f048-829c-4034-a133-2b93622e8046', NULL, NULL, '2026-03-28 12:56:28.448085+00', '2026-04-27 12:56:28.448085+00', NULL);
INSERT INTO public.user_sessions VALUES (836, 3, 'a6cfd731-8cf5-4037-a310-8c2e8c024b87', NULL, NULL, '2026-03-28 12:57:43.253676+00', '2026-04-27 12:57:43.253676+00', NULL);
INSERT INTO public.user_sessions VALUES (837, 3, '42569414-f43a-4c98-89c0-6d359633914e', NULL, NULL, '2026-03-28 13:02:19.849862+00', '2026-04-27 13:02:19.849862+00', NULL);
INSERT INTO public.user_sessions VALUES (838, 3, '029a100e-645b-4417-9519-5cb93536af60', NULL, NULL, '2026-03-28 13:03:10.410209+00', '2026-04-27 13:03:10.410209+00', NULL);
INSERT INTO public.user_sessions VALUES (839, 3, 'ba81b8b8-5e4c-4219-a139-02a49c0bd896', NULL, NULL, '2026-03-28 13:13:46.216998+00', '2026-04-27 13:13:46.216998+00', NULL);
INSERT INTO public.user_sessions VALUES (840, 3, '9fde5acb-dbf3-4af2-8be0-44a35849543d', NULL, NULL, '2026-03-28 13:18:09.859395+00', '2026-04-27 13:18:09.859395+00', NULL);
INSERT INTO public.user_sessions VALUES (841, 3, 'efa80719-0e80-4ade-8079-0b818b861d10', NULL, NULL, '2026-03-28 13:23:59.650349+00', '2026-04-27 13:23:59.650349+00', NULL);
INSERT INTO public.user_sessions VALUES (842, 3, '478cbf9c-b4ca-4427-b1a6-5f16bfe9548d', NULL, NULL, '2026-03-28 13:33:38.319995+00', '2026-04-27 13:33:38.319995+00', NULL);
INSERT INTO public.user_sessions VALUES (843, 3, 'f7cbf21d-24af-4cd4-86fe-66d36b9a0009', NULL, NULL, '2026-03-28 13:52:32.37818+00', '2026-04-27 13:52:32.37818+00', NULL);
INSERT INTO public.user_sessions VALUES (844, 3, '832b5bce-c111-461f-8f02-ab61db16e330', NULL, NULL, '2026-03-28 16:35:48.031718+00', '2026-04-27 16:35:48.031718+00', NULL);
INSERT INTO public.user_sessions VALUES (845, 3, '21d09bbf-a4f7-410c-aad5-b9a0d7b7c72e', NULL, NULL, '2026-03-28 16:44:19.742892+00', '2026-04-27 16:44:19.742892+00', NULL);
INSERT INTO public.user_sessions VALUES (846, 3, 'f203e6cb-9826-4517-89c8-fb1eaa909062', NULL, NULL, '2026-03-28 17:38:56.040632+00', '2026-04-27 17:38:56.040632+00', NULL);
INSERT INTO public.user_sessions VALUES (847, 4, '60a5bd04-13bb-4c78-9785-346e55255efa', NULL, NULL, '2026-03-28 17:42:19.897387+00', '2026-04-27 17:42:19.897387+00', NULL);
INSERT INTO public.user_sessions VALUES (848, 3, 'da9b1ae3-cb37-4c53-aa2c-e0c6134eaff5', NULL, NULL, '2026-03-28 18:04:40.989911+00', '2026-04-27 18:04:40.989911+00', NULL);
INSERT INTO public.user_sessions VALUES (849, 3, '65c6b8f6-eda0-44ce-8336-898f6fbbe2c4', NULL, NULL, '2026-03-28 20:45:32.919205+00', '2026-04-27 20:45:32.919205+00', NULL);
INSERT INTO public.user_sessions VALUES (850, 3, '30139958-6b8e-4c7c-bb81-0f84a0e0ab1c', NULL, NULL, '2026-03-28 20:50:21.137609+00', '2026-04-27 20:50:21.137609+00', NULL);
INSERT INTO public.user_sessions VALUES (851, 3, '9cd6c980-a784-4f2d-baaa-3a44686139ed', NULL, NULL, '2026-03-28 20:55:34.748919+00', '2026-04-27 20:55:34.748919+00', NULL);
INSERT INTO public.user_sessions VALUES (852, 3, '49647f20-285d-4d8c-a335-c9bea1fe80e4', NULL, NULL, '2026-03-28 21:25:42.500808+00', '2026-04-27 21:25:42.500808+00', NULL);
INSERT INTO public.user_sessions VALUES (853, 3, 'a08b91cf-91b2-49e9-a5ac-fe90dbb3124c', NULL, NULL, '2026-03-28 21:30:18.047056+00', '2026-04-27 21:30:18.047056+00', NULL);
INSERT INTO public.user_sessions VALUES (854, 3, '1be6950a-4222-46c8-9bee-ec2f2f4e51de', NULL, NULL, '2026-03-28 21:32:37.434796+00', '2026-04-27 21:32:37.434796+00', NULL);
INSERT INTO public.user_sessions VALUES (855, 3, '263ec621-100f-4fe1-b5f0-13151b6762a9', NULL, NULL, '2026-03-28 21:33:34.422688+00', '2026-04-27 21:33:34.422688+00', NULL);
INSERT INTO public.user_sessions VALUES (856, 3, '3543a892-865d-4375-9758-f6aaa8ee3fe1', NULL, NULL, '2026-03-28 21:35:12.405669+00', '2026-04-27 21:35:12.405669+00', NULL);
INSERT INTO public.user_sessions VALUES (857, 3, 'c230fc5d-a17c-407b-ad8c-2800af2a9962', NULL, NULL, '2026-03-28 22:00:59.451896+00', '2026-04-27 22:00:59.451896+00', NULL);
INSERT INTO public.user_sessions VALUES (858, 3, '6ed16cfd-1c96-4c22-9285-f572699f397b', NULL, NULL, '2026-03-28 22:03:27.035503+00', '2026-04-27 22:03:27.035503+00', NULL);
INSERT INTO public.user_sessions VALUES (859, 3, '8ed03f67-e4e8-443b-99a1-e0d76e057644', NULL, NULL, '2026-03-29 08:25:10.706069+00', '2026-04-28 08:25:10.706069+00', NULL);
INSERT INTO public.user_sessions VALUES (860, 3, 'be4c7c12-8443-498e-8ced-2fc752c437d6', NULL, NULL, '2026-03-29 08:28:56.944407+00', '2026-04-28 08:28:56.944407+00', NULL);
INSERT INTO public.user_sessions VALUES (861, 3, '2b809edb-bcc3-4aa2-9c44-2b13ee413281', NULL, NULL, '2026-03-29 11:54:55.804766+00', '2026-04-28 11:54:55.804766+00', NULL);
INSERT INTO public.user_sessions VALUES (862, 3, '75a5fa09-11a3-4cbf-9c6e-96a389c6e55c', NULL, NULL, '2026-03-29 11:58:23.388285+00', '2026-04-28 11:58:23.388285+00', NULL);
INSERT INTO public.user_sessions VALUES (863, 3, '966cb995-3070-4943-b2eb-bd731038b8dc', NULL, NULL, '2026-03-29 12:03:30.991603+00', '2026-04-28 12:03:30.991603+00', NULL);
INSERT INTO public.user_sessions VALUES (864, 3, '2dff8dea-29c0-4d31-992a-75bca3d3ea4a', NULL, NULL, '2026-03-29 12:08:37.294806+00', '2026-04-28 12:08:37.294806+00', NULL);
INSERT INTO public.user_sessions VALUES (865, 3, '6b6f0973-981c-4598-a7dc-3dbebba0cecf', NULL, NULL, '2026-03-29 12:31:04.140683+00', '2026-04-28 12:31:04.140683+00', NULL);
INSERT INTO public.user_sessions VALUES (866, 3, '3405fdd9-f5ae-463a-a73a-33b9854958cd', NULL, NULL, '2026-03-29 12:31:14.757706+00', '2026-04-28 12:31:14.757706+00', NULL);
INSERT INTO public.user_sessions VALUES (867, 3, '848a75ed-3baa-41da-a0ec-73bee26db928', NULL, NULL, '2026-03-29 12:35:49.410073+00', '2026-04-28 12:35:49.410073+00', NULL);
INSERT INTO public.user_sessions VALUES (868, 4, 'b44f87f1-fe0e-4d6f-89fd-385904fa3fe1', NULL, NULL, '2026-03-29 12:36:05.070436+00', '2026-04-28 12:36:05.070436+00', NULL);
INSERT INTO public.user_sessions VALUES (869, 3, 'b5f2128b-e68a-492c-a6ea-88e14f2559dd', NULL, NULL, '2026-03-29 12:44:08.029+00', '2026-04-28 12:44:08.029+00', NULL);
INSERT INTO public.user_sessions VALUES (870, 3, 'd471b0a7-bd6e-4a98-829d-eba37480d7f3', NULL, NULL, '2026-03-29 12:46:10.025793+00', '2026-04-28 12:46:10.025793+00', NULL);
INSERT INTO public.user_sessions VALUES (871, 3, '2bf2566e-f9a9-4cf7-9d61-500c7db5131a', NULL, NULL, '2026-03-29 13:22:37.334906+00', '2026-04-28 13:22:37.334906+00', NULL);
INSERT INTO public.user_sessions VALUES (872, 3, '6d859fd7-8624-4fc3-97c7-9c3d16b7177b', NULL, NULL, '2026-03-29 13:24:01.134489+00', '2026-04-28 13:24:01.134489+00', NULL);
INSERT INTO public.user_sessions VALUES (873, 3, '79c2060c-9d80-4b6e-8e3c-e11f0cde8188', NULL, NULL, '2026-03-29 13:25:12.342616+00', '2026-04-28 13:25:12.342616+00', NULL);
INSERT INTO public.user_sessions VALUES (874, 3, '875bd3cc-1703-47e2-ae30-e55ec6e450e9', NULL, NULL, '2026-03-29 13:47:49.23446+00', '2026-04-28 13:47:49.23446+00', NULL);
INSERT INTO public.user_sessions VALUES (875, 3, '7e38e350-5af5-4ccd-9bc9-d2ed06876c26', NULL, NULL, '2026-03-29 13:49:56.898762+00', '2026-04-28 13:49:56.898762+00', NULL);
INSERT INTO public.user_sessions VALUES (876, 3, '9cdb5556-8135-4e89-9da3-71b42120000e', NULL, NULL, '2026-03-29 13:52:05.648899+00', '2026-04-28 13:52:05.648899+00', NULL);
INSERT INTO public.user_sessions VALUES (877, 3, '3a588271-f00b-4506-a90d-eb0942ca3f6c', NULL, NULL, '2026-03-29 15:38:30.91362+00', '2026-04-28 15:38:30.91362+00', NULL);
INSERT INTO public.user_sessions VALUES (878, 3, '3c306ebc-5040-423e-8510-3f6a9526b37a', NULL, NULL, '2026-03-29 15:38:51.508102+00', '2026-04-28 15:38:51.508102+00', NULL);
INSERT INTO public.user_sessions VALUES (879, 3, '9c90f07f-6b60-42f1-9436-998f9ed4e5db', NULL, NULL, '2026-03-29 16:09:49.11445+00', '2026-04-28 16:09:49.11445+00', NULL);
INSERT INTO public.user_sessions VALUES (880, 3, 'ee8ad72b-43fc-4468-ade0-5b0f2d3b21c0', NULL, NULL, '2026-03-29 16:17:07.107102+00', '2026-04-28 16:17:07.107102+00', NULL);
INSERT INTO public.user_sessions VALUES (881, 3, '43fdb263-5e3b-4d33-9ef3-c18b7694c2a9', NULL, NULL, '2026-03-29 16:24:28.345548+00', '2026-04-28 16:24:28.345548+00', NULL);
INSERT INTO public.user_sessions VALUES (882, 3, '34f113ff-8f5d-4bd5-ad83-9e0e2f69530e', NULL, NULL, '2026-03-29 16:25:09.482964+00', '2026-04-28 16:25:09.482964+00', NULL);
INSERT INTO public.user_sessions VALUES (883, 3, 'fd2802f5-a787-4767-97fd-9d0d3a6a1cdc', NULL, NULL, '2026-03-29 16:38:56.51304+00', '2026-04-28 16:38:56.51304+00', NULL);
INSERT INTO public.user_sessions VALUES (884, 3, '95c2687b-3a32-4a9f-8eb7-3f5c58457d4a', NULL, NULL, '2026-03-29 16:50:26.723667+00', '2026-04-28 16:50:26.723667+00', NULL);
INSERT INTO public.user_sessions VALUES (885, 3, '1113b109-2faf-4e22-b990-2824289d87bb', NULL, NULL, '2026-03-29 17:23:42.372731+00', '2026-04-28 17:23:42.372731+00', NULL);
INSERT INTO public.user_sessions VALUES (886, 4, '5e5c940a-4381-4ee9-b279-880802d84d88', NULL, NULL, '2026-03-29 17:24:10.889006+00', '2026-04-28 17:24:10.889006+00', NULL);
INSERT INTO public.user_sessions VALUES (887, 3, 'aa8a0702-4d86-4db7-be51-ef600469b688', NULL, NULL, '2026-03-29 17:50:26.512696+00', '2026-04-28 17:50:26.512696+00', NULL);
INSERT INTO public.user_sessions VALUES (888, 3, 'b29d6811-ef24-4bc9-ae47-6e5d3b292820', NULL, NULL, '2026-03-29 17:50:37.073566+00', '2026-04-28 17:50:37.073566+00', NULL);
INSERT INTO public.user_sessions VALUES (889, 3, 'f80ec0b9-f45d-4341-bca8-c4792c8fc831', NULL, NULL, '2026-03-29 18:41:36.191213+00', '2026-04-28 18:41:36.191213+00', NULL);
INSERT INTO public.user_sessions VALUES (890, 3, 'ff9b6b12-d5be-43fd-b075-cc80cd06ed1c', NULL, NULL, '2026-03-29 18:44:12.679191+00', '2026-04-28 18:44:12.679191+00', NULL);
INSERT INTO public.user_sessions VALUES (891, 3, '216f59b4-e45c-4bde-b069-cab3c2d81a00', NULL, NULL, '2026-03-29 18:51:16.588775+00', '2026-04-28 18:51:16.588775+00', NULL);
INSERT INTO public.user_sessions VALUES (892, 3, 'a0329c55-c0f9-4705-af2c-f0bb75c66b34', NULL, NULL, '2026-03-29 18:53:15.52856+00', '2026-04-28 18:53:15.52856+00', NULL);
INSERT INTO public.user_sessions VALUES (893, 3, '11f53dbb-bb37-4b14-bb12-5b433ce5acaf', NULL, NULL, '2026-03-29 18:57:40.497718+00', '2026-04-28 18:57:40.497718+00', NULL);
INSERT INTO public.user_sessions VALUES (894, 3, 'ce95f6f0-e1b6-40c0-a423-9a0a949179cd', NULL, NULL, '2026-03-29 18:57:59.768229+00', '2026-04-28 18:57:59.768229+00', NULL);
INSERT INTO public.user_sessions VALUES (895, 3, '8bed817b-1a2d-4075-aa1c-bdd39195f961', NULL, NULL, '2026-03-29 19:17:55.814313+00', '2026-04-28 19:17:55.814313+00', NULL);
INSERT INTO public.user_sessions VALUES (896, 3, '18dfef10-4f95-498e-a1e6-77b29cd3d501', NULL, NULL, '2026-03-29 19:23:47.418676+00', '2026-04-28 19:23:47.418676+00', NULL);
INSERT INTO public.user_sessions VALUES (897, 3, 'e0bf7830-c542-41c2-bd36-172a25e7c1f4', NULL, NULL, '2026-03-29 19:30:26.746667+00', '2026-04-28 19:30:26.746667+00', NULL);
INSERT INTO public.user_sessions VALUES (898, 3, '324df5f5-b32d-4ebd-b55a-11d9f9fdbf68', NULL, NULL, '2026-03-29 19:31:03.807887+00', '2026-04-28 19:31:03.807887+00', NULL);
INSERT INTO public.user_sessions VALUES (899, 3, '399773ab-3034-4c44-8a4f-a6919136e7cd', NULL, NULL, '2026-03-29 19:58:03.629937+00', '2026-04-28 19:58:03.629937+00', NULL);
INSERT INTO public.user_sessions VALUES (900, 3, '22bac16f-d0f5-482b-a467-62ccbf65c3b6', NULL, NULL, '2026-03-29 20:14:42.450116+00', '2026-04-28 20:14:42.450116+00', NULL);
INSERT INTO public.user_sessions VALUES (901, 3, '1cdf02ff-99e9-4bfe-a2e1-20ef7bd969e2', NULL, NULL, '2026-03-30 10:43:56.332285+00', '2026-04-29 10:43:56.332285+00', NULL);
INSERT INTO public.user_sessions VALUES (902, 3, 'ce6ae892-b7d5-458b-ad97-45986e6fa9ea', NULL, NULL, '2026-03-30 10:57:23.785539+00', '2026-04-29 10:57:23.785539+00', NULL);
INSERT INTO public.user_sessions VALUES (903, 3, '582846bd-63fa-4580-b8a5-c3a25c0cd3ba', NULL, NULL, '2026-03-30 17:27:26.676737+00', '2026-04-29 17:27:26.676737+00', NULL);
INSERT INTO public.user_sessions VALUES (904, 3, '448f6160-38f7-45bb-9c81-17ddf0b03c20', NULL, NULL, '2026-03-30 17:28:28.382717+00', '2026-04-29 17:28:28.382717+00', NULL);
INSERT INTO public.user_sessions VALUES (905, 3, '4b095963-93c5-4269-8433-40ff03223440', NULL, NULL, '2026-03-30 19:28:29.715491+00', '2026-04-29 19:28:29.715491+00', NULL);
INSERT INTO public.user_sessions VALUES (906, 3, 'd0c3a093-1acd-4d4f-8a7c-5640de7e3eb1', NULL, NULL, '2026-03-30 19:31:51.901715+00', '2026-04-29 19:31:51.901715+00', NULL);
INSERT INTO public.user_sessions VALUES (907, 3, '59300325-3b6e-4a0b-a9ed-63bbd754bafd', NULL, NULL, '2026-03-30 19:32:35.570328+00', '2026-04-29 19:32:35.570328+00', NULL);
INSERT INTO public.user_sessions VALUES (908, 3, 'ea9848bb-b9dc-4171-aaea-d35195d2c159', NULL, NULL, '2026-03-30 19:39:51.35304+00', '2026-04-29 19:39:51.35304+00', NULL);
INSERT INTO public.user_sessions VALUES (909, 3, '7a8289fb-7e50-47f3-ba29-89a5665c818e', NULL, NULL, '2026-03-30 19:40:26.509224+00', '2026-04-29 19:40:26.509224+00', NULL);
INSERT INTO public.user_sessions VALUES (910, 3, '0506597e-9bf5-4265-bf76-19ce092b1a12', NULL, NULL, '2026-03-30 19:41:11.139212+00', '2026-04-29 19:41:11.139212+00', NULL);
INSERT INTO public.user_sessions VALUES (911, 3, '41fa83f8-120f-427c-8acc-958d767d31e7', NULL, NULL, '2026-03-30 19:45:32.565318+00', '2026-04-29 19:45:32.565318+00', NULL);
INSERT INTO public.user_sessions VALUES (912, 3, '698cd3e1-9f03-46ac-954a-f7fe6eaad331', NULL, NULL, '2026-03-31 09:23:12.786386+00', '2026-04-30 09:23:12.786386+00', NULL);
INSERT INTO public.user_sessions VALUES (913, 3, '440763d4-8582-45bc-9e90-19ed23c16749', NULL, NULL, '2026-03-31 10:23:00.315123+00', '2026-04-30 10:23:00.315123+00', NULL);
INSERT INTO public.user_sessions VALUES (914, 3, '59505fe5-b304-4bcb-9939-9c4fb57bd1d0', NULL, NULL, '2026-03-31 13:51:08.578975+00', '2026-04-30 13:51:08.578975+00', NULL);
INSERT INTO public.user_sessions VALUES (915, 3, '591ed98b-bc2a-4293-9d3a-a8d3c6b91949', NULL, NULL, '2026-03-31 13:52:33.310458+00', '2026-04-30 13:52:33.310458+00', NULL);
INSERT INTO public.user_sessions VALUES (916, 3, 'bd43d7b7-07a1-49f5-ad48-f8677fe5ddde', NULL, NULL, '2026-03-31 14:08:38.062146+00', '2026-04-30 14:08:38.062146+00', NULL);
INSERT INTO public.user_sessions VALUES (917, 3, '7ee7e5a1-2d80-4bb1-9b42-8924d8e77028', NULL, NULL, '2026-03-31 14:08:56.845108+00', '2026-04-30 14:08:56.845108+00', NULL);
INSERT INTO public.user_sessions VALUES (918, 3, '3c77a1fa-fbfb-4780-bc45-dcc31b7ed88f', NULL, NULL, '2026-03-31 14:28:36.153554+00', '2026-04-30 14:28:36.153554+00', NULL);
INSERT INTO public.user_sessions VALUES (919, 3, 'bba14f32-acf2-43ff-9140-778882347bbf', NULL, NULL, '2026-03-31 14:31:49.728869+00', '2026-04-30 14:31:49.728869+00', NULL);
INSERT INTO public.user_sessions VALUES (920, 3, '3e14e5ef-35ae-4162-a84e-d969750b8dbc', NULL, NULL, '2026-03-31 15:44:18.230725+00', '2026-04-30 15:44:18.230725+00', NULL);
INSERT INTO public.user_sessions VALUES (921, 3, '4a92d0fe-b219-49dc-8523-fd0c185f5ac8', NULL, NULL, '2026-03-31 15:47:56.793208+00', '2026-04-30 15:47:56.793208+00', NULL);
INSERT INTO public.user_sessions VALUES (922, 3, '01da5332-210b-42a0-8481-9bec467d5334', NULL, NULL, '2026-03-31 15:48:20.918136+00', '2026-04-30 15:48:20.918136+00', NULL);
INSERT INTO public.user_sessions VALUES (923, 3, '74bdbb98-2b33-483a-8bff-38d0df15d3c3', NULL, NULL, '2026-03-31 15:52:39.027829+00', '2026-04-30 15:52:39.027829+00', NULL);
INSERT INTO public.user_sessions VALUES (924, 3, 'c011e3b4-e2e7-43e0-a77c-719ef062f0f8', NULL, NULL, '2026-03-31 16:23:23.22105+00', '2026-04-30 16:23:23.22105+00', NULL);
INSERT INTO public.user_sessions VALUES (925, 3, 'c48b0e2c-efe3-4a2a-8866-3b4b3b2137da', NULL, NULL, '2026-03-31 16:24:38.436312+00', '2026-04-30 16:24:38.436312+00', NULL);
INSERT INTO public.user_sessions VALUES (926, 3, 'b1b54817-7d25-4dc6-85e8-58a60feed7b4', NULL, NULL, '2026-03-31 16:26:50.713953+00', '2026-04-30 16:26:50.713953+00', NULL);
INSERT INTO public.user_sessions VALUES (927, 3, '7b9c1c44-dea7-4bbd-8cfa-c3a76b67de7b', NULL, NULL, '2026-03-31 17:17:38.92479+00', '2026-04-30 17:17:38.92479+00', NULL);
INSERT INTO public.user_sessions VALUES (928, 3, '209243a9-eff1-4664-bd93-1a30bd7da2d0', NULL, NULL, '2026-03-31 17:17:53.318696+00', '2026-04-30 17:17:53.318696+00', NULL);
INSERT INTO public.user_sessions VALUES (929, 3, '520094c7-bb60-4249-9159-436029ec0dde', NULL, NULL, '2026-03-31 17:19:08.000334+00', '2026-04-30 17:19:08.000334+00', NULL);
INSERT INTO public.user_sessions VALUES (930, 3, '71db2bfc-55ef-4f04-8380-6da645b922a7', NULL, NULL, '2026-03-31 17:32:27.922517+00', '2026-04-30 17:32:27.922517+00', NULL);
INSERT INTO public.user_sessions VALUES (931, 3, 'e667717d-ad5a-40b6-b96b-4b9bb87fc118', NULL, NULL, '2026-03-31 17:36:17.787978+00', '2026-04-30 17:36:17.787978+00', NULL);
INSERT INTO public.user_sessions VALUES (936, 3, 'ad74ca80-ccef-4ee8-aad6-16bd88d989df', NULL, NULL, '2026-03-31 20:15:53.528191+00', '2026-04-30 20:15:53.528191+00', NULL);
INSERT INTO public.user_sessions VALUES (932, 3, '33642752-cd5d-4a0a-a0ba-6bc343092bec', NULL, NULL, '2026-03-31 17:44:53.596873+00', '2026-04-30 17:44:53.596873+00', NULL);
INSERT INTO public.user_sessions VALUES (933, 3, 'd2ce01a0-8f07-4458-b676-2d844f4d9320', NULL, NULL, '2026-03-31 17:45:25.319208+00', '2026-04-30 17:45:25.319208+00', NULL);
INSERT INTO public.user_sessions VALUES (934, 3, '8fd4cafd-ddb3-4d96-9d3c-db56ecec79d5', NULL, NULL, '2026-03-31 17:45:33.369434+00', '2026-04-30 17:45:33.369434+00', NULL);
INSERT INTO public.user_sessions VALUES (935, 3, '9079e1fc-35dd-4266-8bf0-68a3d265d802', NULL, NULL, '2026-03-31 18:16:54.046334+00', '2026-04-30 18:16:54.046334+00', NULL);
INSERT INTO public.user_sessions VALUES (937, 3, 'f992cca2-e91d-458d-8cc8-fe547749a1e1', NULL, NULL, '2026-04-01 08:24:28.669501+00', '2026-05-01 08:24:28.669501+00', NULL);
INSERT INTO public.user_sessions VALUES (938, 3, 'c19cfeab-75a1-4572-872e-3b09f0e9a149', NULL, NULL, '2026-04-01 08:38:58.66228+00', '2026-05-01 08:38:58.66228+00', NULL);
INSERT INTO public.user_sessions VALUES (939, 3, '1a47cdf7-e520-4dce-8f43-eb1e61529077', NULL, NULL, '2026-04-01 08:40:42.491056+00', '2026-05-01 08:40:42.491056+00', NULL);
INSERT INTO public.user_sessions VALUES (940, 3, 'ae730a35-d4db-4e7e-9072-59d249b19a41', NULL, NULL, '2026-04-01 09:01:29.747161+00', '2026-05-01 09:01:29.747161+00', NULL);
INSERT INTO public.user_sessions VALUES (941, 3, '2d97807f-2582-477f-b2b6-df4ad4b53fb2', NULL, NULL, '2026-04-01 09:49:23.441476+00', '2026-05-01 09:49:23.441476+00', NULL);
INSERT INTO public.user_sessions VALUES (942, 3, '68af0ba0-2558-4d18-85dd-e19aa68dbe53', NULL, NULL, '2026-04-01 09:49:52.816277+00', '2026-05-01 09:49:52.816277+00', NULL);
INSERT INTO public.user_sessions VALUES (943, 3, '493427a8-9dea-465e-ba50-4bb476e610c1', NULL, NULL, '2026-04-01 10:12:30.666806+00', '2026-05-01 10:12:30.666806+00', NULL);
INSERT INTO public.user_sessions VALUES (944, 3, '4cf871ce-9f30-402f-be64-e7fc266dc907', NULL, NULL, '2026-04-01 11:35:42.542476+00', '2026-05-01 11:35:42.542476+00', NULL);
INSERT INTO public.user_sessions VALUES (945, 3, 'fb652c28-5be0-4e53-8244-f1d785381378', NULL, NULL, '2026-04-01 11:41:43.364818+00', '2026-05-01 11:41:43.364818+00', NULL);
INSERT INTO public.user_sessions VALUES (946, 3, 'fca36c07-98c3-4321-a2d0-aade7c86a08d', NULL, NULL, '2026-04-01 11:58:53.163395+00', '2026-05-01 11:58:53.163395+00', NULL);
INSERT INTO public.user_sessions VALUES (947, 3, 'c834aa20-0ce0-4a99-91fe-fc90fca8939d', NULL, NULL, '2026-04-01 12:07:17.029142+00', '2026-05-01 12:07:17.029142+00', NULL);
INSERT INTO public.user_sessions VALUES (948, 3, '420c7e0d-6f52-4836-8c48-bdbd1703bddd', NULL, NULL, '2026-04-01 12:22:30.426358+00', '2026-05-01 12:22:30.426358+00', NULL);
INSERT INTO public.user_sessions VALUES (949, 3, 'a3931360-556f-4ef3-8074-8b3033d47c71', NULL, NULL, '2026-04-01 12:26:16.406508+00', '2026-05-01 12:26:16.406508+00', NULL);
INSERT INTO public.user_sessions VALUES (950, 3, '29d03be2-053d-428a-a514-f0f825f66080', NULL, NULL, '2026-04-01 12:50:02.232277+00', '2026-05-01 12:50:02.232277+00', NULL);
INSERT INTO public.user_sessions VALUES (951, 3, 'f826a0d2-3d8b-423b-ba62-44d7b71c7156', NULL, NULL, '2026-04-01 13:18:13.530954+00', '2026-05-01 13:18:13.530954+00', NULL);
INSERT INTO public.user_sessions VALUES (952, 3, 'f1028e6b-56b2-4e8b-b12d-8e612f3da943', NULL, NULL, '2026-04-01 13:25:32.443963+00', '2026-05-01 13:25:32.443963+00', NULL);
INSERT INTO public.user_sessions VALUES (953, 3, '6982ea30-a223-451b-9c97-7ccfc769d411', NULL, NULL, '2026-04-01 13:25:56.357933+00', '2026-05-01 13:25:56.357933+00', NULL);
INSERT INTO public.user_sessions VALUES (954, 3, 'b586c42f-7128-4d84-8651-0658b1a18b47', NULL, NULL, '2026-04-01 13:26:04.630858+00', '2026-05-01 13:26:04.630858+00', NULL);
INSERT INTO public.user_sessions VALUES (955, 3, 'c61b59ef-b9ca-4137-b2af-062ad4dcb3c0', NULL, NULL, '2026-04-01 13:41:44.294211+00', '2026-05-01 13:41:44.294211+00', NULL);
INSERT INTO public.user_sessions VALUES (956, 3, '61ab0649-68cf-45bd-a45f-00d8889e6487', NULL, NULL, '2026-04-01 14:36:30.789498+00', '2026-05-01 14:36:30.789498+00', NULL);
INSERT INTO public.user_sessions VALUES (957, 3, 'b232ad3c-d444-4d08-876f-52a2b804393e', NULL, NULL, '2026-04-01 14:37:04.350427+00', '2026-05-01 14:37:04.350427+00', NULL);
INSERT INTO public.user_sessions VALUES (958, 3, '79d0571e-9791-498b-b26b-8afa7876731e', NULL, NULL, '2026-04-01 14:41:04.625411+00', '2026-05-01 14:41:04.625411+00', NULL);
INSERT INTO public.user_sessions VALUES (959, 3, '2cfaa4ba-8390-4f04-a70b-df98ab5135e3', NULL, NULL, '2026-04-01 14:59:31.828951+00', '2026-05-01 14:59:31.828951+00', NULL);
INSERT INTO public.user_sessions VALUES (960, 3, '5c7933a9-4b36-4eaa-8cc9-237bb41405c9', NULL, NULL, '2026-04-01 14:59:42.613749+00', '2026-05-01 14:59:42.613749+00', NULL);
INSERT INTO public.user_sessions VALUES (961, 3, '5a23ce0a-6df5-4c5d-94c9-699cd7063e60', NULL, NULL, '2026-04-01 15:05:41.429925+00', '2026-05-01 15:05:41.429925+00', NULL);
INSERT INTO public.user_sessions VALUES (962, 3, '234bad61-4e64-46f3-8bc8-2f4a00a8b915', NULL, NULL, '2026-04-01 15:05:55.074215+00', '2026-05-01 15:05:55.074215+00', NULL);
INSERT INTO public.user_sessions VALUES (963, 3, '4aeb895a-a21f-4974-87d4-3aafaa0c9fd0', NULL, NULL, '2026-04-01 15:16:29.688361+00', '2026-05-01 15:16:29.688361+00', NULL);
INSERT INTO public.user_sessions VALUES (964, 3, '495e11dc-5a8c-41a5-b0a9-954475d97fba', NULL, NULL, '2026-04-01 15:16:45.54297+00', '2026-05-01 15:16:45.54297+00', NULL);
INSERT INTO public.user_sessions VALUES (965, 3, '2dd65787-1825-4b75-bc24-743fb21eacee', NULL, NULL, '2026-04-01 15:16:58.605164+00', '2026-05-01 15:16:58.605164+00', NULL);
INSERT INTO public.user_sessions VALUES (966, 3, '7a423fcd-9477-40a5-ad1d-7a00c70a5a00', NULL, NULL, '2026-04-01 15:22:43.039929+00', '2026-05-01 15:22:43.039929+00', NULL);
INSERT INTO public.user_sessions VALUES (967, 3, '224015a1-1e2d-4137-8974-ee64d64a530a', NULL, NULL, '2026-04-01 15:50:30.310778+00', '2026-05-01 15:50:30.310778+00', NULL);
INSERT INTO public.user_sessions VALUES (968, 3, '0cd1df80-5b9a-4eb1-9344-bdac1b337606', NULL, NULL, '2026-04-01 15:50:37.834462+00', '2026-05-01 15:50:37.834462+00', NULL);
INSERT INTO public.user_sessions VALUES (969, 3, '238f70cb-c867-475b-b380-db139843cd86', NULL, NULL, '2026-04-01 15:51:04.331215+00', '2026-05-01 15:51:04.331215+00', NULL);
INSERT INTO public.user_sessions VALUES (970, 3, '9904d6e8-b9f5-412d-95e1-8c6b5182c6aa', NULL, NULL, '2026-04-01 15:57:26.168867+00', '2026-05-01 15:57:26.168867+00', NULL);
INSERT INTO public.user_sessions VALUES (971, 3, '5b29a8e3-5127-45c0-8341-765760c82ddc', NULL, NULL, '2026-04-01 16:14:45.097638+00', '2026-05-01 16:14:45.097638+00', NULL);
INSERT INTO public.user_sessions VALUES (972, 3, 'dca8ec60-bc01-4add-9df5-ea64de069ce8', NULL, NULL, '2026-04-01 16:23:40.333119+00', '2026-05-01 16:23:40.333119+00', NULL);
INSERT INTO public.user_sessions VALUES (973, 3, '4a2d2615-30c7-4f21-ace0-f6d4aba474bb', NULL, NULL, '2026-04-01 18:52:28.715849+00', '2026-05-01 18:52:28.715849+00', NULL);
INSERT INTO public.user_sessions VALUES (974, 3, '4f30dc85-5666-485d-a3b8-50ccad127c5d', NULL, NULL, '2026-04-01 18:52:58.704077+00', '2026-05-01 18:52:58.704077+00', NULL);
INSERT INTO public.user_sessions VALUES (975, 3, '13638edf-28dc-4489-90aa-8a72ce3d777c', NULL, NULL, '2026-04-01 18:53:06.502095+00', '2026-05-01 18:53:06.502095+00', NULL);
INSERT INTO public.user_sessions VALUES (976, 3, 'b149d606-3b71-472c-8386-71e835d59496', NULL, NULL, '2026-04-01 18:53:15.936766+00', '2026-05-01 18:53:15.936766+00', NULL);
INSERT INTO public.user_sessions VALUES (977, 3, '27f4226d-80b7-4489-b7c3-594f33e785c1', NULL, NULL, '2026-04-01 19:02:48.189918+00', '2026-05-01 19:02:48.189918+00', NULL);
INSERT INTO public.user_sessions VALUES (978, 3, '808aed36-90df-486a-8602-a0c56b8d0ff1', NULL, NULL, '2026-04-01 19:03:02.025757+00', '2026-05-01 19:03:02.025757+00', NULL);
INSERT INTO public.user_sessions VALUES (979, 3, 'fd04fe2d-d420-4db8-b825-a5033f8383dc', NULL, NULL, '2026-04-01 19:33:11.263084+00', '2026-05-01 19:33:11.263084+00', NULL);
INSERT INTO public.user_sessions VALUES (980, 3, 'bbe10206-7efa-446b-828c-91e970615d7a', NULL, NULL, '2026-04-01 19:33:24.891394+00', '2026-05-01 19:33:24.891394+00', NULL);
INSERT INTO public.user_sessions VALUES (981, 3, '92205f26-5d86-451f-b1d5-82494e046ca4', NULL, NULL, '2026-04-01 19:51:24.327118+00', '2026-05-01 19:51:24.327118+00', NULL);
INSERT INTO public.user_sessions VALUES (982, 3, '2b80bebd-c2c2-4b78-b548-57e235ad31c4', NULL, NULL, '2026-04-01 19:51:35.71618+00', '2026-05-01 19:51:35.71618+00', NULL);
INSERT INTO public.user_sessions VALUES (983, 3, '076ef0b3-de3f-4c52-8ff0-657c609100d2', NULL, NULL, '2026-04-01 19:57:05.650141+00', '2026-05-01 19:57:05.650141+00', NULL);
INSERT INTO public.user_sessions VALUES (984, 3, '79261c36-73db-4df1-bb3c-414d090d07e8', NULL, NULL, '2026-04-01 19:57:14.814802+00', '2026-05-01 19:57:14.814802+00', NULL);
INSERT INTO public.user_sessions VALUES (985, 3, '2d1dce80-5e6a-4dff-b63f-0237d5d1bb18', NULL, NULL, '2026-04-02 17:01:22.23146+00', '2026-05-02 17:01:22.23146+00', NULL);
INSERT INTO public.user_sessions VALUES (986, 3, '8a57e425-49d1-4ebe-8fc9-12ef5be80a9f', NULL, NULL, '2026-04-02 17:54:30.343274+00', '2026-05-02 17:54:30.343274+00', NULL);
INSERT INTO public.user_sessions VALUES (987, 3, '2ccb2d02-f147-418c-aabe-131f08122a58', NULL, NULL, '2026-04-03 08:24:02.143907+00', '2026-05-03 08:24:02.143907+00', NULL);
INSERT INTO public.user_sessions VALUES (988, 3, '0af2245a-2c45-43c6-8857-4c41ad5b51a6', NULL, NULL, '2026-04-03 09:15:29.930163+00', '2026-05-03 09:15:29.930163+00', NULL);
INSERT INTO public.user_sessions VALUES (989, 3, '5f254440-a87e-4e4c-a1a9-b88671f6b674', NULL, NULL, '2026-04-03 09:41:52.471976+00', '2026-05-03 09:41:52.471976+00', NULL);
INSERT INTO public.user_sessions VALUES (990, 3, '58f3f418-7af0-4452-8298-7992b52c0ead', NULL, NULL, '2026-04-03 09:42:10.3077+00', '2026-05-03 09:42:10.3077+00', NULL);
INSERT INTO public.user_sessions VALUES (991, 3, '45dcb99c-3551-4bdb-b127-5cb1ab737406', NULL, NULL, '2026-04-03 09:44:48.058781+00', '2026-05-03 09:44:48.058781+00', NULL);
INSERT INTO public.user_sessions VALUES (992, 3, '641206ef-90e3-4416-a0c2-e7d935006005', NULL, NULL, '2026-04-03 10:04:14.673171+00', '2026-05-03 10:04:14.673171+00', NULL);
INSERT INTO public.user_sessions VALUES (993, 3, 'eeeadbfc-83ff-43ca-996d-c64e2c317d07', NULL, NULL, '2026-04-03 10:05:12.004266+00', '2026-05-03 10:05:12.004266+00', NULL);
INSERT INTO public.user_sessions VALUES (994, 3, '7641f9e4-62cf-4d33-bea3-36962b1e7a74', NULL, NULL, '2026-04-03 10:09:05.866963+00', '2026-05-03 10:09:05.866963+00', NULL);
INSERT INTO public.user_sessions VALUES (995, 3, '15238e04-5876-47b0-b1f0-26c525d10e21', NULL, NULL, '2026-04-03 10:25:18.296712+00', '2026-05-03 10:25:18.296712+00', NULL);
INSERT INTO public.user_sessions VALUES (996, 3, 'f2355f62-f9e2-4a48-8523-973eb1ffd397', NULL, NULL, '2026-04-03 10:31:16.651143+00', '2026-05-03 10:31:16.651143+00', NULL);
INSERT INTO public.user_sessions VALUES (997, 3, 'd8f75c7d-3f56-48b6-9e6e-8817803ebbc8', NULL, NULL, '2026-04-03 11:20:22.32699+00', '2026-05-03 11:20:22.32699+00', NULL);
INSERT INTO public.user_sessions VALUES (998, 3, 'cfcc2a2a-33c7-4ad3-96b4-fbc0d6fbf8cb', NULL, NULL, '2026-04-03 11:28:45.320249+00', '2026-05-03 11:28:45.320249+00', NULL);
INSERT INTO public.user_sessions VALUES (999, 3, 'c890062e-582b-40cb-990f-716421721188', NULL, NULL, '2026-04-03 12:01:46.526402+00', '2026-05-03 12:01:46.526402+00', NULL);
INSERT INTO public.user_sessions VALUES (1000, 3, '11256eb9-d58a-4f85-8e7d-171173b249a2', NULL, NULL, '2026-04-03 12:02:42.509342+00', '2026-05-03 12:02:42.509342+00', NULL);
INSERT INTO public.user_sessions VALUES (1001, 3, 'e90fab59-6cd4-4c9e-b6b5-38f5dbb8905b', NULL, NULL, '2026-04-03 12:04:38.395582+00', '2026-05-03 12:04:38.395582+00', NULL);
INSERT INTO public.user_sessions VALUES (1002, 3, '9dfa99c0-4572-47f7-a1cc-a51eaa56298c', NULL, NULL, '2026-04-03 12:06:48.24894+00', '2026-05-03 12:06:48.24894+00', NULL);
INSERT INTO public.user_sessions VALUES (1003, 3, '7ae3f49d-4f78-47ab-87c3-17086bad5b34', NULL, NULL, '2026-04-03 12:16:20.793186+00', '2026-05-03 12:16:20.793186+00', NULL);
INSERT INTO public.user_sessions VALUES (1004, 3, '74f602f5-2585-4447-b1e9-ced982500cba', NULL, NULL, '2026-04-03 12:23:21.098285+00', '2026-05-03 12:23:21.098285+00', NULL);
INSERT INTO public.user_sessions VALUES (1005, 3, 'ffad9f0a-8434-4ff0-af0b-a17270cc7bb1', NULL, NULL, '2026-04-03 12:23:48.407396+00', '2026-05-03 12:23:48.407396+00', NULL);
INSERT INTO public.user_sessions VALUES (1006, 3, 'a0f52218-1277-4ab3-8f72-c2092c673d42', NULL, NULL, '2026-04-03 12:24:49.864199+00', '2026-05-03 12:24:49.864199+00', NULL);
INSERT INTO public.user_sessions VALUES (1007, 3, 'a94a2bf8-8a4e-4307-87ae-f2c809b8fbea', NULL, NULL, '2026-04-03 12:32:52.2835+00', '2026-05-03 12:32:52.2835+00', NULL);
INSERT INTO public.user_sessions VALUES (1008, 3, '6208776f-1664-4eea-b90a-fb1f05c9e856', NULL, NULL, '2026-04-03 12:33:13.303133+00', '2026-05-03 12:33:13.303133+00', NULL);
INSERT INTO public.user_sessions VALUES (1009, 3, 'ba63a9e1-fa48-4d41-9032-c784f30f14d1', NULL, NULL, '2026-04-03 12:35:08.959317+00', '2026-05-03 12:35:08.959317+00', NULL);
INSERT INTO public.user_sessions VALUES (1010, 3, '6ff69134-9484-454e-9e01-c6f1f449ffdc', NULL, NULL, '2026-04-03 12:38:30.00163+00', '2026-05-03 12:38:30.00163+00', NULL);
INSERT INTO public.user_sessions VALUES (1011, 3, '943d1f97-e044-4215-8bd6-8699de733243', NULL, NULL, '2026-04-03 12:40:15.257549+00', '2026-05-03 12:40:15.257549+00', NULL);
INSERT INTO public.user_sessions VALUES (1012, 3, '9630250d-1390-4950-bdd4-b3418dad21f3', NULL, NULL, '2026-04-03 12:53:35.100678+00', '2026-05-03 12:53:35.100678+00', NULL);
INSERT INTO public.user_sessions VALUES (1013, 3, 'b96ef056-1fe0-4ad8-aec6-fb494ef7f448', NULL, NULL, '2026-04-03 12:57:44.633945+00', '2026-05-03 12:57:44.633945+00', NULL);
INSERT INTO public.user_sessions VALUES (1014, 3, '571590c9-c9b6-4f03-a9cf-a2c1b15684fe', NULL, NULL, '2026-04-03 12:58:14.350447+00', '2026-05-03 12:58:14.350447+00', NULL);
INSERT INTO public.user_sessions VALUES (1015, 3, '328d2b7a-efba-47ff-b60c-89bf5b02837a', NULL, NULL, '2026-04-03 13:07:04.480611+00', '2026-05-03 13:07:04.480611+00', NULL);
INSERT INTO public.user_sessions VALUES (1016, 3, '275c7a77-b6e4-4a26-ab34-8567f28b0a30', NULL, NULL, '2026-04-03 13:17:29.490512+00', '2026-05-03 13:17:29.490512+00', NULL);
INSERT INTO public.user_sessions VALUES (1017, 4, 'a9b37ad3-5b97-4f4c-aa89-223a55d5bbcf', NULL, NULL, '2026-04-03 13:18:31.860226+00', '2026-05-03 13:18:31.860226+00', NULL);
INSERT INTO public.user_sessions VALUES (1018, 3, '7c9f9d6e-03a8-4d4b-9dc7-7a3480334c67', NULL, NULL, '2026-04-03 18:52:29.713283+00', '2026-05-03 18:52:29.713283+00', NULL);
INSERT INTO public.user_sessions VALUES (1019, 3, '53f3c69e-a6b6-40a6-931e-696e6f918b98', NULL, NULL, '2026-04-03 18:53:26.185191+00', '2026-05-03 18:53:26.185191+00', NULL);
INSERT INTO public.user_sessions VALUES (1020, 3, '8ffb0588-073d-4519-baec-a132ea9ac4b7', NULL, NULL, '2026-04-03 18:54:16.087308+00', '2026-05-03 18:54:16.087308+00', NULL);
INSERT INTO public.user_sessions VALUES (1021, 3, 'a08a3a24-ee08-49a4-b2c2-8dc205d71cd2', NULL, NULL, '2026-04-03 18:58:44.636559+00', '2026-05-03 18:58:44.636559+00', NULL);
INSERT INTO public.user_sessions VALUES (1022, 3, '4686bc5d-f928-4a37-af22-86be15f67465', NULL, NULL, '2026-04-03 19:00:05.047883+00', '2026-05-03 19:00:05.047883+00', NULL);
INSERT INTO public.user_sessions VALUES (1023, 4, '19d36f78-549a-4f83-9394-006dbfeff239', NULL, NULL, '2026-04-03 19:00:10.486239+00', '2026-05-03 19:00:10.486239+00', NULL);
INSERT INTO public.user_sessions VALUES (1024, 3, 'b2e3deb3-9aff-4b23-a7f9-e4e467d2c280', NULL, NULL, '2026-04-03 19:01:54.886059+00', '2026-05-03 19:01:54.886059+00', NULL);
INSERT INTO public.user_sessions VALUES (1025, 3, '1f501cba-2c5a-4add-8067-40d2fe2265af', NULL, NULL, '2026-04-03 19:13:16.802206+00', '2026-05-03 19:13:16.802206+00', NULL);
INSERT INTO public.user_sessions VALUES (1026, 4, '0c6be95e-9d3e-4a51-be0f-87ef33a131f9', NULL, NULL, '2026-04-03 19:13:35.763849+00', '2026-05-03 19:13:35.763849+00', NULL);
INSERT INTO public.user_sessions VALUES (1027, 3, '87c4ff3b-92f0-455c-86c3-e3e7a8be94ed', NULL, NULL, '2026-04-03 19:27:59.552167+00', '2026-05-03 19:27:59.552167+00', NULL);
INSERT INTO public.user_sessions VALUES (1028, 4, '5fb8fd84-424e-4452-8582-e9c5ddbf5bfe', NULL, NULL, '2026-04-03 19:28:09.974575+00', '2026-05-03 19:28:09.974575+00', NULL);
INSERT INTO public.user_sessions VALUES (1029, 3, '4549f170-e943-4cf6-841e-c75df80da66e', NULL, NULL, '2026-04-03 19:38:46.727547+00', '2026-05-03 19:38:46.727547+00', NULL);
INSERT INTO public.user_sessions VALUES (1030, 4, '252b0904-cff3-4c95-84b6-bf045bca693c', NULL, NULL, '2026-04-03 19:38:55.496796+00', '2026-05-03 19:38:55.496796+00', NULL);
INSERT INTO public.user_sessions VALUES (1031, 3, 'af2cdd8d-2067-4fcd-aab8-737740d37a60', NULL, NULL, '2026-04-03 19:41:01.174384+00', '2026-05-03 19:41:01.174384+00', NULL);
INSERT INTO public.user_sessions VALUES (1032, 4, 'b50ec493-a958-472b-94e1-7c27b741a7ac', NULL, NULL, '2026-04-03 19:41:05.933661+00', '2026-05-03 19:41:05.933661+00', NULL);
INSERT INTO public.user_sessions VALUES (1033, 3, 'bab1e1ef-76e6-4284-a405-97e13a0c6066', NULL, NULL, '2026-04-03 19:48:25.190885+00', '2026-05-03 19:48:25.190885+00', NULL);
INSERT INTO public.user_sessions VALUES (1034, 4, 'a839f54e-1dba-45fc-8c29-105c86034566', NULL, NULL, '2026-04-03 19:48:31.163971+00', '2026-05-03 19:48:31.163971+00', NULL);
INSERT INTO public.user_sessions VALUES (1035, 3, 'ebf25165-c1ec-4f04-b6a8-72afbe627c75', NULL, NULL, '2026-04-03 19:49:41.700701+00', '2026-05-03 19:49:41.700701+00', NULL);
INSERT INTO public.user_sessions VALUES (1036, 4, 'b8e64ac7-5a51-49db-b960-ddcc6aa1b597', NULL, NULL, '2026-04-03 19:49:54.12587+00', '2026-05-03 19:49:54.12587+00', NULL);
INSERT INTO public.user_sessions VALUES (1037, 3, '1534220c-6e2a-4b63-89ed-f147f211df7d', NULL, NULL, '2026-04-03 19:50:15.06765+00', '2026-05-03 19:50:15.06765+00', NULL);
INSERT INTO public.user_sessions VALUES (1038, 3, '0d46ad64-1151-44f1-a1b8-7623055c0993', NULL, NULL, '2026-04-03 19:50:40.232376+00', '2026-05-03 19:50:40.232376+00', NULL);
INSERT INTO public.user_sessions VALUES (1039, 3, 'fe536220-146d-43c6-a8a5-032b62c90b78', NULL, NULL, '2026-04-03 19:51:26.581357+00', '2026-05-03 19:51:26.581357+00', NULL);
INSERT INTO public.user_sessions VALUES (1040, 4, 'b1a3886e-2d46-4847-bb34-80c8c27a12a3', NULL, NULL, '2026-04-03 19:51:31.387477+00', '2026-05-03 19:51:31.387477+00', NULL);
INSERT INTO public.user_sessions VALUES (1041, 3, '3570d8ff-739b-4989-b088-bd3c0d1e0643', NULL, NULL, '2026-04-03 20:06:34.997727+00', '2026-05-03 20:06:34.997727+00', NULL);
INSERT INTO public.user_sessions VALUES (1042, 4, '1f197d9b-093a-4564-b3e1-846f8bdc4709', NULL, NULL, '2026-04-03 20:06:47.560739+00', '2026-05-03 20:06:47.560739+00', NULL);
INSERT INTO public.user_sessions VALUES (1043, 3, '0c21527f-cce2-4447-91df-6b8d2d6371c9', NULL, NULL, '2026-04-03 20:14:15.345101+00', '2026-05-03 20:14:15.345101+00', NULL);
INSERT INTO public.user_sessions VALUES (1044, 4, '3076ed6a-c861-4cbf-8379-c1276d0ae883', NULL, NULL, '2026-04-03 20:14:25.014014+00', '2026-05-03 20:14:25.014014+00', NULL);
INSERT INTO public.user_sessions VALUES (1045, 3, 'fc8a5845-a499-4e5e-9751-bc81105c517a', NULL, NULL, '2026-04-03 20:15:24.590718+00', '2026-05-03 20:15:24.590718+00', NULL);
INSERT INTO public.user_sessions VALUES (1046, 4, 'efad3f6a-3cbc-44ea-9017-8ccd5c504bd4', NULL, NULL, '2026-04-03 20:15:29.318569+00', '2026-05-03 20:15:29.318569+00', NULL);
INSERT INTO public.user_sessions VALUES (1047, 3, '932abf55-2b7a-4198-b843-c727d5f1ed26', NULL, NULL, '2026-04-03 20:18:32.272926+00', '2026-05-03 20:18:32.272926+00', NULL);
INSERT INTO public.user_sessions VALUES (1048, 4, '39af66e6-4982-494c-8095-cc4b3fe4d20e', NULL, NULL, '2026-04-03 20:18:41.922536+00', '2026-05-03 20:18:41.922536+00', NULL);
INSERT INTO public.user_sessions VALUES (1049, 3, '59c5c9c1-6f93-46c9-8418-55c015d2e74e', NULL, NULL, '2026-04-04 09:02:11.599793+00', '2026-05-04 09:02:11.599793+00', NULL);
INSERT INTO public.user_sessions VALUES (1050, 3, '4e09df96-3391-4215-b2dc-76ff27e63895', NULL, NULL, '2026-04-04 09:18:59.720115+00', '2026-05-04 09:18:59.720115+00', NULL);
INSERT INTO public.user_sessions VALUES (1051, 3, '6df668b5-e12a-4c72-b264-8b76ba1a5d95', NULL, NULL, '2026-04-04 09:19:29.927879+00', '2026-05-04 09:19:29.927879+00', NULL);
INSERT INTO public.user_sessions VALUES (1052, 3, '872197b8-b599-41be-83dd-3a16e2259f44', NULL, NULL, '2026-04-04 09:20:09.141392+00', '2026-05-04 09:20:09.141392+00', NULL);
INSERT INTO public.user_sessions VALUES (1053, 3, 'c91ad896-436f-474a-a9cd-45c904877b32', NULL, NULL, '2026-04-04 09:21:11.157143+00', '2026-05-04 09:21:11.157143+00', NULL);
INSERT INTO public.user_sessions VALUES (1054, 3, '0af0d118-3739-4577-9970-58071f76cade', NULL, NULL, '2026-04-04 09:26:14.629244+00', '2026-05-04 09:26:14.629244+00', NULL);
INSERT INTO public.user_sessions VALUES (1055, 4, 'e6ea1560-3b0b-4f25-a94b-016decd71006', NULL, NULL, '2026-04-04 09:26:17.208844+00', '2026-05-04 09:26:17.208844+00', NULL);
INSERT INTO public.user_sessions VALUES (1056, 3, 'b00e4761-853e-47c9-95b9-690888eb807c', NULL, NULL, '2026-04-04 09:27:09.094712+00', '2026-05-04 09:27:09.094712+00', NULL);
INSERT INTO public.user_sessions VALUES (1057, 3, '99db9485-eec0-4388-93da-e4d564519c3c', NULL, NULL, '2026-04-04 09:35:50.281113+00', '2026-05-04 09:35:50.281113+00', NULL);
INSERT INTO public.user_sessions VALUES (1058, 3, '39334e48-6c1b-42fb-b773-6b7a52d5e340', NULL, NULL, '2026-04-04 09:44:44.019885+00', '2026-05-04 09:44:44.019885+00', NULL);
INSERT INTO public.user_sessions VALUES (1059, 3, 'f99ac837-f755-4cbc-90c5-285208289eca', NULL, NULL, '2026-04-04 09:52:23.346397+00', '2026-05-04 09:52:23.346397+00', NULL);
INSERT INTO public.user_sessions VALUES (1060, 3, '92654675-84d4-4fe7-9f77-f02f7c2f3dc3', NULL, NULL, '2026-04-04 10:25:34.026406+00', '2026-05-04 10:25:34.026406+00', NULL);
INSERT INTO public.user_sessions VALUES (1061, 4, '37801df2-b81a-42a8-9235-53693a055e43', NULL, NULL, '2026-04-04 10:25:45.101737+00', '2026-05-04 10:25:45.101737+00', NULL);
INSERT INTO public.user_sessions VALUES (1062, 3, 'c5f04944-e318-4ffe-a54c-69f36528bbbf', NULL, NULL, '2026-04-04 10:34:29.159416+00', '2026-05-04 10:34:29.159416+00', NULL);
INSERT INTO public.user_sessions VALUES (1063, 4, '5fe55e1a-a7b5-4a8b-b8a7-d11f7af2231c', NULL, NULL, '2026-04-04 10:34:35.182404+00', '2026-05-04 10:34:35.182404+00', NULL);
INSERT INTO public.user_sessions VALUES (1064, 3, 'af56b21c-ee5a-47a0-950e-ab9c33d526c7', NULL, NULL, '2026-04-04 11:08:01.967278+00', '2026-05-04 11:08:01.967278+00', NULL);
INSERT INTO public.user_sessions VALUES (1065, 3, '4298a155-1f61-4253-97eb-f9c47801a1f5', NULL, NULL, '2026-04-04 11:08:43.535914+00', '2026-05-04 11:08:43.535914+00', NULL);
INSERT INTO public.user_sessions VALUES (1066, 3, '1d0abea4-6f8a-412f-85e3-531cbfccbef3', NULL, NULL, '2026-04-04 11:09:22.751616+00', '2026-05-04 11:09:22.751616+00', NULL);
INSERT INTO public.user_sessions VALUES (1067, 4, 'fe4c92e9-c2b5-440e-955b-9f8534c7f288', NULL, NULL, '2026-04-04 11:09:32.215539+00', '2026-05-04 11:09:32.215539+00', NULL);
INSERT INTO public.user_sessions VALUES (1068, 3, '6f27a330-a2b6-4214-acd0-680a5d232afa', NULL, NULL, '2026-04-04 11:14:59.258211+00', '2026-05-04 11:14:59.258211+00', NULL);
INSERT INTO public.user_sessions VALUES (1069, 4, 'c8605b0a-c3bf-473d-8767-e592a77db2e6', NULL, NULL, '2026-04-04 11:15:06.412262+00', '2026-05-04 11:15:06.412262+00', NULL);
INSERT INTO public.user_sessions VALUES (1070, 3, '2e13c50b-b1dd-4ae6-ad44-fe2965331d37', NULL, NULL, '2026-04-04 11:16:07.239515+00', '2026-05-04 11:16:07.239515+00', NULL);
INSERT INTO public.user_sessions VALUES (1071, 4, '2849f847-240c-4e03-a843-ead817a30833', NULL, NULL, '2026-04-04 11:16:12.406337+00', '2026-05-04 11:16:12.406337+00', NULL);
INSERT INTO public.user_sessions VALUES (1072, 3, '82cd9d51-26b9-4261-9c1a-7a9f534d09d7', NULL, NULL, '2026-04-04 11:16:41.30539+00', '2026-05-04 11:16:41.30539+00', NULL);
INSERT INTO public.user_sessions VALUES (1073, 4, 'ee75f2a4-5bba-4880-b071-22b874a62d10', NULL, NULL, '2026-04-04 11:16:46.479182+00', '2026-05-04 11:16:46.479182+00', NULL);
INSERT INTO public.user_sessions VALUES (1074, 3, '94373013-584f-4b02-ab2a-62a9430d5479', NULL, NULL, '2026-04-04 11:17:46.466991+00', '2026-05-04 11:17:46.466991+00', NULL);
INSERT INTO public.user_sessions VALUES (1075, 3, 'ec769916-de20-45dd-996d-7ecb1a8fb280', NULL, NULL, '2026-04-04 11:18:54.758547+00', '2026-05-04 11:18:54.758547+00', NULL);
INSERT INTO public.user_sessions VALUES (1076, 4, '5d481d5c-2523-4d03-9592-df289d9fbc85', NULL, NULL, '2026-04-04 11:19:01.4485+00', '2026-05-04 11:19:01.4485+00', NULL);
INSERT INTO public.user_sessions VALUES (1077, 3, '884532b6-6ed8-4661-acda-1c45539580cc', NULL, NULL, '2026-04-04 11:27:02.617641+00', '2026-05-04 11:27:02.617641+00', NULL);
INSERT INTO public.user_sessions VALUES (1078, 4, '4a940016-703f-4833-855b-b8c55986f699', NULL, NULL, '2026-04-04 11:27:09.75014+00', '2026-05-04 11:27:09.75014+00', NULL);
INSERT INTO public.user_sessions VALUES (1079, 3, '81d6ccb3-39be-4ba9-a46d-eec62bba2d78', NULL, NULL, '2026-04-04 11:28:59.539039+00', '2026-05-04 11:28:59.539039+00', NULL);
INSERT INTO public.user_sessions VALUES (1080, 4, '6e8dd1db-00ce-455e-9576-4ad8c55009d4', NULL, NULL, '2026-04-04 11:29:05.121209+00', '2026-05-04 11:29:05.121209+00', NULL);
INSERT INTO public.user_sessions VALUES (1081, 3, '883a7b8a-3685-48b9-a9e4-d8528f158db7', NULL, NULL, '2026-04-04 11:32:33.910076+00', '2026-05-04 11:32:33.910076+00', NULL);
INSERT INTO public.user_sessions VALUES (1082, 3, 'f1ce4e7a-bbc8-496d-a639-ef50e73a7a44', NULL, NULL, '2026-04-04 11:33:06.44621+00', '2026-05-04 11:33:06.44621+00', NULL);
INSERT INTO public.user_sessions VALUES (1083, 4, '1a48386d-e98b-4d94-8d5b-973295e5cb04', NULL, NULL, '2026-04-04 11:33:16.69988+00', '2026-05-04 11:33:16.69988+00', NULL);
INSERT INTO public.user_sessions VALUES (1084, 4, '00d787f7-a7c8-4b68-92e4-51cf971663c3', NULL, NULL, '2026-04-04 11:34:31.443597+00', '2026-05-04 11:34:31.443597+00', NULL);
INSERT INTO public.user_sessions VALUES (1085, 3, 'c08fb349-71d6-4ef9-91d3-2188c23902b7', NULL, NULL, '2026-04-04 11:34:42.037266+00', '2026-05-04 11:34:42.037266+00', NULL);
INSERT INTO public.user_sessions VALUES (1086, 3, '6b985600-0d53-4127-a940-19ff26e292c3', NULL, NULL, '2026-04-04 11:35:47.098612+00', '2026-05-04 11:35:47.098612+00', NULL);
INSERT INTO public.user_sessions VALUES (1087, 3, 'aa203c59-0d25-435e-b05c-aa66364affe9', NULL, NULL, '2026-04-04 11:37:20.698229+00', '2026-05-04 11:37:20.698229+00', NULL);
INSERT INTO public.user_sessions VALUES (1088, 4, 'cde9d547-a86f-4c3e-a022-27f141bb579e', NULL, NULL, '2026-04-04 11:37:23.681431+00', '2026-05-04 11:37:23.681431+00', NULL);
INSERT INTO public.user_sessions VALUES (1089, 3, '19b7bd7f-689f-4b19-8afc-453cae3fb827', NULL, NULL, '2026-04-04 11:39:06.818985+00', '2026-05-04 11:39:06.818985+00', NULL);
INSERT INTO public.user_sessions VALUES (1090, 3, 'ac4a9d56-f403-485c-a91e-4441089a430a', NULL, NULL, '2026-04-04 11:39:20.707411+00', '2026-05-04 11:39:20.707411+00', NULL);
INSERT INTO public.user_sessions VALUES (1091, 3, '71241f69-8d68-46e1-b4e7-9d7a611556af', NULL, NULL, '2026-04-04 11:46:27.875292+00', '2026-05-04 11:46:27.875292+00', NULL);
INSERT INTO public.user_sessions VALUES (1092, 4, 'ff57f636-57c9-45ae-98d7-824b3e12c99e', NULL, NULL, '2026-04-04 11:46:56.897019+00', '2026-05-04 11:46:56.897019+00', NULL);
INSERT INTO public.user_sessions VALUES (1093, 3, '82859274-da3e-44a1-bf3f-58e9a2d3f3be', NULL, NULL, '2026-04-04 11:48:30.066057+00', '2026-05-04 11:48:30.066057+00', NULL);
INSERT INTO public.user_sessions VALUES (1094, 4, 'c4188824-e0fd-47a0-aead-509569ed766b', NULL, NULL, '2026-04-04 11:48:38.327576+00', '2026-05-04 11:48:38.327576+00', NULL);
INSERT INTO public.user_sessions VALUES (1095, 3, '141d04f7-831c-40db-b124-498e5c80fb6c', NULL, NULL, '2026-04-04 11:49:04.254786+00', '2026-05-04 11:49:04.254786+00', NULL);
INSERT INTO public.user_sessions VALUES (1096, 4, 'ffcb2988-7359-417a-bb53-896c6da921ff', NULL, NULL, '2026-04-04 11:49:10.723147+00', '2026-05-04 11:49:10.723147+00', NULL);
INSERT INTO public.user_sessions VALUES (1097, 3, 'af6b18c2-a543-4b47-b2d5-420eb0cde04e', NULL, NULL, '2026-04-04 12:00:36.918898+00', '2026-05-04 12:00:36.918898+00', NULL);
INSERT INTO public.user_sessions VALUES (1098, 4, '5170087c-0c82-4ab5-a53e-35827c98a22c', NULL, NULL, '2026-04-04 12:00:51.971826+00', '2026-05-04 12:00:51.971826+00', NULL);
INSERT INTO public.user_sessions VALUES (1103, 3, '795d7558-be76-41c4-92c3-ba7c052bdeaa', NULL, NULL, '2026-04-04 12:34:17.615379+00', '2026-05-04 12:34:17.615379+00', NULL);
INSERT INTO public.user_sessions VALUES (1108, 3, '103adedb-0bbb-4b5b-bfe9-53f5f5460902', NULL, NULL, '2026-04-04 13:01:57.199418+00', '2026-05-04 13:01:57.199418+00', NULL);
INSERT INTO public.user_sessions VALUES (1113, 3, 'ee05da4f-ae69-48f0-a8b1-aac49f40768a', NULL, NULL, '2026-04-04 13:05:57.907125+00', '2026-05-04 13:05:57.907125+00', NULL);
INSERT INTO public.user_sessions VALUES (1118, 3, 'cdc9c280-7f88-4f97-bf69-54c99726a935', NULL, NULL, '2026-04-04 13:36:13.289956+00', '2026-05-04 13:36:13.289956+00', NULL);
INSERT INTO public.user_sessions VALUES (1123, 3, '956b4d11-28c3-4fcd-8b44-91eef4145c7f', NULL, NULL, '2026-04-04 13:41:50.557633+00', '2026-05-04 13:41:50.557633+00', NULL);
INSERT INTO public.user_sessions VALUES (1128, 3, '196d590a-aea0-4cd1-ab91-746c8fc8c88e', NULL, NULL, '2026-04-04 13:50:35.135115+00', '2026-05-04 13:50:35.135115+00', NULL);
INSERT INTO public.user_sessions VALUES (1133, 4, '151fd6b8-6e19-42bc-bf2e-05dd8369ddcb', NULL, NULL, '2026-04-04 13:54:37.819718+00', '2026-05-04 13:54:37.819718+00', NULL);
INSERT INTO public.user_sessions VALUES (1099, 3, '607d8138-0bcc-4b77-b89d-db338661d035', NULL, NULL, '2026-04-04 12:09:24.973991+00', '2026-05-04 12:09:24.973991+00', NULL);
INSERT INTO public.user_sessions VALUES (1104, 4, '1b46fa66-1f0c-4be2-872a-4c2c94cd3d4b', NULL, NULL, '2026-04-04 12:34:34.288609+00', '2026-05-04 12:34:34.288609+00', NULL);
INSERT INTO public.user_sessions VALUES (1109, 3, '40019ad5-9b69-47f0-84aa-036415d0fcb3', NULL, NULL, '2026-04-04 13:04:00.590929+00', '2026-05-04 13:04:00.590929+00', NULL);
INSERT INTO public.user_sessions VALUES (1114, 4, '334a13c3-a4ef-47ae-a65b-f2fb91b32894', NULL, NULL, '2026-04-04 13:06:04.964864+00', '2026-05-04 13:06:04.964864+00', NULL);
INSERT INTO public.user_sessions VALUES (1119, 4, 'c23d1229-2bda-4b36-949d-80c02061ec61', NULL, NULL, '2026-04-04 13:36:50.068299+00', '2026-05-04 13:36:50.068299+00', NULL);
INSERT INTO public.user_sessions VALUES (1124, 3, '46f6c0d2-a04a-4ff3-8031-74f70d5788fa', NULL, NULL, '2026-04-04 13:42:09.137499+00', '2026-05-04 13:42:09.137499+00', NULL);
INSERT INTO public.user_sessions VALUES (1129, 4, '215d2285-d6b4-4354-badb-a6c1782708b4', NULL, NULL, '2026-04-04 13:50:44.289779+00', '2026-05-04 13:50:44.289779+00', NULL);
INSERT INTO public.user_sessions VALUES (1134, 3, '82f1aab3-a511-4f2d-afdd-3a79f58228c8', NULL, NULL, '2026-04-04 14:07:00.215032+00', '2026-05-04 14:07:00.215032+00', NULL);
INSERT INTO public.user_sessions VALUES (1100, 4, '7f7aa052-b901-4ed2-9e3d-ed90e6ff47a0', NULL, NULL, '2026-04-04 12:09:32.826857+00', '2026-05-04 12:09:32.826857+00', NULL);
INSERT INTO public.user_sessions VALUES (1105, 3, 'eb5ec3f3-85f8-4961-88b0-5401c62df250', NULL, NULL, '2026-04-04 12:45:07.934473+00', '2026-05-04 12:45:07.934473+00', NULL);
INSERT INTO public.user_sessions VALUES (1110, 4, 'd377884d-f1db-400b-9b43-27607e8a5ae5', NULL, NULL, '2026-04-04 13:04:13.421099+00', '2026-05-04 13:04:13.421099+00', NULL);
INSERT INTO public.user_sessions VALUES (1115, 3, '9b51ffc2-e568-4caa-935a-6889f11e453d', NULL, NULL, '2026-04-04 13:25:41.077147+00', '2026-05-04 13:25:41.077147+00', NULL);
INSERT INTO public.user_sessions VALUES (1120, 3, 'fd3b8eed-f355-47af-976a-ef28d8e8f586', NULL, NULL, '2026-04-04 13:37:55.580936+00', '2026-05-04 13:37:55.580936+00', NULL);
INSERT INTO public.user_sessions VALUES (1125, 3, 'bd828aac-6bd2-46c3-a52c-11e0bdc1a636', NULL, NULL, '2026-04-04 13:44:33.776471+00', '2026-05-04 13:44:33.776471+00', NULL);
INSERT INTO public.user_sessions VALUES (1130, 3, '9fa501cc-94cc-4132-a423-052848dcf946', NULL, NULL, '2026-04-04 13:52:36.53405+00', '2026-05-04 13:52:36.53405+00', NULL);
INSERT INTO public.user_sessions VALUES (1135, 4, 'cf9ad00d-aa61-4b8f-b14f-aecae56a8db7', NULL, NULL, '2026-04-04 14:07:06.872562+00', '2026-05-04 14:07:06.872562+00', NULL);
INSERT INTO public.user_sessions VALUES (1101, 3, '1118a6ac-924a-4408-922f-6ffed47a22dc', NULL, NULL, '2026-04-04 12:19:12.904336+00', '2026-05-04 12:19:12.904336+00', NULL);
INSERT INTO public.user_sessions VALUES (1106, 4, 'b23f51ec-9bed-4e92-83bf-cb779d838d3d', NULL, NULL, '2026-04-04 12:45:25.536037+00', '2026-05-04 12:45:25.536037+00', NULL);
INSERT INTO public.user_sessions VALUES (1111, 3, '2ea6d6dd-63b9-4beb-a807-e75c9cab6ae1', NULL, NULL, '2026-04-04 13:04:51.464262+00', '2026-05-04 13:04:51.464262+00', NULL);
INSERT INTO public.user_sessions VALUES (1116, 4, '61c69ddf-4095-4231-aa07-2c454d545029', NULL, NULL, '2026-04-04 13:25:49.587753+00', '2026-05-04 13:25:49.587753+00', NULL);
INSERT INTO public.user_sessions VALUES (1121, 3, '9fcc8bf0-9e63-41ab-a0ba-1be8ba3a52c3', NULL, NULL, '2026-04-04 13:40:46.062803+00', '2026-05-04 13:40:46.062803+00', NULL);
INSERT INTO public.user_sessions VALUES (1126, 3, '86053d45-0c1a-4973-847d-974f1d12f718', NULL, NULL, '2026-04-04 13:49:43.849738+00', '2026-05-04 13:49:43.849738+00', NULL);
INSERT INTO public.user_sessions VALUES (1131, 4, 'c34c47a3-610c-464c-a27e-7e14678831bd', NULL, NULL, '2026-04-04 13:52:58.493131+00', '2026-05-04 13:52:58.493131+00', NULL);
INSERT INTO public.user_sessions VALUES (1136, 3, '129aff9f-7173-4c17-a55b-52cdcf374a66', NULL, NULL, '2026-04-04 14:07:35.629667+00', '2026-05-04 14:07:35.629667+00', NULL);
INSERT INTO public.user_sessions VALUES (1102, 4, '8a7017a1-f907-4233-ab8a-57ee077e0bf1', NULL, NULL, '2026-04-04 12:19:17.425901+00', '2026-05-04 12:19:17.425901+00', NULL);
INSERT INTO public.user_sessions VALUES (1107, 3, 'c385b36c-9f3f-4bdd-bdde-7d6a28f6f586', NULL, NULL, '2026-04-04 13:01:27.566255+00', '2026-05-04 13:01:27.566255+00', NULL);
INSERT INTO public.user_sessions VALUES (1112, 4, 'ce4ca17b-8066-4b6f-a487-582ae3772f65', NULL, NULL, '2026-04-04 13:04:59.866412+00', '2026-05-04 13:04:59.866412+00', NULL);
INSERT INTO public.user_sessions VALUES (1117, 3, '946fe4a0-4240-469c-9584-b3b343fa8d10', NULL, NULL, '2026-04-04 13:26:52.008434+00', '2026-05-04 13:26:52.008434+00', NULL);
INSERT INTO public.user_sessions VALUES (1122, 4, '2683debe-dddb-490f-a12c-f51054f47b9e', NULL, NULL, '2026-04-04 13:40:58.133392+00', '2026-05-04 13:40:58.133392+00', NULL);
INSERT INTO public.user_sessions VALUES (1127, 4, 'f61fdc72-98ed-4238-8e94-55b833e18d78', NULL, NULL, '2026-04-04 13:49:48.805484+00', '2026-05-04 13:49:48.805484+00', NULL);
INSERT INTO public.user_sessions VALUES (1132, 3, 'ad9b16a2-75f0-4e55-8bc0-d099ee0397f5', NULL, NULL, '2026-04-04 13:54:30.434998+00', '2026-05-04 13:54:30.434998+00', NULL);
INSERT INTO public.user_sessions VALUES (1137, 4, 'b9587b1f-327e-4dc4-aa2d-f31e1670312e', NULL, NULL, '2026-04-04 14:07:41.19341+00', '2026-05-04 14:07:41.19341+00', NULL);
INSERT INTO public.user_sessions VALUES (1138, 3, 'c78486b3-34e2-4ea1-994b-d0fe7c236414', NULL, NULL, '2026-04-04 14:11:52.520076+00', '2026-05-04 14:11:52.520076+00', NULL);
INSERT INTO public.user_sessions VALUES (1139, 4, 'f5919d58-f5a1-4eb2-9b8d-7570ac9f64a6', NULL, NULL, '2026-04-04 14:11:58.272902+00', '2026-05-04 14:11:58.272902+00', NULL);
INSERT INTO public.user_sessions VALUES (1140, 3, '6bd18794-7031-41ef-8741-4cf4df5ef1d1', NULL, NULL, '2026-04-04 14:18:45.930803+00', '2026-05-04 14:18:45.930803+00', NULL);
INSERT INTO public.user_sessions VALUES (1141, 4, 'bc0d040c-fc74-4634-87d2-f1a0c5bdb3e6', NULL, NULL, '2026-04-04 14:18:53.935231+00', '2026-05-04 14:18:53.935231+00', NULL);
INSERT INTO public.user_sessions VALUES (1142, 3, '4a4de6b0-7bef-457d-95c7-109ea186beaa', NULL, NULL, '2026-04-04 14:19:53.388624+00', '2026-05-04 14:19:53.388624+00', NULL);
INSERT INTO public.user_sessions VALUES (1143, 4, '69a04344-415c-4752-a6eb-c06da83faf98', NULL, NULL, '2026-04-04 14:19:57.147648+00', '2026-05-04 14:19:57.147648+00', NULL);
INSERT INTO public.user_sessions VALUES (1144, 3, '605de1da-c542-4bc4-bfe6-1ffcf9c6eee9', NULL, NULL, '2026-04-04 14:23:55.380161+00', '2026-05-04 14:23:55.380161+00', NULL);
INSERT INTO public.user_sessions VALUES (1145, 4, 'd0f7e597-9dd4-4b55-9cba-eaee477000ea', NULL, NULL, '2026-04-04 14:24:02.768898+00', '2026-05-04 14:24:02.768898+00', NULL);
INSERT INTO public.user_sessions VALUES (1146, 3, '5081e4bf-c6bd-4775-896b-2316a53ee3f0', NULL, NULL, '2026-04-04 14:24:31.550608+00', '2026-05-04 14:24:31.550608+00', NULL);
INSERT INTO public.user_sessions VALUES (1147, 4, '3ea22bd5-c9c1-4a7f-895a-97238ab0144a', NULL, NULL, '2026-04-04 14:24:35.778882+00', '2026-05-04 14:24:35.778882+00', NULL);
INSERT INTO public.user_sessions VALUES (1148, 3, '0ec3c1be-8eee-4ae1-b2b6-db806614eb5c', NULL, NULL, '2026-04-04 14:31:09.959997+00', '2026-05-04 14:31:09.959997+00', NULL);
INSERT INTO public.user_sessions VALUES (1149, 4, 'df568d62-1452-43a2-849e-beb4c060982b', NULL, NULL, '2026-04-04 14:31:17.711902+00', '2026-05-04 14:31:17.711902+00', NULL);
INSERT INTO public.user_sessions VALUES (1150, 3, 'e5046dba-59ae-4ec6-8c1b-fc394ed82ac1', NULL, NULL, '2026-04-04 14:31:52.173293+00', '2026-05-04 14:31:52.173293+00', NULL);
INSERT INTO public.user_sessions VALUES (1151, 4, 'f9629b28-f0ad-4ec3-90aa-5508baef7244', NULL, NULL, '2026-04-04 14:31:55.820754+00', '2026-05-04 14:31:55.820754+00', NULL);
INSERT INTO public.user_sessions VALUES (1152, 3, 'de5f4a71-2247-4f42-84fc-c87da712d716', NULL, NULL, '2026-04-04 14:35:18.311833+00', '2026-05-04 14:35:18.311833+00', NULL);
INSERT INTO public.user_sessions VALUES (1153, 4, 'a32d7cab-b487-47f1-8bcc-adf22ce0cfb5', NULL, NULL, '2026-04-04 14:35:26.707317+00', '2026-05-04 14:35:26.707317+00', NULL);
INSERT INTO public.user_sessions VALUES (1154, 3, '19e773d2-4614-4d42-aab5-03dd5554e9f3', NULL, NULL, '2026-04-04 14:35:41.679374+00', '2026-05-04 14:35:41.679374+00', NULL);
INSERT INTO public.user_sessions VALUES (1155, 3, 'e0dee71b-4f81-4132-a57a-1f6eebd4d114', NULL, NULL, '2026-04-04 14:36:28.625681+00', '2026-05-04 14:36:28.625681+00', NULL);
INSERT INTO public.user_sessions VALUES (1156, 3, 'e18c6e6c-3f2b-4eaf-9e7f-1a04a3231084', NULL, NULL, '2026-04-04 14:38:54.692027+00', '2026-05-04 14:38:54.692027+00', NULL);
INSERT INTO public.user_sessions VALUES (1157, 4, '92a9f0ac-002d-4853-affa-fb4baffd66cf', NULL, NULL, '2026-04-04 14:39:04.224755+00', '2026-05-04 14:39:04.224755+00', NULL);
INSERT INTO public.user_sessions VALUES (1158, 3, 'da31545a-1a8c-47a8-be78-620847b8a788', NULL, NULL, '2026-04-04 14:39:27.713399+00', '2026-05-04 14:39:27.713399+00', NULL);
INSERT INTO public.user_sessions VALUES (1159, 3, '40e7da15-a030-4b0b-b4f7-e97a68c8c56f', NULL, NULL, '2026-04-04 14:39:56.063343+00', '2026-05-04 14:39:56.063343+00', NULL);
INSERT INTO public.user_sessions VALUES (1160, 4, '9846cc2e-6942-4eb0-bb38-59d910309d4c', NULL, NULL, '2026-04-04 14:40:48.395298+00', '2026-05-04 14:40:48.395298+00', NULL);
INSERT INTO public.user_sessions VALUES (1161, 3, '558bab22-4dcb-4d46-bdb2-933651bc93ac', NULL, NULL, '2026-04-04 14:43:12.478216+00', '2026-05-04 14:43:12.478216+00', NULL);
INSERT INTO public.user_sessions VALUES (1162, 4, '14863f95-3c3e-463e-849e-97f26138935d', NULL, NULL, '2026-04-04 14:43:30.98742+00', '2026-05-04 14:43:30.98742+00', NULL);
INSERT INTO public.user_sessions VALUES (1163, 3, '771a5836-8497-4819-9fad-45e60027842d', NULL, NULL, '2026-04-04 14:46:30.42077+00', '2026-05-04 14:46:30.42077+00', NULL);
INSERT INTO public.user_sessions VALUES (1164, 3, 'ad3e26bd-d7ec-49ec-83c1-c06529c705c7', NULL, NULL, '2026-04-04 15:05:02.791187+00', '2026-05-04 15:05:02.791187+00', NULL);
INSERT INTO public.user_sessions VALUES (1165, 3, '4c6370ea-6ab4-4c61-bad0-3982e1b4ba26', NULL, NULL, '2026-04-04 15:38:47.362809+00', '2026-05-04 15:38:47.362809+00', NULL);
INSERT INTO public.user_sessions VALUES (1166, 3, '4b24161f-b031-4066-8ce6-44beffb00a4c', NULL, NULL, '2026-04-04 15:52:29.115543+00', '2026-05-04 15:52:29.115543+00', NULL);
INSERT INTO public.user_sessions VALUES (1167, 3, '3d169f3e-3330-4884-8d11-2b8553323290', NULL, NULL, '2026-04-04 16:11:03.632546+00', '2026-05-04 16:11:03.632546+00', NULL);
INSERT INTO public.user_sessions VALUES (1168, 3, '2c84bbca-5590-4f31-bcc5-495eb0f6ee7c', NULL, NULL, '2026-04-04 16:19:55.435941+00', '2026-05-04 16:19:55.435941+00', NULL);
INSERT INTO public.user_sessions VALUES (1169, 3, '5202ccd2-0adc-4b1a-b015-8f8be65caf60', NULL, NULL, '2026-04-04 16:25:16.630595+00', '2026-05-04 16:25:16.630595+00', NULL);
INSERT INTO public.user_sessions VALUES (1170, 3, 'dbe05ff4-2e2a-44a3-8fda-2d34690729eb', NULL, NULL, '2026-04-04 16:33:35.445345+00', '2026-05-04 16:33:35.445345+00', NULL);
INSERT INTO public.user_sessions VALUES (1171, 3, '5ebdc5bb-268e-4219-86d1-a13f9a5ee416', NULL, NULL, '2026-04-04 16:36:19.829264+00', '2026-05-04 16:36:19.829264+00', NULL);
INSERT INTO public.user_sessions VALUES (1172, 3, '94297975-fddc-4df5-9633-29abb649bda4', NULL, NULL, '2026-04-04 16:47:08.851482+00', '2026-05-04 16:47:08.851482+00', NULL);
INSERT INTO public.user_sessions VALUES (1173, 3, 'b96b93c1-bd0a-4fa4-ab9d-0dbcec225cc3', NULL, NULL, '2026-04-04 17:00:20.560778+00', '2026-05-04 17:00:20.560778+00', NULL);
INSERT INTO public.user_sessions VALUES (1174, 3, '7d7a06b2-01b5-4013-9a7b-0eea2a66a315', NULL, NULL, '2026-04-04 17:07:22.612853+00', '2026-05-04 17:07:22.612853+00', NULL);
INSERT INTO public.user_sessions VALUES (1175, 3, '98c972b5-4aeb-4c89-84a9-988e921f897b', NULL, NULL, '2026-04-04 17:11:01.763491+00', '2026-05-04 17:11:01.763491+00', NULL);
INSERT INTO public.user_sessions VALUES (1176, 3, 'ab06613d-2eb5-47ed-b51f-49b09536f2a9', NULL, NULL, '2026-04-04 17:16:33.793894+00', '2026-05-04 17:16:33.793894+00', NULL);
INSERT INTO public.user_sessions VALUES (1177, 3, '7c656b37-a6aa-4b3f-b2dc-bebdea282629', NULL, NULL, '2026-04-04 17:24:06.005052+00', '2026-05-04 17:24:06.005052+00', NULL);
INSERT INTO public.user_sessions VALUES (1178, 3, '4d891a89-33c4-43bd-8b49-bd4062aba21b', NULL, NULL, '2026-04-04 17:28:09.033708+00', '2026-05-04 17:28:09.033708+00', NULL);
INSERT INTO public.user_sessions VALUES (1179, 3, 'cdb96eb3-c6c4-48ff-a0fe-d4f5990319ab', NULL, NULL, '2026-04-04 17:29:47.416786+00', '2026-05-04 17:29:47.416786+00', NULL);
INSERT INTO public.user_sessions VALUES (1180, 3, 'bb154f84-5ceb-454f-be72-74d4c0f610cf', NULL, NULL, '2026-04-04 17:33:19.573442+00', '2026-05-04 17:33:19.573442+00', NULL);
INSERT INTO public.user_sessions VALUES (1181, 3, '96e63a15-5b9e-4872-9287-bacf62bbe537', NULL, NULL, '2026-04-04 17:34:21.764903+00', '2026-05-04 17:34:21.764903+00', NULL);
INSERT INTO public.user_sessions VALUES (1182, 3, 'f7a94596-c3ee-41ec-963d-4c3bb9b3ddab', NULL, NULL, '2026-04-04 17:36:40.534684+00', '2026-05-04 17:36:40.534684+00', NULL);
INSERT INTO public.user_sessions VALUES (1183, 3, 'b1b5da43-0998-4fee-b626-f756de046076', NULL, NULL, '2026-04-04 17:45:44.37009+00', '2026-05-04 17:45:44.37009+00', NULL);
INSERT INTO public.user_sessions VALUES (1184, 3, '67096301-c673-4e73-bd86-66f77fc43e27', NULL, NULL, '2026-04-04 17:49:14.40116+00', '2026-05-04 17:49:14.40116+00', NULL);
INSERT INTO public.user_sessions VALUES (1185, 3, 'd1fd6d1d-cdd1-4bbb-b549-fb02af5e1b54', NULL, NULL, '2026-04-04 18:05:07.834392+00', '2026-05-04 18:05:07.834392+00', NULL);
INSERT INTO public.user_sessions VALUES (1186, 3, 'ac84f190-237f-4de6-bfea-13d35cbf8def', NULL, NULL, '2026-04-04 18:05:33.605758+00', '2026-05-04 18:05:33.605758+00', NULL);
INSERT INTO public.user_sessions VALUES (1187, 3, '98fa8e14-2b9b-4d81-8baf-0f833283f223', NULL, NULL, '2026-04-04 18:14:54.797602+00', '2026-05-04 18:14:54.797602+00', NULL);
INSERT INTO public.user_sessions VALUES (1188, 3, 'a4bd03b1-539c-4983-9271-198d65566f3f', NULL, NULL, '2026-04-04 18:27:23.522053+00', '2026-05-04 18:27:23.522053+00', NULL);
INSERT INTO public.user_sessions VALUES (1189, 3, 'ba464ca6-ad70-4ed5-bc69-c14f0e1016ab', NULL, NULL, '2026-04-04 18:27:35.454211+00', '2026-05-04 18:27:35.454211+00', NULL);
INSERT INTO public.user_sessions VALUES (1190, 3, '10cafafd-cf81-49dd-9f59-c2394c773796', NULL, NULL, '2026-04-04 18:32:29.953568+00', '2026-05-04 18:32:29.953568+00', NULL);
INSERT INTO public.user_sessions VALUES (1191, 3, '10283c3f-ff9b-412c-b1d4-e47d70720738', NULL, NULL, '2026-04-04 18:41:39.448366+00', '2026-05-04 18:41:39.448366+00', NULL);
INSERT INTO public.user_sessions VALUES (1192, 3, '1e153d23-110c-4c95-b7ef-aeaac546f2f6', NULL, NULL, '2026-04-04 18:52:57.487876+00', '2026-05-04 18:52:57.487876+00', NULL);
INSERT INTO public.user_sessions VALUES (1193, 3, '74136c8a-3026-4f9c-b6d7-b480294dfc4d', NULL, NULL, '2026-04-04 18:54:56.507743+00', '2026-05-04 18:54:56.507743+00', NULL);
INSERT INTO public.user_sessions VALUES (1194, 3, '4c96f124-caa0-45b1-bd61-54e8e3ed1614', NULL, NULL, '2026-04-04 19:02:06.957664+00', '2026-05-04 19:02:06.957664+00', NULL);
INSERT INTO public.user_sessions VALUES (1195, 3, 'ebaf6367-83c4-44a0-9d46-0e7b0a1465cd', NULL, NULL, '2026-04-04 19:10:54.990129+00', '2026-05-04 19:10:54.990129+00', NULL);
INSERT INTO public.user_sessions VALUES (1196, 3, '11ff97a0-068d-4109-b5e8-1e22cfb9254f', NULL, NULL, '2026-04-04 19:20:36.436241+00', '2026-05-04 19:20:36.436241+00', NULL);
INSERT INTO public.user_sessions VALUES (1197, 3, '32615d89-9655-4142-945d-21a33f62c984', NULL, NULL, '2026-04-04 19:29:47.55844+00', '2026-05-04 19:29:47.55844+00', NULL);
INSERT INTO public.user_sessions VALUES (1198, 4, '45205adf-10c2-4410-9f44-9aa01f598b21', NULL, NULL, '2026-04-04 19:41:07.937013+00', '2026-05-04 19:41:07.937013+00', NULL);
INSERT INTO public.user_sessions VALUES (1199, 3, '3fe76064-c4ac-4dd8-92aa-3d0319c1a5ed', NULL, NULL, '2026-04-04 19:55:30.623612+00', '2026-05-04 19:55:30.623612+00', NULL);
INSERT INTO public.user_sessions VALUES (1200, 3, '74c6c83e-d79d-4078-bacf-501f860b09b7', NULL, NULL, '2026-04-04 20:13:44.80831+00', '2026-05-04 20:13:44.80831+00', NULL);
INSERT INTO public.user_sessions VALUES (1201, 3, 'c3e36b4c-2004-477e-9f67-4bdb0f6dea14', NULL, NULL, '2026-04-05 07:57:50.417945+00', '2026-05-05 07:57:50.417945+00', NULL);
INSERT INTO public.user_sessions VALUES (1202, 3, '2f8cd058-bd00-4ad5-8006-60a5eea11afe', NULL, NULL, '2026-04-05 10:25:32.098592+00', '2026-05-05 10:25:32.098592+00', NULL);
INSERT INTO public.user_sessions VALUES (1203, 3, 'fa4be166-80d0-4dc8-96f3-44d941c265e9', NULL, NULL, '2026-04-05 10:26:21.21078+00', '2026-05-05 10:26:21.21078+00', NULL);
INSERT INTO public.user_sessions VALUES (1204, 3, '48ab718e-f415-4cb0-b79b-2113bc686f49', NULL, NULL, '2026-04-05 10:27:58.583087+00', '2026-05-05 10:27:58.583087+00', NULL);
INSERT INTO public.user_sessions VALUES (1205, 3, 'c75365b7-0be6-4d8c-b3e0-3d69d27c8aea', NULL, NULL, '2026-04-05 10:39:43.994215+00', '2026-05-05 10:39:43.994215+00', NULL);
INSERT INTO public.user_sessions VALUES (1206, 3, '57015420-6ba0-4987-bbfe-e12dd8d53bfc', NULL, NULL, '2026-04-05 10:44:41.344773+00', '2026-05-05 10:44:41.344773+00', NULL);
INSERT INTO public.user_sessions VALUES (1207, 3, '529158b4-9fff-4601-834c-3f71febcde05', NULL, NULL, '2026-04-05 10:55:21.21615+00', '2026-05-05 10:55:21.21615+00', NULL);
INSERT INTO public.user_sessions VALUES (1208, 3, '3d319803-9fb7-4187-bbcb-f790687d6de4', NULL, NULL, '2026-04-05 10:57:32.909838+00', '2026-05-05 10:57:32.909838+00', NULL);
INSERT INTO public.user_sessions VALUES (1209, 3, '5093f7ef-6e76-4dca-addb-c1c560ce90df', NULL, NULL, '2026-04-05 11:01:05.747397+00', '2026-05-05 11:01:05.747397+00', NULL);
INSERT INTO public.user_sessions VALUES (1210, 3, '538b3f6e-cca1-44c2-8257-9ff17baf8046', NULL, NULL, '2026-04-05 11:06:10.090589+00', '2026-05-05 11:06:10.090589+00', NULL);
INSERT INTO public.user_sessions VALUES (1211, 3, '92412b8f-9e6b-40f7-8d28-638dd5fc7858', NULL, NULL, '2026-04-05 11:09:31.036063+00', '2026-05-05 11:09:31.036063+00', NULL);
INSERT INTO public.user_sessions VALUES (1216, 3, 'b3e82044-0414-4bac-bd7b-8f06bb8fd7cc', NULL, NULL, '2026-04-05 11:31:19.45906+00', '2026-05-05 11:31:19.45906+00', NULL);
INSERT INTO public.user_sessions VALUES (1221, 3, 'eb22f371-a5a4-4826-a5c6-e834c4e16376', NULL, NULL, '2026-04-05 11:41:53.547742+00', '2026-05-05 11:41:53.547742+00', NULL);
INSERT INTO public.user_sessions VALUES (1226, 3, 'cc33b8dd-4041-4341-aea5-2fbbd6f84b0d', NULL, NULL, '2026-04-05 12:18:07.073556+00', '2026-05-05 12:18:07.073556+00', NULL);
INSERT INTO public.user_sessions VALUES (1231, 3, 'cafe0850-d290-4193-bedc-39a99c97519e', NULL, NULL, '2026-04-05 13:58:15.756149+00', '2026-05-05 13:58:15.756149+00', NULL);
INSERT INTO public.user_sessions VALUES (1236, 3, '9a2ef507-9096-4f7e-b35a-40e5d6c51719', NULL, NULL, '2026-04-05 14:18:05.39338+00', '2026-05-05 14:18:05.39338+00', NULL);
INSERT INTO public.user_sessions VALUES (1241, 3, 'c0d41bf1-bd96-4989-8ad2-4ffc347a128a', NULL, NULL, '2026-04-05 14:54:38.069197+00', '2026-05-05 14:54:38.069197+00', NULL);
INSERT INTO public.user_sessions VALUES (1246, 3, '8f19e2a5-324b-4173-8a56-37d5c4e8272a', NULL, NULL, '2026-04-05 15:22:21.314053+00', '2026-05-05 15:22:21.314053+00', NULL);
INSERT INTO public.user_sessions VALUES (1251, 3, '73e278ef-60f1-4091-8466-fddf73909eb1', NULL, NULL, '2026-04-05 16:36:13.972561+00', '2026-05-05 16:36:13.972561+00', NULL);
INSERT INTO public.user_sessions VALUES (1256, 3, 'ad80e20e-9723-409c-a4f7-083e52529b9c', NULL, NULL, '2026-04-05 17:50:24.921877+00', '2026-05-05 17:50:24.921877+00', NULL);
INSERT INTO public.user_sessions VALUES (1261, 3, '0e893a40-f58d-4607-b4d3-91deb6e1ea80', NULL, NULL, '2026-04-05 19:27:10.852344+00', '2026-05-05 19:27:10.852344+00', NULL);
INSERT INTO public.user_sessions VALUES (1212, 3, '1d5ac984-2480-444c-8cdc-6d4122c57af1', NULL, NULL, '2026-04-05 11:11:44.765776+00', '2026-05-05 11:11:44.765776+00', NULL);
INSERT INTO public.user_sessions VALUES (1217, 3, '5bb72e75-527f-4ca9-b9ef-46edbb48debb', NULL, NULL, '2026-04-05 11:31:51.58364+00', '2026-05-05 11:31:51.58364+00', NULL);
INSERT INTO public.user_sessions VALUES (1222, 3, '9ca51540-8ba8-4f8b-a5c2-672c08c92bb1', NULL, NULL, '2026-04-05 11:42:26.659365+00', '2026-05-05 11:42:26.659365+00', NULL);
INSERT INTO public.user_sessions VALUES (1227, 3, '179b2b0c-d925-4eba-8b4e-4c280ef772d4', NULL, NULL, '2026-04-05 12:20:25.890361+00', '2026-05-05 12:20:25.890361+00', NULL);
INSERT INTO public.user_sessions VALUES (1232, 3, '544896fc-1518-42c3-9a9b-e835bbfcbcb6', NULL, NULL, '2026-04-05 14:00:28.660135+00', '2026-05-05 14:00:28.660135+00', NULL);
INSERT INTO public.user_sessions VALUES (1237, 3, '6f5bd4bd-30e1-42b8-9669-594d91cf4ea2', NULL, NULL, '2026-04-05 14:20:59.239121+00', '2026-05-05 14:20:59.239121+00', NULL);
INSERT INTO public.user_sessions VALUES (1242, 3, '0f937eaa-27bf-4d05-b19e-3ce6dbee7859', NULL, NULL, '2026-04-05 14:58:20.282702+00', '2026-05-05 14:58:20.282702+00', NULL);
INSERT INTO public.user_sessions VALUES (1247, 3, '9f72fbd9-1d05-47c3-83ed-aba52253ea88', NULL, NULL, '2026-04-05 15:27:05.527305+00', '2026-05-05 15:27:05.527305+00', NULL);
INSERT INTO public.user_sessions VALUES (1252, 3, 'e4c9bccd-a568-4134-ad53-7706d299f428', NULL, NULL, '2026-04-05 16:57:59.666113+00', '2026-05-05 16:57:59.666113+00', NULL);
INSERT INTO public.user_sessions VALUES (1257, 3, '2ede587d-4a8d-4b29-8c03-bd8a3da9320a', NULL, NULL, '2026-04-05 18:04:23.702218+00', '2026-05-05 18:04:23.702218+00', NULL);
INSERT INTO public.user_sessions VALUES (1213, 3, 'd1dc78f5-b1b3-411f-a576-7d2a1b0b8c82', NULL, NULL, '2026-04-05 11:15:57.974162+00', '2026-05-05 11:15:57.974162+00', NULL);
INSERT INTO public.user_sessions VALUES (1218, 4, 'f3108e5e-6433-4396-8e79-74284f51a500', NULL, NULL, '2026-04-05 11:33:05.502003+00', '2026-05-05 11:33:05.502003+00', NULL);
INSERT INTO public.user_sessions VALUES (1223, 3, 'ea3bb40a-868d-40dc-ba35-b94d0f43b03b', NULL, NULL, '2026-04-05 11:42:57.663779+00', '2026-05-05 11:42:57.663779+00', NULL);
INSERT INTO public.user_sessions VALUES (1228, 3, 'd724da7f-a57d-46a4-b52c-841812ce1bba', NULL, NULL, '2026-04-05 12:23:11.727694+00', '2026-05-05 12:23:11.727694+00', NULL);
INSERT INTO public.user_sessions VALUES (1233, 3, '458fc799-2ce1-446f-90f7-476c148c00e6', NULL, NULL, '2026-04-05 14:05:11.899088+00', '2026-05-05 14:05:11.899088+00', NULL);
INSERT INTO public.user_sessions VALUES (1238, 3, '901ef198-bfae-4bf2-ab33-ba272c05607b', NULL, NULL, '2026-04-05 14:23:22.557081+00', '2026-05-05 14:23:22.557081+00', NULL);
INSERT INTO public.user_sessions VALUES (1243, 3, '2c9d9fae-61e9-4444-ab65-e7291d599e2f', NULL, NULL, '2026-04-05 15:02:43.745176+00', '2026-05-05 15:02:43.745176+00', NULL);
INSERT INTO public.user_sessions VALUES (1248, 3, '5cb0e6ae-a27a-41c9-b353-31fe6f68336c', NULL, NULL, '2026-04-05 15:37:29.916668+00', '2026-05-05 15:37:29.916668+00', NULL);
INSERT INTO public.user_sessions VALUES (1253, 3, 'cdb16b66-10be-4100-af67-011a8ec6a80a', NULL, NULL, '2026-04-05 17:07:36.250817+00', '2026-05-05 17:07:36.250817+00', NULL);
INSERT INTO public.user_sessions VALUES (1258, 3, '5b6b0564-01ce-4b69-9fce-ae4c876389e7', NULL, NULL, '2026-04-05 18:10:15.462129+00', '2026-05-05 18:10:15.462129+00', NULL);
INSERT INTO public.user_sessions VALUES (1214, 3, '3ee2866a-ef37-4fd6-a2b2-6ee6551f5fa8', NULL, NULL, '2026-04-05 11:17:52.110834+00', '2026-05-05 11:17:52.110834+00', NULL);
INSERT INTO public.user_sessions VALUES (1219, 3, '3c328b07-e83c-4e24-8850-0788c7ceee0f', NULL, NULL, '2026-04-05 11:33:47.507164+00', '2026-05-05 11:33:47.507164+00', NULL);
INSERT INTO public.user_sessions VALUES (1224, 3, 'd468f6c4-ece1-448b-8646-83676bc5b06b', NULL, NULL, '2026-04-05 11:43:28.906465+00', '2026-05-05 11:43:28.906465+00', NULL);
INSERT INTO public.user_sessions VALUES (1229, 3, '12373484-44f1-44aa-a47a-d6c220d9331f', NULL, NULL, '2026-04-05 13:06:05.429365+00', '2026-05-05 13:06:05.429365+00', NULL);
INSERT INTO public.user_sessions VALUES (1234, 3, '512a2051-0eef-4b3c-adcc-4aa7b9eaa429', NULL, NULL, '2026-04-05 14:11:04.866268+00', '2026-05-05 14:11:04.866268+00', NULL);
INSERT INTO public.user_sessions VALUES (1239, 3, '2d225e52-6c38-4404-9afc-4c4fbda620bb', NULL, NULL, '2026-04-05 14:26:47.2579+00', '2026-05-05 14:26:47.2579+00', NULL);
INSERT INTO public.user_sessions VALUES (1244, 3, '684dfeb5-af2e-4f21-b041-c0c24ac09e2e', NULL, NULL, '2026-04-05 15:14:24.675285+00', '2026-05-05 15:14:24.675285+00', NULL);
INSERT INTO public.user_sessions VALUES (1249, 3, 'a628d17f-17c7-4149-a8cc-555ebbd5f41a', NULL, NULL, '2026-04-05 15:55:16.712658+00', '2026-05-05 15:55:16.712658+00', NULL);
INSERT INTO public.user_sessions VALUES (1254, 3, '6e1dd570-c074-4b3c-bc55-545b4fb41ed6', NULL, NULL, '2026-04-05 17:16:48.843286+00', '2026-05-05 17:16:48.843286+00', NULL);
INSERT INTO public.user_sessions VALUES (1259, 3, 'edaa6237-6032-4416-b9bc-eecb9bb59a58', NULL, NULL, '2026-04-05 18:40:24.068072+00', '2026-05-05 18:40:24.068072+00', NULL);
INSERT INTO public.user_sessions VALUES (1215, 3, '86a2191f-e3b2-4aad-b887-6665d40607f8', NULL, NULL, '2026-04-05 11:28:48.359349+00', '2026-05-05 11:28:48.359349+00', NULL);
INSERT INTO public.user_sessions VALUES (1220, 4, '9ba29002-2275-4f99-8e77-a9e7d503d5b2', NULL, NULL, '2026-04-05 11:34:01.849702+00', '2026-05-05 11:34:01.849702+00', NULL);
INSERT INTO public.user_sessions VALUES (1225, 3, '379f1cc5-4396-4ace-8d3b-2617a3d22d39', NULL, NULL, '2026-04-05 11:47:38.089706+00', '2026-05-05 11:47:38.089706+00', NULL);
INSERT INTO public.user_sessions VALUES (1230, 3, 'a49cc8c5-f000-4cf8-bb98-d4c0b6bb1bcc', NULL, NULL, '2026-04-05 13:10:36.70808+00', '2026-05-05 13:10:36.70808+00', NULL);
INSERT INTO public.user_sessions VALUES (1235, 3, '3416e41d-63f6-409a-82bd-8fe200e2efb9', NULL, NULL, '2026-04-05 14:14:20.412345+00', '2026-05-05 14:14:20.412345+00', NULL);
INSERT INTO public.user_sessions VALUES (1240, 3, 'e3bbf1ba-104e-48bb-a174-636dca38d56f', NULL, NULL, '2026-04-05 14:27:50.839669+00', '2026-05-05 14:27:50.839669+00', NULL);
INSERT INTO public.user_sessions VALUES (1245, 3, '1cc1bbbf-ccf4-47d3-b85d-96e810856d25', NULL, NULL, '2026-04-05 15:19:34.478353+00', '2026-05-05 15:19:34.478353+00', NULL);
INSERT INTO public.user_sessions VALUES (1250, 3, 'ce447375-7294-4474-b4a0-13b65c6bb884', NULL, NULL, '2026-04-05 16:13:44.76846+00', '2026-05-05 16:13:44.76846+00', NULL);
INSERT INTO public.user_sessions VALUES (1255, 3, '35337c08-a2f6-4b26-83e8-7fd999bccd77', NULL, NULL, '2026-04-05 17:19:18.484184+00', '2026-05-05 17:19:18.484184+00', NULL);
INSERT INTO public.user_sessions VALUES (1260, 3, 'fc974c9c-cd8d-4704-a8a1-1c0f36dd7be9', NULL, NULL, '2026-04-05 19:02:33.623354+00', '2026-05-05 19:02:33.623354+00', NULL);
INSERT INTO public.user_sessions VALUES (1262, 3, '93e783dc-434b-468c-bf22-e57e7c6485e6', NULL, NULL, '2026-04-06 09:22:42.111222+00', '2026-05-06 09:22:42.111222+00', NULL);
INSERT INTO public.user_sessions VALUES (1263, 3, 'c6d93155-cf59-440b-9f74-57178bac6b3b', NULL, NULL, '2026-04-06 09:23:32.235172+00', '2026-05-06 09:23:32.235172+00', NULL);
INSERT INTO public.user_sessions VALUES (1264, 3, '32c6011d-3ace-41f3-a689-4df3375956c7', NULL, NULL, '2026-04-06 09:24:44.110552+00', '2026-05-06 09:24:44.110552+00', NULL);
INSERT INTO public.user_sessions VALUES (1265, 3, 'fb5882bf-ef56-4e33-af72-4ec4c61c7431', NULL, NULL, '2026-04-06 14:06:18.659773+00', '2026-05-06 14:06:18.659773+00', NULL);
INSERT INTO public.user_sessions VALUES (1266, 3, 'e475d744-c36f-4b9e-b03b-250b53df4cf3', NULL, NULL, '2026-04-06 14:07:56.945969+00', '2026-05-06 14:07:56.945969+00', NULL);
INSERT INTO public.user_sessions VALUES (1267, 3, '6fcdddba-09a4-4f78-926a-76bc6163d272', NULL, NULL, '2026-04-06 14:08:37.606176+00', '2026-05-06 14:08:37.606176+00', NULL);
INSERT INTO public.user_sessions VALUES (1268, 3, 'd60d1dc9-9bf6-4c44-b1dc-20ac74570ce3', NULL, NULL, '2026-04-06 14:09:58.899962+00', '2026-05-06 14:09:58.899962+00', NULL);
INSERT INTO public.user_sessions VALUES (1269, 3, 'c693541c-9695-44bc-9bb1-408fe0823971', NULL, NULL, '2026-04-06 16:42:42.949755+00', '2026-05-06 16:42:42.949755+00', NULL);
INSERT INTO public.user_sessions VALUES (1270, 3, '0a179643-9b33-4ce4-9ff2-d9637a1e893c', NULL, NULL, '2026-04-06 16:44:34.3568+00', '2026-05-06 16:44:34.3568+00', NULL);
INSERT INTO public.user_sessions VALUES (1271, 3, '0f34d951-1484-4e9c-9f7b-0bb4c0e31cac', NULL, NULL, '2026-04-06 16:47:29.840437+00', '2026-05-06 16:47:29.840437+00', NULL);
INSERT INTO public.user_sessions VALUES (1272, 3, '3f2a7226-e775-49dc-bddb-23d9d64c28fb', NULL, NULL, '2026-04-06 16:49:17.324707+00', '2026-05-06 16:49:17.324707+00', NULL);
INSERT INTO public.user_sessions VALUES (1273, 3, 'd0add8d6-b08a-4597-9011-52d057069e21', NULL, NULL, '2026-04-06 16:56:04.723511+00', '2026-05-06 16:56:04.723511+00', NULL);
INSERT INTO public.user_sessions VALUES (1274, 3, 'ddd041f9-8e6a-4c6e-90ef-5b29cff8cfd2', NULL, NULL, '2026-04-06 16:56:58.642418+00', '2026-05-06 16:56:58.642418+00', NULL);
INSERT INTO public.user_sessions VALUES (1275, 3, 'b8a3e2d4-554d-4937-96c5-e32f072aede2', NULL, NULL, '2026-04-06 17:00:44.855215+00', '2026-05-06 17:00:44.855215+00', NULL);
INSERT INTO public.user_sessions VALUES (1276, 3, 'fdc5b3dd-f99f-4f27-a5f4-b44e3e53e371', NULL, NULL, '2026-04-06 17:04:21.022601+00', '2026-05-06 17:04:21.022601+00', NULL);
INSERT INTO public.user_sessions VALUES (1277, 3, '53a03a79-3153-4cbe-9039-0fca1355b596', NULL, NULL, '2026-04-06 17:06:46.764896+00', '2026-05-06 17:06:46.764896+00', NULL);
INSERT INTO public.user_sessions VALUES (1278, 3, '77be0048-10ef-4fb4-bba0-fb0255ae493a', NULL, NULL, '2026-04-06 17:09:10.086262+00', '2026-05-06 17:09:10.086262+00', NULL);
INSERT INTO public.user_sessions VALUES (1279, 3, '19c7e0cb-e2de-4582-a734-cf66f020767b', NULL, NULL, '2026-04-06 17:19:06.953029+00', '2026-05-06 17:19:06.953029+00', NULL);
INSERT INTO public.user_sessions VALUES (1280, 3, '1933ac2f-69e3-47e8-a21f-713b4a799c80', NULL, NULL, '2026-04-06 17:20:38.554413+00', '2026-05-06 17:20:38.554413+00', NULL);
INSERT INTO public.user_sessions VALUES (1281, 3, '47a3a82a-bd73-478b-8f28-dfb2f9060676', NULL, NULL, '2026-04-06 17:20:50.220947+00', '2026-05-06 17:20:50.220947+00', NULL);
INSERT INTO public.user_sessions VALUES (1282, 3, '3cdc441d-59f9-4990-b36a-c846d504b347', NULL, NULL, '2026-04-06 17:21:23.979767+00', '2026-05-06 17:21:23.979767+00', NULL);
INSERT INTO public.user_sessions VALUES (1283, 3, 'c2eb7b84-58eb-4a43-98f4-74465271d3d1', NULL, NULL, '2026-04-06 17:22:26.350622+00', '2026-05-06 17:22:26.350622+00', NULL);
INSERT INTO public.user_sessions VALUES (1284, 4, '0ac2aa1e-b440-4d35-a04b-97d5e9a3b444', NULL, NULL, '2026-04-06 17:22:30.954272+00', '2026-05-06 17:22:30.954272+00', NULL);
INSERT INTO public.user_sessions VALUES (1285, 3, '77df94af-7209-4bef-aa3b-febbd510a3a9', NULL, NULL, '2026-04-06 17:23:33.360861+00', '2026-05-06 17:23:33.360861+00', NULL);
INSERT INTO public.user_sessions VALUES (1286, 3, '7d3e3a74-1ff2-436a-882c-f414c3593b3c', NULL, NULL, '2026-04-06 17:24:27.836565+00', '2026-05-06 17:24:27.836565+00', NULL);
INSERT INTO public.user_sessions VALUES (1287, 3, 'df1c917b-b835-4df1-9610-e5326850d544', NULL, NULL, '2026-04-06 17:52:40.875995+00', '2026-05-06 17:52:40.875995+00', NULL);
INSERT INTO public.user_sessions VALUES (1288, 3, 'f881ff7a-000d-4d08-b9d3-0ba5d0ce526e', NULL, NULL, '2026-04-06 17:56:07.454506+00', '2026-05-06 17:56:07.454506+00', NULL);
INSERT INTO public.user_sessions VALUES (1289, 3, 'fe1f80b6-3a9d-481e-9295-e149a868ace6', NULL, NULL, '2026-04-06 18:01:19.257136+00', '2026-05-06 18:01:19.257136+00', NULL);
INSERT INTO public.user_sessions VALUES (1290, 3, '99fa0f71-5c90-4b8d-8cac-5c1b3a27dc38', NULL, NULL, '2026-04-06 18:11:12.69455+00', '2026-05-06 18:11:12.69455+00', NULL);
INSERT INTO public.user_sessions VALUES (1291, 3, '3ecdc369-619d-4c0a-bb70-eafa55d80974', NULL, NULL, '2026-04-06 18:12:06.986826+00', '2026-05-06 18:12:06.986826+00', NULL);
INSERT INTO public.user_sessions VALUES (1292, 3, 'b28923d2-ff4d-4a29-9a9c-e8a5364e7481', NULL, NULL, '2026-04-06 18:19:44.897158+00', '2026-05-06 18:19:44.897158+00', NULL);
INSERT INTO public.user_sessions VALUES (1293, 3, '6f2847cb-6b6b-42a2-ba9b-3db7329247d0', NULL, NULL, '2026-04-06 18:57:29.143926+00', '2026-05-06 18:57:29.143926+00', NULL);
INSERT INTO public.user_sessions VALUES (1294, 3, '077ef6cb-3394-4079-877c-371fe4baa7ce', NULL, NULL, '2026-04-06 19:33:50.734983+00', '2026-05-06 19:33:50.734983+00', NULL);
INSERT INTO public.user_sessions VALUES (1295, 3, 'c486abb9-b024-4192-a05b-39baba6b4e7f', NULL, NULL, '2026-04-06 19:34:51.89554+00', '2026-05-06 19:34:51.89554+00', NULL);
INSERT INTO public.user_sessions VALUES (1296, 3, '0395ad42-d9fe-4f75-942d-98c13990d2b5', NULL, NULL, '2026-04-06 19:49:26.97438+00', '2026-05-06 19:49:26.97438+00', NULL);
INSERT INTO public.user_sessions VALUES (1297, 4, '88040aa6-f681-428b-a4ba-95e3e57ddc8f', NULL, NULL, '2026-04-06 19:55:17.471135+00', '2026-05-06 19:55:17.471135+00', NULL);
INSERT INTO public.user_sessions VALUES (1298, 3, 'c86ca132-d884-409e-bb2b-6122eb0d70dd', NULL, NULL, '2026-04-06 20:01:08.668275+00', '2026-05-06 20:01:08.668275+00', NULL);
INSERT INTO public.user_sessions VALUES (1299, 3, 'b3242aca-39ad-48b1-a9c7-396aa3047506', NULL, NULL, '2026-04-07 10:28:45.258453+00', '2026-05-07 10:28:45.258453+00', NULL);
INSERT INTO public.user_sessions VALUES (1300, 3, 'bbeedcf7-21a6-459b-b390-3aece67299e4', NULL, NULL, '2026-04-07 10:30:56.12146+00', '2026-05-07 10:30:56.12146+00', NULL);
INSERT INTO public.user_sessions VALUES (1301, 3, '97c2315e-c09c-4f30-8e58-2f1d196ad8dc', NULL, NULL, '2026-04-07 12:12:25.425214+00', '2026-05-07 12:12:25.425214+00', NULL);
INSERT INTO public.user_sessions VALUES (1302, 3, 'c10533ea-c604-4a8f-81c9-795c8cef3fae', NULL, NULL, '2026-04-07 12:45:48.236902+00', '2026-05-07 12:45:48.236902+00', NULL);
INSERT INTO public.user_sessions VALUES (1303, 3, '7319a180-e7d1-4f9d-ad86-e94dabbfd47b', NULL, NULL, '2026-04-07 12:47:13.19955+00', '2026-05-07 12:47:13.19955+00', NULL);
INSERT INTO public.user_sessions VALUES (1304, 3, 'a4ed9b52-927b-4c53-a2a9-616ef4a55ec8', NULL, NULL, '2026-04-07 12:56:34.130793+00', '2026-05-07 12:56:34.130793+00', NULL);
INSERT INTO public.user_sessions VALUES (1305, 3, 'b41b4f75-d91e-4436-9ca7-5527317c8bec', NULL, NULL, '2026-04-07 13:15:56.411232+00', '2026-05-07 13:15:56.411232+00', NULL);
INSERT INTO public.user_sessions VALUES (1306, 3, '0d44e2f6-6e6c-42df-bc61-3e5b9155fec2', NULL, NULL, '2026-04-07 13:24:50.727234+00', '2026-05-07 13:24:50.727234+00', NULL);
INSERT INTO public.user_sessions VALUES (1307, 3, '88af5e6b-d692-4a34-94f5-150b589cda62', NULL, NULL, '2026-04-07 13:26:08.991469+00', '2026-05-07 13:26:08.991469+00', NULL);
INSERT INTO public.user_sessions VALUES (1308, 3, 'da5b69ea-1abc-49ab-926b-0a5990cb782a', NULL, NULL, '2026-04-07 13:38:51.026093+00', '2026-05-07 13:38:51.026093+00', NULL);
INSERT INTO public.user_sessions VALUES (1309, 3, 'a24ea0ee-d310-472f-9d24-91f61941d4e6', NULL, NULL, '2026-04-07 13:47:59.799899+00', '2026-05-07 13:47:59.799899+00', NULL);
INSERT INTO public.user_sessions VALUES (1310, 3, '447ee0d7-41b2-443c-b8fb-4c5a65fe30c5', NULL, NULL, '2026-04-07 13:56:47.59472+00', '2026-05-07 13:56:47.59472+00', NULL);
INSERT INTO public.user_sessions VALUES (1311, 3, 'f217b8aa-270d-4c50-b438-dce3e5ebf99f', NULL, NULL, '2026-04-07 13:59:59.541378+00', '2026-05-07 13:59:59.541378+00', NULL);
INSERT INTO public.user_sessions VALUES (1312, 3, '93d7a115-634c-43c7-ae1f-d063b0c27ea1', NULL, NULL, '2026-04-07 14:04:04.207533+00', '2026-05-07 14:04:04.207533+00', NULL);
INSERT INTO public.user_sessions VALUES (1313, 3, 'ef0f5e97-a943-4ef9-869d-b8543e045568', NULL, NULL, '2026-04-07 14:15:16.9071+00', '2026-05-07 14:15:16.9071+00', NULL);
INSERT INTO public.user_sessions VALUES (1314, 3, 'ffa47228-2df7-49d8-96c4-e4f8a5847dfe', NULL, NULL, '2026-04-07 14:16:30.891104+00', '2026-05-07 14:16:30.891104+00', NULL);
INSERT INTO public.user_sessions VALUES (1315, 3, '9c4fa2f0-7c6b-47d7-ac2e-33f616331611', NULL, NULL, '2026-04-07 14:22:04.392662+00', '2026-05-07 14:22:04.392662+00', NULL);
INSERT INTO public.user_sessions VALUES (1316, 3, '67e0b30a-1b77-4889-858f-0ac1fbe2e2e6', NULL, NULL, '2026-04-07 14:57:48.491181+00', '2026-05-07 14:57:48.491181+00', NULL);
INSERT INTO public.user_sessions VALUES (1317, 3, '3096f12c-0adb-4509-ab58-6454aeeb60f1', NULL, NULL, '2026-04-07 14:58:52.909656+00', '2026-05-07 14:58:52.909656+00', NULL);
INSERT INTO public.user_sessions VALUES (1318, 3, '405f414c-1f75-4522-9fb2-e0cdb3b8150b', NULL, NULL, '2026-04-07 14:59:05.038147+00', '2026-05-07 14:59:05.038147+00', NULL);
INSERT INTO public.user_sessions VALUES (1319, 3, '99434e70-975d-4c5d-ad9b-e23a8c5ad431', NULL, NULL, '2026-04-07 15:18:56.116046+00', '2026-05-07 15:18:56.116046+00', NULL);
INSERT INTO public.user_sessions VALUES (1320, 3, 'bb38d464-e77f-40c7-a88c-e6150308e238', NULL, NULL, '2026-04-07 15:20:50.689118+00', '2026-05-07 15:20:50.689118+00', NULL);
INSERT INTO public.user_sessions VALUES (1321, 3, '29df9583-6b4e-4201-bff3-8dc3efda2ccd', NULL, NULL, '2026-04-07 15:22:40.292438+00', '2026-05-07 15:22:40.292438+00', NULL);
INSERT INTO public.user_sessions VALUES (1322, 3, '8d897045-47d2-4748-a453-934c86493322', NULL, NULL, '2026-04-07 15:27:52.053587+00', '2026-05-07 15:27:52.053587+00', NULL);
INSERT INTO public.user_sessions VALUES (1323, 3, '83e1b121-6061-4a6b-ab74-7f324f62f600', NULL, NULL, '2026-04-07 15:30:20.135472+00', '2026-05-07 15:30:20.135472+00', NULL);
INSERT INTO public.user_sessions VALUES (1324, 3, '3e846cb4-edcf-4e90-9ae8-a62298137b6b', NULL, NULL, '2026-04-07 16:01:28.868868+00', '2026-05-07 16:01:28.868868+00', NULL);
INSERT INTO public.user_sessions VALUES (1325, 3, 'dc0b9604-4729-4bbb-aeae-d0905fdfc884', NULL, NULL, '2026-04-07 16:02:09.8541+00', '2026-05-07 16:02:09.8541+00', NULL);
INSERT INTO public.user_sessions VALUES (1326, 3, '257fd88c-02b6-4b65-831c-7153843f61c2', NULL, NULL, '2026-04-07 16:08:37.409414+00', '2026-05-07 16:08:37.409414+00', NULL);
INSERT INTO public.user_sessions VALUES (1327, 3, '52034697-e069-4d6f-9944-3c69773a2cab', NULL, NULL, '2026-04-07 16:28:08.522908+00', '2026-05-07 16:28:08.522908+00', NULL);
INSERT INTO public.user_sessions VALUES (1328, 3, '10fe60a7-1210-49b7-a92f-9bfc9e30c9b1', NULL, NULL, '2026-04-07 16:30:13.699503+00', '2026-05-07 16:30:13.699503+00', NULL);
INSERT INTO public.user_sessions VALUES (1329, 3, '0e629f20-3ffc-4b29-b734-c70a44ef3d9f', NULL, NULL, '2026-04-07 16:31:30.040354+00', '2026-05-07 16:31:30.040354+00', NULL);
INSERT INTO public.user_sessions VALUES (1330, 3, 'b12a27e7-2ef6-49d6-a189-f1d833e1b201', NULL, NULL, '2026-04-07 16:44:35.614244+00', '2026-05-07 16:44:35.614244+00', NULL);
INSERT INTO public.user_sessions VALUES (1331, 3, '9a585fd7-f79f-4c1b-a30b-0e050a8d0135', NULL, NULL, '2026-04-07 16:59:12.809189+00', '2026-05-07 16:59:12.809189+00', NULL);
INSERT INTO public.user_sessions VALUES (1332, 3, 'be7dcf42-719f-4646-8f56-10b5e05a6341', NULL, NULL, '2026-04-07 17:03:31.29922+00', '2026-05-07 17:03:31.29922+00', NULL);
INSERT INTO public.user_sessions VALUES (1333, 3, '897b8bf2-b354-4a76-b6ca-cc99e7d52eb6', NULL, NULL, '2026-04-07 17:04:45.288885+00', '2026-05-07 17:04:45.288885+00', NULL);
INSERT INTO public.user_sessions VALUES (1338, 3, '811613cc-3fe0-48df-8d95-4afd280d310b', NULL, NULL, '2026-04-07 17:53:13.488495+00', '2026-05-07 17:53:13.488495+00', NULL);
INSERT INTO public.user_sessions VALUES (1343, 3, '12c84350-fea5-4ddf-90b8-e8eff8342b65', NULL, NULL, '2026-04-07 19:03:54.408672+00', '2026-05-07 19:03:54.408672+00', NULL);
INSERT INTO public.user_sessions VALUES (1334, 3, 'f777f144-968e-4207-a72c-20292d68393e', NULL, NULL, '2026-04-07 17:05:12.492276+00', '2026-05-07 17:05:12.492276+00', NULL);
INSERT INTO public.user_sessions VALUES (1339, 3, '3b5413c2-4680-40ab-96f8-2a43c91bdc51', NULL, NULL, '2026-04-07 17:56:07.39976+00', '2026-05-07 17:56:07.39976+00', NULL);
INSERT INTO public.user_sessions VALUES (1335, 3, 'f9aa05f9-1c39-4277-9847-6e1363e0a389', NULL, NULL, '2026-04-07 17:09:06.029827+00', '2026-05-07 17:09:06.029827+00', NULL);
INSERT INTO public.user_sessions VALUES (1340, 3, 'be66e395-3096-4d4e-b4a8-a6bd853288fb', NULL, NULL, '2026-04-07 18:42:46.800358+00', '2026-05-07 18:42:46.800358+00', NULL);
INSERT INTO public.user_sessions VALUES (1336, 3, '272c6b5e-4dc3-4d80-b38e-baf95d7c0f20', NULL, NULL, '2026-04-07 17:16:34.80991+00', '2026-05-07 17:16:34.80991+00', NULL);
INSERT INTO public.user_sessions VALUES (1341, 3, '9d487071-83c0-4211-9237-a869da8da406', NULL, NULL, '2026-04-07 18:52:35.6055+00', '2026-05-07 18:52:35.6055+00', NULL);
INSERT INTO public.user_sessions VALUES (1337, 3, '63bcbfc5-a7f7-4745-bd07-14f715ebb9b1', NULL, NULL, '2026-04-07 17:29:54.759279+00', '2026-05-07 17:29:54.759279+00', NULL);
INSERT INTO public.user_sessions VALUES (1342, 3, 'ed5b860b-c1d1-4f4f-9077-be70a9230374', NULL, NULL, '2026-04-07 18:55:37.004991+00', '2026-05-07 18:55:37.004991+00', NULL);
INSERT INTO public.user_sessions VALUES (1344, 3, 'f5a2919b-fb76-41d1-9312-f2a1d60e13b5', NULL, NULL, '2026-04-08 10:52:25.253424+00', '2026-05-08 10:52:25.253424+00', NULL);
INSERT INTO public.user_sessions VALUES (1345, 3, 'fb732c23-e251-4b08-a047-d002488ed8b0', NULL, NULL, '2026-04-08 11:00:24.986667+00', '2026-05-08 11:00:24.986667+00', NULL);
INSERT INTO public.user_sessions VALUES (1346, 3, 'd35c7589-1aa6-45c9-a20b-020e883cd16d', NULL, NULL, '2026-04-08 11:15:50.822388+00', '2026-05-08 11:15:50.822388+00', NULL);
INSERT INTO public.user_sessions VALUES (1347, 3, 'ab3e63ff-c4e2-42c5-b8a8-746e0fce033b', NULL, NULL, '2026-04-08 12:52:37.159955+00', '2026-05-08 12:52:37.159955+00', NULL);
INSERT INTO public.user_sessions VALUES (1348, 3, 'ec36469c-cad4-4f84-aada-f6fbbea9ab00', NULL, NULL, '2026-04-08 12:53:54.186859+00', '2026-05-08 12:53:54.186859+00', NULL);
INSERT INTO public.user_sessions VALUES (1349, 3, '0cf64ee6-8824-4983-91da-78abdd13017e', NULL, NULL, '2026-04-08 13:09:28.872513+00', '2026-05-08 13:09:28.872513+00', NULL);
INSERT INTO public.user_sessions VALUES (1350, 3, '5b4cf337-a347-4626-bf66-9311bc1b3d49', NULL, NULL, '2026-04-08 14:01:26.957139+00', '2026-05-08 14:01:26.957139+00', NULL);
INSERT INTO public.user_sessions VALUES (1351, 3, '9824c9da-3452-4d83-a568-dc679274924f', NULL, NULL, '2026-04-08 14:06:32.554825+00', '2026-05-08 14:06:32.554825+00', NULL);
INSERT INTO public.user_sessions VALUES (1352, 3, 'be7d5965-a2c2-437c-bc09-4e33fed84087', NULL, NULL, '2026-04-08 15:16:26.939166+00', '2026-05-08 15:16:26.939166+00', NULL);
INSERT INTO public.user_sessions VALUES (1353, 3, 'd3c5fce4-e2ba-4b52-8f2d-dd4927b245de', NULL, NULL, '2026-04-08 15:17:57.502798+00', '2026-05-08 15:17:57.502798+00', NULL);
INSERT INTO public.user_sessions VALUES (1354, 3, '66c4fd6b-aea1-4cef-8cea-851968303127', NULL, NULL, '2026-04-08 15:25:56.998874+00', '2026-05-08 15:25:56.998874+00', NULL);
INSERT INTO public.user_sessions VALUES (1355, 3, 'd8fe30c8-ab35-4813-a38c-035e075ad9e2', NULL, NULL, '2026-04-08 15:27:08.257453+00', '2026-05-08 15:27:08.257453+00', NULL);
INSERT INTO public.user_sessions VALUES (1356, 3, 'd5492b09-b72b-4c5b-b0e9-6f0de93722d8', NULL, NULL, '2026-04-08 15:44:00.175309+00', '2026-05-08 15:44:00.175309+00', NULL);
INSERT INTO public.user_sessions VALUES (1357, 3, 'be85b040-318a-4b38-86d3-4a7171f142f5', NULL, NULL, '2026-04-08 15:58:06.898213+00', '2026-05-08 15:58:06.898213+00', NULL);
INSERT INTO public.user_sessions VALUES (1358, 3, '02c0fb9b-a928-4dd5-ab39-4252940c049d', NULL, NULL, '2026-04-08 16:13:16.655075+00', '2026-05-08 16:13:16.655075+00', NULL);
INSERT INTO public.user_sessions VALUES (1359, 3, 'ea569573-78a9-466c-82df-01adc9ffda48', NULL, NULL, '2026-04-08 16:13:55.948194+00', '2026-05-08 16:13:55.948194+00', NULL);
INSERT INTO public.user_sessions VALUES (1360, 3, '4c57e7e3-2442-4119-93ca-b7291df5552a', NULL, NULL, '2026-04-08 17:09:05.39532+00', '2026-05-08 17:09:05.39532+00', NULL);
INSERT INTO public.user_sessions VALUES (1361, 3, '638f3155-1abd-40b0-bd5e-1e8915424a14', NULL, NULL, '2026-04-08 17:12:37.967398+00', '2026-05-08 17:12:37.967398+00', NULL);
INSERT INTO public.user_sessions VALUES (1362, 3, 'ca845ab5-d3fa-4311-9994-3f37fe585da4', NULL, NULL, '2026-04-08 17:14:24.658309+00', '2026-05-08 17:14:24.658309+00', NULL);
INSERT INTO public.user_sessions VALUES (1363, 3, '6ae7195b-25af-45dd-8ee1-123a41520592', NULL, NULL, '2026-04-08 17:25:04.178423+00', '2026-05-08 17:25:04.178423+00', NULL);
INSERT INTO public.user_sessions VALUES (1364, 3, '0750393c-0677-49d1-b037-516c084da088', NULL, NULL, '2026-04-08 17:27:52.989047+00', '2026-05-08 17:27:52.989047+00', NULL);
INSERT INTO public.user_sessions VALUES (1365, 3, '58bb0da5-b51e-42e4-aed2-bcedd6693c4c', NULL, NULL, '2026-04-08 17:34:53.422273+00', '2026-05-08 17:34:53.422273+00', NULL);
INSERT INTO public.user_sessions VALUES (1366, 3, 'f65c734f-0d00-4d06-a0b6-6256f590d0dc', NULL, NULL, '2026-04-08 17:40:17.704685+00', '2026-05-08 17:40:17.704685+00', NULL);
INSERT INTO public.user_sessions VALUES (1367, 3, '60a598fb-a223-4fca-9443-be6e53654e9a', NULL, NULL, '2026-04-08 17:42:01.894606+00', '2026-05-08 17:42:01.894606+00', NULL);
INSERT INTO public.user_sessions VALUES (1368, 3, 'c3264fbb-3a68-42e6-a3db-8abd0586c462', NULL, NULL, '2026-04-08 17:43:28.646193+00', '2026-05-08 17:43:28.646193+00', NULL);
INSERT INTO public.user_sessions VALUES (1369, 3, '17a64f93-f120-4f89-bce6-23697f79929d', NULL, NULL, '2026-04-08 17:44:28.593559+00', '2026-05-08 17:44:28.593559+00', NULL);
INSERT INTO public.user_sessions VALUES (1370, 3, '222a9e6b-ccad-4ddd-9f23-d984196b3e50', NULL, NULL, '2026-04-08 17:48:45.371776+00', '2026-05-08 17:48:45.371776+00', NULL);
INSERT INTO public.user_sessions VALUES (1371, 3, '7cd31dd0-bfc3-4d4d-8d22-2e2f396ec02d', NULL, NULL, '2026-04-08 18:22:04.210235+00', '2026-05-08 18:22:04.210235+00', NULL);
INSERT INTO public.user_sessions VALUES (1372, 4, '7696ad80-08b3-4687-b750-59e4e96d207a', NULL, NULL, '2026-04-08 18:23:48.59954+00', '2026-05-08 18:23:48.59954+00', NULL);
INSERT INTO public.user_sessions VALUES (1373, 4, '32c073fe-fd82-41f3-b6a8-e6532b935b20', NULL, NULL, '2026-04-08 18:25:28.376181+00', '2026-05-08 18:25:28.376181+00', NULL);
INSERT INTO public.user_sessions VALUES (1374, 3, '70bdf166-6576-4a80-8488-ba1e762b241a', NULL, NULL, '2026-04-08 18:25:39.89373+00', '2026-05-08 18:25:39.89373+00', NULL);
INSERT INTO public.user_sessions VALUES (1375, 3, '322a9e27-13ab-4272-a88f-3b43269cef98', NULL, NULL, '2026-04-08 18:51:17.231056+00', '2026-05-08 18:51:17.231056+00', NULL);
INSERT INTO public.user_sessions VALUES (1376, 3, '02a22ea0-b6b5-4627-a04e-585a273153e4', NULL, NULL, '2026-04-09 08:31:41.035334+00', '2026-05-09 08:31:41.035334+00', NULL);
INSERT INTO public.user_sessions VALUES (1377, 4, '303f849e-22b5-49ee-8e68-7731debf6206', NULL, NULL, '2026-04-09 08:31:55.092539+00', '2026-05-09 08:31:55.092539+00', NULL);
INSERT INTO public.user_sessions VALUES (1378, 3, '42f3e5a5-3015-4795-b3ac-829f2dfb6ab5', NULL, NULL, '2026-04-09 08:41:47.501373+00', '2026-05-09 08:41:47.501373+00', NULL);
INSERT INTO public.user_sessions VALUES (1379, 4, 'cb26e723-330b-49b5-a9c7-14c69bd2ae03', NULL, NULL, '2026-04-09 08:41:56.80707+00', '2026-05-09 08:41:56.80707+00', NULL);
INSERT INTO public.user_sessions VALUES (1380, 4, 'aacf36a0-58bd-4e56-ab52-6ceb4ceccb96', NULL, NULL, '2026-04-09 09:27:33.810245+00', '2026-05-09 09:27:33.810245+00', NULL);
INSERT INTO public.user_sessions VALUES (1381, 3, '0e4ba0e9-8494-48ff-a843-cef163192ea2', NULL, NULL, '2026-04-09 09:27:40.035081+00', '2026-05-09 09:27:40.035081+00', NULL);
INSERT INTO public.user_sessions VALUES (1382, 3, '62b470c6-86ea-4114-8f51-f53f0c544e23', NULL, NULL, '2026-04-09 09:39:55.572924+00', '2026-05-09 09:39:55.572924+00', NULL);
INSERT INTO public.user_sessions VALUES (1383, 4, '4e8917b9-4269-4ae0-836a-7a01b13fdcc8', NULL, NULL, '2026-04-09 09:39:59.950285+00', '2026-05-09 09:39:59.950285+00', NULL);
INSERT INTO public.user_sessions VALUES (1384, 4, '8baba32d-a628-4030-86db-0218def6a73c', NULL, NULL, '2026-04-09 09:41:18.931441+00', '2026-05-09 09:41:18.931441+00', NULL);
INSERT INTO public.user_sessions VALUES (1385, 3, '63365125-bfe9-465c-a767-0d1adae92514', NULL, NULL, '2026-04-09 09:41:27.437778+00', '2026-05-09 09:41:27.437778+00', NULL);
INSERT INTO public.user_sessions VALUES (1386, 4, '9178541b-0383-4699-8707-bce45d77e1d1', NULL, NULL, '2026-04-09 09:43:23.135362+00', '2026-05-09 09:43:23.135362+00', NULL);
INSERT INTO public.user_sessions VALUES (1387, 3, 'bd78f51f-3644-4d49-b9de-918fba85ae1d', NULL, NULL, '2026-04-09 09:43:26.267945+00', '2026-05-09 09:43:26.267945+00', NULL);
INSERT INTO public.user_sessions VALUES (1388, 3, '12387d52-5fef-4192-b46b-37baa8abb307', NULL, NULL, '2026-04-09 10:25:57.169228+00', '2026-05-09 10:25:57.169228+00', NULL);
INSERT INTO public.user_sessions VALUES (1389, 4, '94b44ef0-e7cc-4788-99b7-7799d59a8831', NULL, NULL, '2026-04-09 10:26:11.485888+00', '2026-05-09 10:26:11.485888+00', NULL);
INSERT INTO public.user_sessions VALUES (1390, 3, '3bbc09a4-3370-4dfb-a30b-00b19cf4eb60', NULL, NULL, '2026-04-09 10:26:18.611256+00', '2026-05-09 10:26:18.611256+00', NULL);
INSERT INTO public.user_sessions VALUES (1391, 4, '90b2463f-1718-4149-a6ac-53737e32ebbc', NULL, NULL, '2026-04-09 10:52:13.652443+00', '2026-05-09 10:52:13.652443+00', NULL);
INSERT INTO public.user_sessions VALUES (1392, 3, 'a58d3699-79a1-4585-a65b-a8858e6a68a1', NULL, NULL, '2026-04-09 10:52:18.766796+00', '2026-05-09 10:52:18.766796+00', NULL);
INSERT INTO public.user_sessions VALUES (1393, 4, 'aae0af38-5748-4614-8230-3252fde9f7cc', NULL, NULL, '2026-04-09 11:30:29.048148+00', '2026-05-09 11:30:29.048148+00', NULL);
INSERT INTO public.user_sessions VALUES (1394, 3, 'f383387c-6814-4bde-acbf-916ee87aebcd', NULL, NULL, '2026-04-09 11:30:35.924341+00', '2026-05-09 11:30:35.924341+00', NULL);
INSERT INTO public.user_sessions VALUES (1395, 4, '59ed312c-812b-49c0-aca9-c05848417284', NULL, NULL, '2026-04-09 11:32:16.4177+00', '2026-05-09 11:32:16.4177+00', NULL);
INSERT INTO public.user_sessions VALUES (1396, 3, 'd3dc9730-fbd3-4166-85e8-0fe40bb50b67', NULL, NULL, '2026-04-09 11:32:21.205969+00', '2026-05-09 11:32:21.205969+00', NULL);
INSERT INTO public.user_sessions VALUES (1397, 4, '2ea5806a-ce63-41c8-b646-d9dea53ce85e', NULL, NULL, '2026-04-09 11:36:01.433855+00', '2026-05-09 11:36:01.433855+00', NULL);
INSERT INTO public.user_sessions VALUES (1398, 3, 'f365a816-e7d7-4170-87b5-801664f4818f', NULL, NULL, '2026-04-09 18:42:24.344793+00', '2026-05-09 18:42:24.344793+00', NULL);
INSERT INTO public.user_sessions VALUES (1399, 4, '8aee99b8-c0ef-4fe4-b1a0-1025ff2d2c6d', NULL, NULL, '2026-04-09 18:43:42.195206+00', '2026-05-09 18:43:42.195206+00', NULL);
INSERT INTO public.user_sessions VALUES (1400, 3, '541dc29f-bfba-4f99-9173-c4979dab9698', NULL, NULL, '2026-04-09 18:43:47.229852+00', '2026-05-09 18:43:47.229852+00', NULL);
INSERT INTO public.user_sessions VALUES (1401, 3, 'd74c1323-b05d-4021-b708-ca6825d9e509', NULL, NULL, '2026-04-09 19:02:49.301831+00', '2026-05-09 19:02:49.301831+00', NULL);
INSERT INTO public.user_sessions VALUES (1402, 3, 'e2729ba4-88da-4875-9ed1-49451baedb28', NULL, NULL, '2026-04-09 19:05:51.182452+00', '2026-05-09 19:05:51.182452+00', NULL);
INSERT INTO public.user_sessions VALUES (1403, 3, '59011305-b64f-4a47-953e-e4c88762fe04', NULL, NULL, '2026-04-09 19:09:09.494265+00', '2026-05-09 19:09:09.494265+00', NULL);
INSERT INTO public.user_sessions VALUES (1404, 3, 'b9f1b1c1-404e-44a0-a6f3-f25acf7e7119', NULL, NULL, '2026-04-09 19:12:50.608555+00', '2026-05-09 19:12:50.608555+00', NULL);
INSERT INTO public.user_sessions VALUES (1405, 3, 'd8c72bc6-60c5-483f-b643-b86abd702c80', NULL, NULL, '2026-04-09 19:18:59.908536+00', '2026-05-09 19:18:59.908536+00', NULL);
INSERT INTO public.user_sessions VALUES (1406, 4, '34132757-ace5-4082-b7b3-93b1e126f2a6', NULL, NULL, '2026-04-09 19:45:41.685811+00', '2026-05-09 19:45:41.685811+00', NULL);
INSERT INTO public.user_sessions VALUES (1407, 3, '5faf4ac5-143e-4024-8735-e56982077f6a', NULL, NULL, '2026-04-09 19:45:46.350213+00', '2026-05-09 19:45:46.350213+00', NULL);
INSERT INTO public.user_sessions VALUES (1408, 4, '57152481-2103-4fbf-aa3e-3da466026dfb', NULL, NULL, '2026-04-09 19:47:29.249799+00', '2026-05-09 19:47:29.249799+00', NULL);
INSERT INTO public.user_sessions VALUES (1409, 3, '7dc4d375-3371-402e-8f4b-e1c5f954901b', NULL, NULL, '2026-04-09 19:47:34.193364+00', '2026-05-09 19:47:34.193364+00', NULL);
INSERT INTO public.user_sessions VALUES (1410, 4, '733a05cc-e97e-4437-b563-5f2c02de89b2', NULL, NULL, '2026-04-09 19:50:04.396241+00', '2026-05-09 19:50:04.396241+00', NULL);
INSERT INTO public.user_sessions VALUES (1411, 3, '74a9b32c-669f-4ddc-858b-ea9b667aec39', NULL, NULL, '2026-04-09 19:50:19.027898+00', '2026-05-09 19:50:19.027898+00', NULL);
INSERT INTO public.user_sessions VALUES (1412, 4, '53e9ae4f-6328-4e1a-916e-3d8641ea9c5b', NULL, NULL, '2026-04-09 19:52:06.897282+00', '2026-05-09 19:52:06.897282+00', NULL);
INSERT INTO public.user_sessions VALUES (1413, 3, 'ed473710-8666-49d3-a652-39efef5e4cff', NULL, NULL, '2026-04-09 19:52:26.280181+00', '2026-05-09 19:52:26.280181+00', NULL);
INSERT INTO public.user_sessions VALUES (1414, 4, 'c3fbd90a-02d0-4071-b4a7-81f6af224795', NULL, NULL, '2026-04-09 20:25:47.646986+00', '2026-05-09 20:25:47.646986+00', NULL);
INSERT INTO public.user_sessions VALUES (1415, 3, '1e7abebc-81eb-4dad-9973-c87cc22f2c7b', NULL, NULL, '2026-04-09 20:25:52.135264+00', '2026-05-09 20:25:52.135264+00', NULL);
INSERT INTO public.user_sessions VALUES (1416, 4, '822228de-a5c9-4a7c-ba53-4cefd426bdab', NULL, NULL, '2026-04-10 08:41:06.849135+00', '2026-05-10 08:41:06.849135+00', NULL);
INSERT INTO public.user_sessions VALUES (1417, 3, '0d39fb78-4412-49c0-927c-9db494c8095d', NULL, NULL, '2026-04-10 08:41:13.102592+00', '2026-05-10 08:41:13.102592+00', NULL);
INSERT INTO public.user_sessions VALUES (1418, 3, 'a6ae7c08-bc75-4187-bde6-32cfada76256', NULL, NULL, '2026-04-10 08:42:06.517038+00', '2026-05-10 08:42:06.517038+00', NULL);
INSERT INTO public.user_sessions VALUES (1419, 4, '4c21cff9-d5a4-4abf-b458-a8957ff6a55c', NULL, NULL, '2026-04-10 08:42:11.676516+00', '2026-05-10 08:42:11.676516+00', NULL);
INSERT INTO public.user_sessions VALUES (1420, 4, '00e13bda-b0f0-4236-ba9f-c58395e2129c', NULL, NULL, '2026-04-10 08:57:23.008517+00', '2026-05-10 08:57:23.008517+00', NULL);
INSERT INTO public.user_sessions VALUES (1421, 3, '9875b01d-d726-47b0-879d-12aa97ccafe6', NULL, NULL, '2026-04-10 08:57:34.332296+00', '2026-05-10 08:57:34.332296+00', NULL);
INSERT INTO public.user_sessions VALUES (1422, 3, '2f97543b-fa6d-4696-aba7-0fd037bb239d', NULL, NULL, '2026-04-10 09:07:13.618873+00', '2026-05-10 09:07:13.618873+00', NULL);
INSERT INTO public.user_sessions VALUES (1423, 4, 'eacc214e-221c-468c-b5ac-3b56d65831f5', NULL, NULL, '2026-04-10 09:07:26.50837+00', '2026-05-10 09:07:26.50837+00', NULL);
INSERT INTO public.user_sessions VALUES (1428, 3, 'efda4911-be05-47b6-bb3f-501b783b2bc2', NULL, NULL, '2026-04-10 09:32:58.696236+00', '2026-05-10 09:32:58.696236+00', NULL);
INSERT INTO public.user_sessions VALUES (1433, 3, '7a4461a7-1a6e-4735-a469-b7e22b331f8e', NULL, NULL, '2026-04-10 16:16:13.963719+00', '2026-05-10 16:16:13.963719+00', NULL);
INSERT INTO public.user_sessions VALUES (1438, 3, 'cadf92a0-e0f0-4588-a726-6479c5425fa4', NULL, NULL, '2026-04-10 17:31:36.635154+00', '2026-05-10 17:31:36.635154+00', NULL);
INSERT INTO public.user_sessions VALUES (1443, 3, '3cc189c1-a71a-4fb3-a9b3-b13f14411a50', NULL, NULL, '2026-04-10 18:04:45.288228+00', '2026-05-10 18:04:45.288228+00', NULL);
INSERT INTO public.user_sessions VALUES (1448, 3, '5758b763-af86-4ada-887d-96ae7f42885d', NULL, NULL, '2026-04-10 18:45:18.505262+00', '2026-05-10 18:45:18.505262+00', NULL);
INSERT INTO public.user_sessions VALUES (1453, 3, 'f5eea4f1-79f4-4cdc-a13b-baccd9e7897e', NULL, NULL, '2026-04-10 20:15:35.070715+00', '2026-05-10 20:15:35.070715+00', NULL);
INSERT INTO public.user_sessions VALUES (1458, 3, 'e345bd32-af98-46fd-80c9-aea9ba5e1e67', NULL, NULL, '2026-04-10 20:42:05.415469+00', '2026-05-10 20:42:05.415469+00', NULL);
INSERT INTO public.user_sessions VALUES (1424, 4, '836e81d3-f8e0-41bf-aa4f-d1acf8ae07a8', NULL, NULL, '2026-04-10 09:10:49.384998+00', '2026-05-10 09:10:49.384998+00', NULL);
INSERT INTO public.user_sessions VALUES (1429, 3, '8a2cda17-310f-4563-b780-4730b18231e2', NULL, NULL, '2026-04-10 09:48:40.343774+00', '2026-05-10 09:48:40.343774+00', NULL);
INSERT INTO public.user_sessions VALUES (1434, 3, '4006c65b-6a96-4ae8-a0bd-d8348123eab8', NULL, NULL, '2026-04-10 16:46:21.97381+00', '2026-05-10 16:46:21.97381+00', NULL);
INSERT INTO public.user_sessions VALUES (1439, 3, '0bb9102a-d58b-4069-9e7f-5acbb4ccc660', NULL, NULL, '2026-04-10 17:36:12.361162+00', '2026-05-10 17:36:12.361162+00', NULL);
INSERT INTO public.user_sessions VALUES (1444, 3, '5fe24336-5e15-41e7-8d54-a52b2e085437', NULL, NULL, '2026-04-10 18:15:56.733805+00', '2026-05-10 18:15:56.733805+00', NULL);
INSERT INTO public.user_sessions VALUES (1449, 3, '3f3ab355-5d9a-4557-b939-8529ad8d6df9', NULL, NULL, '2026-04-10 19:06:01.519719+00', '2026-05-10 19:06:01.519719+00', NULL);
INSERT INTO public.user_sessions VALUES (1454, 3, '441be3d3-a168-4f9a-8587-4ca5e6eaa713', NULL, NULL, '2026-04-10 20:26:14.648418+00', '2026-05-10 20:26:14.648418+00', NULL);
INSERT INTO public.user_sessions VALUES (1425, 4, '3bca044f-54f7-4b5c-961d-f23794a41b2b', NULL, NULL, '2026-04-10 09:21:41.870342+00', '2026-05-10 09:21:41.870342+00', NULL);
INSERT INTO public.user_sessions VALUES (1430, 3, '97c1340e-54fe-4103-bb59-0b5e1082eeb8', NULL, NULL, '2026-04-10 09:53:33.80205+00', '2026-05-10 09:53:33.80205+00', NULL);
INSERT INTO public.user_sessions VALUES (1435, 3, 'a1b97da8-ffc8-4d95-a2e1-136bb35e87df', NULL, NULL, '2026-04-10 16:53:45.708732+00', '2026-05-10 16:53:45.708732+00', NULL);
INSERT INTO public.user_sessions VALUES (1440, 3, '9ba4fd2b-f3cf-42aa-83dc-ed5098de59e9', NULL, NULL, '2026-04-10 17:47:41.76027+00', '2026-05-10 17:47:41.76027+00', NULL);
INSERT INTO public.user_sessions VALUES (1445, 3, '97fbf591-f5e1-439e-9f46-60b02bd15529', NULL, NULL, '2026-04-10 18:36:28.441844+00', '2026-05-10 18:36:28.441844+00', NULL);
INSERT INTO public.user_sessions VALUES (1450, 3, '1584b71f-afac-46e9-8f88-75bf3e0da90f', NULL, NULL, '2026-04-10 19:30:56.983679+00', '2026-05-10 19:30:56.983679+00', NULL);
INSERT INTO public.user_sessions VALUES (1455, 3, '2c383d37-fedc-4d39-b8f3-4de9142f00d2', NULL, NULL, '2026-04-10 20:31:54.862355+00', '2026-05-10 20:31:54.862355+00', NULL);
INSERT INTO public.user_sessions VALUES (1426, 3, 'c2e9823d-55dd-402b-b99c-4e7bbfb7138b', NULL, NULL, '2026-04-10 09:27:15.39344+00', '2026-05-10 09:27:15.39344+00', NULL);
INSERT INTO public.user_sessions VALUES (1431, 3, 'a587d46e-2b5d-4e6c-b701-78c19f129eef', NULL, NULL, '2026-04-10 15:13:50.590141+00', '2026-05-10 15:13:50.590141+00', NULL);
INSERT INTO public.user_sessions VALUES (1436, 3, '69ab54b1-7410-43b2-a2b8-27cfbf3850da', NULL, NULL, '2026-04-10 16:55:18.932931+00', '2026-05-10 16:55:18.932931+00', NULL);
INSERT INTO public.user_sessions VALUES (1441, 3, 'd235ba82-404a-47d8-9945-81cb65d66095', NULL, NULL, '2026-04-10 17:48:46.610678+00', '2026-05-10 17:48:46.610678+00', NULL);
INSERT INTO public.user_sessions VALUES (1446, 3, 'd860c013-3820-4c02-aa0b-93c18c09e450', NULL, NULL, '2026-04-10 18:40:21.737822+00', '2026-05-10 18:40:21.737822+00', NULL);
INSERT INTO public.user_sessions VALUES (1451, 3, '110e4ae0-805a-4783-be4c-e311afea70e0', NULL, NULL, '2026-04-10 19:55:31.252182+00', '2026-05-10 19:55:31.252182+00', NULL);
INSERT INTO public.user_sessions VALUES (1456, 3, 'd35e1667-cb89-4bac-9f9b-f2dafda84f8e', NULL, NULL, '2026-04-10 20:35:30.121562+00', '2026-05-10 20:35:30.121562+00', NULL);
INSERT INTO public.user_sessions VALUES (1427, 3, 'b3c49494-6a8e-4abd-aa4c-8223ae1cb6fb', NULL, NULL, '2026-04-10 09:28:41.373947+00', '2026-05-10 09:28:41.373947+00', NULL);
INSERT INTO public.user_sessions VALUES (1432, 3, '1f18d9f9-6863-4f68-8e03-428d508e95b0', NULL, NULL, '2026-04-10 15:15:18.11907+00', '2026-05-10 15:15:18.11907+00', NULL);
INSERT INTO public.user_sessions VALUES (1437, 3, 'c6b541e9-b4ce-4671-9fd5-1df0bfb367fb', NULL, NULL, '2026-04-10 17:24:41.906188+00', '2026-05-10 17:24:41.906188+00', NULL);
INSERT INTO public.user_sessions VALUES (1442, 3, '9fe813f9-2305-4f0f-b045-6e075634831b', NULL, NULL, '2026-04-10 18:04:01.077166+00', '2026-05-10 18:04:01.077166+00', NULL);
INSERT INTO public.user_sessions VALUES (1447, 3, '01c94813-43b8-4013-ab89-c5a06777cf54', NULL, NULL, '2026-04-10 18:43:34.431987+00', '2026-05-10 18:43:34.431987+00', NULL);
INSERT INTO public.user_sessions VALUES (1452, 3, '518014d5-badf-45a3-8f2a-979c92d3a8a0', NULL, NULL, '2026-04-10 20:01:14.048604+00', '2026-05-10 20:01:14.048604+00', NULL);
INSERT INTO public.user_sessions VALUES (1457, 3, 'a9c71ace-b730-4e51-8132-cc5394079cab', NULL, NULL, '2026-04-10 20:38:45.045132+00', '2026-05-10 20:38:45.045132+00', NULL);
INSERT INTO public.user_sessions VALUES (1459, 3, '2cc4efd5-1684-45d1-a7b8-208ac8c73d4a', NULL, NULL, '2026-04-11 07:48:38.368413+00', '2026-05-11 07:48:38.368413+00', NULL);
INSERT INTO public.user_sessions VALUES (1460, 3, '8a1d5edc-a416-4f56-888e-b52d96fbd5f9', NULL, NULL, '2026-04-11 07:50:03.015122+00', '2026-05-11 07:50:03.015122+00', NULL);
INSERT INTO public.user_sessions VALUES (1461, 3, '4d4ac883-bce3-4f6c-8118-10010bcd2dbd', NULL, NULL, '2026-04-11 07:59:12.646132+00', '2026-05-11 07:59:12.646132+00', NULL);
INSERT INTO public.user_sessions VALUES (1462, 3, 'dc47d46e-70f8-4f74-8db7-0fdbc1aa6aea', NULL, NULL, '2026-04-11 08:03:58.86193+00', '2026-05-11 08:03:58.86193+00', NULL);
INSERT INTO public.user_sessions VALUES (1463, 3, '5405b283-6b4f-4ca5-b4c0-b354b6eb13ae', NULL, NULL, '2026-04-11 09:02:16.811396+00', '2026-05-11 09:02:16.811396+00', NULL);
INSERT INTO public.user_sessions VALUES (1464, 3, 'f831c24e-1140-40f9-87c5-7cc52c43400a', NULL, NULL, '2026-04-11 09:06:05.568731+00', '2026-05-11 09:06:05.568731+00', NULL);
INSERT INTO public.user_sessions VALUES (1465, 4, '7d97d205-1098-4280-b258-e3166a40cf03', NULL, NULL, '2026-04-11 09:06:09.765222+00', '2026-05-11 09:06:09.765222+00', NULL);
INSERT INTO public.user_sessions VALUES (1466, 3, '304e8075-3fa8-4e86-94a3-a44cd6a31fa8', NULL, NULL, '2026-04-11 09:22:19.403678+00', '2026-05-11 09:22:19.403678+00', NULL);
INSERT INTO public.user_sessions VALUES (1467, 4, '27b6c056-894b-4627-bee1-cd86382454b3', NULL, NULL, '2026-04-11 09:22:24.350285+00', '2026-05-11 09:22:24.350285+00', NULL);
INSERT INTO public.user_sessions VALUES (1468, 3, 'e2073910-3697-491f-b953-f93adce36b35', NULL, NULL, '2026-04-11 09:34:46.843982+00', '2026-05-11 09:34:46.843982+00', NULL);
INSERT INTO public.user_sessions VALUES (1469, 4, '225bafdd-ae3b-4fab-8af1-658cbc203d73', NULL, NULL, '2026-04-11 09:34:53.058092+00', '2026-05-11 09:34:53.058092+00', NULL);
INSERT INTO public.user_sessions VALUES (1470, 3, '5d2e4150-7e31-43d5-98dc-8350b570e902', NULL, NULL, '2026-04-11 09:41:03.577982+00', '2026-05-11 09:41:03.577982+00', NULL);
INSERT INTO public.user_sessions VALUES (1471, 3, '49218226-1ee1-480a-b247-cccefa35ccb3', NULL, NULL, '2026-04-11 09:45:04.665264+00', '2026-05-11 09:45:04.665264+00', NULL);
INSERT INTO public.user_sessions VALUES (1472, 4, 'f8db52c8-6864-4c7c-a0e6-1fe01587dbf6', NULL, NULL, '2026-04-11 09:45:13.628512+00', '2026-05-11 09:45:13.628512+00', NULL);
INSERT INTO public.user_sessions VALUES (1473, 3, '8e86aecf-7efd-4755-8a41-2c977c59b64a', NULL, NULL, '2026-04-11 10:16:16.124877+00', '2026-05-11 10:16:16.124877+00', NULL);
INSERT INTO public.user_sessions VALUES (1474, 4, 'eec06934-ccba-43c0-8975-be6ddf7205f5', NULL, NULL, '2026-04-11 10:16:20.898745+00', '2026-05-11 10:16:20.898745+00', NULL);
INSERT INTO public.user_sessions VALUES (1475, 3, '49c467c0-5908-452b-a147-651502442b79', NULL, NULL, '2026-04-11 10:21:13.144495+00', '2026-05-11 10:21:13.144495+00', NULL);
INSERT INTO public.user_sessions VALUES (1476, 4, 'd0d5da2a-a4aa-42ac-b424-15f87e23fb62', NULL, NULL, '2026-04-11 10:21:18.251453+00', '2026-05-11 10:21:18.251453+00', NULL);
INSERT INTO public.user_sessions VALUES (1477, 3, 'fe30e9cc-09c0-4c12-9ae5-db2b82684e3d', NULL, NULL, '2026-04-11 10:27:16.19471+00', '2026-05-11 10:27:16.19471+00', NULL);
INSERT INTO public.user_sessions VALUES (1478, 3, 'bca3f046-a1c9-4c05-b1a5-1048f2f98f64', NULL, NULL, '2026-04-11 13:30:45.533567+00', '2026-05-11 13:30:45.533567+00', NULL);
INSERT INTO public.user_sessions VALUES (1479, 3, '3a1a467b-8fa7-4dcf-9993-d4826cecd2f2', NULL, NULL, '2026-04-11 13:36:07.522517+00', '2026-05-11 13:36:07.522517+00', NULL);
INSERT INTO public.user_sessions VALUES (1480, 3, '70751950-ea90-4d14-8733-1b805011a849', NULL, NULL, '2026-04-11 13:53:35.940199+00', '2026-05-11 13:53:35.940199+00', NULL);
INSERT INTO public.user_sessions VALUES (1481, 3, '59593715-4a4b-4361-b8ae-27ea03a5fd5b', NULL, NULL, '2026-04-11 14:17:27.818165+00', '2026-05-11 14:17:27.818165+00', NULL);
INSERT INTO public.user_sessions VALUES (1482, 3, 'bd51352c-fd6f-4221-a84a-7cb8db1105af', NULL, NULL, '2026-04-11 14:23:45.768077+00', '2026-05-11 14:23:45.768077+00', NULL);
INSERT INTO public.user_sessions VALUES (1483, 3, 'd2a342ca-5da0-4b07-8bc2-c95cc88113c5', NULL, NULL, '2026-04-11 14:38:36.641934+00', '2026-05-11 14:38:36.641934+00', NULL);
INSERT INTO public.user_sessions VALUES (1484, 3, '3344b639-4296-4d61-a62a-4f1328d095e7', NULL, NULL, '2026-04-11 15:16:45.835401+00', '2026-05-11 15:16:45.835401+00', NULL);
INSERT INTO public.user_sessions VALUES (1485, 3, '0c617779-e032-44d8-b9a8-318d6c242274', NULL, NULL, '2026-04-11 15:19:49.658863+00', '2026-05-11 15:19:49.658863+00', NULL);
INSERT INTO public.user_sessions VALUES (1486, 3, '33e023c4-bff0-4297-9927-9b9edacac8b9', NULL, NULL, '2026-04-11 15:50:03.598223+00', '2026-05-11 15:50:03.598223+00', NULL);
INSERT INTO public.user_sessions VALUES (1487, 3, '3a333666-181f-4cb2-81f1-8c592e647cb9', NULL, NULL, '2026-04-11 15:51:03.08509+00', '2026-05-11 15:51:03.08509+00', NULL);
INSERT INTO public.user_sessions VALUES (1488, 3, '4b2ae6b8-fee2-4f87-a1c4-5681fb04cf4f', NULL, NULL, '2026-04-11 15:51:18.051095+00', '2026-05-11 15:51:18.051095+00', NULL);
INSERT INTO public.user_sessions VALUES (1489, 3, '12730408-3fad-41ad-9ff9-f6a6e642679a', NULL, NULL, '2026-04-11 16:05:34.625613+00', '2026-05-11 16:05:34.625613+00', NULL);
INSERT INTO public.user_sessions VALUES (1490, 3, '4208883a-4953-43e1-b27b-cb3d90bd61e6', NULL, NULL, '2026-04-11 16:06:49.994977+00', '2026-05-11 16:06:49.994977+00', NULL);
INSERT INTO public.user_sessions VALUES (1491, 3, '957e7e6c-28f2-493a-85ec-d504c9992727', NULL, NULL, '2026-04-11 16:07:14.626733+00', '2026-05-11 16:07:14.626733+00', NULL);
INSERT INTO public.user_sessions VALUES (1492, 3, '314274b5-8232-4b89-a96c-64923ec76421', NULL, NULL, '2026-04-11 16:18:51.414997+00', '2026-05-11 16:18:51.414997+00', NULL);
INSERT INTO public.user_sessions VALUES (1493, 3, '22c4ace0-5f15-412d-ad9a-2c573bc7824f', NULL, NULL, '2026-04-11 16:24:55.138188+00', '2026-05-11 16:24:55.138188+00', NULL);
INSERT INTO public.user_sessions VALUES (1494, 3, '5c34e705-d1d1-4c52-8c7a-916865852c7f', NULL, NULL, '2026-04-11 16:30:41.872031+00', '2026-05-11 16:30:41.872031+00', NULL);
INSERT INTO public.user_sessions VALUES (1495, 3, 'de585608-8269-400a-a7a0-d5075216bc57', NULL, NULL, '2026-04-11 16:36:36.148375+00', '2026-05-11 16:36:36.148375+00', NULL);
INSERT INTO public.user_sessions VALUES (1496, 4, 'c9855c0d-7277-4a50-a188-1780e48c6fe4', NULL, NULL, '2026-04-11 16:37:37.828997+00', '2026-05-11 16:37:37.828997+00', NULL);
INSERT INTO public.user_sessions VALUES (1497, 3, 'e34d7d90-4236-4719-a3b1-06b599c7e64e', NULL, NULL, '2026-04-11 16:43:05.710104+00', '2026-05-11 16:43:05.710104+00', NULL);
INSERT INTO public.user_sessions VALUES (1498, 3, 'e137073b-681f-4b61-bf04-fc0aab66aa9a', NULL, NULL, '2026-04-11 16:44:17.257143+00', '2026-05-11 16:44:17.257143+00', NULL);
INSERT INTO public.user_sessions VALUES (1499, 3, '9a169c9a-a836-41be-bb02-46a920373b15', NULL, NULL, '2026-04-11 17:05:27.354925+00', '2026-05-11 17:05:27.354925+00', NULL);
INSERT INTO public.user_sessions VALUES (1500, 3, 'd5f798e9-fce2-460f-ad13-26126dbd1ba2', NULL, NULL, '2026-04-11 17:08:09.670028+00', '2026-05-11 17:08:09.670028+00', NULL);
INSERT INTO public.user_sessions VALUES (1501, 3, '98b6dbaf-3a80-44cf-8ad2-c93434b2f9ce', NULL, NULL, '2026-04-11 17:10:24.244617+00', '2026-05-11 17:10:24.244617+00', NULL);
INSERT INTO public.user_sessions VALUES (1502, 3, '097f16cb-ea8a-4aee-9920-064aafa46766', NULL, NULL, '2026-04-11 17:28:40.826463+00', '2026-05-11 17:28:40.826463+00', NULL);
INSERT INTO public.user_sessions VALUES (1503, 3, '72aaba38-aaee-47a9-8649-9b091b28f093', NULL, NULL, '2026-04-11 18:06:49.408053+00', '2026-05-11 18:06:49.408053+00', NULL);
INSERT INTO public.user_sessions VALUES (1504, 3, 'bd1f7274-44c8-47e1-a288-ef71b7181f01', NULL, NULL, '2026-04-11 18:18:45.366611+00', '2026-05-11 18:18:45.366611+00', NULL);
INSERT INTO public.user_sessions VALUES (1505, 3, '3cf96d58-6e7d-47dc-a21f-4699fe060f49', NULL, NULL, '2026-04-11 18:21:29.370007+00', '2026-05-11 18:21:29.370007+00', NULL);
INSERT INTO public.user_sessions VALUES (1506, 3, '9eeda405-6146-4783-9d23-6fee2d6ebf5c', NULL, NULL, '2026-04-11 18:44:17.328768+00', '2026-05-11 18:44:17.328768+00', NULL);
INSERT INTO public.user_sessions VALUES (1507, 3, '8b8f01a7-c00c-4371-97d3-c639d60de310', NULL, NULL, '2026-04-11 18:46:36.717343+00', '2026-05-11 18:46:36.717343+00', NULL);
INSERT INTO public.user_sessions VALUES (1508, 3, '2fc28965-dca6-42ee-9479-13be23c28333', NULL, NULL, '2026-04-11 18:53:20.986469+00', '2026-05-11 18:53:20.986469+00', NULL);
INSERT INTO public.user_sessions VALUES (1509, 3, '88239012-e094-43cc-b7db-807ef31a770a', NULL, NULL, '2026-04-12 16:48:47.770778+00', '2026-05-12 16:48:47.770778+00', NULL);
INSERT INTO public.user_sessions VALUES (1510, 4, '20a247ec-ec7c-4d9e-ad7a-41b913ecaf9f', NULL, NULL, '2026-04-12 16:49:40.333107+00', '2026-05-12 16:49:40.333107+00', NULL);
INSERT INTO public.user_sessions VALUES (1511, 3, '80b5a8be-45f3-4868-8dca-dc479c6aa7d9', NULL, NULL, '2026-04-13 09:00:40.917398+00', '2026-05-13 09:00:40.917398+00', NULL);
INSERT INTO public.user_sessions VALUES (1512, 3, '8434fe98-e75f-490c-90b6-97b3f8dc9b77', NULL, NULL, '2026-04-13 09:22:15.074532+00', '2026-05-13 09:22:15.074532+00', NULL);
INSERT INTO public.user_sessions VALUES (1513, 3, '175c56da-2977-4bae-8775-5ffd9f3940c4', NULL, NULL, '2026-04-13 09:22:32.268228+00', '2026-05-13 09:22:32.268228+00', NULL);
INSERT INTO public.user_sessions VALUES (1514, 3, '85afb0ae-8383-4466-a7d3-8264a38e2fd9', NULL, NULL, '2026-04-13 10:52:34.164947+00', '2026-05-13 10:52:34.164947+00', NULL);
INSERT INTO public.user_sessions VALUES (1515, 3, '0e2b38d2-d75b-4552-b7dd-7f8a79225d84', NULL, NULL, '2026-04-13 10:55:30.243688+00', '2026-05-13 10:55:30.243688+00', NULL);
INSERT INTO public.user_sessions VALUES (1516, 4, '0834c334-f4e5-4ad3-8c3b-cff35438e8dc', NULL, NULL, '2026-04-13 10:56:00.3407+00', '2026-05-13 10:56:00.3407+00', NULL);
INSERT INTO public.user_sessions VALUES (1517, 3, '931afae8-1b0f-4cd9-9d7a-6745094dc792', NULL, NULL, '2026-04-13 12:35:42.576293+00', '2026-05-13 12:35:42.576293+00', NULL);
INSERT INTO public.user_sessions VALUES (1518, 4, 'a08292fc-f6a2-44ae-b743-0b62c2225907', NULL, NULL, '2026-04-13 12:35:47.972771+00', '2026-05-13 12:35:47.972771+00', NULL);
INSERT INTO public.user_sessions VALUES (1519, 3, 'eda246ee-715f-454e-95d7-64bc36f079f9', NULL, NULL, '2026-04-13 12:59:51.430696+00', '2026-05-13 12:59:51.430696+00', NULL);
INSERT INTO public.user_sessions VALUES (1520, 4, '18672e6c-5e4f-498b-a625-e08f3e04d004', NULL, NULL, '2026-04-13 13:00:00.565253+00', '2026-05-13 13:00:00.565253+00', NULL);
INSERT INTO public.user_sessions VALUES (1521, 3, '609e94b4-4367-4721-b963-ed5d19ff5a03', NULL, NULL, '2026-04-13 13:15:52.705905+00', '2026-05-13 13:15:52.705905+00', NULL);
INSERT INTO public.user_sessions VALUES (1522, 4, 'edd1a4fb-3730-412c-8802-43f99021b634', NULL, NULL, '2026-04-13 13:16:00.463817+00', '2026-05-13 13:16:00.463817+00', NULL);
INSERT INTO public.user_sessions VALUES (1523, 3, 'cbd02463-8624-4510-9855-ba688d78a531', NULL, NULL, '2026-04-13 13:59:27.677334+00', '2026-05-13 13:59:27.677334+00', NULL);
INSERT INTO public.user_sessions VALUES (1524, 4, '58e82962-ebca-45e9-91bd-27a588de64ee', NULL, NULL, '2026-04-13 13:59:32.033435+00', '2026-05-13 13:59:32.033435+00', NULL);
INSERT INTO public.user_sessions VALUES (1525, 3, '5897710d-0f08-411b-b83b-2978e43f4ee2', NULL, NULL, '2026-04-13 14:00:44.893955+00', '2026-05-13 14:00:44.893955+00', NULL);
INSERT INTO public.user_sessions VALUES (1526, 4, '0f38ce60-61f2-49c7-84f5-d334af219d8e', NULL, NULL, '2026-04-13 14:00:48.886656+00', '2026-05-13 14:00:48.886656+00', NULL);
INSERT INTO public.user_sessions VALUES (1527, 3, 'da633e64-34f4-48fd-8c99-f2bd06fb6b88', NULL, NULL, '2026-04-13 14:01:41.500738+00', '2026-05-13 14:01:41.500738+00', NULL);
INSERT INTO public.user_sessions VALUES (1528, 4, '66287e69-58ca-4c35-8eec-961b1bf1404a', NULL, NULL, '2026-04-13 14:01:46.254552+00', '2026-05-13 14:01:46.254552+00', NULL);
INSERT INTO public.user_sessions VALUES (1529, 3, '8c9bdf7d-8aae-4814-855f-3e09645c2b80', NULL, NULL, '2026-04-13 14:02:58.562638+00', '2026-05-13 14:02:58.562638+00', NULL);
INSERT INTO public.user_sessions VALUES (1530, 3, '2fbc54b2-5c91-4f39-9a0d-dcb877e774c0', NULL, NULL, '2026-04-13 14:04:33.185128+00', '2026-05-13 14:04:33.185128+00', NULL);
INSERT INTO public.user_sessions VALUES (1531, 3, 'c5d89f74-0621-4a9a-9cf4-efa4c4e407da', NULL, NULL, '2026-04-13 14:25:49.584818+00', '2026-05-13 14:25:49.584818+00', NULL);
INSERT INTO public.user_sessions VALUES (1532, 4, 'ec6470ba-ee79-4f49-90c4-be160f82db4e', NULL, NULL, '2026-04-13 14:26:10.516317+00', '2026-05-13 14:26:10.516317+00', NULL);
INSERT INTO public.user_sessions VALUES (1533, 3, '5ab87b00-e49b-4d91-82c8-07ef7a8305b0', NULL, NULL, '2026-04-13 14:26:38.464542+00', '2026-05-13 14:26:38.464542+00', NULL);
INSERT INTO public.user_sessions VALUES (1538, 4, '810dc182-cdc7-40ca-a539-764aa5fc54c9', NULL, NULL, '2026-04-13 15:59:01.383429+00', '2026-05-13 15:59:01.383429+00', NULL);
INSERT INTO public.user_sessions VALUES (1543, 3, 'ff4173c8-3108-4091-a8f2-664276bf945b', NULL, NULL, '2026-04-13 20:12:04.406647+00', '2026-05-13 20:12:04.406647+00', NULL);
INSERT INTO public.user_sessions VALUES (1534, 3, '0334fc18-2816-45a3-a1b8-9a297f7d1810', NULL, NULL, '2026-04-13 14:58:55.062481+00', '2026-05-13 14:58:55.062481+00', NULL);
INSERT INTO public.user_sessions VALUES (1539, 3, '089d3c4a-b9f9-45bf-a4a6-816e567d069c', NULL, NULL, '2026-04-13 16:09:40.129914+00', '2026-05-13 16:09:40.129914+00', NULL);
INSERT INTO public.user_sessions VALUES (1535, 4, 'faad10e8-0288-49d0-8d1f-2cf60dda3e4c', NULL, NULL, '2026-04-13 14:59:30.105604+00', '2026-05-13 14:59:30.105604+00', NULL);
INSERT INTO public.user_sessions VALUES (1540, 3, 'c360bdb8-9fcb-44bd-baa3-690f325c601c', NULL, NULL, '2026-04-13 19:59:07.206915+00', '2026-05-13 19:59:07.206915+00', NULL);
INSERT INTO public.user_sessions VALUES (1536, 3, '1ea5719f-6fa0-4d44-9d68-1237bcdc4a38', NULL, NULL, '2026-04-13 15:55:19.100611+00', '2026-05-13 15:55:19.100611+00', NULL);
INSERT INTO public.user_sessions VALUES (1541, 4, '18a7df93-55d5-4185-a5f0-95dbdb7c7364', NULL, NULL, '2026-04-13 19:59:17.612232+00', '2026-05-13 19:59:17.612232+00', NULL);
INSERT INTO public.user_sessions VALUES (1537, 3, 'b249a3a7-7ab5-45f9-b5a4-74efe81539c8', NULL, NULL, '2026-04-13 15:58:56.813379+00', '2026-05-13 15:58:56.813379+00', NULL);
INSERT INTO public.user_sessions VALUES (1542, 3, '7abe8d03-2470-4f43-8401-9f0287f5d545', NULL, NULL, '2026-04-13 20:06:01.943356+00', '2026-05-13 20:06:01.943356+00', NULL);
INSERT INTO public.user_sessions VALUES (1544, 3, '13ca1858-1113-4153-b5ed-f701cc2c8adf', NULL, NULL, '2026-04-14 08:14:36.424886+00', '2026-05-14 08:14:36.424886+00', NULL);
INSERT INTO public.user_sessions VALUES (1545, 4, '870f980e-54f9-47ab-959d-4a4e03aa8027', NULL, NULL, '2026-04-14 08:14:49.553518+00', '2026-05-14 08:14:49.553518+00', NULL);
INSERT INTO public.user_sessions VALUES (1546, 3, '328f1048-2bef-49d1-9c3b-a0f4b3a254af', NULL, NULL, '2026-04-14 08:20:15.549172+00', '2026-05-14 08:20:15.549172+00', NULL);
INSERT INTO public.user_sessions VALUES (1547, 3, '7db107d3-6bf7-4635-aa76-54576095eeb0', NULL, NULL, '2026-04-14 08:21:37.632939+00', '2026-05-14 08:21:37.632939+00', NULL);
INSERT INTO public.user_sessions VALUES (1548, 3, '79fc3bcc-d020-48bc-b7b5-14f6baccddd8', NULL, NULL, '2026-04-14 08:24:02.124634+00', '2026-05-14 08:24:02.124634+00', NULL);
INSERT INTO public.user_sessions VALUES (1549, 3, '36d0591f-2319-4466-bd2a-19d12615f65f', NULL, NULL, '2026-04-14 08:59:48.927517+00', '2026-05-14 08:59:48.927517+00', NULL);
INSERT INTO public.user_sessions VALUES (1550, 4, 'ab9d4509-38fe-4006-a582-19d82cb4dbae', NULL, NULL, '2026-04-14 08:59:55.28595+00', '2026-05-14 08:59:55.28595+00', NULL);
INSERT INTO public.user_sessions VALUES (1551, 3, '9e6fddb2-e26b-4598-a62a-74e224cb8157', NULL, NULL, '2026-04-14 09:56:08.049759+00', '2026-05-14 09:56:08.049759+00', NULL);
INSERT INTO public.user_sessions VALUES (1552, 3, '4b2af53a-4900-46eb-9290-1c34d963564e', NULL, NULL, '2026-04-14 09:57:55.013985+00', '2026-05-14 09:57:55.013985+00', NULL);
INSERT INTO public.user_sessions VALUES (1553, 3, '35c4a5bf-e38d-4a95-85eb-267e4425778e', NULL, NULL, '2026-04-14 10:04:28.342861+00', '2026-05-14 10:04:28.342861+00', NULL);
INSERT INTO public.user_sessions VALUES (1554, 3, '4e444234-2fdb-4a28-bbf1-c0457ed521ab', NULL, NULL, '2026-04-14 10:13:50.360138+00', '2026-05-14 10:13:50.360138+00', NULL);
INSERT INTO public.user_sessions VALUES (1555, 3, '769c155a-6cc2-47dd-8ef2-54396358f386', NULL, NULL, '2026-04-14 10:14:53.920571+00', '2026-05-14 10:14:53.920571+00', NULL);
INSERT INTO public.user_sessions VALUES (1556, 3, '4aee26ca-4f94-462c-8219-e4cf9801541f', NULL, NULL, '2026-04-14 10:23:47.090996+00', '2026-05-14 10:23:47.090996+00', NULL);
INSERT INTO public.user_sessions VALUES (1557, 3, '8daad134-e824-4d69-a437-42900d20cf0f', NULL, NULL, '2026-04-14 10:25:07.0274+00', '2026-05-14 10:25:07.0274+00', NULL);
INSERT INTO public.user_sessions VALUES (1558, 3, '0626e78c-85ea-49fd-a842-ab3dc755baf8', NULL, NULL, '2026-04-14 10:25:57.743714+00', '2026-05-14 10:25:57.743714+00', NULL);
INSERT INTO public.user_sessions VALUES (1559, 3, 'e4bae336-5d59-4b73-9d2c-9e8fb3c2d0a7', NULL, NULL, '2026-04-14 10:31:17.493843+00', '2026-05-14 10:31:17.493843+00', NULL);
INSERT INTO public.user_sessions VALUES (1560, 3, '18bcf65d-ee8e-4b32-8e14-9150b453904a', NULL, NULL, '2026-04-14 10:44:55.397249+00', '2026-05-14 10:44:55.397249+00', NULL);
INSERT INTO public.user_sessions VALUES (1561, 3, '26de192e-0ec0-4166-bb89-8d6925cb8332', NULL, NULL, '2026-04-14 10:45:50.571914+00', '2026-05-14 10:45:50.571914+00', NULL);
INSERT INTO public.user_sessions VALUES (1562, 3, 'd77ac252-6703-4cd8-8b57-5230fb23d348', NULL, NULL, '2026-04-14 11:20:58.50767+00', '2026-05-14 11:20:58.50767+00', NULL);
INSERT INTO public.user_sessions VALUES (1563, 3, '98623625-2d75-495e-b4ba-cfa3be3efac8', NULL, NULL, '2026-04-14 11:29:07.323428+00', '2026-05-14 11:29:07.323428+00', NULL);
INSERT INTO public.user_sessions VALUES (1564, 3, 'e123b1e5-4d76-4aa0-886a-70e84379dbe8', NULL, NULL, '2026-04-14 11:32:35.537198+00', '2026-05-14 11:32:35.537198+00', NULL);
INSERT INTO public.user_sessions VALUES (1565, 3, 'faa53274-6182-41a0-9381-2583611315b9', NULL, NULL, '2026-04-14 11:36:36.724014+00', '2026-05-14 11:36:36.724014+00', NULL);
INSERT INTO public.user_sessions VALUES (1566, 3, '69d79e21-96e5-4ae9-b130-13d6c128e85f', NULL, NULL, '2026-04-14 12:01:21.416854+00', '2026-05-14 12:01:21.416854+00', NULL);
INSERT INTO public.user_sessions VALUES (1567, 3, '4a2cfde4-61d3-4553-bb86-a3ca59c6d568', NULL, NULL, '2026-04-14 12:03:39.669629+00', '2026-05-14 12:03:39.669629+00', NULL);
INSERT INTO public.user_sessions VALUES (1568, 3, '051f6065-1ce8-4bb5-adc1-3f9c9241521a', NULL, NULL, '2026-04-14 12:11:30.982646+00', '2026-05-14 12:11:30.982646+00', NULL);
INSERT INTO public.user_sessions VALUES (1569, 3, '997b414d-07ba-4692-bf29-b38ddafa395a', NULL, NULL, '2026-04-14 12:12:46.496553+00', '2026-05-14 12:12:46.496553+00', NULL);
INSERT INTO public.user_sessions VALUES (1570, 3, '0cacc373-1525-470c-909c-8796b58a8e09', NULL, NULL, '2026-04-14 12:29:55.054426+00', '2026-05-14 12:29:55.054426+00', NULL);
INSERT INTO public.user_sessions VALUES (1571, 3, '2179c97d-439a-4f92-98b8-787280b59be5', NULL, NULL, '2026-04-14 12:34:32.042481+00', '2026-05-14 12:34:32.042481+00', NULL);
INSERT INTO public.user_sessions VALUES (1572, 3, '03209f60-fd81-49b9-a7f2-50a584585cfb', NULL, NULL, '2026-04-14 12:37:49.044032+00', '2026-05-14 12:37:49.044032+00', NULL);
INSERT INTO public.user_sessions VALUES (1573, 3, '46b24da9-6f8a-43fd-bdfc-ad2c4c627321', NULL, NULL, '2026-04-14 12:44:05.484089+00', '2026-05-14 12:44:05.484089+00', NULL);
INSERT INTO public.user_sessions VALUES (1574, 3, '32d5acf8-4dc7-42bb-818a-d155f6f13bd7', NULL, NULL, '2026-04-14 12:45:22.647977+00', '2026-05-14 12:45:22.647977+00', NULL);
INSERT INTO public.user_sessions VALUES (1575, 3, '186097ce-9261-4694-b66b-b78c2f954539', NULL, NULL, '2026-04-14 12:46:48.481672+00', '2026-05-14 12:46:48.481672+00', NULL);
INSERT INTO public.user_sessions VALUES (1576, 3, '5df1f240-57c2-44fb-9a16-b7d2f65f75bb', NULL, NULL, '2026-04-14 13:01:46.434857+00', '2026-05-14 13:01:46.434857+00', NULL);
INSERT INTO public.user_sessions VALUES (1577, 3, '42ec2eb8-2d86-46af-a9a3-d8f0c9c7e882', NULL, NULL, '2026-04-14 13:16:59.903414+00', '2026-05-14 13:16:59.903414+00', NULL);
INSERT INTO public.user_sessions VALUES (1578, 3, 'bf091470-2baf-4e8e-ab97-a434e420c2fa', NULL, NULL, '2026-04-14 13:39:57.777751+00', '2026-05-14 13:39:57.777751+00', NULL);
INSERT INTO public.user_sessions VALUES (1579, 3, '3c9b10b6-98d4-49aa-a31c-28991c099ee2', NULL, NULL, '2026-04-14 13:55:13.808524+00', '2026-05-14 13:55:13.808524+00', NULL);
INSERT INTO public.user_sessions VALUES (1580, 3, 'c029d3fc-ec2f-4bdb-951f-0da2c41c1c5f', NULL, NULL, '2026-04-14 13:56:45.267922+00', '2026-05-14 13:56:45.267922+00', NULL);
INSERT INTO public.user_sessions VALUES (1581, 3, '73313947-0e7c-41b0-a489-22964f188d40', NULL, NULL, '2026-04-14 13:57:11.14852+00', '2026-05-14 13:57:11.14852+00', NULL);
INSERT INTO public.user_sessions VALUES (1582, 3, '62ced631-eddd-4a37-9dfc-b18a310bc93e', NULL, NULL, '2026-04-14 13:59:09.544184+00', '2026-05-14 13:59:09.544184+00', NULL);
INSERT INTO public.user_sessions VALUES (1583, 3, 'c746bb8c-92a7-4864-bbe2-a32ea162b7b7', NULL, NULL, '2026-04-14 14:00:19.393583+00', '2026-05-14 14:00:19.393583+00', NULL);
INSERT INTO public.user_sessions VALUES (1584, 3, '504a9f1d-5630-46ab-bc80-40cb6e42124c', NULL, NULL, '2026-04-14 15:09:34.182248+00', '2026-05-14 15:09:34.182248+00', NULL);
INSERT INTO public.user_sessions VALUES (1585, 3, 'bcdcc8eb-037e-4806-901b-55630ff1a40f', NULL, NULL, '2026-04-14 15:10:01.746486+00', '2026-05-14 15:10:01.746486+00', NULL);
INSERT INTO public.user_sessions VALUES (1586, 3, '7d5e03ff-816b-42c7-8f7c-aa24da33e2dc', NULL, NULL, '2026-04-14 15:10:31.3028+00', '2026-05-14 15:10:31.3028+00', NULL);
INSERT INTO public.user_sessions VALUES (1587, 3, 'a223011d-2089-4f49-be29-631b3c16a1c5', NULL, NULL, '2026-04-14 15:15:30.344164+00', '2026-05-14 15:15:30.344164+00', NULL);
INSERT INTO public.user_sessions VALUES (1588, 3, 'e6bc591e-de84-4a6d-87d3-dd5af393e8cf', NULL, NULL, '2026-04-14 15:24:42.187706+00', '2026-05-14 15:24:42.187706+00', NULL);
INSERT INTO public.user_sessions VALUES (1589, 3, '2785d58a-da22-4b3b-b36c-45c32600af99', NULL, NULL, '2026-04-14 15:27:15.432849+00', '2026-05-14 15:27:15.432849+00', NULL);
INSERT INTO public.user_sessions VALUES (1590, 3, '2fa994b2-913d-4b52-b869-2d88e59d283e', NULL, NULL, '2026-04-14 15:57:56.394955+00', '2026-05-14 15:57:56.394955+00', NULL);
INSERT INTO public.user_sessions VALUES (1591, 3, 'e3de8925-bf04-4763-b334-62426b6778e3', NULL, NULL, '2026-04-14 15:59:39.285849+00', '2026-05-14 15:59:39.285849+00', NULL);
INSERT INTO public.user_sessions VALUES (1592, 3, 'dcc6a282-93fe-4072-89ca-b36096c5df1b', NULL, NULL, '2026-04-14 16:36:25.393665+00', '2026-05-14 16:36:25.393665+00', NULL);
INSERT INTO public.user_sessions VALUES (1593, 4, 'f1d2cec0-7c2e-489c-b0c7-8c2e4487df53', NULL, NULL, '2026-04-14 16:38:11.315516+00', '2026-05-14 16:38:11.315516+00', NULL);
INSERT INTO public.user_sessions VALUES (1594, 3, '2464745d-3af7-4be4-bd71-bc30c5e498aa', NULL, NULL, '2026-04-14 16:41:20.69426+00', '2026-05-14 16:41:20.69426+00', NULL);
INSERT INTO public.user_sessions VALUES (1595, 3, '8a1991ae-4f7f-4439-8f69-8af40f883dbe', NULL, NULL, '2026-04-14 16:46:36.75523+00', '2026-05-14 16:46:36.75523+00', NULL);
INSERT INTO public.user_sessions VALUES (1596, 3, '38047769-3e1c-449b-ac05-d6019b421ca3', NULL, NULL, '2026-04-14 19:01:19.153426+00', '2026-05-14 19:01:19.153426+00', NULL);
INSERT INTO public.user_sessions VALUES (1597, 4, '8e679707-a0ec-4127-9bb2-e1fd26f321c8', NULL, NULL, '2026-04-14 19:02:09.860098+00', '2026-05-14 19:02:09.860098+00', NULL);
INSERT INTO public.user_sessions VALUES (1598, 4, '8f4b59f0-5394-4070-9c2d-5bf347349921', NULL, NULL, '2026-04-14 19:06:22.014356+00', '2026-05-14 19:06:22.014356+00', NULL);
INSERT INTO public.user_sessions VALUES (1599, 3, 'cd236329-39ad-48ac-b359-c7d1070a2884', NULL, NULL, '2026-04-14 19:06:37.57513+00', '2026-05-14 19:06:37.57513+00', NULL);
INSERT INTO public.user_sessions VALUES (1600, 3, 'b7ce85a1-d424-4b79-af92-934895a60a96', NULL, NULL, '2026-04-14 19:11:40.518632+00', '2026-05-14 19:11:40.518632+00', NULL);
INSERT INTO public.user_sessions VALUES (1601, 4, 'eac3baaf-85ca-44a8-b388-bc3e6f312a9c', NULL, NULL, '2026-04-14 19:18:50.520584+00', '2026-05-14 19:18:50.520584+00', NULL);
INSERT INTO public.user_sessions VALUES (1602, 3, '2ba87607-420b-4e95-8c69-7a1370d53209', NULL, NULL, '2026-04-15 08:55:05.933317+00', '2026-05-15 08:55:05.933317+00', NULL);
INSERT INTO public.user_sessions VALUES (1603, 3, '0df78ce1-d785-445d-90e9-682bc7fa95e5', NULL, NULL, '2026-04-15 08:58:53.872387+00', '2026-05-15 08:58:53.872387+00', NULL);
INSERT INTO public.user_sessions VALUES (1604, 3, '3b2d492a-fa2f-493e-baac-7a0ae99c47a5', NULL, NULL, '2026-04-15 09:21:14.770126+00', '2026-05-15 09:21:14.770126+00', NULL);
INSERT INTO public.user_sessions VALUES (1605, 3, '9183b2b3-4e66-4be9-8152-92988cbe9df3', NULL, NULL, '2026-04-15 09:23:33.524241+00', '2026-05-15 09:23:33.524241+00', NULL);
INSERT INTO public.user_sessions VALUES (1606, 3, 'e02c77cd-4267-426f-a5ff-b0e516634c02', NULL, NULL, '2026-04-15 09:29:26.905198+00', '2026-05-15 09:29:26.905198+00', NULL);
INSERT INTO public.user_sessions VALUES (1607, 3, 'bf55efbd-5cb7-4435-af73-57612d110d63', NULL, NULL, '2026-04-15 13:44:52.601703+00', '2026-05-15 13:44:52.601703+00', NULL);
INSERT INTO public.user_sessions VALUES (1608, 3, 'a932b397-448f-471a-ab2e-0cd5f8df2eb1', NULL, NULL, '2026-04-15 13:47:22.699274+00', '2026-05-15 13:47:22.699274+00', NULL);
INSERT INTO public.user_sessions VALUES (1609, 3, '92973fcd-2c63-4b0d-bae9-b750963821ab', NULL, NULL, '2026-04-15 14:48:41.13658+00', '2026-05-15 14:48:41.13658+00', NULL);
INSERT INTO public.user_sessions VALUES (1610, 3, '376310cb-8daf-4afa-b58a-dd0c25e05c6d', NULL, NULL, '2026-04-15 14:51:52.481254+00', '2026-05-15 14:51:52.481254+00', NULL);
INSERT INTO public.user_sessions VALUES (1611, 3, '6e6cf76f-4c47-478b-a1a6-f86a988e421c', NULL, NULL, '2026-04-15 14:53:46.038057+00', '2026-05-15 14:53:46.038057+00', NULL);
INSERT INTO public.user_sessions VALUES (1612, 3, 'a707490c-dc73-4af2-b5e1-dfdf41bef9a9', NULL, NULL, '2026-04-15 14:55:12.256077+00', '2026-05-15 14:55:12.256077+00', NULL);
INSERT INTO public.user_sessions VALUES (1613, 3, '812f585c-dd7f-4f0a-8a0a-718db5583900', NULL, NULL, '2026-04-15 14:58:24.944791+00', '2026-05-15 14:58:24.944791+00', NULL);
INSERT INTO public.user_sessions VALUES (1614, 3, 'c9a9315b-a679-4158-b6d6-fd2b1777ae1a', NULL, NULL, '2026-04-15 15:03:01.82258+00', '2026-05-15 15:03:01.82258+00', NULL);
INSERT INTO public.user_sessions VALUES (1615, 3, '5fef7dd8-5854-47db-9496-379373d035c4', NULL, NULL, '2026-04-15 15:09:56.919618+00', '2026-05-15 15:09:56.919618+00', NULL);
INSERT INTO public.user_sessions VALUES (1616, 3, '7ddc87e3-cc52-4cde-b38e-d9b61cf6b6f1', NULL, NULL, '2026-04-15 15:19:01.598533+00', '2026-05-15 15:19:01.598533+00', NULL);
INSERT INTO public.user_sessions VALUES (1617, 3, '77aa2870-2eee-4a2a-811e-55d43227f18a', NULL, NULL, '2026-04-15 15:21:23.017435+00', '2026-05-15 15:21:23.017435+00', NULL);
INSERT INTO public.user_sessions VALUES (1618, 3, '84e3ee11-ade5-4161-ac93-ae9578b2c5b4', NULL, NULL, '2026-04-15 15:23:40.511549+00', '2026-05-15 15:23:40.511549+00', NULL);
INSERT INTO public.user_sessions VALUES (1619, 3, '86f5ea84-35d8-4835-bc47-875296e54ff2', NULL, NULL, '2026-04-15 15:25:28.418701+00', '2026-05-15 15:25:28.418701+00', NULL);
INSERT INTO public.user_sessions VALUES (1620, 3, '398584fb-f330-478b-b150-b1153bcceb29', NULL, NULL, '2026-04-15 15:30:31.51706+00', '2026-05-15 15:30:31.51706+00', NULL);
INSERT INTO public.user_sessions VALUES (1621, 3, '433eca13-98fc-489d-9441-494847b92e63', NULL, NULL, '2026-04-15 15:59:30.795134+00', '2026-05-15 15:59:30.795134+00', NULL);
INSERT INTO public.user_sessions VALUES (1622, 3, '956a69bc-988e-42aa-b1ea-93ed16667b3c', NULL, NULL, '2026-04-15 16:19:04.772615+00', '2026-05-15 16:19:04.772615+00', NULL);
INSERT INTO public.user_sessions VALUES (1623, 3, 'e0c3d874-4031-434a-a549-7cbebac11274', NULL, NULL, '2026-04-15 16:24:47.324078+00', '2026-05-15 16:24:47.324078+00', NULL);
INSERT INTO public.user_sessions VALUES (1628, 3, '71133ed1-0c5c-4290-9a0a-235f6f8e7f16', NULL, NULL, '2026-04-15 16:46:48.234803+00', '2026-05-15 16:46:48.234803+00', NULL);
INSERT INTO public.user_sessions VALUES (1633, 3, 'c8fc87b8-07ee-4d81-bb5a-9c671c641083', NULL, NULL, '2026-04-15 17:19:32.947373+00', '2026-05-15 17:19:32.947373+00', NULL);
INSERT INTO public.user_sessions VALUES (1638, 3, 'fb1ce122-7df2-4c3e-a0e5-24f57ca3025a', NULL, NULL, '2026-04-15 18:05:36.116792+00', '2026-05-15 18:05:36.116792+00', NULL);
INSERT INTO public.user_sessions VALUES (1643, 3, '2a0be962-5241-435b-91bd-98a3b84dccee', NULL, NULL, '2026-04-15 18:27:14.151176+00', '2026-05-15 18:27:14.151176+00', NULL);
INSERT INTO public.user_sessions VALUES (1648, 3, 'e7e3bb67-d412-4e98-8f1d-a6fb1cfb6f8a', NULL, NULL, '2026-04-15 18:52:32.024364+00', '2026-05-15 18:52:32.024364+00', NULL);
INSERT INTO public.user_sessions VALUES (1653, 3, 'e453d03d-5ca7-4202-9f44-93c7cc74c022', NULL, NULL, '2026-04-15 20:00:56.953304+00', '2026-05-15 20:00:56.953304+00', NULL);
INSERT INTO public.user_sessions VALUES (1624, 3, '554b7db7-ac48-4f42-82e6-32bb9b81e7c4', NULL, NULL, '2026-04-15 16:31:07.328917+00', '2026-05-15 16:31:07.328917+00', NULL);
INSERT INTO public.user_sessions VALUES (1629, 3, 'fbcb9fa8-1e52-44e3-ba3e-d116e14951b3', NULL, NULL, '2026-04-15 16:52:00.287955+00', '2026-05-15 16:52:00.287955+00', NULL);
INSERT INTO public.user_sessions VALUES (1634, 3, '1fbad8a6-cc38-45aa-a527-3e6a95c602ba', NULL, NULL, '2026-04-15 17:22:48.254618+00', '2026-05-15 17:22:48.254618+00', NULL);
INSERT INTO public.user_sessions VALUES (1639, 3, '2ce35fa7-c326-4392-b89c-19a8b1b5e49f', NULL, NULL, '2026-04-15 18:07:08.68093+00', '2026-05-15 18:07:08.68093+00', NULL);
INSERT INTO public.user_sessions VALUES (1644, 3, '0c2351d3-ed83-4937-b52e-ef840ebefde3', NULL, NULL, '2026-04-15 18:49:02.429604+00', '2026-05-15 18:49:02.429604+00', NULL);
INSERT INTO public.user_sessions VALUES (1649, 3, '556f35bf-139f-4bf6-9cbd-77399def0cbb', NULL, NULL, '2026-04-15 18:59:25.444609+00', '2026-05-15 18:59:25.444609+00', NULL);
INSERT INTO public.user_sessions VALUES (1654, 3, 'af55fd97-acac-4d8c-b085-81f53da67f30', NULL, NULL, '2026-04-15 20:03:47.411134+00', '2026-05-15 20:03:47.411134+00', NULL);
INSERT INTO public.user_sessions VALUES (1625, 3, 'd3635ca0-3716-49dd-801a-0c2fe95134cf', NULL, NULL, '2026-04-15 16:35:10.512556+00', '2026-05-15 16:35:10.512556+00', NULL);
INSERT INTO public.user_sessions VALUES (1630, 3, '1de94a59-df8a-4f2c-bb23-3f7ff7a7d4fa', NULL, NULL, '2026-04-15 17:05:59.973539+00', '2026-05-15 17:05:59.973539+00', NULL);
INSERT INTO public.user_sessions VALUES (1635, 3, '629a9e06-a1e4-45da-a069-b436337b7e8d', NULL, NULL, '2026-04-15 17:27:15.570989+00', '2026-05-15 17:27:15.570989+00', NULL);
INSERT INTO public.user_sessions VALUES (1640, 3, '2a006e5c-f4f9-4989-a37a-c6c558753f80', NULL, NULL, '2026-04-15 18:10:07.822807+00', '2026-05-15 18:10:07.822807+00', NULL);
INSERT INTO public.user_sessions VALUES (1645, 3, '7400edaa-72ad-4f7e-aca7-a84df89ffeff', NULL, NULL, '2026-04-15 18:50:12.893048+00', '2026-05-15 18:50:12.893048+00', NULL);
INSERT INTO public.user_sessions VALUES (1650, 3, 'bd473861-bef3-4269-9308-58628c172d09', NULL, NULL, '2026-04-15 19:21:57.712829+00', '2026-05-15 19:21:57.712829+00', NULL);
INSERT INTO public.user_sessions VALUES (1655, 3, '6a36cb2e-a781-4d5f-bbd0-dfcb3e9a6246', NULL, NULL, '2026-04-15 20:17:26.355441+00', '2026-05-15 20:17:26.355441+00', NULL);
INSERT INTO public.user_sessions VALUES (1626, 3, '23538a39-d9f5-4040-99b4-a2d1ff84ac14', NULL, NULL, '2026-04-15 16:37:41.141814+00', '2026-05-15 16:37:41.141814+00', NULL);
INSERT INTO public.user_sessions VALUES (1631, 3, '55e5d0af-1de7-4587-b28a-fb808a73dc66', NULL, NULL, '2026-04-15 17:06:49.309439+00', '2026-05-15 17:06:49.309439+00', NULL);
INSERT INTO public.user_sessions VALUES (1636, 3, 'cc3d5c8a-c2bf-4872-9e9b-1197bae06be0', NULL, NULL, '2026-04-15 17:28:11.798504+00', '2026-05-15 17:28:11.798504+00', NULL);
INSERT INTO public.user_sessions VALUES (1641, 3, 'ec95a1dc-d89a-44bd-b7ae-c4c3766bf02b', NULL, NULL, '2026-04-15 18:11:41.400332+00', '2026-05-15 18:11:41.400332+00', NULL);
INSERT INTO public.user_sessions VALUES (1646, 3, '63c34338-cf6d-4937-9b3f-3c28b4ede3e0', NULL, NULL, '2026-04-15 18:50:50.765307+00', '2026-05-15 18:50:50.765307+00', NULL);
INSERT INTO public.user_sessions VALUES (1651, 3, 'bb32f148-e8c5-493b-9d92-a4f9800ae267', NULL, NULL, '2026-04-15 19:32:59.912343+00', '2026-05-15 19:32:59.912343+00', NULL);
INSERT INTO public.user_sessions VALUES (1627, 3, 'f96cbdfd-d81a-4983-99b6-e02c9033fa70', NULL, NULL, '2026-04-15 16:44:44.024407+00', '2026-05-15 16:44:44.024407+00', NULL);
INSERT INTO public.user_sessions VALUES (1632, 3, 'f12abb70-010c-4a26-b88d-8a7d0e140fc7', NULL, NULL, '2026-04-15 17:14:46.806694+00', '2026-05-15 17:14:46.806694+00', NULL);
INSERT INTO public.user_sessions VALUES (1637, 3, '280f61d8-8627-47c0-a743-4dcf02956707', NULL, NULL, '2026-04-15 18:04:26.502264+00', '2026-05-15 18:04:26.502264+00', NULL);
INSERT INTO public.user_sessions VALUES (1642, 3, '3bc3a807-98d6-4a40-b32b-83552eae2c2b', NULL, NULL, '2026-04-15 18:13:11.213613+00', '2026-05-15 18:13:11.213613+00', NULL);
INSERT INTO public.user_sessions VALUES (1647, 3, '0500b92c-ef64-4d7d-8393-0fbeaf058c31', NULL, NULL, '2026-04-15 18:51:31.215367+00', '2026-05-15 18:51:31.215367+00', NULL);
INSERT INTO public.user_sessions VALUES (1652, 3, 'b8ccbc17-9c2a-4a14-931d-3add22380a40', NULL, NULL, '2026-04-15 19:39:03.190008+00', '2026-05-15 19:39:03.190008+00', NULL);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (5, 'test3', 'test3', '2023-05-04 16:25:31.727922+00', NULL, 0, '2026-03-03 16:16:54.618401+00', true, 0, NULL, NULL, NULL, false);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (4, 'test2', 'test2', '2026-04-14 19:18:50.516743+00', NULL, 0, '2026-03-03 16:16:54.618401+00', true, 0, NULL, '127.0.0.1', NULL, false);
INSERT INTO public.users OVERRIDING SYSTEM VALUE VALUES (3, 'test1', 'test1', '2026-04-15 20:17:26.351758+00', NULL, 0, '2026-03-03 16:16:54.618401+00', true, 0, NULL, '127.0.0.1', NULL, false);


--
-- Data for Name: vendor_inventory; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.vendor_inventory VALUES (3, 1, 3, -1, NULL, 0, -1, 3600, NULL);
INSERT INTO public.vendor_inventory VALUES (4, 1, 4, -1, NULL, 0, -1, 3600, NULL);
INSERT INTO public.vendor_inventory VALUES (1, 1, 1, 5, NULL, 5, -1, 3600, NULL);
INSERT INTO public.vendor_inventory VALUES (2, 1, 2, 5, NULL, 5, -1, 3600, NULL);
INSERT INTO public.vendor_inventory VALUES (5, 1, 15, 5, NULL, 5, -1, 3600, NULL);
INSERT INTO public.vendor_inventory VALUES (6, 2, 18, -1, NULL, 0, -1, 0, NULL);
INSERT INTO public.vendor_inventory VALUES (7, 2, 20, -1, NULL, 0, -1, 0, NULL);
INSERT INTO public.vendor_inventory VALUES (8, 2, 21, -1, NULL, 0, -1, 0, NULL);
INSERT INTO public.vendor_inventory VALUES (9, 3, 22, -1, NULL, 0, -1, 0, NULL);
INSERT INTO public.vendor_inventory VALUES (10, 3, 23, -1, NULL, 0, -1, 0, NULL);
INSERT INTO public.vendor_inventory VALUES (11, 3, 25, -1, NULL, 0, -1, 0, NULL);
INSERT INTO public.vendor_inventory VALUES (12, 3, 26, -1, NULL, 0, -1, 0, NULL);


--
-- Data for Name: vendor_npc; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.vendor_npc VALUES (1, 1, 10);
INSERT INTO public.vendor_npc VALUES (2, 4, 0);
INSERT INTO public.vendor_npc VALUES (3, 5, 0);


--
-- Data for Name: world_object_states; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: world_objects; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: zone_event_templates; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.zone_event_templates VALUES (1, 'wolf_hour', 1, 'random', 1200, 1.5, 1, 1.3, 'event.wolf_hour.announce', 0, 0.15, false, NULL, 0, NULL, NULL);
INSERT INTO public.zone_event_templates VALUES (2, 'merchant_convoy', 1, 'scheduled', 900, 1, 1, 1, 'event.merchant_convoy', 6, 0, false, NULL, 0, NULL, NULL);
INSERT INTO public.zone_event_templates VALUES (3, 'fog_of_twilight', NULL, 'random', 1800, 1.2, 1, 0.8, 'event.fog_of_twilight', 0, 0.08, false, NULL, 0, NULL, NULL);


--
-- Data for Name: zones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.zones VALUES (1, 'village', 'Village', 1, 10, false, true,  -5394.954042227455, 4568.621024817196, -5471.3412259071965, 3002.10848639096, 100, 100, 'RECT', -413.1665087051295, -1234.6163697581183, 0, 0);
INSERT INTO public.zones VALUES (2, 'fields',  'Fields',  1, 20, false, false, -5438.206711468296, 4555.443380622781,  3054.1359757361442, 7954.135975736144, 100, 100, 'RECT', -441.3816654227575,  5504.135975736144,  0, 0);


--
-- Name: character_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_attributes_id_seq', 183, true);


--
-- Name: character_attributes_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_attributes_id_seq1', 26, true);


--
-- Name: character_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_class_id_seq', 2, true);


--
-- Name: character_emotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_emotes_id_seq', 191, true);


--
-- Name: character_equipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_equipment_id_seq', 92, true);


--
-- Name: character_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_position_id_seq', 3, true);


--
-- Name: character_skills_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.character_skills_id_seq1', 18, true);


--
-- Name: characters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.characters_id_seq', 3, true);


--
-- Name: class_skill_tree_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.class_skill_tree_id_seq', 22, true);


--
-- Name: currency_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.currency_transactions_id_seq', 1, false);


--
-- Name: dialogue_edge_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.dialogue_edge_id_seq', 144, true);


--
-- Name: dialogue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.dialogue_id_seq', 6, true);


--
-- Name: dialogue_node_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.dialogue_node_id_seq', 611, true);


--
-- Name: emote_definitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.emote_definitions_id_seq', 13, true);


--
-- Name: exp_for_level_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.exp_for_level_id_seq', 10, true);


--
-- Name: factions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.factions_id_seq', 5, true);


--
-- Name: game_analytics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.game_analytics_id_seq', 1, false);


--
-- Name: gm_action_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.gm_action_log_id_seq', 1, false);


--
-- Name: item_attributes_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_attributes_mapping_id_seq', 10, true);


--
-- Name: item_set_bonuses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_set_bonuses_id_seq', 1, false);


--
-- Name: item_sets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_sets_id_seq', 1, false);


--
-- Name: item_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_types_id_seq', 10, true);


--
-- Name: item_use_effects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_use_effects_id_seq', 2, true);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.items_id_seq', 26, true);


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

SELECT pg_catalog.setval('public.mob_loot_info_id_seq', 35, true);


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

SELECT pg_catalog.setval('public.mob_stat_id_seq', 192, true);


--
-- Name: npc_ambient_speech_configs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_ambient_speech_configs_id_seq', 1, true);


--
-- Name: npc_ambient_speech_lines_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_ambient_speech_lines_id_seq', 3, true);


--
-- Name: npc_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_attributes_id_seq', 13, true);


--
-- Name: npc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_id_seq', 6, true);


--
-- Name: npc_placements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_placements_id_seq', 12, true);


--
-- Name: npc_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_position_id_seq', 8, true);


--
-- Name: npc_skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_skills_id_seq', 2, true);


--
-- Name: npc_trainer_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_trainer_class_id_seq', 2, true);


--
-- Name: npc_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.npc_type_id_seq', 6, true);


--
-- Name: passive_skill_modifiers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.passive_skill_modifiers_id_seq', 1, false);


--
-- Name: player_active_effect_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.player_active_effect_id_seq', 1152, true);


--
-- Name: player_inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.player_inventory_id_seq', 234, true);


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

SELECT pg_catalog.setval('public.quest_step_id_seq', 4, true);


--
-- Name: race_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.race_id_seq', 2, true);


--
-- Name: respawn_zones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.respawn_zones_id_seq', 1, true);


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

SELECT pg_catalog.setval('public.skill_properties_id_seq', 8, true);


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

SELECT pg_catalog.setval('public.skills_attributes_mapping_id_seq', 50, true);


--
-- Name: skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skills_id_seq', 12, true);


--
-- Name: spawn_zone_mobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.spawn_zone_mobs_id_seq', 5, true);


--
-- Name: spawn_zones_zone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.spawn_zones_zone_id_seq', 5, true);


--
-- Name: status_effect_modifiers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.status_effect_modifiers_id_seq', 1, true);


--
-- Name: status_effects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.status_effects_id_seq', 2, true);


--
-- Name: target_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.target_type_id_seq', 6, true);


--
-- Name: timed_champion_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.timed_champion_templates_id_seq', 1, false);


--
-- Name: title_definitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.title_definitions_id_seq', 12, true);


--
-- Name: user_bans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_bans_id_seq', 1, false);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_sessions_id_seq', 1655, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 5, true);


--
-- Name: vendor_inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vendor_inventory_id_seq', 27, true);


--
-- Name: vendor_npc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vendor_npc_id_seq', 1, true);


--
-- Name: world_objects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.world_objects_id_seq', 1, false);


--
-- Name: zone_event_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zone_event_templates_id_seq', 3, true);


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
-- Name: character_bestiary character_bestiary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_bestiary
    ADD CONSTRAINT character_bestiary_pkey PRIMARY KEY (character_id, mob_template_id);


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
-- Name: character_emotes character_emotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_emotes
    ADD CONSTRAINT character_emotes_pkey PRIMARY KEY (id);


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
-- Name: character_pity character_pity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_pity
    ADD CONSTRAINT character_pity_pkey PRIMARY KEY (character_id, item_id);


--
-- Name: character_position character_position_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_position
    ADD CONSTRAINT character_position_pkey PRIMARY KEY (id);


--
-- Name: character_reputation character_reputation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_reputation
    ADD CONSTRAINT character_reputation_pkey PRIMARY KEY (character_id, faction_slug);


--
-- Name: character_skill_bar character_skill_bar_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_skill_bar
    ADD CONSTRAINT character_skill_bar_pkey PRIMARY KEY (character_id, slot_index);


--
-- Name: character_skill_mastery character_skill_mastery_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_skill_mastery
    ADD CONSTRAINT character_skill_mastery_pkey PRIMARY KEY (character_id, mastery_slug);


--
-- Name: character_skills character_skills_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_skills
    ADD CONSTRAINT character_skills_pkey1 PRIMARY KEY (id);


--
-- Name: character_titles character_titles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_titles
    ADD CONSTRAINT character_titles_pkey PRIMARY KEY (character_id, title_slug);


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
-- Name: damage_elements damage_elements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.damage_elements
    ADD CONSTRAINT damage_elements_pkey PRIMARY KEY (slug);


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
-- Name: emote_definitions emote_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emote_definitions
    ADD CONSTRAINT emote_definitions_pkey PRIMARY KEY (id);


--
-- Name: emote_definitions emote_definitions_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emote_definitions
    ADD CONSTRAINT emote_definitions_slug_key UNIQUE (slug);


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
-- Name: factions factions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factions
    ADD CONSTRAINT factions_pkey PRIMARY KEY (id);


--
-- Name: factions factions_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factions
    ADD CONSTRAINT factions_slug_key UNIQUE (slug);


--
-- Name: game_analytics game_analytics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_analytics
    ADD CONSTRAINT game_analytics_pkey PRIMARY KEY (id);


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
-- Name: item_class_restrictions item_class_restrictions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_class_restrictions
    ADD CONSTRAINT item_class_restrictions_pkey PRIMARY KEY (item_id, class_id);


--
-- Name: item_set_bonuses item_set_bonuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_set_bonuses
    ADD CONSTRAINT item_set_bonuses_pkey PRIMARY KEY (id);


--
-- Name: item_set_members item_set_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_set_members
    ADD CONSTRAINT item_set_members_pkey PRIMARY KEY (set_id, item_id);


--
-- Name: item_sets item_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets
    ADD CONSTRAINT item_sets_pkey PRIMARY KEY (id);


--
-- Name: item_sets item_sets_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets
    ADD CONSTRAINT item_sets_slug_key UNIQUE (slug);


--
-- Name: item_types item_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_types
    ADD CONSTRAINT item_types_pkey PRIMARY KEY (id);


--
-- Name: item_use_effects item_use_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_use_effects
    ADD CONSTRAINT item_use_effects_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: mastery_definitions mastery_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mastery_definitions
    ADD CONSTRAINT mastery_definitions_pkey PRIMARY KEY (slug);


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
-- Name: mob_resistances mob_resistances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_resistances
    ADD CONSTRAINT mob_resistances_pkey PRIMARY KEY (mob_id, element_slug);


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
-- Name: mob_weaknesses mob_weaknesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_weaknesses
    ADD CONSTRAINT mob_weaknesses_pkey PRIMARY KEY (mob_id, element_slug);


--
-- Name: npc_ambient_speech_configs npc_ambient_speech_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_ambient_speech_configs
    ADD CONSTRAINT npc_ambient_speech_configs_pkey PRIMARY KEY (id);


--
-- Name: npc_ambient_speech_lines npc_ambient_speech_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_ambient_speech_lines
    ADD CONSTRAINT npc_ambient_speech_lines_pkey PRIMARY KEY (id);


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
-- Name: npc_trainer_class npc_trainer_class_npc_id_class_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_trainer_class
    ADD CONSTRAINT npc_trainer_class_npc_id_class_id_key UNIQUE (npc_id, class_id);


--
-- Name: npc_trainer_class npc_trainer_class_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_trainer_class
    ADD CONSTRAINT npc_trainer_class_pkey PRIMARY KEY (id);


--
-- Name: npc_type npc_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_type
    ADD CONSTRAINT npc_type_pkey PRIMARY KEY (id);


--
-- Name: passive_skill_modifiers passive_skill_modifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passive_skill_modifiers
    ADD CONSTRAINT passive_skill_modifiers_pkey PRIMARY KEY (id);


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
-- Name: respawn_zones respawn_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.respawn_zones
    ADD CONSTRAINT respawn_zones_pkey PRIMARY KEY (id);


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
-- Name: skill_damage_formulas skill_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_damage_formulas
    ADD CONSTRAINT skill_effects_pkey PRIMARY KEY (id);


--
-- Name: skill_damage_formulas skill_effects_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_damage_formulas
    ADD CONSTRAINT skill_effects_slug_key UNIQUE (slug);


--
-- Name: skill_damage_types skill_effects_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_damage_types
    ADD CONSTRAINT skill_effects_type_pkey PRIMARY KEY (id);


--
-- Name: skill_damage_types skill_effects_type_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_damage_types
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
-- Name: status_effect_modifiers status_effect_modifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_effect_modifiers
    ADD CONSTRAINT status_effect_modifiers_pkey PRIMARY KEY (id);


--
-- Name: status_effects status_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_effects
    ADD CONSTRAINT status_effects_pkey PRIMARY KEY (id);


--
-- Name: status_effects status_effects_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_effects
    ADD CONSTRAINT status_effects_slug_key UNIQUE (slug);


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
-- Name: timed_champion_templates timed_champion_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timed_champion_templates
    ADD CONSTRAINT timed_champion_templates_pkey PRIMARY KEY (id);


--
-- Name: timed_champion_templates timed_champion_templates_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timed_champion_templates
    ADD CONSTRAINT timed_champion_templates_slug_key UNIQUE (slug);


--
-- Name: title_definitions title_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.title_definitions
    ADD CONSTRAINT title_definitions_pkey PRIMARY KEY (id);


--
-- Name: title_definitions title_definitions_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.title_definitions
    ADD CONSTRAINT title_definitions_slug_key UNIQUE (slug);


--
-- Name: character_emotes uq_character_emote; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_emotes
    ADD CONSTRAINT uq_character_emote UNIQUE (character_id, emote_slug);


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
-- Name: npc_ambient_speech_configs uq_npc_ambient_config; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_ambient_speech_configs
    ADD CONSTRAINT uq_npc_ambient_config UNIQUE (npc_id);


--
-- Name: passive_skill_modifiers uq_psm_skill_attr; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passive_skill_modifiers
    ADD CONSTRAINT uq_psm_skill_attr UNIQUE (skill_id, attribute_slug);


--
-- Name: status_effect_modifiers uq_sem_effect_attr; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_effect_modifiers
    ADD CONSTRAINT uq_sem_effect_attr UNIQUE (status_effect_id, attribute_id);


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
-- Name: world_object_states world_object_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_object_states
    ADD CONSTRAINT world_object_states_pkey PRIMARY KEY (object_id);


--
-- Name: world_objects world_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_objects
    ADD CONSTRAINT world_objects_pkey PRIMARY KEY (id);


--
-- Name: world_objects world_objects_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_objects
    ADD CONSTRAINT world_objects_slug_key UNIQUE (slug);


--
-- Name: zone_event_templates zone_event_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_event_templates
    ADD CONSTRAINT zone_event_templates_pkey PRIMARY KEY (id);


--
-- Name: zone_event_templates zone_event_templates_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_event_templates
    ADD CONSTRAINT zone_event_templates_slug_key UNIQUE (slug);


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
-- Name: idx_ambient_lines_npc_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ambient_lines_npc_id ON public.npc_ambient_speech_lines USING btree (npc_id);


--
-- Name: idx_char_mastery_char; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_char_mastery_char ON public.character_skill_mastery USING btree (character_id);


--
-- Name: idx_char_rep_char; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_char_rep_char ON public.character_reputation USING btree (character_id);


--
-- Name: idx_char_titles_char; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_char_titles_char ON public.character_titles USING btree (character_id);


--
-- Name: idx_character_bestiary_char; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_character_bestiary_char ON public.character_bestiary USING btree (character_id);


--
-- Name: idx_character_emotes_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_character_emotes_character_id ON public.character_emotes USING btree (character_id);


--
-- Name: idx_character_pity_char; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_character_pity_char ON public.character_pity USING btree (character_id);


--
-- Name: idx_ga_character; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ga_character ON public.game_analytics USING btree (character_id, created_at DESC);


--
-- Name: idx_ga_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ga_created_at ON public.game_analytics USING btree (created_at DESC);


--
-- Name: idx_ga_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ga_event_type ON public.game_analytics USING btree (event_type, created_at DESC);


--
-- Name: idx_ga_payload; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ga_payload ON public.game_analytics USING gin (payload);


--
-- Name: idx_ga_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ga_session ON public.game_analytics USING btree (session_id);


--
-- Name: idx_item_set_bonuses_set; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_item_set_bonuses_set ON public.item_set_bonuses USING btree (set_id);


--
-- Name: idx_item_set_members_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_item_set_members_item ON public.item_set_members USING btree (item_id);


--
-- Name: idx_item_use_effects_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_item_use_effects_item_id ON public.item_use_effects USING btree (item_id);


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
-- Name: idx_mob_loot_tier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mob_loot_tier ON public.mob_loot_info USING btree (mob_id, loot_tier);


--
-- Name: idx_mob_mob_type_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mob_mob_type_slug ON public.mob USING btree (mob_type_slug);


--
-- Name: idx_mob_position_mob; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mob_position_mob ON public.mob_position USING btree (mob_id);


--
-- Name: idx_mob_resistances_mob; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mob_resistances_mob ON public.mob_resistances USING btree (mob_id);


--
-- Name: idx_mob_stat_mob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mob_stat_mob_id ON public.mob_stat USING btree (mob_id);


--
-- Name: idx_mob_weaknesses_mob; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mob_weaknesses_mob ON public.mob_weaknesses USING btree (mob_id);


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
-- Name: idx_player_inventory_char_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_player_inventory_char_item ON public.player_inventory USING btree (character_id, item_id);


--
-- Name: idx_player_inventory_character; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_player_inventory_character ON public.player_inventory USING btree (character_id);


--
-- Name: idx_player_inventory_ground; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_player_inventory_ground ON public.player_inventory USING btree (id) WHERE (character_id IS NULL);


--
-- Name: idx_quest_reward_quest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_quest_reward_quest ON public.quest_reward USING btree (quest_id);


--
-- Name: idx_skill_bar_character; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_skill_bar_character ON public.character_skill_bar USING btree (character_id);


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
-- Name: idx_timed_champion_next; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timed_champion_next ON public.timed_champion_templates USING btree (next_spawn_at);


--
-- Name: idx_timed_champion_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timed_champion_zone ON public.timed_champion_templates USING btree (zone_id);


--
-- Name: idx_world_object_states_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_world_object_states_state ON public.world_object_states USING btree (state);


--
-- Name: idx_world_objects_type_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_world_objects_type_scope ON public.world_objects USING btree (object_type, scope);


--
-- Name: idx_world_objects_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_world_objects_zone ON public.world_objects USING btree (zone_id);


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
-- Name: ix_items_mastery_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_items_mastery_slug ON public.items USING btree (mastery_slug) WHERE (mastery_slug IS NOT NULL);


--
-- Name: ix_mob_active_effect_src_player; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mob_active_effect_src_player ON public.mob_active_effect USING btree (source_player_id) WHERE (source_player_id IS NOT NULL);


--
-- Name: ix_mob_faction_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mob_faction_slug ON public.mob USING btree (faction_slug) WHERE (faction_slug IS NOT NULL);


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
-- Name: ix_npc_dialogue_cond_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_npc_dialogue_cond_gin ON public.npc_dialogue USING gin (condition_group) WHERE (condition_group IS NOT NULL);


--
-- Name: ix_npc_faction_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_npc_faction_slug ON public.npc USING btree (faction_slug) WHERE (faction_slug IS NOT NULL);


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

CREATE INDEX ix_pae_effect_id ON public.player_active_effect USING btree (status_effect_id);


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
-- Name: ix_respawn_zones_default; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_respawn_zones_default ON public.respawn_zones USING btree (zone_id, is_default) WHERE (is_default = true);


--
-- Name: ix_respawn_zones_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_respawn_zones_zone_id ON public.respawn_zones USING btree (zone_id);


--
-- Name: ix_timed_champion_mob_tpl; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_timed_champion_mob_tpl ON public.timed_champion_templates USING btree (mob_template_id);


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
-- Name: ix_zone_event_game_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zone_event_game_zone ON public.zone_event_templates USING btree (game_zone_id) WHERE (game_zone_id IS NOT NULL);


--
-- Name: ix_zone_event_invasion_mob; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zone_event_invasion_mob ON public.zone_event_templates USING btree (invasion_mob_template_id) WHERE (invasion_mob_template_id IS NOT NULL);


--
-- Name: ix_zone_event_trigger_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zone_event_trigger_type ON public.zone_event_templates USING btree (trigger_type);


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

CREATE UNIQUE INDEX uq_skill_effects_slug ON public.skill_damage_formulas USING btree (slug);


--
-- Name: uq_skill_effects_type_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_skill_effects_type_slug ON public.skill_damage_types USING btree (slug);


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
-- Name: character_bestiary character_bestiary_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_bestiary
    ADD CONSTRAINT character_bestiary_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_bestiary character_bestiary_mob_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_bestiary
    ADD CONSTRAINT character_bestiary_mob_template_id_fkey FOREIGN KEY (mob_template_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: character_emotes character_emotes_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_emotes
    ADD CONSTRAINT character_emotes_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_emotes character_emotes_emote_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_emotes
    ADD CONSTRAINT character_emotes_emote_slug_fkey FOREIGN KEY (emote_slug) REFERENCES public.emote_definitions(slug) ON DELETE CASCADE;


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
-- Name: character_pity character_pity_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_pity
    ADD CONSTRAINT character_pity_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_pity character_pity_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_pity
    ADD CONSTRAINT character_pity_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


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
-- Name: character_reputation character_reputation_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_reputation
    ADD CONSTRAINT character_reputation_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_reputation character_reputation_faction_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_reputation
    ADD CONSTRAINT character_reputation_faction_slug_fkey FOREIGN KEY (faction_slug) REFERENCES public.factions(slug);


--
-- Name: character_skill_bar character_skill_bar_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_skill_bar
    ADD CONSTRAINT character_skill_bar_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_skill_mastery character_skill_mastery_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_skill_mastery
    ADD CONSTRAINT character_skill_mastery_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_skill_mastery character_skill_mastery_mastery_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_skill_mastery
    ADD CONSTRAINT character_skill_mastery_mastery_slug_fkey FOREIGN KEY (mastery_slug) REFERENCES public.mastery_definitions(slug);


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
-- Name: character_titles character_titles_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_titles
    ADD CONSTRAINT character_titles_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: character_titles character_titles_title_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_titles
    ADD CONSTRAINT character_titles_title_slug_fkey FOREIGN KEY (title_slug) REFERENCES public.title_definitions(slug) ON DELETE CASCADE;


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
-- Name: class_skill_tree class_skill_tree_prerequisite_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT class_skill_tree_prerequisite_skill_id_fkey FOREIGN KEY (prerequisite_skill_id) REFERENCES public.skills(id) ON DELETE SET NULL;


--
-- Name: class_skill_tree class_skill_tree_skill_book_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_skill_tree
    ADD CONSTRAINT class_skill_tree_skill_book_item_id_fkey FOREIGN KEY (skill_book_item_id) REFERENCES public.items(id) ON DELETE SET NULL;


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
-- Name: game_analytics game_analytics_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_analytics
    ADD CONSTRAINT game_analytics_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE SET NULL;


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
-- Name: item_class_restrictions item_class_restrictions_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_class_restrictions
    ADD CONSTRAINT item_class_restrictions_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id) ON DELETE CASCADE;


--
-- Name: item_class_restrictions item_class_restrictions_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_class_restrictions
    ADD CONSTRAINT item_class_restrictions_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: item_set_bonuses item_set_bonuses_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_set_bonuses
    ADD CONSTRAINT item_set_bonuses_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: item_set_bonuses item_set_bonuses_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_set_bonuses
    ADD CONSTRAINT item_set_bonuses_set_id_fkey FOREIGN KEY (set_id) REFERENCES public.item_sets(id) ON DELETE CASCADE;


--
-- Name: item_set_members item_set_members_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_set_members
    ADD CONSTRAINT item_set_members_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: item_set_members item_set_members_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_set_members
    ADD CONSTRAINT item_set_members_set_id_fkey FOREIGN KEY (set_id) REFERENCES public.item_sets(id) ON DELETE CASCADE;


--
-- Name: item_use_effects item_use_effects_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_use_effects
    ADD CONSTRAINT item_use_effects_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


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
-- Name: items items_mastery_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_mastery_slug_fkey FOREIGN KEY (mastery_slug) REFERENCES public.mastery_definitions(slug);


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
    ADD CONSTRAINT mob_active_effect_effect_id_fkey FOREIGN KEY (effect_id) REFERENCES public.skill_damage_formulas(id) ON DELETE CASCADE;


--
-- Name: mob_active_effect mob_active_effect_source_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_active_effect
    ADD CONSTRAINT mob_active_effect_source_player_id_fkey FOREIGN KEY (source_player_id) REFERENCES public.characters(id) ON DELETE SET NULL;


--
-- Name: mob mob_faction_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_faction_slug_fkey FOREIGN KEY (faction_slug) REFERENCES public.factions(slug);


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
-- Name: mob_resistances mob_resistances_element_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_resistances
    ADD CONSTRAINT mob_resistances_element_slug_fkey FOREIGN KEY (element_slug) REFERENCES public.damage_elements(slug);


--
-- Name: mob_resistances mob_resistances_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_resistances
    ADD CONSTRAINT mob_resistances_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


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
-- Name: mob_weaknesses mob_weaknesses_element_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_weaknesses
    ADD CONSTRAINT mob_weaknesses_element_slug_fkey FOREIGN KEY (element_slug) REFERENCES public.damage_elements(slug);


--
-- Name: mob_weaknesses mob_weaknesses_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mob_weaknesses
    ADD CONSTRAINT mob_weaknesses_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;


--
-- Name: npc_ambient_speech_configs npc_ambient_speech_configs_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_ambient_speech_configs
    ADD CONSTRAINT npc_ambient_speech_configs_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: npc_ambient_speech_lines npc_ambient_speech_lines_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_ambient_speech_lines
    ADD CONSTRAINT npc_ambient_speech_lines_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


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
-- Name: npc npc_faction_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_faction_slug_fkey FOREIGN KEY (faction_slug) REFERENCES public.factions(slug);


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
-- Name: npc_trainer_class npc_trainer_class_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_trainer_class
    ADD CONSTRAINT npc_trainer_class_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id) ON DELETE CASCADE;


--
-- Name: npc_trainer_class npc_trainer_class_npc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_trainer_class
    ADD CONSTRAINT npc_trainer_class_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;


--
-- Name: passive_skill_modifiers passive_skill_modifiers_attribute_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passive_skill_modifiers
    ADD CONSTRAINT passive_skill_modifiers_attribute_slug_fkey FOREIGN KEY (attribute_slug) REFERENCES public.entity_attributes(slug);


--
-- Name: passive_skill_modifiers passive_skill_modifiers_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passive_skill_modifiers
    ADD CONSTRAINT passive_skill_modifiers_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id) ON DELETE CASCADE;


--
-- Name: player_active_effect player_active_effect_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: player_active_effect player_active_effect_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.characters(id) ON DELETE CASCADE;


--
-- Name: player_active_effect player_active_effect_status_effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_status_effect_id_fkey FOREIGN KEY (status_effect_id) REFERENCES public.status_effects(id);


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
-- Name: respawn_zones respawn_zones_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.respawn_zones
    ADD CONSTRAINT respawn_zones_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zones(id);


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
-- Name: skill_damage_formulas skill_effects_effect_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_damage_formulas
    ADD CONSTRAINT skill_effects_effect_type_id_fkey FOREIGN KEY (effect_type_id) REFERENCES public.skill_damage_types(id);


--
-- Name: skill_effects_mapping skill_effects_mapping_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: skill_effects_mapping skill_effects_mapping_effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_effect_id_fkey FOREIGN KEY (effect_id) REFERENCES public.skill_damage_formulas(id);


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
-- Name: skills skills_scale_stat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_scale_stat_id_fkey FOREIGN KEY (scale_stat_id) REFERENCES public.skill_scale_type(id);


--
-- Name: skills skills_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.skill_school(id);


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
-- Name: status_effect_modifiers status_effect_modifiers_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_effect_modifiers
    ADD CONSTRAINT status_effect_modifiers_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);


--
-- Name: status_effect_modifiers status_effect_modifiers_status_effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_effect_modifiers
    ADD CONSTRAINT status_effect_modifiers_status_effect_id_fkey FOREIGN KEY (status_effect_id) REFERENCES public.status_effects(id) ON DELETE CASCADE;


--
-- Name: timed_champion_templates timed_champion_templates_mob_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timed_champion_templates
    ADD CONSTRAINT timed_champion_templates_mob_template_id_fkey FOREIGN KEY (mob_template_id) REFERENCES public.mob(id);


--
-- Name: timed_champion_templates timed_champion_templates_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timed_champion_templates
    ADD CONSTRAINT timed_champion_templates_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE CASCADE;


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
-- Name: world_object_states world_object_states_object_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_object_states
    ADD CONSTRAINT world_object_states_object_id_fkey FOREIGN KEY (object_id) REFERENCES public.world_objects(id) ON DELETE CASCADE;


--
-- Name: world_objects world_objects_dialogue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_objects
    ADD CONSTRAINT world_objects_dialogue_id_fkey FOREIGN KEY (dialogue_id) REFERENCES public.dialogue(id) ON DELETE SET NULL;


--
-- Name: world_objects world_objects_required_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_objects
    ADD CONSTRAINT world_objects_required_item_id_fkey FOREIGN KEY (required_item_id) REFERENCES public.items(id) ON DELETE SET NULL;


--
-- Name: world_objects world_objects_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_objects
    ADD CONSTRAINT world_objects_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;


--
-- Name: zone_event_templates zone_event_templates_game_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_event_templates
    ADD CONSTRAINT zone_event_templates_game_zone_id_fkey FOREIGN KEY (game_zone_id) REFERENCES public.zones(id);


--
-- Name: zone_event_templates zone_event_templates_invasion_champion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_event_templates
    ADD CONSTRAINT zone_event_templates_invasion_champion_id_fkey FOREIGN KEY (invasion_champion_template_id) REFERENCES public.timed_champion_templates(id);


--
-- Name: zone_event_templates zone_event_templates_invasion_mob_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_event_templates
    ADD CONSTRAINT zone_event_templates_invasion_mob_id_fkey FOREIGN KEY (invasion_mob_template_id) REFERENCES public.mob(id);


--
-- PostgreSQL database dump complete
--

