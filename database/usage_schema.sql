--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4
-- Dumped by pg_dump version 13.4

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
-- Name: usage_schema; Type: SCHEMA; Schema: -; Owner: usage_owner
--

CREATE SCHEMA usage_schema;


ALTER SCHEMA usage_schema OWNER TO usage_owner;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: std_usage_entry; Type: TABLE; Schema: usage_schema; Owner: usage_owner
--

CREATE TABLE usage_schema.std_usage_entry (
    used_component character varying(64) NOT NULL,
    used_component_version character varying(16),
    used_resource character varying(8198),
    use_timestamp timestamp with time zone NOT NULL,
    use_client character varying(126),
    use_user character varying(512),
    use_amount real,
    use_amount_units character varying(16),
    usage_status character varying(126),
    other_fields_json jsonb,
    id integer NOT NULL,
    batch_uuid uuid
);


ALTER TABLE usage_schema.std_usage_entry OWNER TO usage_owner;

--
-- Name: std_usage_entry_id_seq; Type: SEQUENCE; Schema: usage_schema; Owner: usage_owner
--

CREATE SEQUENCE usage_schema.std_usage_entry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE usage_schema.std_usage_entry_id_seq OWNER TO usage_owner;

--
-- Name: std_usage_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: usage_schema; Owner: usage_owner
--

ALTER SEQUENCE usage_schema.std_usage_entry_id_seq OWNED BY usage_schema.std_usage_entry.id;


--
-- Name: std_usage_entry id; Type: DEFAULT; Schema: usage_schema; Owner: usage_owner
--

ALTER TABLE ONLY usage_schema.std_usage_entry ALTER COLUMN id SET DEFAULT nextval('usage_schema.std_usage_entry_id_seq'::regclass);


--
-- Name: std_usage_entry std_usage_entry_pkey; Type: CONSTRAINT; Schema: usage_schema; Owner: usage_owner
--

ALTER TABLE ONLY usage_schema.std_usage_entry
    ADD CONSTRAINT std_usage_entry_pkey PRIMARY KEY (id);


--
-- Name: std_usage_entry_batch_uuid; Type: INDEX; Schema: usage_schema; Owner: usage_owner
--

CREATE INDEX std_usage_entry_batch_uuid ON usage_schema.std_usage_entry USING btree (batch_uuid);


--
-- Name: std_usage_entry_use_client; Type: INDEX; Schema: usage_schema; Owner: usage_owner
--

CREATE INDEX std_usage_entry_use_client ON usage_schema.std_usage_entry USING btree (use_client);


--
-- Name: std_usage_entry_use_user; Type: INDEX; Schema: usage_schema; Owner: usage_owner
--

CREATE INDEX std_usage_entry_use_user ON usage_schema.std_usage_entry USING btree (use_user);


--
-- Name: std_usage_entry_used_component; Type: INDEX; Schema: usage_schema; Owner: usage_owner
--

CREATE INDEX std_usage_entry_used_component ON usage_schema.std_usage_entry USING btree (used_component);


--
-- Name: SCHEMA usage_schema; Type: ACL; Schema: -; Owner: usage_owner
--

GRANT USAGE ON SCHEMA usage_schema TO usage_load;
GRANT USAGE ON SCHEMA usage_schema TO usage_view;


--
-- Name: TABLE std_usage_entry; Type: ACL; Schema: usage_schema; Owner: usage_owner
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE usage_schema.std_usage_entry TO usage_load;
GRANT SELECT ON TABLE usage_schema.std_usage_entry TO usage_view;


--
-- Name: SEQUENCE std_usage_entry_id_seq; Type: ACL; Schema: usage_schema; Owner: usage_owner
--

GRANT SELECT ON SEQUENCE usage_schema.std_usage_entry_id_seq TO usage_view;
GRANT SELECT,UPDATE ON SEQUENCE usage_schema.std_usage_entry_id_seq TO usage_load;


--
-- PostgreSQL database dump complete
--

