\timing on
REFRESH MATERIALIZED VIEW sum_usage_user_monthly              WITH DATA;
REFRESH MATERIALIZED VIEW sum_usage_monthly_totals_n_clients  WITH DATA:
REFRESH MATERIALIZED VIEW sum_usage_monthly_new_users         WITH DATA:
REFRESH MATERIALIZED VIEW sum_usage_monthly                   WITH DATA;
REFRESH MATERIALIZED VIEW sum_usage_user_daily                WITH DATA;
REFRESH MATERIALIZED VIEW sum_usage_daily                     WITH DATA;
REFRESH MATERIALIZED VIEW sum_usage_user_client_monthly       WITH DATA;
REFRESH MATERIALIZED VIEW sum_usage_user_client_daily         WITH DATA;
-- REFRESH MATERIALIZED VIEW sum_usage_user_hourly   WITH DATA;
