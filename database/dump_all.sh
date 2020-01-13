#!/bin/bash -x
pg_dumpall --roles-only -U postgres -f roles_raw.sql
pg_dump -U postgres usage_db -f usage_raw.sql -s -n usage_schema
