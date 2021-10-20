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
    used_component          character varying(64) NOT NULL,
    use_timestamp           timestamp with time zone NOT NULL,
    use_client              character varying(253) NOT NULL,
    used_component_version  character varying(16),
    use_user                character varying(512),
    use_amount              character varying(32),
    use_amount_units        character varying(8),
    used_resource           character varying(2048),
    usage_status            character varying(2048),
    other_fields_json       text,
    id                      integer PRIMARY KEY,
    batch_uuid              uuid
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

CREATE INDEX std_usage_entry_use_client ON std_usage_entry USING btree (use_client);


--
-- Name: std_usage_entry_use_user; Type: INDEX; Schema: usage_schema; Owner: usage_owner; Tablespace: 
--

CREATE INDEX std_usage_entry_use_user ON std_usage_entry USING btree (use_user);


--
-- Name: std_usage_entry_used_component; Type: INDEX; Schema: usage_schema; Owner: usage_owner; Tablespace: 
--

CREATE INDEX std_usage_entry_used_component ON std_usage_entry USING btree (used_component);


--
-- Name: std_usage_entry_batch_uuid; Type: INDEX; Schema: usage_schema; Owner: usage_owner; Tablespace:
--

CREATE INDEX std_usage_entry_batch_uuid ON std_usage_entry USING btree (batch_uuid);


--
-- Name: usage_schema; Type: ACL; Schema: -; Owner: usage_owner
--

REVOKE ALL ON SCHEMA usage_schema FROM PUBLIC;
REVOKE ALL ON SCHEMA usage_schema FROM usage_owner;
GRANT ALL ON SCHEMA usage_schema TO usage_owner;
GRANT USAGE ON SCHEMA usage_schema TO usage_load;
GRANT USAGE ON SCHEMA usage_schema TO usage_view;


--
-- Name: std_usage_entry; Type: ACL; Schema: usage_schema; Owner: usage_owner
--

REVOKE ALL ON TABLE std_usage_entry FROM PUBLIC;
REVOKE ALL ON TABLE std_usage_entry FROM usage_owner;
GRANT ALL ON TABLE std_usage_entry TO usage_owner;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE std_usage_entry TO usage_load;
GRANT SELECT ON TABLE std_usage_entry TO usage_view;


--
-- Name: std_usage_entry_id_seq; Type: ACL; Schema: usage_schema; Owner: usage_owner
--

REVOKE ALL ON SEQUENCE std_usage_entry_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE std_usage_entry_id_seq FROM usage_owner;
GRANT ALL ON SEQUENCE std_usage_entry_id_seq TO usage_owner;
GRANT SELECT ON SEQUENCE std_usage_entry_id_seq TO usage_view;
GRANT SELECT,UPDATE ON SEQUENCE std_usage_entry_id_seq TO usage_load;


--
-- PostgreSQL database dump complete
--
