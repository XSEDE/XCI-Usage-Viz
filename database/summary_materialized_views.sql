----------------------------------------------------------------------------------------------------
-- Summary usage by USER for the period, including times used and total amount used
--   Ordering so that component month, day, or hour data is physically continguous
--   Each used_component always has the same use_amount_units
----------------------------------------------------------------------------------------------------

CREATE MATERIALIZED VIEW sum_usage_user_monthly (used_component, use_month, use_user, use_count, use_amount, use_amount_units)
    AS SELECT used_component, DATE_TRUNC('month', use_timestamp) AS use_month, use_user, count(*), sum(use_amount), use_amount_units
        FROM std_usage_entry
        WHERE use_timestamp < DATE_TRUNC('month', now())
        GROUP BY used_component, use_month, use_user, use_amount_units
        ORDER by used_component, use_month;

CREATE INDEX sum_usage_user_monthly_idx1 ON sum_usage_user_monthly USING BTREE (used_component);
CREATE INDEX sum_usage_user_monthly_idx2 ON sum_usage_user_monthly USING BTREE (use_month);
CREATE INDEX sum_usage_user_monthly_idx3 ON sum_usage_user_monthly USING BTREE (use_user);
GRANT SELECT ON sum_usage_user_monthly TO usage_view, usage_load;

CREATE MATERIALIZED VIEW sum_usage_user_daily (used_component, use_day, use_user, use_count, use_amount, use_amount_units)
    AS SELECT used_component, DATE_TRUNC('day', use_timestamp) AS use_day, use_user, count(*), sum(use_amount), use_amount_units
        FROM std_usage_entry
        WHERE use_timestamp >= DATE_TRUNC('month', now()) - interval '3 months'
          AND use_timestamp < DATE_TRUNC('month', now())
        GROUP BY used_component, use_day, use_user, use_amount_units
        ORDER BY used_component, use_day;

CREATE INDEX sum_usage_user_daily_idx1 ON sum_usage_user_daily USING BTREE (used_component);
CREATE INDEX sum_usage_user_daily_idx2 ON sum_usage_user_daily USING BTREE (use_day);
CREATE INDEX sum_usage_user_daily_idx3 ON sum_usage_user_daily USING BTREE (use_user);
GRANT SELECT ON sum_usage_user_daily TO usage_view, usage_load;

-- CREATE MATERIALIZED VIEW sum_usage_user_hourly (used_component, use_hour, use_user, use_count, use_amount, use_amount_units)
--     AS SELECT used_component, DATE_TRUNC('hour', use_timestamp) AS use_hour, use_user, count(*), sum(use_amount), use_amount_units
--         FROM std_usage_entry
--         WHERE use_timestamp >= DATE_TRUNC('month', now()) - interval '1 months'
--           AND use_timestamp < DATE_TRUNC('day', now())  - interval '1 day'
--         GROUP BY used_component, use_hour, use_user, use_amount_units
--         ORDER BY used_component, use_hour;
--
-- CREATE INDEX sum_usage_user_hourly_idx1 ON sum_usage_user_hourly USING BTREE (used_component);
-- CREATE INDEX sum_usage_user_hourly_idx2 ON sum_usage_user_hourly USING BTREE (use_hour);
-- CREATE INDEX sum_usage_user_hourly_idx3 ON sum_usage_user_hourly USING BTREE (use_user);
-- GRANT SELECT ON sum_usage_user_hourly TO usage_view, usage_load;

--------------------------------------------------------------------------------------
-- Summary usage by USER for the period with total and distinct users
--------------------------------------------------------------------------------------

-- CREATE MATERIALIZED VIEW sum_usage_monthly (used_component, use_month, use_count, use_distinct_users, use_amount, use_amount_units)
--     AS SELECT used_component, use_month, sum(use_count), count(distinct(use_user)), sum(use_amount), use_amount_units
--         FROM sum_usage_user_monthly
--         GROUP BY used_component, use_month, use_amount_units
--         ORDER by used_component, use_month;

CREATE MATERIALIZED VIEW sum_usage_monthly (used_component, use_month, use_count, use_distinct_users, use_distinct_clients, use_amount, use_amount_units)
    AS SELECT used_component, DATE_TRUNC('month', use_timestamp) AS use_month, count(*), count(distinct(use_user)), count(distinct(use_client)), sum(use_amount), use_amount_units
        FROM std_usage_entry
        WHERE use_timestamp < DATE_TRUNC('month', now())
        GROUP BY used_component, use_month, use_amount_units
        ORDER by used_component, use_month;

