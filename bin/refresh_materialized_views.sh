#!/bin/bash

HOME=/soft/XCI-Usage-Viz/
CODE=${HOME}/PROD

OUTPUT=${HOME}/var/refresh_materialized_views.log

echo 'START' `date -Iseconds` >>${OUTPUT}
/usr/pgsql-13/bin/psql --echo-all -p 5432 -U usage_owner usage_db \
   -f ${CODE}/database/refresh_materialized_views.sql \
   >> ${HOME}/var/refresh_materialized_views.log
echo 'END  ' `date -Iseconds` >>${OUTPUT}
