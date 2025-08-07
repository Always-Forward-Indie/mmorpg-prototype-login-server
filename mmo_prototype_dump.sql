--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5 (Ubuntu 15.5-1.pgdg22.04+1)
-- Dumped by pg_dump version 16.1 (Ubuntu 16.1-1.pgdg22.04+1)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: character_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_attributes (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL
);


ALTER TABLE public.character_attributes OWNER TO postgres;

--
-- Name: character_attributes_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_attributes_mapping (
    id bigint NOT NULL,
    character_id integer DEFAULT 0 NOT NULL,
    attribute_id integer DEFAULT 0 NOT NULL,
    value integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.character_attributes_mapping OWNER TO postgres;

--
-- Name: character_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.character_attributes_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.character_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: character_attributes_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.character_attributes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
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
-- Name: character_skill_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_skill_properties (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    color character varying(20) NOT NULL
);


ALTER TABLE public.character_skill_properties OWNER TO postgres;

--
-- Name: character_skill_properties_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_skill_properties_mapping (
    id integer NOT NULL,
    skill_id integer NOT NULL,
    skill_level integer NOT NULL,
    property_id integer NOT NULL,
    property_value integer NOT NULL
);


ALTER TABLE public.character_skill_properties_mapping OWNER TO postgres;

--
-- Name: character_skills; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_skills (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    level integer NOT NULL
);


ALTER TABLE public.character_skills OWNER TO postgres;

--
-- Name: character_skills_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.character_skills_mapping (
    id integer NOT NULL,
    skill_id integer NOT NULL,
    character_id integer NOT NULL
);


ALTER TABLE public.character_skills_mapping OWNER TO postgres;

--
-- Name: character_skills_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.character_skills_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.character_skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: characters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.characters (
    id bigint NOT NULL,
    name character varying(20) NOT NULL,
    owner_id bigint NOT NULL,
    class_id integer DEFAULT 1 NOT NULL,
    race_id integer DEFAULT 1 NOT NULL,
    radius integer DEFAULT 100 NOT NULL,
    experience_points bigint DEFAULT 0 NOT NULL,
    level integer DEFAULT 0 NOT NULL,
    current_health integer DEFAULT 1 NOT NULL,
    current_mana integer DEFAULT 1 NOT NULL,
    is_dead boolean DEFAULT false NOT NULL
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
-- Name: mob; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL,
    race_id integer DEFAULT 1 NOT NULL,
    radius integer DEFAULT 100 NOT NULL,
    current_health integer DEFAULT 1 NOT NULL,
    current_mana integer DEFAULT 1 NOT NULL,
    is_aggressive boolean DEFAULT false NOT NULL,
    is_dead boolean DEFAULT false NOT NULL,
    level integer NOT NULL
);


ALTER TABLE public.mob OWNER TO postgres;

--
-- Name: mob_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_attributes (
    id integer,
    name character varying(100),
    slug character varying(100)
);


ALTER TABLE public.mob_attributes OWNER TO postgres;

--
-- Name: mob_attributes_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_attributes_mapping (
    id bigint,
    mob_id bigint,
    attribute_id integer,
    value integer
);


ALTER TABLE public.mob_attributes_mapping OWNER TO postgres;

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
-- Name: mob_position; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_position (
    id bigint,
    mob_id bigint,
    x numeric(11,2),
    y numeric(11,2),
    z numeric(11,2)
);


ALTER TABLE public.mob_position OWNER TO postgres;

--
-- Name: mob_skill_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_skill_properties (
    id integer,
    name character varying(50),
    color character varying(20)
);


ALTER TABLE public.mob_skill_properties OWNER TO postgres;

--
-- Name: mob_skill_properties_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_skill_properties_mapping (
    id integer,
    skill_id integer,
    skill_level integer,
    property_id integer,
    property_value integer
);


ALTER TABLE public.mob_skill_properties_mapping OWNER TO postgres;

--
-- Name: mob_skills; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_skills (
    id integer,
    name character varying(50),
    level integer
);


ALTER TABLE public.mob_skills OWNER TO postgres;

--
-- Name: mob_skills_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mob_skills_mapping (
    id integer,
    skill_id integer,
    mob_id integer
);


ALTER TABLE public.mob_skills_mapping OWNER TO postgres;

--
-- Name: npc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    race_id integer DEFAULT 1 NOT NULL,
    radius integer DEFAULT 100 NOT NULL,
    level integer NOT NULL,
    experience_points integer NOT NULL,
    current_health integer NOT NULL,
    current_mana integer NOT NULL,
    is_dead boolean DEFAULT false NOT NULL
);


