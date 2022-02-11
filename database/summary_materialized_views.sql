----------------------------------------------------------------------------------------------------
-- MONTHLY summary for EACH user, including:
--     use_count -> times used
--     use_amount -> total amount used
--     previous_month -> previous month this user used
--   Ordering so that component month, day, or hour data is physically continguous
--   Each used_component always has the same use_amount_units
-- INPUT is individual usage records
----------------------------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW sum_usage_user_monthly AS
SELECT used_component, DATE_TRUNC('month', use_timestamp) AS use_month, use_user, use_amount_units,
        COUNT(*) AS use_count,
        SUM(use_amount) AS use_amount,
        LAG(DATE_TRUNC('month', use_timestamp), 1) OVER (PARTITION BY used_component, use_user, use_amount_units ORDER BY DATE_TRUNC('month', use_timestamp)) AS previous_use_month
    FROM std_usage_entry
    WHERE use_timestamp < DATE_TRUNC('month', NOW())
    GROUP BY used_component, use_month, use_user, use_amount_units
    ORDER BY used_component, use_month;

-- Create indexes and grant access for Grafana
CREATE INDEX sum_usage_user_monthly_idx1 ON sum_usage_user_monthly USING BTREE (used_component);
CREATE INDEX sum_usage_user_monthly_idx2 ON sum_usage_user_monthly USING BTREE (use_month);
CREATE INDEX sum_usage_user_monthly_idx3 ON sum_usage_user_monthly USING BTREE (use_user);
GRANT SELECT ON sum_usage_user_monthly TO usage_view, usage_load;

-- NOT FOR GRAFANA USE; USED ONLY TO GENERATE sum_usage_monthly
-- MONTHLY summary for ALL users, including:
--    how many times used
--    distinct clients
--    total amount used
-- INPUT is individual usage records
CREATE MATERIALIZED VIEW sum_usage_monthly_totals_n_clients AS
SELECT used_component, DATE_TRUNC('month', use_timestamp) AS use_month, use_amount_units,
        SUM(use_amount) AS use_amount,
        COUNT(*) AS use_count,
        COUNT(distinct(use_client)) AS distinct_clients
    FROM std_usage_entry
    WHERE use_timestamp < DATE_TRUNC('month', NOW())
    GROUP BY used_component, use_month, use_amount_units;

-- NOT FOR GRAFANA USE; USED ONLY TO GENERATE sum_usage_monthly
-- MONTHLY summary for ALL users, including:
--    distinct users,
--    first time total_users
--    prior month users
-- INPUT is the above user monthly summary
CREATE MATERIALIZED VIEW sum_usage_monthly_new_users AS
SELECT used_component, use_month, use_amount_units,
        COUNT(*) AS distinct_users,
        SUM(CASE WHEN previous_use_month is null THEN 1 ELSE 0 END) AS first_time_users,
        SUM(CASE WHEN previous_use_month is not null THEN 1 ELSE 0 END) AS returning_users
    FROM sum_usage_user_monthly
    GROUP BY used_component, use_month, use_amount_units;
    -- SUM(CASE WHEN previous_use_month is null THEN 0 WHEN use_month - INTERVAL '1 month' = previous_use_month THEN 1 ELSE 0 END) AS last_month_users

CREATE MATERIALIZED VIEW sum_usage_monthly AS
SELECT T.used_component, T.use_month, T.use_amount_units,
        use_amount, use_count, distinct_clients, distinct_users, first_time_users, returning_users
    FROM sum_usage_monthly_totals_n_clients T, sum_usage_monthly_new_users U
    WHERE T.used_component = U.used_component
      AND T.use_month = U.use_month
      AND T.use_amount_units IS NOT DISTINCT FROM U.use_amount_units
    ORDER BY used_component, use_month;

-- Create indexes and grant access for Grafana
CREATE INDEX sum_usage_monthly_idx1 ON sum_usage_monthly USING BTREE (used_component);
CREATE INDEX sum_usage_monthly_idx2 ON sum_usage_monthly USING BTREE (use_month);
GRANT SELECT ON sum_usage_monthly TO usage_view, usage_load;

----------------------------------------------------------------------------------------------------
-- DAILY summary usage by USER, including:
--     use_count -> times used
--     use_amount -> total amount used
--     previous_month -> previous month this user used
--   Ordering so that component month, day, or hour data is physically continguous
--   Each used_component always has the same use_amount_units
-- INPUT is individual usage records
----------------------------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW sum_usage_user_daily AS
SELECT used_component, DATE_TRUNC('day', use_timestamp) AS use_day, use_user, use_amount_units,
        COUNT(*) AS use_count,
        SUM(use_amount) AS use_amount,
        LAG(DATE_TRUNC('day', use_timestamp), 1) OVER (PARTITION BY used_component, use_user, use_amount_units ORDER BY DATE_TRUNC('day', use_timestamp)) AS previous_use_day
    FROM std_usage_entry
    WHERE use_timestamp >= DATE_TRUNC('month', NOW()) - INTERVAL '4 months'
      AND use_timestamp < DATE_TRUNC('month', NOW())
    GROUP BY used_component, use_day, use_user, use_amount_units
    ORDER BY used_component, use_day;

