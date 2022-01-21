\timing on
REFRESH MATERIALIZED VIEW sum_usage_user_monthly         WITH DATA;
REFRESH MATERIALIZED VIEW sum_usage_user_daily           WITH DATA;
REFRESH MATERIALIZED VIEW sum_usage_user_client_monthly  WITH DATA;
REFRESH MATERIALIZED VIEW sum_usage_user_client_daily    WITH DATA;
REFRESH MATERIALIZED VIEW sum_usage_monthly              WITH DATA;
REFRESH MATERIALIZED VIEW sum_usage_daily                WITH DATA;
-- REFRESH MATERIALIZED VIEW sum_usage_user_hourly   WITH DATA;


CREATE MATERIALIZED VIEW sum_usage_user_monthly (used_component, use_month, use_user, use_count, use_amount, use_amount_units)
CREATE MATERIALIZED VIEW sum_usage_user_daily (used_component, use_day, use_user, use_count, use_amount, use_amount_units)
CREATE MATERIALIZED VIEW sum_usage_monthly (used_component, use_month, use_count, use_distinct_users, use_distinct_clients, use_amount, use_amount_units)
CREATE MATERIALIZED VIEW sum_usage_daily (used_component, use_day, use_count, use_distinct_users, use_distinct_clients, use_amount, use_amount_units)
CREATE MATERIALIZED VIEW sum_usage_user_client_monthly (used_component, use_month, use_user, use_client, use_count)
CREATE MATERIALIZED VIEW sum_usage_user_client_daily (used_component, use_day, use_user, use_client, use_count)