ALTER TABLE public.npc OWNER TO postgres;

--
-- Name: none_player_characters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.npc ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.none_player_characters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: npc_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_attributes (
    id integer,
    name character varying(100),
    slug character varying(100)
);


ALTER TABLE public.npc_attributes OWNER TO postgres;

--
-- Name: npc_attributes_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_attributes_mapping (
    id bigint NOT NULL,
    npc_id bigint NOT NULL,
    attribute_id integer NOT NULL,
    value integer NOT NULL
);


ALTER TABLE public.npc_attributes_mapping OWNER TO postgres;

--
-- Name: npc_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.npc_attributes_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.npc_attributes_id_seq
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
    id bigint,
    npc_id bigint,
    x numeric(11,2),
    y numeric(11,2),
    z numeric(11,2)
);


ALTER TABLE public.npc_position OWNER TO postgres;

--
-- Name: npc_skill_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_skill_properties (
    id integer,
    name character varying(50),
    color character varying(20)
);


ALTER TABLE public.npc_skill_properties OWNER TO postgres;

--
-- Name: npc_skill_properties_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_skill_properties_mapping (
    id integer,
    skill_id integer,
    skill_level integer,
    property_id integer,
    property_value integer
);


ALTER TABLE public.npc_skill_properties_mapping OWNER TO postgres;

--
-- Name: npc_skills; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_skills (
    id integer,
    name character varying(50),
    level integer
);


ALTER TABLE public.npc_skills OWNER TO postgres;

--
-- Name: npc_skills_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.npc_skills_mapping (
    id integer,
    skill_id integer,
    npc_id integer
);


ALTER TABLE public.npc_skills_mapping OWNER TO postgres;

