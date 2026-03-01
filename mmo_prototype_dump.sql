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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: character_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_attributes (
    id bigint NOT NULL,
    character_id bigint DEFAULT 0 NOT NULL,
    attribute_id integer DEFAULT 0 NOT NULL,
    value numeric DEFAULT 0 NOT NULL
);


ALTER TABLE public.character_attributes OWNER TO postgres;

--
-- Name: character_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.character_attributes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
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
-- Name: character_class; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_class (
    id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.character_class OWNER TO postgres;

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
-- Name: character_position; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_position (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    x numeric(11,2) NOT NULL,
    y numeric(11,2) NOT NULL,
    z numeric(11,2) NOT NULL
);


ALTER TABLE public.character_position OWNER TO postgres;

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
    current_health integer DEFAULT 1 NOT NULL,
    current_mana integer DEFAULT 1 NOT NULL,
    is_dead boolean DEFAULT false NOT NULL,
    radius integer DEFAULT 100 NOT NULL
);


ALTER TABLE public.characters OWNER TO postgres;

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
-- Name: exp_for_level; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exp_for_level (
    id integer NOT NULL,
    level integer NOT NULL,
    experience_points bigint NOT NULL
);


ALTER TABLE public.exp_for_level OWNER TO postgres;

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
-- Name: item_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_attributes (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL
);


ALTER TABLE public.item_attributes OWNER TO postgres;

--
-- Name: item_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.item_attributes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.item_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: item_attributes_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_attributes_mapping (
    id bigint NOT NULL,
    item_id bigint NOT NULL,
    attribute_id integer NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.item_attributes_mapping OWNER TO postgres;

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
-- Name: item_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL
);


ALTER TABLE public.item_types OWNER TO postgres;

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
    equip_slot bigint DEFAULT NULL,
    level_requirement bigint DEFAULT 0 NOT NULL,
    is_equippable boolean DEFAULT false NOT NULL,
    is_harvest boolean DEFAULT false NOT NULL
);


ALTER TABLE public.items OWNER TO postgres;

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
-- Name: mob; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    race_id integer DEFAULT 1 NOT NULL,
    level integer NOT NULL,
    current_health integer DEFAULT 1 NOT NULL,
    current_mana integer DEFAULT 1 NOT NULL,
    is_aggressive boolean DEFAULT false NOT NULL,
    is_dead boolean DEFAULT false NOT NULL,
    slug character varying(50),
    radius integer DEFAULT 100 NOT NULL,
    base_xp integer DEFAULT 1 NOT NULL,
    rank_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.mob OWNER TO postgres;

--
-- Name: mob_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_attributes (
    id bigint NOT NULL,
    mob_id bigint NOT NULL,
    attribute_id integer NOT NULL,
    value numeric NOT NULL
);


ALTER TABLE public.mob_attributes OWNER TO postgres;

--
-- Name: mob_attributes_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.mob_attributes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_attributes_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
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
    drop_chance numeric(5,2) DEFAULT 0.00 NOT NULL
);


ALTER TABLE public.mob_loot_info OWNER TO postgres;

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
    mob_id bigint NOT NULL,
    x numeric(11,2) NOT NULL,
    y numeric(11,2) NOT NULL,
    z numeric(11,2) NOT NULL
);


ALTER TABLE public.mob_position OWNER TO postgres;

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
    npc_type integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.npc OWNER TO postgres;