CREATE INDEX sum_usage_monthly_idx1 ON sum_usage_monthly USING BTREE (used_component);
CREATE INDEX sum_usage_monthly_idx2 ON sum_usage_monthly USING BTREE (use_month);
GRANT SELECT ON sum_usage_monthly TO usage_view, usage_load;

-- CREATE MATERIALIZED VIEW sum_usage_daily (used_component, use_day, use_count, use_distinct_users, use_amount, use_amount_units)
--     AS SELECT used_component, use_day, sum(use_count), count(distinct(use_user)), sum(use_amount), use_amount_units
--         FROM sum_usage_user_daily
--         GROUP BY used_component, use_day, use_amount_units
--         ORDER BY used_component, use_day;

CREATE MATERIALIZED VIEW sum_usage_daily (used_component, use_day, use_count, use_distinct_users, use_distinct_clients, use_amount, use_amount_units)
    AS SELECT used_component, DATE_TRUNC('day', use_timestamp) AS use_day, count(*), count(distinct(use_user)), count(distinct(use_client)), sum(use_amount), use_amount_units
        FROM std_usage_entry
        WHERE use_timestamp >= DATE_TRUNC('month', now()) - interval '3 months'
          AND use_timestamp < DATE_TRUNC('month', now())
        GROUP BY used_component, use_day, use_amount_units
        ORDER BY used_component, use_day;

CREATE INDEX sum_usage_daily_idx1 ON sum_usage_daily USING BTREE (used_component);
CREATE INDEX sum_usage_daily_idx2 ON sum_usage_daily USING BTREE (use_day);
GRANT SELECT ON sum_usage_daily TO usage_view, usage_load;

-- CREATE MATERIALIZED VIEW sum_usage_hourly (used_component, use_hour, use_count, use_distinct_users, use_amount, use_amount_units)
--     AS SELECT used_component, use_hour, sum(use_count), count(distinct(use_user)), count(distinct(use_client)), sum(use_amount), use_amount_units
--         FROM sum_usage_user_hourly
--         GROUP BY used_component, use_hour, use_amount_units
--         ORDER BY used_component, use_hour;

-- CREATE MATERIALIZED VIEW sum_usage_hourly (used_component, use_hour, use_count, use_distinct_users, use_distinct_clients, use_amount, use_amount_units)
--     AS SELECT used_component, DATE_TRUNC('hour', use_timestamp) AS use_hour, count(*), count(distinct(use_user)), count(distinct(use_client)), sum(use_amount), use_amount_units
--         FROM std_usage_entry
--         WHERE use_timestamp >= DATE_TRUNC('month', now()) - interval '1 months'
--           AND use_timestamp < DATE_TRUNC('day', now())  - interval '1 day'
--         GROUP BY used_component, use_hour, use_amount_units
--         ORDER BY used_component, use_hour;
--
-- CREATE INDEX sum_usage_hourly_idx1 ON sum_usage_hourly USING BTREE (used_component);
-- CREATE INDEX sum_usage_hourly_idx2 ON sum_usage_hourly USING BTREE (use_hour);
-- GRANT SELECT ON sum_usage_hourly TO usage_view, usage_load;

----------------------------------------------------------------------------------------------------
-- Summary usage by USER AND CLIENT for the period, including times used but NOT amount used
-- Initially only used by component org.cilogon.auth
----------------------------------------------------------------------------------------------------

CREATE MATERIALIZED VIEW sum_usage_user_client_monthly (used_component, use_month, use_user, use_client, use_count)
    AS SELECT used_component, DATE_TRUNC('month', use_timestamp) AS use_month, use_user, use_client, count(*)
        FROM std_usage_entry
        WHERE use_timestamp < DATE_TRUNC('month', now())
          AND used_component in ('org.cilogon.auth', 'org.globus.auth')
        GROUP BY used_component, use_month, use_user, use_client
        ORDER by used_component, use_month;

CREATE INDEX sum_usage_user_client_monthly_idx1 ON sum_usage_user_client_monthly USING BTREE (used_component);
CREATE INDEX sum_usage_user_client_monthly_idx2 ON sum_usage_user_client_monthly USING BTREE (use_month);
CREATE INDEX sum_usage_user_client_monthly_idx3 ON sum_usage_user_client_monthly USING BTREE (use_user);
GRANT SELECT ON sum_usage_user_client_monthly TO usage_view, usage_load;

