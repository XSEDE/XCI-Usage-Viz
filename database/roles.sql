--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE usage_load;
ALTER ROLE usage_load WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md54fbaa54e6e2727c6d1f3eb76ce87ce46';
CREATE ROLE usage_owner;
ALTER ROLE usage_owner WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:10zktijBWfjlXvxx7ba9mw==$iMc4+QNJ04vnvAFBdCB9xcLxbOlWmoNMwiW6Xhz5Qgc=:776qd1xEdDXDGg1xyqPr2pDL1oj/aYJM5P82G9Oj8/g=';
CREATE ROLE usage_view;
ALTER ROLE usage_view WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md5df38a549a1978e75f0b46646c6aaffb1';

--
-- User Configurations
--

ALTER ROLE usage_load SET search_path TO usage_schema;
ALTER ROLE usage_owner SET search_path TO usage_schema;
ALTER ROLE usage_view SET search_path TO usage_schema;

CREATE DATABASE usage_db;
ALTER DATABASE usage_db OWNER TO usage_owner;
--
-- PostgreSQL database cluster dump complete
--
