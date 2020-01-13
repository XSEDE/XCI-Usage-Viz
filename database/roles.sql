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
ALTER ROLE usage_load WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION PASSWORD 'md54fbaa54e6e2727c6d1f3eb76ce87ce46';
CREATE ROLE usage_owner;
ALTER ROLE usage_owner WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION PASSWORD 'md56f87b37489469eac2707e08620c8ad19';
CREATE ROLE usage_view;
ALTER ROLE usage_view WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION PASSWORD 'md5df38a549a1978e75f0b46646c6aaffb1';
ALTER ROLE usage_load SET search_path TO usage_schema;
ALTER ROLE usage_owner SET search_path TO usage_schema;
ALTER ROLE usage_view SET search_path TO usage_schema;




--
-- PostgreSQL database cluster dump complete
--

