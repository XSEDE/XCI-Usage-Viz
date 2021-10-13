#!/bin/bash -x
pg_dumpall --roles-only -U postgres -f roles_dump.sql
pg_dump -U postgres usage_db -f schema_dump.sql -n usage_schema -s
pg_dump -U postgres usage_db -f table_dump.sql -t usage_schema.std_usage_entry