CREATE MATERIALIZED VIEW sum_usage_user_client_daily (used_component, use_day, use_user, use_client, use_count)
    AS SELECT used_component,DATE_TRUNC('day', use_timestamp) AS use_day, use_user, use_client, count(*)
        FROM std_usage_entry
        WHERE use_timestamp >= DATE_TRUNC('month', now()) - interval '3 months'
          AND use_timestamp < DATE_TRUNC('month', now())
          AND used_component in ('org.cilogon.auth', 'org.globus.auth')
        GROUP BY used_component, use_day, use_user, use_client
        ORDER BY used_component, use_day;

CREATE INDEX sum_usage_user_client_daily_idx1 ON sum_usage_user_client_daily USING BTREE (used_component);
CREATE INDEX sum_usage_user_client_daily_idx2 ON sum_usage_user_client_daily USING BTREE (use_day);
CREATE INDEX sum_usage_user_client_daily_idx3 ON sum_usage_user_client_daily USING BTREE (use_user);
GRANT SELECT ON sum_usage_user_client_daily TO usage_view, usage_load;

-- CREATE MATERIALIZED VIEW sum_usage_user_client_hourly (used_component, use_hour, use_user, use_client, use_count)
--     AS SELECT used_component,DATE_TRUNC('hour', use_timestamp) AS use_hour, use_user, use_client, count(*)
--         FROM std_usage_entry
--         WHERE use_timestamp >= DATE_TRUNC('month', now()) - interval '1 months'
--           AND use_timestamp < DATE_TRUNC('day', now())  - interval '1 day'
--           AND used_component in ('org.cilogon.auth', 'org.globus.auth')
--         GROUP BY used_component, use_hour, use_user, use_client
--         ORDER BY used_component, use_hour;
--
-- CREATE INDEX sum_usage_user_client_hourly_idx1 ON sum_usage_user_client_hourly USING BTREE (used_component);
-- CREATE INDEX sum_usage_user_client_hourly_idx2 ON sum_usage_user_client_hourly USING BTREE (use_hour);
-- CREATE INDEX sum_usage_user_client_hourly_idx3 ON sum_usage_user_client_hourly USING BTREE (use_user);
-- GRANT SELECT ON sum_usage_user_client_hourly TO usage_view, usage_load;

----------------------------------------------------------------------------------------------------
-- Summary usage by USER AND CLIENT for the period with total and distinct users and clients
----------------------------------------------------------------------------------------------------

-- CREATE MATERIALIZED VIEW sum_usage2_monthly (used_component, use_month, use_count, use_distinct_users, use_distinct_clients)
--     AS SELECT used_component, use_month, sum(use_count), count(distinct(use_user)), count(distinct(use_client))
--         FROM sum_usage_user_client_monthly
--         GROUP BY used_component, use_month
--         ORDER by used_component, use_month;
--
-- CREATE INDEX sum_usage2_monthly_idx1 ON sum_usage2_monthly USING BTREE (used_component);
-- CREATE INDEX sum_usage2_monthly_idx2 ON sum_usage2_monthly USING BTREE (use_month);
-- GRANT SELECT ON sum_usage2_monthly TO usage_view, usage_load;
--
-- CREATE MATERIALIZED VIEW sum_usage2_daily (used_component, use_day, use_count, use_distinct_users, use_distinct_clients)
--     AS SELECT used_component, use_day, sum(use_count), count(distinct(use_user)), count(distinct(use_client))
--         FROM sum_usage_user_client_daily
--         GROUP BY used_component, use_day
--         ORDER BY used_component, use_day;
--
-- CREATE INDEX sum_usage2_daily_idx1 ON sum_usage2_daily USING BTREE (used_component);
-- CREATE INDEX sum_usage2_daily_idx2 ON sum_usage2_daily USING BTREE (use_day);
-- GRANT SELECT ON sum_usage2_daily TO usage_view, usage_load;
--
-- CREATE MATERIALIZED VIEW sum_usage2_hourly (used_component, use_hour, use_count, use_distinct_users, use_distinct_clients)
--     AS SELECT used_component, use_hour, sum(use_count), count(distinct(use_user)), count(distinct(use_client))
--         FROM sum_usage_user_client_hourly
--         GROUP BY used_component, use_hour
--         ORDER BY used_component, use_hour;
--
-- CREATE INDEX sum_usage2_hourly_idx1 ON sum_usage2_hourly USING BTREE (used_component);
-- CREATE INDEX sum_usage2_hourly_idx2 ON sum_usage2_hourly USING BTREE (use_hour);
-- GRANT SELECT ON sum_usage2_hourly TO usage_view, usage_load;
