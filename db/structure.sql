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
-- Name: agent_relation_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_relation_types (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    uri character varying NOT NULL
);


--
-- Name: agent_relation_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_relation_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_relation_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_relation_types_id_seq OWNED BY public.agent_relation_types.id;


--
-- Name: agent_relations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_relations (
    id integer NOT NULL,
    agent_id integer NOT NULL,
    related_agent_id integer NOT NULL,
    dates character varying,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    agent_relation_type_id integer NOT NULL
);


--
-- Name: agent_relations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_relations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_relations_id_seq OWNED BY public.agent_relations.id;


--
-- Name: agent_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_rules (
    id integer NOT NULL,
    name character varying NOT NULL,
    abbreviation character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: agent_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_rules_id_seq OWNED BY public.agent_rules.id;


--
-- Name: agent_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_types (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: agent_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_types_id_seq OWNED BY public.agent_types.id;


--
-- Name: agent_uris; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_uris (
    id integer NOT NULL,
    uri character varying NOT NULL,
    agent_id integer,
    "primary" boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: agent_uris_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_uris_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_uris_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_uris_id_seq OWNED BY public.agent_uris.id;


--
-- Name: agents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agents (
    id integer NOT NULL,
    name character varying NOT NULL,
    begin_date timestamp without time zone,
    end_date timestamp without time zone,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    agent_rule_id integer,
    agent_type_id integer
);


--
-- Name: agents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agents_id_seq OWNED BY public.agents.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: binaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.binaries (
    id integer NOT NULL,
    master_type integer,
    media_type character varying DEFAULT 'unknown/unknown'::character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    item_id integer,
    object_key character varying,
    medusa_uuid character varying,
    byte_size numeric(15,0) NOT NULL,
    width numeric(6,0),
    height numeric(6,0),
    media_category integer,
    duration integer,
    public boolean DEFAULT true NOT NULL,
    metadata_json text,
    full_text text,
    hocr text,
    tesseract_json text,
    ocred_at timestamp without time zone
);


--
-- Name: binaries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.binaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: binaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.binaries_id_seq OWNED BY public.binaries.id;


--
-- Name: collection_joins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_joins (
    id integer NOT NULL,
    parent_repository_id character varying NOT NULL,
    child_repository_id character varying NOT NULL
);


--
-- Name: collection_joins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collection_joins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collection_joins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collection_joins_id_seq OWNED BY public.collection_joins.id;


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collections (
    id integer NOT NULL,
    repository_id character varying NOT NULL,
    description_html character varying,
    access_url character varying,
    public_in_medusa boolean,
    published_in_dls boolean DEFAULT false,
    representative_medusa_file_id character varying,
    representative_item_id character varying,
    metadata_profile_id integer,
    medusa_file_group_uuid character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    resource_types text,
    medusa_directory_uuid character varying,
    package_profile_id integer,
    access_systems text,
    medusa_repository_id integer,
    rights_statement text,
    rights_term_uri character varying,
    contentdm_alias character varying,
    physical_collection_url character varying,
    harvestable boolean DEFAULT false NOT NULL,
    external_id character varying,
    descriptive_element_id integer,
    harvestable_by_idhh boolean DEFAULT false NOT NULL,
    harvestable_by_primo boolean DEFAULT false NOT NULL,
    restricted boolean DEFAULT false NOT NULL,
    publicize_binaries boolean DEFAULT true NOT NULL,
    representative_image character varying,
    representation_type character varying DEFAULT 'self'::character varying NOT NULL,
    rightsstatements_org_uri character varying
);


--
-- Name: collections_host_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collections_host_groups (
    id bigint NOT NULL,
    collection_id integer,
    allowed_host_group_id integer,
    denied_host_group_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: collections_host_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collections_host_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collections_host_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collections_host_groups_id_seq OWNED BY public.collections_host_groups.id;


--
-- Name: collections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collections_id_seq OWNED BY public.collections.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: downloads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.downloads (
    id integer NOT NULL,
    key character varying NOT NULL,
    filename character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    url character varying,
    task_id integer,
    expired boolean DEFAULT false,
    ip_address character varying,
    object_key character varying
);


--
-- Name: downloads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.downloads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: downloads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.downloads_id_seq OWNED BY public.downloads.id;


--
-- Name: elements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.elements (
    id integer NOT NULL,
    name character varying,
    description character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: elements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.elements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: elements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.elements_id_seq OWNED BY public.elements.id;


--
-- Name: entity_elements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entity_elements (
    id integer NOT NULL,
    name character varying,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    item_id integer,
    vocabulary_id integer,
    uri character varying,
    type character varying,
    collection_id integer
);


--
-- Name: entity_elements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.entity_elements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entity_elements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.entity_elements_id_seq OWNED BY public.entity_elements.id;


--
-- Name: host_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.host_groups (
    id bigint NOT NULL,
    key character varying NOT NULL,
    name character varying NOT NULL,
    pattern text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: host_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.host_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: host_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.host_groups_id_seq OWNED BY public.host_groups.id;


--
-- Name: host_groups_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.host_groups_items (
    id bigint NOT NULL,
    item_id integer,
    allowed_host_group_id integer,
    denied_host_group_id integer,
    effective_allowed_host_group_id integer,
    effective_denied_host_group_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: host_groups_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.host_groups_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: host_groups_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.host_groups_items_id_seq OWNED BY public.host_groups_items.id;


--
-- Name: item_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_sets (
    id integer NOT NULL,
    name character varying NOT NULL,
    collection_repository_id character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: item_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_sets_id_seq
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
-- Name: item_sets_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_sets_items (
    id integer NOT NULL,
    item_set_id integer,
    item_id integer
);


--
-- Name: item_sets_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_sets_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_sets_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_sets_items_id_seq OWNED BY public.item_sets_items.id;


--
-- Name: item_sets_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_sets_users (
    id integer NOT NULL,
    item_set_id integer,
    user_id integer
);


--
-- Name: item_sets_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_sets_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_sets_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_sets_users_id_seq OWNED BY public.item_sets_users.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id integer NOT NULL,
    repository_id character varying NOT NULL,
    collection_repository_id character varying,
    parent_repository_id character varying,
    representative_item_id character varying,
    variant character varying,
    page_number integer,
    subpage_number integer,
    start_date timestamp without time zone,
    published boolean DEFAULT true,
    latitude numeric(10,7),
    longitude numeric(10,7),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    contentdm_pointer integer,
    contentdm_alias character varying,
    embed_tag character varying,
    representative_medusa_file_id character varying,
    end_date timestamp without time zone,
    allowed_netids text,
    published_at timestamp without time zone,
    expose_full_text_search boolean DEFAULT true NOT NULL,
    representative_image character varying,
    representation_type character varying DEFAULT 'self'::character varying NOT NULL
);


--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: metadata_profile_elements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metadata_profile_elements (
    id integer NOT NULL,
    metadata_profile_id integer,
    name character varying,
    label character varying,
    index integer,
    searchable boolean DEFAULT true,
    facetable boolean DEFAULT true,
    visible boolean DEFAULT true,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sortable boolean DEFAULT true,
    dc_map character varying,
    dcterms_map character varying,
    data_type integer DEFAULT 0 NOT NULL,
    indexed boolean DEFAULT true
);


--
-- Name: metadata_profile_elements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.metadata_profile_elements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: metadata_profile_elements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.metadata_profile_elements_id_seq OWNED BY public.metadata_profile_elements.id;


--
-- Name: metadata_profile_elements_vocabularies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metadata_profile_elements_vocabularies (
    metadata_profile_element_id integer NOT NULL,
    vocabulary_id integer NOT NULL
);


--
-- Name: metadata_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metadata_profiles (
    id integer NOT NULL,
    name character varying,
    "default" boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    default_sortable_element_id integer
);


--
-- Name: metadata_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.metadata_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: metadata_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.metadata_profiles_id_seq OWNED BY public.metadata_profiles.id;


--
-- Name: options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.options (
    id integer NOT NULL,
    key character varying,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.options_id_seq OWNED BY public.options.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id integer NOT NULL,
    name character varying,
    status numeric,
    status_text character varying,
    job_id character varying,
    percent_complete double precision DEFAULT 0.0,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    indeterminate boolean DEFAULT false,
    detail text,
    backtrace text,
    started_at timestamp without time zone,
    queue character varying
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    api_key character varying,
    human boolean DEFAULT true NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vocabularies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vocabularies (
    id integer NOT NULL,
    key character varying,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: vocabularies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vocabularies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vocabularies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vocabularies_id_seq OWNED BY public.vocabularies.id;


--
-- Name: vocabulary_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vocabulary_terms (
    id integer NOT NULL,
    string character varying,
    uri character varying,
    vocabulary_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: vocabulary_terms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vocabulary_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vocabulary_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vocabulary_terms_id_seq OWNED BY public.vocabulary_terms.id;


--
-- Name: watches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.watches (
    id bigint NOT NULL,
    user_id bigint,
    collection_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    email character varying
);


--
-- Name: watches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.watches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: watches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.watches_id_seq OWNED BY public.watches.id;


--
-- Name: agent_relation_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_relation_types ALTER COLUMN id SET DEFAULT nextval('public.agent_relation_types_id_seq'::regclass);


--
-- Name: agent_relations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_relations ALTER COLUMN id SET DEFAULT nextval('public.agent_relations_id_seq'::regclass);


--
-- Name: agent_rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_rules ALTER COLUMN id SET DEFAULT nextval('public.agent_rules_id_seq'::regclass);


--
-- Name: agent_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_types ALTER COLUMN id SET DEFAULT nextval('public.agent_types_id_seq'::regclass);


--
-- Name: agent_uris id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_uris ALTER COLUMN id SET DEFAULT nextval('public.agent_uris_id_seq'::regclass);


--
-- Name: agents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents ALTER COLUMN id SET DEFAULT nextval('public.agents_id_seq'::regclass);


--
-- Name: binaries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.binaries ALTER COLUMN id SET DEFAULT nextval('public.binaries_id_seq'::regclass);


--
-- Name: collection_joins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_joins ALTER COLUMN id SET DEFAULT nextval('public.collection_joins_id_seq'::regclass);


--
-- Name: collections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections ALTER COLUMN id SET DEFAULT nextval('public.collections_id_seq'::regclass);


--
-- Name: collections_host_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections_host_groups ALTER COLUMN id SET DEFAULT nextval('public.collections_host_groups_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: downloads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.downloads ALTER COLUMN id SET DEFAULT nextval('public.downloads_id_seq'::regclass);


--
-- Name: elements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.elements ALTER COLUMN id SET DEFAULT nextval('public.elements_id_seq'::regclass);


--
-- Name: entity_elements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_elements ALTER COLUMN id SET DEFAULT nextval('public.entity_elements_id_seq'::regclass);


--
-- Name: host_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.host_groups ALTER COLUMN id SET DEFAULT nextval('public.host_groups_id_seq'::regclass);


--
-- Name: host_groups_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.host_groups_items ALTER COLUMN id SET DEFAULT nextval('public.host_groups_items_id_seq'::regclass);


--
-- Name: item_sets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets ALTER COLUMN id SET DEFAULT nextval('public.item_sets_id_seq'::regclass);


--
-- Name: item_sets_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets_items ALTER COLUMN id SET DEFAULT nextval('public.item_sets_items_id_seq'::regclass);


--
-- Name: item_sets_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets_users ALTER COLUMN id SET DEFAULT nextval('public.item_sets_users_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: metadata_profile_elements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_profile_elements ALTER COLUMN id SET DEFAULT nextval('public.metadata_profile_elements_id_seq'::regclass);


--
-- Name: metadata_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_profiles ALTER COLUMN id SET DEFAULT nextval('public.metadata_profiles_id_seq'::regclass);


--
-- Name: options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options ALTER COLUMN id SET DEFAULT nextval('public.options_id_seq'::regclass);


--
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: vocabularies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabularies ALTER COLUMN id SET DEFAULT nextval('public.vocabularies_id_seq'::regclass);


--
-- Name: vocabulary_terms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_terms ALTER COLUMN id SET DEFAULT nextval('public.vocabulary_terms_id_seq'::regclass);


--
-- Name: watches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watches ALTER COLUMN id SET DEFAULT nextval('public.watches_id_seq'::regclass);


--
-- Name: agent_relation_types agent_relation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_relation_types
    ADD CONSTRAINT agent_relation_types_pkey PRIMARY KEY (id);


--
-- Name: agent_relations agent_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_relations
    ADD CONSTRAINT agent_relations_pkey PRIMARY KEY (id);


--
-- Name: agent_rules agent_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_rules
    ADD CONSTRAINT agent_rules_pkey PRIMARY KEY (id);


--
-- Name: agent_types agent_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_types
    ADD CONSTRAINT agent_types_pkey PRIMARY KEY (id);


--
-- Name: agent_uris agent_uris_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_uris
    ADD CONSTRAINT agent_uris_pkey PRIMARY KEY (id);


--
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: binaries binaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.binaries
    ADD CONSTRAINT binaries_pkey PRIMARY KEY (id);


--
-- Name: collection_joins collection_joins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_joins
    ADD CONSTRAINT collection_joins_pkey PRIMARY KEY (id);


--
-- Name: collections_host_groups collections_host_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections_host_groups
    ADD CONSTRAINT collections_host_groups_pkey PRIMARY KEY (id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: downloads downloads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.downloads
    ADD CONSTRAINT downloads_pkey PRIMARY KEY (id);


--
-- Name: elements elements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.elements
    ADD CONSTRAINT elements_pkey PRIMARY KEY (id);


--
-- Name: entity_elements entity_elements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_elements
    ADD CONSTRAINT entity_elements_pkey PRIMARY KEY (id);


--
-- Name: host_groups_items host_groups_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.host_groups_items
    ADD CONSTRAINT host_groups_items_pkey PRIMARY KEY (id);


--
-- Name: host_groups host_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.host_groups
    ADD CONSTRAINT host_groups_pkey PRIMARY KEY (id);


--
-- Name: item_sets_items item_sets_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets_items
    ADD CONSTRAINT item_sets_items_pkey PRIMARY KEY (id);


--
-- Name: item_sets item_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets
    ADD CONSTRAINT item_sets_pkey PRIMARY KEY (id);


--
-- Name: item_sets_users item_sets_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets_users
    ADD CONSTRAINT item_sets_users_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: metadata_profile_elements metadata_profile_elements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_profile_elements
    ADD CONSTRAINT metadata_profile_elements_pkey PRIMARY KEY (id);


--
-- Name: metadata_profiles metadata_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_profiles
    ADD CONSTRAINT metadata_profiles_pkey PRIMARY KEY (id);


--
-- Name: options options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options
    ADD CONSTRAINT options_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vocabularies vocabularies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabularies
    ADD CONSTRAINT vocabularies_pkey PRIMARY KEY (id);


--
-- Name: vocabulary_terms vocabulary_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_terms
    ADD CONSTRAINT vocabulary_terms_pkey PRIMARY KEY (id);


--
-- Name: watches watches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watches
    ADD CONSTRAINT watches_pkey PRIMARY KEY (id);


--
-- Name: by_relationship; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX by_relationship ON public.agent_relations USING btree (agent_id, agent_relation_type_id, related_agent_id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_agent_relations_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_relations_on_agent_id ON public.agent_relations USING btree (agent_id);


--
-- Name: index_agent_relations_on_related_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_relations_on_related_agent_id ON public.agent_relations USING btree (related_agent_id);


--
-- Name: index_agent_rules_on_abbreviation; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agent_rules_on_abbreviation ON public.agent_rules USING btree (abbreviation);


--
-- Name: index_agent_rules_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agent_rules_on_name ON public.agent_rules USING btree (name);


--
-- Name: index_agent_types_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agent_types_on_name ON public.agent_types USING btree (name);


--
-- Name: index_agent_uris_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_uris_on_agent_id ON public.agent_uris USING btree (agent_id);


--
-- Name: index_agent_uris_on_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agent_uris_on_uri ON public.agent_uris USING btree (uri);


--
-- Name: index_agents_on_agent_rule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_on_agent_rule_id ON public.agents USING btree (agent_rule_id);


--
-- Name: index_agents_on_agent_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_on_agent_type_id ON public.agents USING btree (agent_type_id);


--
-- Name: index_agents_on_begin_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_on_begin_date ON public.agents USING btree (begin_date);


--
-- Name: index_agents_on_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_on_end_date ON public.agents USING btree (end_date);


--
-- Name: index_agents_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agents_on_name ON public.agents USING btree (name);


--
-- Name: index_binaries_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_binaries_on_item_id ON public.binaries USING btree (item_id);


--
-- Name: index_binaries_on_master_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_binaries_on_master_type ON public.binaries USING btree (master_type);


--
-- Name: index_binaries_on_media_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_binaries_on_media_category ON public.binaries USING btree (media_category);


--
-- Name: index_binaries_on_media_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_binaries_on_media_type ON public.binaries USING btree (media_type);


--
-- Name: index_binaries_on_object_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_binaries_on_object_key ON public.binaries USING btree (object_key);


--
-- Name: index_binaries_on_ocred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_binaries_on_ocred_at ON public.binaries USING btree (ocred_at);


--
-- Name: index_collection_joins_on_child_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_joins_on_child_identifier ON public.collection_joins USING btree (child_repository_id);


--
-- Name: index_collection_joins_on_parent_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_joins_on_parent_identifier ON public.collection_joins USING btree (parent_repository_id);


--
-- Name: index_collections_host_groups_on_allowed_host_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_host_groups_on_allowed_host_group_id ON public.collections_host_groups USING btree (allowed_host_group_id);


--
-- Name: index_collections_host_groups_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_host_groups_on_collection_id ON public.collections_host_groups USING btree (collection_id);


--
-- Name: index_collections_host_groups_on_denied_host_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_host_groups_on_denied_host_group_id ON public.collections_host_groups USING btree (denied_host_group_id);


--
-- Name: index_collections_on_descriptive_element_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_descriptive_element_id ON public.collections USING btree (descriptive_element_id);


--
-- Name: index_collections_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_external_id ON public.collections USING btree (external_id);


--
-- Name: index_collections_on_harvestable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_harvestable ON public.collections USING btree (harvestable);


--
-- Name: index_collections_on_harvestable_by_idhh; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_harvestable_by_idhh ON public.collections USING btree (harvestable_by_idhh);


--
-- Name: index_collections_on_harvestable_by_primo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_harvestable_by_primo ON public.collections USING btree (harvestable_by_primo);


--
-- Name: index_collections_on_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collections_on_identifier ON public.collections USING btree (repository_id);


--
-- Name: index_collections_on_metadata_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_metadata_profile_id ON public.collections USING btree (metadata_profile_id);


--
-- Name: index_collections_on_public_in_medusa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_public_in_medusa ON public.collections USING btree (public_in_medusa);


--
-- Name: index_collections_on_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_published ON public.collections USING btree (published_in_dls);


--
-- Name: index_collections_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collections_on_repository_id ON public.collections USING btree (repository_id);


--
-- Name: index_collections_on_representative_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_representative_item_id ON public.collections USING btree (representative_item_id);


--
-- Name: index_downloads_on_expired; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_downloads_on_expired ON public.downloads USING btree (expired);


--
-- Name: index_downloads_on_ip_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_downloads_on_ip_address ON public.downloads USING btree (ip_address);


--
-- Name: index_downloads_on_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_downloads_on_task_id ON public.downloads USING btree (task_id);


--
-- Name: index_elements_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_elements_on_name ON public.elements USING btree (name);


--
-- Name: index_entity_elements_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_elements_on_collection_id ON public.entity_elements USING btree (collection_id);


--
-- Name: index_entity_elements_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_elements_on_item_id ON public.entity_elements USING btree (item_id);


--
-- Name: index_entity_elements_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_elements_on_name ON public.entity_elements USING btree (name);


--
-- Name: index_entity_elements_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_elements_on_type ON public.entity_elements USING btree (type);


--
-- Name: index_entity_elements_on_vocabulary_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_elements_on_vocabulary_id ON public.entity_elements USING btree (vocabulary_id);


--
-- Name: index_host_groups_items_on_allowed_host_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_host_groups_items_on_allowed_host_group_id ON public.host_groups_items USING btree (allowed_host_group_id);


--
-- Name: index_host_groups_items_on_denied_host_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_host_groups_items_on_denied_host_group_id ON public.host_groups_items USING btree (denied_host_group_id);


--
-- Name: index_host_groups_items_on_effective_allowed_host_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_host_groups_items_on_effective_allowed_host_group_id ON public.host_groups_items USING btree (effective_allowed_host_group_id);


--
-- Name: index_host_groups_items_on_effective_denied_host_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_host_groups_items_on_effective_denied_host_group_id ON public.host_groups_items USING btree (effective_denied_host_group_id);


--
-- Name: index_host_groups_items_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_host_groups_items_on_item_id ON public.host_groups_items USING btree (item_id);


--
-- Name: index_host_groups_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_host_groups_on_key ON public.host_groups USING btree (key);


--
-- Name: index_item_sets_items_on_item_set_id_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_item_sets_items_on_item_set_id_and_item_id ON public.item_sets_items USING btree (item_set_id, item_id);


--
-- Name: index_item_sets_on_collection_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_item_sets_on_collection_repository_id ON public.item_sets USING btree (collection_repository_id);


--
-- Name: index_item_sets_users_on_item_set_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_item_sets_users_on_item_set_id_and_user_id ON public.item_sets_users USING btree (item_set_id, user_id);


--
-- Name: index_items_on_collection_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_collection_identifier ON public.items USING btree (collection_repository_id);


--
-- Name: index_items_on_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_items_on_identifier ON public.items USING btree (repository_id);


--
-- Name: index_items_on_parent_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_parent_identifier ON public.items USING btree (parent_repository_id);


--
-- Name: index_items_on_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_published ON public.items USING btree (published);


--
-- Name: index_items_on_published_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_published_at ON public.items USING btree (published_at);


--
-- Name: index_items_on_representative_item_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_representative_item_identifier ON public.items USING btree (representative_item_id);


--
-- Name: index_items_on_variant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_variant ON public.items USING btree (variant);


--
-- Name: index_metadata_profile_elements_on_facetable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_profile_elements_on_facetable ON public.metadata_profile_elements USING btree (facetable);


--
-- Name: index_metadata_profile_elements_on_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_profile_elements_on_index ON public.metadata_profile_elements USING btree (index);


--
-- Name: index_metadata_profile_elements_on_indexed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_profile_elements_on_indexed ON public.metadata_profile_elements USING btree (indexed);


--
-- Name: index_metadata_profile_elements_on_metadata_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_profile_elements_on_metadata_profile_id ON public.metadata_profile_elements USING btree (metadata_profile_id);


--
-- Name: index_metadata_profile_elements_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_profile_elements_on_name ON public.metadata_profile_elements USING btree (name);


--
-- Name: index_metadata_profile_elements_on_searchable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_profile_elements_on_searchable ON public.metadata_profile_elements USING btree (searchable);


--
-- Name: index_metadata_profile_elements_on_sortable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_profile_elements_on_sortable ON public.metadata_profile_elements USING btree (sortable);


--
-- Name: index_metadata_profile_elements_on_visible; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_profile_elements_on_visible ON public.metadata_profile_elements USING btree (visible);


--
-- Name: index_metadata_profiles_on_default; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_profiles_on_default ON public.metadata_profiles USING btree ("default");


--
-- Name: index_metadata_profiles_on_default_sortable_element_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_profiles_on_default_sortable_element_id ON public.metadata_profiles USING btree (default_sortable_element_id);


--
-- Name: index_metadata_profiles_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_profiles_on_name ON public.metadata_profiles USING btree (name);


--
-- Name: index_options_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_options_on_key ON public.options USING btree (key);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: index_vocabularies_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vocabularies_on_key ON public.vocabularies USING btree (key);


--
-- Name: index_vocabulary_terms_on_string; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vocabulary_terms_on_string ON public.vocabulary_terms USING btree (string);


--
-- Name: index_vocabulary_terms_on_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vocabulary_terms_on_uri ON public.vocabulary_terms USING btree (uri);


--
-- Name: index_vocabulary_terms_on_vocabulary_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vocabulary_terms_on_vocabulary_id ON public.vocabulary_terms USING btree (vocabulary_id);


--
-- Name: index_watches_on_user_id_and_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_watches_on_user_id_and_collection_id ON public.watches USING btree (user_id, collection_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: metadata_profiles fk_rails_0169b65fc2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_profiles
    ADD CONSTRAINT fk_rails_0169b65fc2 FOREIGN KEY (default_sortable_element_id) REFERENCES public.metadata_profile_elements(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: item_sets_users fk_rails_0c5c3f91b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets_users
    ADD CONSTRAINT fk_rails_0c5c3f91b6 FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: item_sets_items fk_rails_24146ea428; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets_items
    ADD CONSTRAINT fk_rails_24146ea428 FOREIGN KEY (item_id) REFERENCES public.items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: collections_host_groups fk_rails_274bbbf772; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections_host_groups
    ADD CONSTRAINT fk_rails_274bbbf772 FOREIGN KEY (allowed_host_group_id) REFERENCES public.host_groups(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: metadata_profile_elements_vocabularies fk_rails_28d147a892; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_profile_elements_vocabularies
    ADD CONSTRAINT fk_rails_28d147a892 FOREIGN KEY (vocabulary_id) REFERENCES public.vocabularies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: item_sets_items fk_rails_2a93ea7b44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets_items
    ADD CONSTRAINT fk_rails_2a93ea7b44 FOREIGN KEY (item_set_id) REFERENCES public.item_sets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: vocabulary_terms fk_rails_34c36c6d0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_terms
    ADD CONSTRAINT fk_rails_34c36c6d0a FOREIGN KEY (vocabulary_id) REFERENCES public.vocabularies(id) ON DELETE CASCADE;


--
-- Name: host_groups_items fk_rails_3b28c8e5a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.host_groups_items
    ADD CONSTRAINT fk_rails_3b28c8e5a3 FOREIGN KEY (allowed_host_group_id) REFERENCES public.host_groups(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: host_groups_items fk_rails_3c28067ae9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.host_groups_items
    ADD CONSTRAINT fk_rails_3c28067ae9 FOREIGN KEY (effective_allowed_host_group_id) REFERENCES public.host_groups(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: agents fk_rails_3ed59a0ea2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT fk_rails_3ed59a0ea2 FOREIGN KEY (agent_rule_id) REFERENCES public.agent_rules(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: agent_uris fk_rails_4307bd7009; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_uris
    ADD CONSTRAINT fk_rails_4307bd7009 FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: entity_elements fk_rails_4865b3a9e4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_elements
    ADD CONSTRAINT fk_rails_4865b3a9e4 FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: metadata_profile_elements_vocabularies fk_rails_48a581111e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_profile_elements_vocabularies
    ADD CONSTRAINT fk_rails_48a581111e FOREIGN KEY (metadata_profile_element_id) REFERENCES public.metadata_profile_elements(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: watches fk_rails_5ab4cadb89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watches
    ADD CONSTRAINT fk_rails_5ab4cadb89 FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: host_groups_items fk_rails_624237bcc7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.host_groups_items
    ADD CONSTRAINT fk_rails_624237bcc7 FOREIGN KEY (effective_denied_host_group_id) REFERENCES public.host_groups(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: collections fk_rails_6a2239f00f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT fk_rails_6a2239f00f FOREIGN KEY (descriptive_element_id) REFERENCES public.metadata_profile_elements(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: entity_elements fk_rails_6e7b234259; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_elements
    ADD CONSTRAINT fk_rails_6e7b234259 FOREIGN KEY (vocabulary_id) REFERENCES public.vocabularies(id) ON DELETE RESTRICT;


--
-- Name: binaries fk_rails_7ddb206113; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.binaries
    ADD CONSTRAINT fk_rails_7ddb206113 FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: collections_host_groups fk_rails_8b0a21d403; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections_host_groups
    ADD CONSTRAINT fk_rails_8b0a21d403 FOREIGN KEY (denied_host_group_id) REFERENCES public.host_groups(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: agent_relations fk_rails_916d38e391; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_relations
    ADD CONSTRAINT fk_rails_916d38e391 FOREIGN KEY (related_agent_id) REFERENCES public.agents(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agent_relations fk_rails_92698dfe00; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_relations
    ADD CONSTRAINT fk_rails_92698dfe00 FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: host_groups_items fk_rails_9a9f1d8dc5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.host_groups_items
    ADD CONSTRAINT fk_rails_9a9f1d8dc5 FOREIGN KEY (item_id) REFERENCES public.items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: host_groups_items fk_rails_b2b3c072f3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.host_groups_items
    ADD CONSTRAINT fk_rails_b2b3c072f3 FOREIGN KEY (denied_host_group_id) REFERENCES public.host_groups(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: collections_host_groups fk_rails_b414f8c127; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections_host_groups
    ADD CONSTRAINT fk_rails_b414f8c127 FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: item_sets_users fk_rails_d36998c0cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_sets_users
    ADD CONSTRAINT fk_rails_d36998c0cf FOREIGN KEY (item_set_id) REFERENCES public.item_sets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agent_relations fk_rails_e0aef3556d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_relations
    ADD CONSTRAINT fk_rails_e0aef3556d FOREIGN KEY (agent_relation_type_id) REFERENCES public.agent_relation_types(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: entity_elements fk_rails_ef949eebfa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_elements
    ADD CONSTRAINT fk_rails_ef949eebfa FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: metadata_profile_elements fk_rails_f24a449353; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_profile_elements
    ADD CONSTRAINT fk_rails_f24a449353 FOREIGN KEY (metadata_profile_id) REFERENCES public.metadata_profiles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: watches fk_rails_f9e5562894; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watches
    ADD CONSTRAINT fk_rails_f9e5562894 FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agents fk_rails_fd453c9ee9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT fk_rails_fd453c9ee9 FOREIGN KEY (agent_type_id) REFERENCES public.agent_types(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20151031232125'),
('20151031233145'),
('20151111162114'),
('20151111162154'),
('20151111162949'),
('20151111213653'),
('20151112152434'),
('20151112161443'),
('20151112165546'),
('20151215152343'),
('20151221154301'),
('20151221155520'),
('20160108174937'),
('20160108175822'),
('20160108183318'),
('20160113150908'),
('20160113161140'),
('20160113193257'),
('20160113213408'),
('20160216180927'),
('20160216202159'),
('20160316141953'),
('20160316200617'),
('20160329161518'),
('20160411184507'),
('20160411185548'),
('20160411202239'),
('20160412140611'),
('20160412144729'),
('20160412150309'),
('20160412202527'),
('20160412203153'),
('20160412203353'),
('20160412211215'),
('20160413135206'),
('20160413171025'),
('20160414144340'),
('20160414161056'),
('20160415014131'),
('20160415171222'),
('20160415171341'),
('20160415192603'),
('20160419145959'),
('20160419195154'),
('20160419200022'),
('20160421013630'),
('20160421205847'),
('20160426191152'),
('20160505165037'),
('20160510153038'),
('20160510163453'),
('20160510165648'),
('20160513155502'),
('20160516163103'),
('20160527151950'),
('20160621204805'),
('20160621210324'),
('20160628134506'),
('20160628145618'),
('20160628180023'),
('20160629165451'),
('20160714140631'),
('20160714185252'),
('20160721164523'),
('20160721185034'),
('20160725181442'),
('20160727192248'),
('20160802155603'),
('20160802161059'),
('20160802162834'),
('20160817152218'),
('20160817153624'),
('20160824142251'),
('20160824145757'),
('20160824155447'),
('20160824223455'),
('20160826134846'),
('20160826163636'),
('20160826164327'),
('20160831182142'),
('20160901182447'),
('20160901193517'),
('20160908161727'),
('20160908165439'),
('20160908195612'),
('20160912152929'),
('20160912182950'),
('20160912194604'),
('20160912212114'),
('20160914181708'),
('20160919173801'),
('20160920141611'),
('20160930135358'),
('20161013142850'),
('20161018203357'),
('20161028181524'),
('20161101182551'),
('20161101200710'),
('20161117181018'),
('20161130193722'),
('20161201203606'),
('20161201210700'),
('20161202164802'),
('20161202190505'),
('20161202202134'),
('20161202212723'),
('20161202214658'),
('20161202214912'),
('20161205175322'),
('20161205212000'),
('20161205213232'),
('20161205214113'),
('20161206174210'),
('20161207163426'),
('20161213154023'),
('20161213163237'),
('20161213183026'),
('20161216162212'),
('20170123182047'),
('20170125152104'),
('20170207150142'),
('20170317191828'),
('20170320204343'),
('20170404195912'),
('20170508143735'),
('20170508154139'),
('20170508171952'),
('20170508173553'),
('20170518140629'),
('20170531144224'),
('20170608153727'),
('20170615163116'),
('20170615163824'),
('20170616194838'),
('20170619152317'),
('20170619154015'),
('20170619162823'),
('20170619165919'),
('20170630163938'),
('20170710195351'),
('20170712185802'),
('20170712194707'),
('20170717173540'),
('20170726180139'),
('20170731163638'),
('20170807191410'),
('20170815174701'),
('20170823190343'),
('20170823193243'),
('20170829142849'),
('20170831161318'),
('20170912195504'),
('20170928164630'),
('20171003190136'),
('20171103200514'),
('20171114152247'),
('20171204212737'),
('20171219173142'),
('20180302144403'),
('20180302145007'),
('20180626142132'),
('20181217172350'),
('20190109150445'),
('20190212170952'),
('20190212224705'),
('20190226143441'),
('20190919205815'),
('20191004143449'),
('20191017212722'),
('20191028202451'),
('20191028204156'),
('20191114021116'),
('20191121164204'),
('20191204151404'),
('20191204201546'),
('20191205210707'),
('20200224205106'),
('20200629143237'),
('20201027200545'),
('20201130154247'),
('20201202174600'),
('20201203222018'),
('20201215154716'),
('20210106161354'),
('20210106163106'),
('20210504165111'),
('20210510142839'),
('20210511135637'),
('20210513141617'),
('20210519200852'),
('20210520140639'),
('20210614151454'),
('20210621181359'),
('20210629184236'),
('20210630134430'),
('20210630211809'),
('20210716182520'),
('20210720133622'),
('20211015143858'),
('20211027144413'),
('20211027155238'),
('20211028135917'),
('20211028183916'),
('20211102181408'),
('20211103143136'),
('20211220202658'),
('20211221152114'),
('20220204222328');


