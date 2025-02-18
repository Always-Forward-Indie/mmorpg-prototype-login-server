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
    experience_points bigint DEFAULT 0 NOT NULL,
    level integer DEFAULT 0 NOT NULL,
    current_health integer DEFAULT 1 NOT NULL,
    current_mana integer DEFAULT 1 NOT NULL
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
    race_id integer DEFAULT 1 NOT NULL,
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
    level integer NOT NULL,
    experience_points integer NOT NULL,
    current_health integer NOT NULL,
    current_mana integer NOT NULL
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
-- Data for Name: character_position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.character_position (id, character_id, x, y, z) FROM stdin;
1	1	50.00	0.00	300.00
2	2	250.00	0.00	300.00
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


--
-- PostgreSQL database dump complete
--

