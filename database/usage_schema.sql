--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: usage_schema; Type: SCHEMA; Schema: -; Owner: usage_owner
--

CREATE SCHEMA usage_schema;


ALTER SCHEMA usage_schema OWNER TO usage_owner;

SET search_path = usage_schema, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: std_usage_entry; Type: TABLE; Schema: usage_schema; Owner: usage_owner; Tablespace: 
--

CREATE TABLE std_usage_entry (
    "USED_COMPONENT" character varying(64) NOT NULL,
    "USE_TIMESTAMP" timestamp with time zone NOT NULL,
    "USE_CLIENT" character varying(32) NOT NULL,
    "USED_COMPONENT_VERSION" character varying(16),
    "USE_USER" character varying(32),
    "USE_AMOUNT" character varying(32),
    "USE_AMOUNT_UNITS" character varying(8),
    "USAGE_STATUS" character varying(2048),
    "OTHER_FIELDS_JSON" text,
    id integer NOT NULL,
    source_tag character varying(32)
);


ALTER TABLE usage_schema.std_usage_entry OWNER TO usage_owner;

--
-- Name: std_usage_entry_id_seq; Type: SEQUENCE; Schema: usage_schema; Owner: usage_owner
--

CREATE SEQUENCE std_usage_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE usage_schema.std_usage_entry_id_seq OWNER TO usage_owner;

--
-- Name: std_usage_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: usage_schema; Owner: usage_owner
--

ALTER SEQUENCE std_usage_entry_id_seq OWNED BY std_usage_entry.id;


--
-- Name: id; Type: DEFAULT; Schema: usage_schema; Owner: usage_owner
--

ALTER TABLE ONLY std_usage_entry ALTER COLUMN id SET DEFAULT nextval('std_usage_entry_id_seq'::regclass);


--
-- Name: std_usage_entry_use_client; Type: INDEX; Schema: usage_schema; Owner: usage_owner; Tablespace: 
--

CREATE INDEX std_usage_entry_use_client ON std_usage_entry USING btree ("USE_CLIENT");


--
-- Name: std_usage_entry_use_user; Type: INDEX; Schema: usage_schema; Owner: usage_owner; Tablespace: 
--

CREATE INDEX std_usage_entry_use_user ON std_usage_entry USING btree ("USE_USER");


--
-- Name: std_usage_entry_used_component; Type: INDEX; Schema: usage_schema; Owner: usage_owner; Tablespace: 
--

CREATE INDEX std_usage_entry_used_component ON std_usage_entry USING btree ("USED_COMPONENT");


--
-- Name: usage_schema; Type: ACL; Schema: -; Owner: usage_owner
--

REVOKE ALL ON SCHEMA usage_schema FROM PUBLIC;
REVOKE ALL ON SCHEMA usage_schema FROM usage_owner;
GRANT ALL ON SCHEMA usage_schema TO usage_owner;


--
-- Name: std_usage_entry; Type: ACL; Schema: usage_schema; Owner: usage_owner
--

REVOKE ALL ON TABLE std_usage_entry FROM PUBLIC;
REVOKE ALL ON TABLE std_usage_entry FROM usage_owner;
GRANT ALL ON TABLE std_usage_entry TO usage_owner;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE std_usage_entry TO usage_load;
GRANT SELECT ON TABLE std_usage_entry TO usage_view;


--
-- PostgreSQL database dump complete
--