-- Create indexes and grant access for Grafana
CREATE INDEX sum_usage_user_daily_idx1 ON sum_usage_user_daily USING BTREE (used_component);
CREATE INDEX sum_usage_user_daily_idx2 ON sum_usage_user_daily USING BTREE (use_day);
CREATE INDEX sum_usage_user_daily_idx3 ON sum_usage_user_daily USING BTREE (use_user);
GRANT SELECT ON sum_usage_user_daily TO usage_view, usage_load;

-- INPUT is individual usage records
CREATE MATERIALIZED VIEW sum_usage_daily AS
SELECT used_component, DATE_TRUNC('day', use_timestamp) AS use_day, use_amount_units,
        COUNT(*) AS use_count,
        COUNT(distinct(use_user)) AS distinct_users,
        COUNT(distinct(use_client)) AS distinct_clients,
        SUM(use_amount) AS use_amount
    FROM std_usage_entry
    WHERE use_timestamp >= DATE_TRUNC('month', NOW()) - INTERVAL '4 months'
      AND use_timestamp < DATE_TRUNC('month', NOW())
    GROUP BY used_component, use_day, use_amount_units
    ORDER BY used_component, use_day;

-- Create indexes and grant access for Grafana
CREATE INDEX sum_usage_daily_idx1 ON sum_usage_daily USING BTREE (used_component);
CREATE INDEX sum_usage_daily_idx2 ON sum_usage_daily USING BTREE (use_day);
GRANT SELECT ON sum_usage_daily TO usage_view, usage_load;

----------------------------------------------------------------------------------------------------
-- Summary usage by USER AND CLIENT for the period, including times used but NOT amount used
-- Initially only used by component org.cilogon.auth
-- INPUT is individual usage records
----------------------------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW sum_usage_user_client_monthly AS
SELECT used_component, DATE_TRUNC('month', use_timestamp) AS use_month, use_user, use_client,
        COUNT(*) AS use_count,
        LAG(DATE_TRUNC('month', use_timestamp), 1) OVER (PARTITION BY used_component, use_user, use_client ORDER BY DATE_TRUNC('month', use_timestamp)) AS previous_use_month
    FROM std_usage_entry
    WHERE use_timestamp < DATE_TRUNC('month', NOW())
      AND used_component in ('org.cilogon.auth', 'org.globus.auth')
    GROUP BY used_component, use_month, use_user, use_client
    ORDER BY used_component, use_month;

-- Create indexes and grant access for Grafana
CREATE INDEX sum_usage_user_client_monthly_idx1 ON sum_usage_user_client_monthly USING BTREE (used_component);
CREATE INDEX sum_usage_user_client_monthly_idx2 ON sum_usage_user_client_monthly USING BTREE (use_month);
CREATE INDEX sum_usage_user_client_monthly_idx3 ON sum_usage_user_client_monthly USING BTREE (use_user);
GRANT SELECT ON sum_usage_user_client_monthly TO usage_view, usage_load;

-- INPUT is individual usage records
CREATE MATERIALIZED VIEW sum_usage_user_client_daily AS
SELECT used_component, DATE_TRUNC('day', use_timestamp) AS use_day, use_user, use_client,
        COUNT(*) AS use_count,
        LAG(DATE_TRUNC('day', use_timestamp), 1) OVER (PARTITION BY used_component, use_user, use_client ORDER BY DATE_TRUNC('day', use_timestamp)) AS previous_use_day
    FROM std_usage_entry
    WHERE use_timestamp >= DATE_TRUNC('month', NOW()) - INTERVAL '4 months'
      AND use_timestamp < DATE_TRUNC('month', NOW())
      AND used_component in ('org.cilogon.auth', 'org.globus.auth')
    GROUP BY used_component, use_day, use_user, use_client
    ORDER BY used_component, use_day;

-- Create indexes and grant access for Grafana
CREATE INDEX sum_usage_user_client_daily_idx1 ON sum_usage_user_client_daily USING BTREE (used_component);
CREATE INDEX sum_usage_user_client_daily_idx2 ON sum_usage_user_client_daily USING BTREE (use_day);
CREATE INDEX sum_usage_user_client_daily_idx3 ON sum_usage_user_client_daily USING BTREE (use_user);
GRANT SELECT ON sum_usage_user_client_daily TO usage_view, usage_load;