--
-- Name: npc_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_attributes (
    id bigint NOT NULL,
    npc_id bigint NOT NULL,
    attribute_id integer NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.npc_attributes OWNER TO postgres;

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
-- Name: npc_position; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_position (
    id bigint NOT NULL,
    npc_id bigint NOT NULL,
    x numeric(11,2) NOT NULL,
    y numeric(11,2) NOT NULL,
    z numeric(11,2) NOT NULL,
    rot_z numeric(11,2) DEFAULT 0 NOT NULL
);


ALTER TABLE public.npc_position OWNER TO postgres;

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
-- Name: quest_reward; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quest_reward (
    id bigint NOT NULL,
    quest_id bigint NOT NULL,
    reward_type text NOT NULL,
    item_id bigint,
    quantity integer DEFAULT 1 NOT NULL,
    amount bigint DEFAULT 0 NOT NULL,
    CONSTRAINT quest_reward_type_ck CHECK (reward_type IN ('item', 'exp', 'gold'))
);

ALTER TABLE public.quest_reward OWNER TO postgres;

--
-- Name: TABLE quest_reward; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.quest_reward IS 'Награды за сдачу квеста (предметы, опыт, золото)';

COMMENT ON COLUMN public.quest_reward.reward_type IS 'Тип награды: item / exp / gold';
COMMENT ON COLUMN public.quest_reward.item_id IS 'ID предмета (только если reward_type = item)';
COMMENT ON COLUMN public.quest_reward.quantity IS 'Количество предметов (только если reward_type = item)';
COMMENT ON COLUMN public.quest_reward.amount IS 'Количество опыта или золота (только если reward_type = exp / gold)';

CREATE SEQUENCE public.quest_reward_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE public.quest_reward_id_seq OWNER TO postgres;

ALTER SEQUENCE public.quest_reward_id_seq OWNED BY public.quest_reward.id;

ALTER TABLE ONLY public.quest_reward ALTER COLUMN id SET DEFAULT nextval('public.quest_reward_id_seq'::regclass);

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

COMMENT ON TABLE public.player_flag IS 'Гибкие флаги/счётчики игрока (для условий диалогов/квестов)';


--
-- Name: COLUMN player_flag.flag_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_flag.flag_key IS 'Имя флага (например, "mila_thanked")';


--
-- Name: player_inventory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player_inventory (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    item_id bigint NOT NULL,
    quantity integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.player_inventory OWNER TO postgres;

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

COMMENT ON TABLE public.player_quest IS 'Текущее состояние квеста у конкретного игрока';


--
-- Name: COLUMN player_quest.state; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_quest.state IS 'offered/active/completed/turned_in/failed';


--
-- Name: COLUMN player_quest.progress; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_quest.progress IS 'JSON прогресса текущего шага (например, {"have":3})';


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
-- Name: quest_step; Type: TABLE; Schema: public; Owner: postgres
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
-- Name: skill_effects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_effects (
    id integer NOT NULL,
    slug text NOT NULL,
    effect_type_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.skill_effects OWNER TO postgres;

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

ALTER SEQUENCE public.skill_effects_id_seq OWNED BY public.skill_effects.id;


--
-- Name: skill_effects_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_effects_mapping (
    id integer NOT NULL,
    effect_instance_id integer NOT NULL,
    effect_id integer NOT NULL,
    value numeric NOT NULL,
    level integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.skill_effects_mapping OWNER TO postgres;

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
-- Name: skill_effects_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_effects_type (
    id integer NOT NULL,
    slug text NOT NULL
);


ALTER TABLE public.skill_effects_type OWNER TO postgres;

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

ALTER SEQUENCE public.skill_effects_type_id_seq OWNED BY public.skill_effects_type.id;


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
-- Name: skill_scale_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill_scale_type (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL
);


ALTER TABLE public.skill_scale_type OWNER TO postgres;

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
    school_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.skills OWNER TO postgres;

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
-- Name: spawn_zones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.spawn_zones (
    zone_id integer NOT NULL,
    zone_name character varying(50) NOT NULL,
    min_spawn_x numeric(11,2) NOT NULL,
    min_spawn_y numeric(11,2) NOT NULL,
    min_spawn_z numeric(11,2) NOT NULL,
    max_spawn_x numeric(11,2) NOT NULL,
    max_spawn_y numeric(11,2) NOT NULL,
    max_spawn_z numeric(11,2) NOT NULL,
    mob_id integer NOT NULL,
    spawn_count integer NOT NULL,
    respawn_time time without time zone DEFAULT '00:01:00'::time without time zone NOT NULL
);


ALTER TABLE public.spawn_zones OWNER TO postgres;

--
-- Name: spawn_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.spawn_zones ALTER COLUMN zone_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.spawn_zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: target_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.target_type (
    id integer NOT NULL,
    slug text NOT NULL
);


ALTER TABLE public.target_type OWNER TO postgres;

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
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    login character varying(50) NOT NULL,
    password character varying(100) NOT NULL,
    last_login timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    session_key character varying(50) NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

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
-- Name: character_skills id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skills ALTER COLUMN id SET DEFAULT nextval('public.character_skills_id_seq1'::regclass);


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
-- Name: mob_skills id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_skills ALTER COLUMN id SET DEFAULT nextval('public.mob_skills_id_seq'::regclass);


--
-- Name: npc_skills id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_skills ALTER COLUMN id SET DEFAULT nextval('public.npc_skills_id_seq'::regclass);


--
-- Name: quest id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest ALTER COLUMN id SET DEFAULT nextval('public.quest_id_seq'::regclass);


--
-- Name: quest_step id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_step ALTER COLUMN id SET DEFAULT nextval('public.quest_step_id_seq'::regclass);


--
-- Name: skill_effect_instances id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effect_instances ALTER COLUMN id SET DEFAULT nextval('public.skill_effect_instances_id_seq'::regclass);


--
-- Name: skill_effects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_id_seq'::regclass);


--
-- Name: skill_effects_mapping id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects_mapping ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_mapping_id_seq'::regclass);


--
-- Name: skill_effects_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects_type ALTER COLUMN id SET DEFAULT nextval('public.skill_effects_type_id_seq'::regclass);


--
-- Name: target_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.target_type ALTER COLUMN id SET DEFAULT nextval('public.target_type_id_seq'::regclass);


--
-- Data for Name: character_class; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_class (id, name) FROM stdin;
1	Mage
2	Warrior
\.


--
-- Data for Name: character_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_position (id, character_id, x, y, z) FROM stdin;
1	1	-2000.00	4000.00	300.00
2	2	-5483.30	4901.52	187.15
3	3	-5963.46	4788.07	187.15
\.


--
-- Data for Name: character_skills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_skills (id, character_id, skill_id, current_level) FROM stdin;
1	1	1	1
3	1	3	1
4	2	1	1
5	3	1	1
2	3	2	1
\.


--
-- Data for Name: characters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.characters (id, name, owner_id, class_id, race_id, experience_points, level, current_health, current_mana, is_dead, radius) FROM stdin;
1	TetsMage1Player	5	1	1	57	2	39	60	f	100
3	TetsWarrior1Player	3	2	1	530	2	20	25	f	100
2	TetsMage2Player	4	1	1	130	1	45	40	f	100
\.


--
-- Data for Name: dialogue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dialogue (id, slug, version, start_node_id) FROM stdin;
1	milaya_base	1	1
\.


--
-- Data for Name: dialogue_edge; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dialogue_edge (id, from_node_id, to_node_id, order_index, client_choice_key, condition_group, action_group, hide_if_locked) FROM stdin;
1	1	2	0	milaya.choice.about_village	\N	\N	f
\.


--
-- Data for Name: dialogue_node; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dialogue_node (id, dialogue_id, type, speaker_npc_id, client_node_key, condition_group, action_group, jump_target_node_id) FROM stdin;
1	1	line	2	milaya.dialogue.wellcome	\N	\N	\N
2	1	line	2	milaya.dialogue.about_village	\N	\N	\N
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
\.


--
-- Data for Name: character_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_attributes (id, character_id, attribute_id, value) FROM stdin;
4	1	1	100
5	1	2	200
6	1	3	5
7	1	4	15
8	1	5	3
16	1	6	5
17	1	7	5
18	1	10	1
19	1	11	1
20	1	12	3
21	1	13	5
22	1	8	15
23	1	9	2
24	1	14	5
25	1	15	5
26	1	16	15
27	1	17	3
28	1	18	5
29	1	19	5
30	1	20	7
32	2	2	200
33	2	3	5
34	2	4	15
35	2	5	3
36	2	6	5
37	2	7	5
38	2	10	1
39	2	11	1
40	2	12	3
41	2	13	5
42	2	8	15
43	2	9	2
44	2	14	5
45	2	15	5
46	2	16	15
47	2	17	3
48	2	18	5
49	2	19	5
50	2	20	7
52	3	2	200
53	3	3	5
54	3	4	15
55	3	5	3
56	3	6	5
57	3	7	5
58	3	10	1
59	3	11	1
60	3	12	3
61	3	13	5
62	3	8	15
63	3	9	2
64	3	14	5
65	3	15	5
66	3	16	15
67	3	17	3
68	3	18	5
69	3	19	5
70	3	20	7
31	2	1	100
51	3	1	100
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
\.


--
-- Data for Name: item_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item_attributes (id, name, slug) FROM stdin;
1	Damage	damage
2	Defense	defense
3	Healing	healing
4	Hunger Restoration	hunger_restoration
5	Quest Value	quest_value
6	Resource Value	resource_value
\.


--
-- Data for Name: item_attributes_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item_attributes_mapping (id, item_id, attribute_id, value) FROM stdin;
1	1	1	10
2	2	2	5
3	3	3	50
4	4	4	30
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
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.items (id, name, slug, description, is_quest_item, item_type, weight, rarity_id, stack_max, is_container, is_durable, is_tradable, durability_max, vendor_price_buy, vendor_price_sell, equip_slot, level_requirement, is_equippable, is_harvest) FROM stdin;
4	Bread	bread	A loaf of bread to restore hunger.	f	4	0.1	1	64	f	f	t	100	1	1	\N	0	f	f
5	Ancient Artifact	ancient_artifact	A mysterious artifact for quests.	t	5	0.5	1	64	f	f	t	100	1	1	\N	0	f	f
6	Iron Ore	iron_ore	A piece of iron ore, useful for crafting.	f	6	2	1	64	f	f	t	100	1	1	\N	0	f	f
7	Small Animal Bone	small_animal_bone	A small bones of small animal.	f	6	0.5	1	64	f	f	t	100	1	1	\N	0	f	t
1	Iron Sword	iron_sworld	A sturdy iron sword.	f	1	5	1	64	f	t	t	100	1	1	6	1	t	f
2	Wooden Shield	wooden_shield	A basic wooden shield.	f	2	3	1	64	f	t	t	100	1	1	7	1	t	f
10	Animal Fat	animal_fat	Fat extracted from animal.	f	6	0.2	1	64	f	f	t	100	1	1	\N	0	f	t
11	Animal Blood	animal_blood	Blood extracted from animal.	f	6	0.5	1	64	f	f	t	100	1	1	\N	0	f	t
12	Animal Meat	animal_meet	Meat extracted from animal.	f	6	1	1	64	f	f	t	100	1	1	\N	0	f	t
13	Animal Fang	animal_fang	Fang extracted from animal.	f	6	0.2	1	64	f	f	t	100	1	1	\N	0	f	t
14	Animal Eye	animal_eye	Eye extracted from animal.	f	6	0.1	1	64	f	f	t	100	1	1	\N	0	f	t
3	Health Potion	health_potion	Restores 50 health points.	f	3	0.5	1	64	f	f	t	100	1	1	\N	0	f	f
9	Small Animal Skin	small_animal_skin	A basic skin of small animal.	f	6	0.3	1	64	f	f	t	100	1	1	\N	0	f	t
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
-- Data for Name: mob; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob (id, name, race_id, level, current_health, current_mana, is_aggressive, is_dead, slug, radius, base_xp, rank_id) FROM stdin;
1	Small Fox	2	1	100	50	f	f	SmallFox	100	1	1
2	Grey Wolf	2	1	150	50	f	f	GreyWolf	100	1	1
\.


--
-- Data for Name: mob_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_attributes (id, mob_id, attribute_id, value) FROM stdin;
6	2	2	200
7	2	3	5
8	2	4	15
9	2	5	3
10	2	6	5
11	2	7	5
12	2	10	1
13	2	11	1
14	2	12	3
15	2	13	5
16	2	8	15
17	2	9	2
18	2	14	5
19	2	15	5
20	2	16	15
21	2	17	3
22	2	18	5
23	2	19	5
24	2	20	7
26	1	2	200
27	1	3	5
28	1	4	15
29	1	5	3
30	1	6	5
31	1	7	5
32	1	10	1
33	1	11	1
34	1	12	3
35	1	13	5
36	1	8	15
37	1	9	2
38	1	14	5
39	1	15	5
40	1	16	15
41	1	17	3
42	1	18	5
43	1	19	5
44	1	20	7
25	1	1	200
5	2	1	200
\.


--
-- Data for Name: mob_loot_info; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_loot_info (id, mob_id, item_id, drop_chance) FROM stdin;
5	1	6	0.80
1	1	1	0.80
2	1	3	0.80
3	2	2	0.80
4	2	4	0.80
6	1	9	0.80
7	1	10	0.50
8	1	11	0.40
9	1	12	0.20
\.


--
-- Data for Name: mob_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_position (id, mob_id, x, y, z) FROM stdin;
\.


--
-- Data for Name: mob_race; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_race (id, name) FROM stdin;
1	Goblin
2	Animal
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
-- Data for Name: mob_skills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_skills (id, mob_id, skill_id, current_level) FROM stdin;
1	1	1	1
2	2	1	1
\.


--
-- Data for Name: npc; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc (id, name, race_id, level, current_health, current_mana, is_dead, slug, radius, is_interactable, npc_type) FROM stdin;
1	Varan	1	1	100	10	f	varan	100	t	1
2	Milaya	1	1	100	50	f	milaya	100	t	1
3	Edrik	1	1	100	20	f	edrik	100	t	1
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

COPY public.npc_dialogue (npc_id, dialogue_id, priority) FROM stdin;
\.


--
-- Data for Name: npc_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_position (id, npc_id, x, y, z, rot_z) FROM stdin;
2	3	-720.00	2250.00	200.00	-135.00
3	2	2200.00	1120.00	200.00	145.00
1	1	585.00	-3300.00	200.00	-40.00
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
-- Data for Name: player_flag; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_flag (player_id, flag_key, int_value, bool_value, updated_at) FROM stdin;
\.


--
-- Data for Name: player_inventory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_inventory (id, character_id, item_id, quantity) FROM stdin;
\.


--
-- Data for Name: player_quest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_quest (player_id, quest_id, state, current_step, progress, updated_at) FROM stdin;
\.


--
-- Data for Name: quest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quest (id, slug, min_level, repeatable, cooldown_sec, giver_npc_id, turnin_npc_id, client_quest_key) FROM stdin;
1	wolf_hunt_intro	1	t	600	2	2	wolf_hunt_intro
\.


--
-- Data for Name: quest_step; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quest_step (id, quest_id, step_index, step_type, params, client_step_key) FROM stdin;
1	1	0	collect	"{}"	quest_step_collect_pelts
\.


--
-- Data for Name: race; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.race (id, name, slug) FROM stdin;
1	Human	human
2	Elf	elf
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
-- Data for Name: skill_effects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_effects (id, slug, effect_type_id) FROM stdin;
1	coeff	1
2	flat_add	1
\.


--
-- Data for Name: skill_effects_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_effects_mapping (id, effect_instance_id, effect_id, value, level) FROM stdin;
1	1	1	1.0	1
2	2	1	1.8	1
3	2	2	30	1
4	3	1	2.2	1
5	1	2	1	1
\.


--
-- Data for Name: skill_effects_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill_effects_type (id, slug) FROM stdin;
1	damage
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

COPY public.skills (id, name, slug, scale_stat_id, school_id) FROM stdin;
1	Basic Attack	basic_attack	1	1
2	Power Slash	power_slash	1	1
3	Fireball	fireball	2	2
\.


--
-- Data for Name: spawn_zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spawn_zones (zone_id, zone_name, min_spawn_x, min_spawn_y, min_spawn_z, max_spawn_x, max_spawn_y, max_spawn_z, mob_id, spawn_count, respawn_time) FROM stdin;
1	Foxes Nest	-2900.00	4000.00	100.00	1000.00	1000.00	800.00	1	3	00:01:00
2	Wolf Place	-5900.00	5000.00	100.00	1000.00	1000.00	800.00	2	5	00:01:00
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
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, login, password, last_login, session_key) FROM stdin;
3	test1	test1	2023-05-04 16:25:31.727922+00	c14a1d8a-5494-4639-8008-6bc12d560ce7
5	test3	test3	2023-05-04 16:25:31.727922+00	f294043d-0080-437c-9dc5-8049a72b8674
4	test2	test2	2023-05-04 16:25:31.727922+00	9a5fa1a4-be1d-47c1-87f2-c1f661137fef
\.


--
-- Name: character_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_attributes_id_seq', 70, true);


--
-- Name: character_attributes_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_attributes_id_seq1', 20, true);


--
-- Name: character_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_class_id_seq', 2, true);


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
-- Name: dialogue_edge_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dialogue_edge_id_seq', 1, true);


--
-- Name: dialogue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dialogue_id_seq', 1, true);


--
-- Name: dialogue_node_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dialogue_node_id_seq', 2, true);


--
-- Name: exp_for_level_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exp_for_level_id_seq', 3, true);


--
-- Name: item_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_attributes_id_seq', 6, true);


--
-- Name: item_attributes_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_attributes_mapping_id_seq', 6, true);


--
-- Name: item_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_types_id_seq', 6, true);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.items_id_seq', 14, true);


--
-- Name: mob_attributes_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_attributes_mapping_id_seq', 44, true);


--
-- Name: mob_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_id_seq', 2, true);


--
-- Name: mob_loot_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_loot_info_id_seq', 9, true);


--
-- Name: mob_race_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_race_id_seq', 2, true);


--
-- Name: mob_skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_skills_id_seq', 2, true);


--
-- Name: npc_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_attributes_id_seq', 7, true);


--
-- Name: npc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_id_seq', 3, true);


--
-- Name: npc_skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_skills_id_seq', 2, true);


--
-- Name: npc_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_type_id_seq', 1, true);


--
-- Name: player_inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.player_inventory_id_seq', 1, false);


--
-- Name: quest_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quest_id_seq', 1, true);


--
-- Name: quest_step_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quest_step_id_seq', 2, true);


--
-- Name: race_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.race_id_seq', 2, true);


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

SELECT pg_catalog.setval('public.skill_effects_mapping_id_seq', 5, true);


--
-- Name: skill_effects_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_effects_type_id_seq', 2, true);


--
-- Name: skill_properties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_properties_id_seq', 6, true);


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

SELECT pg_catalog.setval('public.skills_attributes_mapping_id_seq', 13, true);


--
-- Name: skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skills_id_seq', 3, true);


--
-- Name: spawn_zones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.spawn_zones_id_seq', 2, true);


--
-- Name: target_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.target_type_id_seq', 6, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 5, true);


--
-- Name: character_attributes character_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_attributes
    ADD CONSTRAINT character_attributes_pkey PRIMARY KEY (id);


--
-- Name: entity_attributes character_attributes_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entity_attributes
    ADD CONSTRAINT character_attributes_pkey1 PRIMARY KEY (id);


--
-- Name: character_class character_class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_class
    ADD CONSTRAINT character_class_pkey PRIMARY KEY (id);


--
-- Name: character_position character_position_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_position
    ADD CONSTRAINT character_position_pkey PRIMARY KEY (id);


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
-- Name: item_attributes_mapping item_attributes_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_attributes_mapping
    ADD CONSTRAINT item_attributes_mapping_pkey PRIMARY KEY (id);


--
-- Name: item_attributes item_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_attributes
    ADD CONSTRAINT item_attributes_pkey PRIMARY KEY (id);


--
-- Name: item_types item_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_types
    ADD CONSTRAINT item_types_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: mob_attributes mob_attributes_map_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_attributes
    ADD CONSTRAINT mob_attributes_map_pkey PRIMARY KEY (id);


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

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_slug_key UNIQUE (slug);

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
-- Name: mob_skills mob_skills_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob_skills
    ADD CONSTRAINT mob_skills_pkey1 PRIMARY KEY (id);


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

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_slug_key UNIQUE (slug);

ALTER TABLE ONLY public.npc_position
    ADD CONSTRAINT npc_position_pkey PRIMARY KEY (id);


--
-- Name: npc_skills npc_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_skills
    ADD CONSTRAINT npc_skills_pkey PRIMARY KEY (id);


--
-- Name: npc_type npc_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_type
    ADD CONSTRAINT npc_type_pkey PRIMARY KEY (id);


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
-- Name: skill_effects skill_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects
    ADD CONSTRAINT skill_effects_pkey PRIMARY KEY (id);


--
-- Name: skill_effects skill_effects_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects
    ADD CONSTRAINT skill_effects_slug_key UNIQUE (slug);


--
-- Name: skill_effects_type skill_effects_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects_type
    ADD CONSTRAINT skill_effects_type_pkey PRIMARY KEY (id);


--
-- Name: skill_effects_type skill_effects_type_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects_type
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
-- Name: spawn_zones spawn_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spawn_zones
    ADD CONSTRAINT spawn_zones_pkey PRIMARY KEY (zone_id);


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
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


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
-- Name: ix_player_flag_bool; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_player_flag_bool ON public.player_flag USING btree (player_id, flag_key, bool_value);


--
-- Name: ix_player_flag_int; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_player_flag_int ON public.player_flag USING btree (player_id, flag_key, int_value);


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
-- Name: uq_character_skills; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_character_skills ON public.character_skills USING btree (character_id, skill_id);


--
-- Name: uq_effects_map; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_effects_map ON public.skill_effects_mapping USING btree (effect_instance_id, level, effect_id);


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

CREATE UNIQUE INDEX uq_skill_effects_slug ON public.skill_effects USING btree (slug);


--
-- Name: uq_skill_effects_type_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_skill_effects_type_slug ON public.skill_effects_type USING btree (slug);


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
-- Name: npc_dialogue npc_dialogue_dialogue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_dialogue
    ADD CONSTRAINT npc_dialogue_dialogue_id_fkey FOREIGN KEY (dialogue_id) REFERENCES public.dialogue(id) ON DELETE CASCADE;


--
-- Name: player_quest player_quest_quest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_quest
    ADD CONSTRAINT player_quest_quest_id_fkey FOREIGN KEY (quest_id) REFERENCES public.quest(id) ON DELETE CASCADE;


--
-- Name: quest_step quest_step_quest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_step
    ADD CONSTRAINT quest_step_quest_id_fkey FOREIGN KEY (quest_id) REFERENCES public.quest(id) ON DELETE CASCADE;


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
-- Name: skill_effects skill_effects_effect_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill_effects
    ADD CONSTRAINT skill_effects_effect_type_id_fkey FOREIGN KEY (effect_type_id) REFERENCES public.skill_effects_type(id);


--
-- Name: quest_reward quest_reward_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_reward
    ADD CONSTRAINT quest_reward_pkey PRIMARY KEY (id);

--
-- Name: quest_reward quest_reward_quest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_reward
    ADD CONSTRAINT quest_reward_quest_id_fkey FOREIGN KEY (quest_id) REFERENCES public.quest(id) ON DELETE CASCADE;

--
-- Name: quest_reward quest_reward_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quest_reward
    ADD CONSTRAINT quest_reward_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE SET NULL;

--
-- Name: player_active_effect; Type: TABLE; Schema: public; Owner: postgres
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
    CONSTRAINT player_active_effect_source_type_ck CHECK (source_type IN ('quest', 'dialogue', 'skill', 'item'))
);

ALTER TABLE public.player_active_effect OWNER TO postgres;

COMMENT ON TABLE public.player_active_effect IS 'Активные эффекты игрока с таймером (баффы/дебаффы от квестов, диалогов, скиллов, предметов)';
COMMENT ON COLUMN public.player_active_effect.source_type IS 'Источник эффекта: quest / dialogue / skill / item';
COMMENT ON COLUMN public.player_active_effect.source_id IS 'ID источника (quest_id, dialogue_node_id, skill_id, item_id)';
COMMENT ON COLUMN public.player_active_effect.value IS 'Величина эффекта (например, +50 к макс. HP)';
COMMENT ON COLUMN public.player_active_effect.expires_at IS 'Время истечения. NULL = бессрочный эффект';

CREATE SEQUENCE public.player_active_effect_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE public.player_active_effect_id_seq OWNER TO postgres;
ALTER SEQUENCE public.player_active_effect_id_seq OWNED BY public.player_active_effect.id;
ALTER TABLE ONLY public.player_active_effect ALTER COLUMN id SET DEFAULT nextval('public.player_active_effect_id_seq'::regclass);

--
-- Name: player_active_effect player_active_effect_pkey; Type: CONSTRAINT
--

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.characters(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.player_active_effect
    ADD CONSTRAINT player_active_effect_effect_id_fkey FOREIGN KEY (effect_id) REFERENCES public.skill_effects(id);

--
-- Indexes for performance
--

-- idx_* indexes below are non-duplicate additions (ix_* cover dialogue/quest/flag already)
CREATE INDEX idx_npc_dialogue_npc ON public.npc_dialogue (npc_id);
CREATE INDEX idx_quest_reward_quest ON public.quest_reward (quest_id);
CREATE INDEX idx_mob_loot_info_mob ON public.mob_loot_info (mob_id);
CREATE INDEX idx_player_inventory_character ON public.player_inventory (character_id);
CREATE INDEX idx_player_active_effect_player ON public.player_active_effect (player_id);
CREATE INDEX idx_player_active_effect_expires ON public.player_active_effect (expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_mob_position_mob ON public.mob_position (mob_id);
CREATE INDEX idx_npc_position_npc ON public.npc_position (npc_id);
CREATE INDEX idx_spawn_zones_mob ON public.spawn_zones (mob_id);

--
-- Missing foreign key constraints
--

-- characters -> users, character_class, race
ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.character_class(id);
ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_race_id_fkey FOREIGN KEY (race_id) REFERENCES public.race(id);

-- character_attributes (mapping) -> characters, entity_attributes
ALTER TABLE ONLY public.character_attributes
    ADD CONSTRAINT character_attributes_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.character_attributes
    ADD CONSTRAINT character_attributes_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);

-- character_position -> characters
ALTER TABLE ONLY public.character_position
    ADD CONSTRAINT character_position_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;

-- character_skills -> characters, skills
ALTER TABLE ONLY public.character_skills
    ADD CONSTRAINT character_skills_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.character_skills
    ADD CONSTRAINT character_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);

-- mob -> mob_race, mob_ranks
ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_race_id_fkey FOREIGN KEY (race_id) REFERENCES public.mob_race(id);
ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_rank_id_fkey FOREIGN KEY (rank_id) REFERENCES public.mob_ranks(rank_id);

-- mob_attributes -> mob, entity_attributes
ALTER TABLE ONLY public.mob_attributes
    ADD CONSTRAINT mob_attributes_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.mob_attributes
    ADD CONSTRAINT mob_attributes_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);