--
-- Name: race; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.race (
    id integer NOT NULL,
    name character varying(50) NOT NULL
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
-- Name: spawn_zones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.spawn_zones (
    zone_id integer NOT NULL,
    zone_name character varying(50) NOT null,
    min_spawn_x numeric(11, 2) NOT null,
    min_spawn_y numeric(11, 2) NOT null,
    min_spawn_z numeric(11, 2) NOT null,
    max_spawn_x numeric(11, 2) NOT null,
    max_spawn_y numeric(11, 2) NOT null,
    max_spawn_z numeric(11, 2) NOT null,
    mob_id integer NOT null,
    spawn_count integer NOT null
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
-- Name: skill_properties_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.character_skill_properties ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.skill_properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


--
-- Name: skills_attributes_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.character_skill_properties_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
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

ALTER TABLE public.character_skills ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


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

-- Name: items; Type: TABLE; Schema: public; Owner: postgres
CREATE TABLE public.items (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL,
    description text,
    is_quest_item boolean DEFAULT false NOT NULL,
    item_type bigint NOT NULL
);

ALTER TABLE public.items OWNER TO postgres;

-- Name: item_types; Type: TABLE; Schema: public; Owner: postgres
CREATE TABLE public.item_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL
);

ALTER TABLE public.item_types OWNER TO postgres;

-- Name: item_types_mapping; Type: TABLE; Schema: public; Owner: postgres
CREATE TABLE public.item_types_mapping (
    id bigint NOT NULL,
    item_id bigint NOT NULL,
    type_id integer NOT NULL
);

ALTER TABLE public.item_types_mapping OWNER TO postgres;

-- Name: item_attributes; Type: TABLE; Schema: public; Owner: postgres
CREATE TABLE public.item_attributes (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL
);

ALTER TABLE public.item_attributes OWNER TO postgres;

-- Name: item_attributes_mapping; Type: TABLE; Schema: public; Owner: postgres
CREATE TABLE public.item_attributes_mapping (
    id bigint NOT NULL,
    item_id bigint NOT NULL,
    attribute_id integer NOT NULL,
    value integer NOT NULL
);

-- Name: player_inventory; Type: TABLE; Schema: public; Owner: postgres
CREATE TABLE public.player_inventory (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    item_id bigint NOT NULL,
    quantity integer DEFAULT 1 NOT NULL
);

ALTER TABLE public.player_inventory OWNER TO postgres;

-- Name: mob_loot_info; Type: TABLE; Schema: public; Owner: postgres
CREATE TABLE public.mob_loot_info (
    id bigint NOT NULL,
    mob_id integer NOT NULL,
    item_id bigint NOT NULL,
    drop_chance numeric(5,2) DEFAULT 0.00 NOT NULL
);

ALTER TABLE public.mob_loot_info OWNER TO postgres;


--
-- Data for Name: character_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_attributes (id, name, slug) FROM stdin;
1	Maximum Health	max_health
2	Maximum Mana	max_mana
3	Strength	strength
4	Intelligence	intelligence
5	Luck	luck
\.


--
-- Data for Name: character_attributes_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_attributes_mapping (id, character_id, attribute_id, value) FROM stdin;
4	1	1	100
5	1	2	200
6	1	3	5
7	1	4	15
8	1	5	3
9	3	5	3
10	3	4	5
11	3	3	15
12	3	2	100
13	3	1	200
\.


--
-- Data for Name: character_class; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_class (id, name) FROM stdin;
1	Mage
2	Warrior
\.

--
-- Data for Name: character_skill_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_skill_properties (id, name, color) FROM stdin;
\.


--
-- Data for Name: character_skill_properties_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_skill_properties_mapping (id, skill_id, skill_level, property_id, property_value) FROM stdin;
\.


--
-- Data for Name: character_skills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_skills (id, name, level) FROM stdin;
\.


--
-- Data for Name: character_skills_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_skills_mapping (id, skill_id, character_id) FROM stdin;
\.


--
-- Data for Name: characters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.characters (id, name, owner_id, class_id, race_id, experience_points, level, current_health, current_mana) FROM stdin;
3	TetsWarrior1Player	3	2	1	0	0	1	1
1	TetsMage1Player	3	1	1	57	1	29	18
2	TetsMage2Player	4	1	1	0	0	10	5
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
-- Data for Name: mob; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob (id, name, race_id, level) FROM stdin;
\.


--
-- Data for Name: mob_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_attributes (id, name, slug) FROM stdin;
\.


--
-- Data for Name: mob_attributes_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_attributes_mapping (id, mob_id, attribute_id, value) FROM stdin;
\.


--
-- Data for Name: mob_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_position (id, mob_id, x, y, z) FROM stdin;
\.


--
-- Data for Name: mob_skill_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_skill_properties (id, name, color) FROM stdin;
\.


--
-- Data for Name: mob_skill_properties_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_skill_properties_mapping (id, skill_id, skill_level, property_id, property_value) FROM stdin;
\.


--
-- Data for Name: mob_skills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_skills (id, name, level) FROM stdin;
\.


--
-- Data for Name: mob_skills_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mob_skills_mapping (id, skill_id, mob_id) FROM stdin;
\.


--
-- Data for Name: npc; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc (id, name, race_id, level, experience_points, current_health, current_mana) FROM stdin;
\.


--
-- Data for Name: npc_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_attributes (id, name, slug) FROM stdin;
\.


--
-- Data for Name: npc_attributes_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_attributes_mapping (id, npc_id, attribute_id, value) FROM stdin;
\.


--
-- Data for Name: npc_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_position (id, npc_id, x, y, z) FROM stdin;
\.


--
-- Data for Name: npc_skill_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_skill_properties (id, name, color) FROM stdin;
\.


--
-- Data for Name: npc_skill_properties_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_skill_properties_mapping (id, skill_id, skill_level, property_id, property_value) FROM stdin;
\.


--
-- Data for Name: npc_skills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_skills (id, name, level) FROM stdin;
\.


--
-- Data for Name: npc_skills_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.npc_skills_mapping (id, skill_id, npc_id) FROM stdin;
\.


--
-- Data for Name: race; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.race (id, name) FROM stdin;
1	Human
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, login, password, last_login, session_key) FROM stdin;
5	test3	test3	2023-05-04 19:25:31.727922+03	3
4	test2	test2	2023-05-04 19:25:31.727922+03	f8f7214a-a794-47fa-9ba3-3d9a8ad6f1b0
3	test1	test1	2023-05-04 19:25:31.727922+03	a0d2cd8e-7fc9-4f67-94a9-4ded050b5ef5
\.


--
-- Name: character_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_attributes_id_seq', 13, true);


--
-- Name: character_attributes_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_attributes_id_seq1', 5, true);


--
-- Name: character_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_class_id_seq', 2, true);


--
-- Name: character_position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_position_id_seq', 2, true);


--
-- Name: character_skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.character_skills_id_seq', 1, false);


--
-- Name: characters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.characters_id_seq', 3, true);


--
-- Name: exp_for_level_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exp_for_level_id_seq', 3, true);


--
-- Name: mob_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mob_id_seq', 1, false);


--
-- Name: none_player_characters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.none_player_characters_id_seq', 1, false);


--
-- Name: npc_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.npc_attributes_id_seq', 1, false);


--
-- Name: race_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.race_id_seq', 1, true);


