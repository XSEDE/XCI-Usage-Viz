-- Ordering so that component and month data is physically continguous
CREATE MATERIALIZED VIEW sum_usage_user_monthly (used_component,use_month,use_user,use_count)
    AS SELECT used_component,DATE_TRUNC('month', use_timestamp) AS use_month,use_user,count(*)
        FROM std_usage_entry
        WHERE use_timestamp < DATE_TRUNC('month', now())
        GROUP BY used_component,use_month,use_user
        ORDER by used_component,use_month;

CREATE INDEX sum_usage_user_monthly_idx1 ON sum_usage_user_monthly USING BTREE (used_component);
CREATE INDEX sum_usage_user_monthly_idx2 ON sum_usage_user_monthly USING BTREE (use_month);
CREATE INDEX sum_usage_user_monthly_idx3 ON sum_usage_user_monthly USING BTREE (use_user);
GRANT SELECT ON sum_usage_user_monthly TO usage_view;
GRANT SELECT ON sum_usage_user_monthly TO usage_load;


CREATE MATERIALIZED VIEW sum_usage_user_daily (used_component,use_day,use_user,use_count)
    AS SELECT used_component,DATE_TRUNC('day', use_timestamp) AS use_day,use_user,count(*)
        FROM std_usage_entry
        WHERE use_timestamp >= DATE_TRUNC('month', now()) - interval '3 months'
          AND use_timestamp < DATE_TRUNC('month', now())
        GROUP BY used_component,use_day,use_user
        ORDER BY used_component,use_day;

CREATE INDEX sum_usage_user_daily_idx1 ON sum_usage_user_daily USING BTREE (used_component);
CREATE INDEX sum_usage_user_daily_idx2 ON sum_usage_user_daily USING BTREE (use_day);
CREATE INDEX sum_usage_user_daily_idx3 ON sum_usage_user_daily USING BTREE (use_user);
GRANT SELECT ON sum_usage_user_daily TO usage_view;
GRANT SELECT ON sum_usage_user_daily TO usage_load;

CREATE MATERIALIZED VIEW sum_usage_user_hourly (used_component,use_hour,use_user,use_count)
    AS SELECT used_component,DATE_TRUNC('hour', use_timestamp) AS use_hour, use_user,count(*)
        FROM std_usage_entry
        WHERE use_timestamp >= DATE_TRUNC('month', now()) - interval '1 months'
          AND use_timestamp < DATE_TRUNC('day', now())  - interval '1 day'
        GROUP BY used_component,use_hour,use_user
        ORDER BY used_component,use_hour;

CREATE INDEX sum_usage_user_hourly_idx1 ON sum_usage_user_hourly USING BTREE (used_component);
CREATE INDEX sum_usage_user_hourly_idx2 ON sum_usage_user_hourly USING BTREE (use_hour);
CREATE INDEX sum_usage_user_hourly_idx3 ON sum_usage_user_hourly USING BTREE (use_user);
GRANT SELECT ON sum_usage_user_hourly TO usage_view;
GRANT SELECT ON sum_usage_user_hourly TO usage_load;