-- mob_loot_info -> mob, items
ALTER TABLE ONLY public.mob_loot_info
    ADD CONSTRAINT mob_loot_info_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.mob_loot_info
    ADD CONSTRAINT mob_loot_info_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;

-- mob_skills -> mob, skills
ALTER TABLE ONLY public.mob_skills
    ADD CONSTRAINT mob_skills_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.mob_skills
    ADD CONSTRAINT mob_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);

-- npc -> race, npc_type
ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_race_id_fkey FOREIGN KEY (race_id) REFERENCES public.race(id);
ALTER TABLE ONLY public.npc
    ADD CONSTRAINT npc_npc_type_fkey FOREIGN KEY (npc_type) REFERENCES public.npc_type(id);

-- npc_attributes -> npc, entity_attributes
ALTER TABLE ONLY public.npc_attributes
    ADD CONSTRAINT npc_attributes_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.npc_attributes
    ADD CONSTRAINT npc_attributes_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.entity_attributes(id);

-- npc_dialogue -> npc
ALTER TABLE ONLY public.npc_dialogue
    ADD CONSTRAINT npc_dialogue_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;

-- npc_skills -> npc, skills
ALTER TABLE ONLY public.npc_skills
    ADD CONSTRAINT npc_skills_npc_id_fkey FOREIGN KEY (npc_id) REFERENCES public.npc(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.npc_skills
    ADD CONSTRAINT npc_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id);