--
-- Name: skill_properties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_properties_id_seq', 1, false);


--
-- Name: skills_attributes_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skills_attributes_mapping_id_seq', 1, false);


--
-- Name: skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skills_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 5, true);


--
-- Name: character_attributes_mapping character_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_attributes_mapping
    ADD CONSTRAINT character_attributes_pkey PRIMARY KEY (id);


--
-- Name: character_attributes character_attributes_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_attributes
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
-- Name: character_skills_mapping character_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skills_mapping
    ADD CONSTRAINT character_skills_pkey PRIMARY KEY (id);


--
-- Name: characters characters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_pkey PRIMARY KEY (id);


--
-- Name: mob mob_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mob
    ADD CONSTRAINT mob_pkey PRIMARY KEY (id);


--
-- Name: npc none_player_characters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc
    ADD CONSTRAINT none_player_characters_pkey PRIMARY KEY (id);


--
-- Name: npc_attributes_mapping npc_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.npc_attributes_mapping
    ADD CONSTRAINT npc_attributes_pkey PRIMARY KEY (id);


--
-- Name: race race_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.race
    ADD CONSTRAINT race_pkey PRIMARY KEY (id);


--
-- Name: character_skill_properties skill_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skill_properties
    ADD CONSTRAINT skill_properties_pkey PRIMARY KEY (id);


--
-- Name: character_skill_properties_mapping skills_attributes_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skill_properties_mapping
    ADD CONSTRAINT skills_attributes_mapping_pkey PRIMARY KEY (id);


--
-- Name: character_skills skills_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.character_skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


-- Name: mob_attributes_mapping mob_attributes_map_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres

ALTER TABLE ONLY public.mob_attributes_mapping
    ADD CONSTRAINT mob_attributes_map_pkey PRIMARY KEY (id);

-- Name: mob_attributes mob_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.mob_attributes
    ADD CONSTRAINT mob_attributes_pkey PRIMARY KEY (id);

-- Name: mob_position mob_position_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.mob_position
    ADD CONSTRAINT mob_position_pkey PRIMARY KEY (id);

-- Name: mob_skill_properties mob_skill_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.mob_skill_properties
    ADD CONSTRAINT mob_skill_properties_pkey PRIMARY KEY (id);

-- Name: mob_skill_properties_mapping mob_skill_properties_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.mob_skill_properties_mapping
    ADD CONSTRAINT mob_skill_properties_mapping_pkey PRIMARY KEY (id);

-- Name: mob_skills mob_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.mob_skills
    ADD CONSTRAINT mob_skills_pkey PRIMARY KEY (id);

-- Name: mob_skills_mapping mob_skills_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.mob_skills_mapping
    ADD CONSTRAINT mob_skills_mapping_pkey PRIMARY KEY (id);

-- Name: npc_position npc_position_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.npc_position
    ADD CONSTRAINT npc_position_pkey PRIMARY KEY (id);

-- Name: npc_skill_properties npc_skill_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.npc_skill_properties
    ADD CONSTRAINT npc_skill_properties_pkey PRIMARY KEY (id);  

-- Name: npc_skill_properties_mapping npc_skill_properties_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.npc_skill_properties_mapping
    ADD CONSTRAINT npc_skill_properties_mapping_pkey PRIMARY KEY (id);

-- Name: npc_skills npc_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.npc_skills
    ADD CONSTRAINT npc_skills_pkey PRIMARY KEY (id);

-- Name: npc_skills_mapping npc_skills_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.npc_skills_mapping
    ADD CONSTRAINT npc_skills_mapping_pkey PRIMARY KEY (id);    

-- Name: item_types item_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.item_types
    ADD CONSTRAINT item_types_pkey PRIMARY KEY (id);

-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);

-- Name: player_inventory player_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.player_inventory
    ADD CONSTRAINT player_inventory_pkey PRIMARY KEY (id);

-- Name: mob_loot_info mob_loot_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
ALTER TABLE ONLY public.mob_loot_info
    ADD CONSTRAINT mob_loot_info_pkey PRIMARY KEY (id);


ALTER TABLE ONLY public.item_attributes
    ADD CONSTRAINT item_attributes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.item_attributes_mapping
    ADD CONSTRAINT item_attributes_mapping_pkey PRIMARY KEY (id);
    

ALTER TABLE public.mob_attributes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


ALTER TABLE public.mob_attributes_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_attributes_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);


