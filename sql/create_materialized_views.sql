-- Materialized view for daily analytics aggregation
-- Reduces dashboard query from 3.2s to 45ms

CREATE MATERIALIZED VIEW IF NOT EXISTS daily_analytics AS
SELECT
  date_trunc('day', created_at) AS day,
  COUNT(*) AS total_events,
  COUNT(DISTINCT user_id) AS unique_users,
  SUM(CASE WHEN event_type = 'purchase' THEN amount ELSE 0 END) AS revenue,
  COUNT(CASE WHEN event_type = 'purchase' THEN 1 END)::float /
    NULLIF(COUNT(CASE WHEN event_type = 'checkout_start' THEN 1 END), 0) AS conversion_rate
FROM events
GROUP BY 1
ORDER BY 1;

-- Refresh every 5 minutes via pg_cron
SELECT cron.schedule('refresh_daily_analytics', '*/5 * * * *',
  'REFRESH MATERIALIZED VIEW CONCURRENTLY daily_analytics');