-- player_flag -> characters
ALTER TABLE ONLY public.player_flag
    ADD CONSTRAINT player_flag_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.characters(id) ON DELETE CASCADE;

-- player_inventory -> characters, items
ALTER TABLE ONLY public.player_inventory
    ADD CONSTRAINT player_inventory_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.player_inventory
    ADD CONSTRAINT player_inventory_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id);

-- player_quest -> characters
ALTER TABLE ONLY public.player_quest
    ADD CONSTRAINT player_quest_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.characters(id) ON DELETE CASCADE;

-- quest -> npc (giver, turnin)
ALTER TABLE ONLY public.quest
    ADD CONSTRAINT quest_giver_npc_id_fkey FOREIGN KEY (giver_npc_id) REFERENCES public.npc(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.quest
    ADD CONSTRAINT quest_turnin_npc_id_fkey FOREIGN KEY (turnin_npc_id) REFERENCES public.npc(id) ON DELETE SET NULL;

-- spawn_zones -> mob
ALTER TABLE ONLY public.spawn_zones
    ADD CONSTRAINT spawn_zones_mob_id_fkey FOREIGN KEY (mob_id) REFERENCES public.mob(id);

-- items -> item_types, items_rarity
ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_item_type_fkey FOREIGN KEY (item_type) REFERENCES public.item_types(id);
ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_rarity_id_fkey FOREIGN KEY (rarity_id) REFERENCES public.items_rarity(id);

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_equip_slot_fkey FOREIGN KEY (equip_slot) REFERENCES public.equip_slot(id) ON DELETE SET NULL;

-- item_attributes_mapping -> items, item_attributes
ALTER TABLE ONLY public.item_attributes_mapping
    ADD CONSTRAINT item_attributes_mapping_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.item_attributes_mapping
    ADD CONSTRAINT item_attributes_mapping_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.item_attributes(id);

-- skill_effects_mapping -> skill_effect_instances, skill_effects
ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_instance_id_fkey FOREIGN KEY (effect_instance_id) REFERENCES public.skill_effect_instances(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.skill_effects_mapping
    ADD CONSTRAINT skill_effects_mapping_effect_id_fkey FOREIGN KEY (effect_id) REFERENCES public.skill_effects(id);

-- skill_properties_mapping -> skills, skill_properties
ALTER TABLE ONLY public.skill_properties_mapping
    ADD CONSTRAINT skill_properties_mapping_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.skill_properties_mapping
    ADD CONSTRAINT skill_properties_mapping_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.skill_properties(id);

-- dialogue_node -> npc (speaker), self (jump_target)
ALTER TABLE ONLY public.dialogue_node
    ADD CONSTRAINT dialogue_node_speaker_npc_id_fkey FOREIGN KEY (speaker_npc_id) REFERENCES public.npc(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.dialogue_node
    ADD CONSTRAINT dialogue_node_jump_target_fkey FOREIGN KEY (jump_target_node_id) REFERENCES public.dialogue_node(id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

--
-- PostgreSQL database dump complete
--