ALTER TABLE public.mob_position ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_position_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.mob_skill_properties ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_skill_properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.mob_skill_properties_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_skill_properties_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.mob_skills ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.mob_skills_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_skills_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.npc_position ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.npc_position_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.npc_skill_properties ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.npc_skill_properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.npc_skill_properties_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.npc_skill_properties_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.npc_skills ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.npc_skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.npc_skills_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.npc_skills_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.item_types ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.item_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.player_inventory ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.player_inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.mob_loot_info ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.mob_loot_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.item_attributes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.item_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

ALTER TABLE public.item_attributes_mapping ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.item_attributes_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
);

-- Insert initial data into character_position
INSERT INTO public.character_position (character_id,x,y,z) VALUES
	 (2,-1800.00,3500.00,300.00),
	 (1,-2000.00,4000.00,300.00),
	 (3,-2500.00,4500.00,300.00);


-- Insert initial data into spawn_zones
INSERT INTO public.spawn_zones (zone_name,min_spawn_x,min_spawn_y,min_spawn_z,max_spawn_x,max_spawn_y,max_spawn_z,mob_id,spawn_count,respawn_time) VALUES
	 ('Foxes Nest',-2900.00,4000.00,100.00,1000.00,1000.00,800.00,1,3,'00:01:00'),
     ('Wolves Den',-2000.00,3000.00,100.00,500.00,500.00,800.00,2,5,'00:02:00');


-- Insert initial data into mob race
INSERT INTO public.mob_race ("name") VALUES
	 ('Animal');


-- Insert initial data into mob
INSERT INTO public.mob ("name",slug,race_id,"level",current_health,current_mana,is_aggressive,is_dead,radius) VALUES
	 ('Small Fox','SmallFox'1,1,100,50,false,false,100),
     ('Grey Wolf','GreyWolf',1,150,50,false,false,100);


-- Insert initial data into mob_attributes
INSERT INTO public.mob_attributes ("name",slug) VALUES
	 ('Maximum Health','max_health'),
	 ('Maximum Mana','max_mana');

-- Insert initial data into mob_attributes_mapping
INSERT INTO public.mob_attributes_mapping (mob_id,attribute_id,value) VALUES
	 (1,1,100),
	 (1,2,50),
     (2,1,150),
     (2,2,50);


-- Insert initial data into item_types
INSERT INTO public.item_types ("name",slug) VALUES
     ('Weapon','weapon'),
     ('Armor','armor'),
     ('Potion','potion'),
     ('Food','food'),
     ('Quest Item','quest_item'),
    ('Resource','resource');

-- Insert initial data into items
INSERT INTO public.items (name,slug,description,is_qest_item,item_type) VALUES
     ('Iron Sword','iron_sworld','A sturdy iron sword.',false,1),
     ('Wooden Shield','wooden_shield','A basic wooden shield.',false,2),
     ('Health Potion','health_potion','Restores 50 health points.',false,3),
     ('Bread','bread','A loaf of bread to restore hunger.',false,4),
     ('Ancient Artifact','ancient_artifact','A mysterious artifact for quests.',true,5),
     ('Iron Ore','iron_ore','A piece of iron ore, useful for crafting.',false,6);

-- Insert initial data into item_attributes
INSERT INTO public.item_attributes (name,slug) VALUES
     ('Damage','damage'),
     ('Defense','defense'),
     ('Healing','healing'),
     ('Hunger Restoration','hunger_restoration'),
     ('Quest Value','quest_value'),
     ('Resource Value','resource_value');

-- Insert initial data into item_attributes_mapping
INSERT INTO public.item_attributes_mapping (item_id,attribute_id,value) VALUES
     (1,1,10),  -- Iron Sword with 10 damage
     (2,2,5),   -- Wooden Shield with 5 defense
     (3,3,50),  -- Health Potion with 50 healing
     (4,4,30),  -- Bread with 30 hunger restoration
     (5,5,1),   -- Ancient Artifact with quest value 1
     (6,6,100); -- Iron Ore with resource value 100

-- Insert initial data into moob_loot_info
INSERT INTO public.mob_loot_info (mob_id,item_id,drop_chance) VALUES
        (1,1,0.20),  -- Small Fox drops Iron Sword with 20% chance
        (1,3,0.10),  -- Small Fox drops Health Potion with 10% chance
        (2,2,0.15),  -- Grey Wolf drops Wooden Shield with 15% chance
        (2,4,0.05),  -- Grey Wolf drops Bread with 5% chance
        (2,6,0.25);  -- Grey Wolf drops Iron Ore with 25% chance

-- Insert initial data into skills
INSERT INTO public.character_skills (name,level) VALUES
        ('Fireball',1),
        ('Frostbolt',1),
        ('Heal',1),
        ('Shield Bash',1);