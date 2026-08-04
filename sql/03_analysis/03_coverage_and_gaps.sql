-- 03_coverage_and_gaps.sql

SELECT device_serial,
       count(DISTINCT measured_at) AS reading_count,
       min(measured_at) AS first_reading,
       max(measured_at) AS last_reading
FROM readings
GROUP BY device_serial
ORDER BY device_serial;

WITH reading_times AS (
    SELECT DISTINCT device_serial, measured_at
    FROM readings
),
gaps AS (
    SELECT device_serial,
           measured_at,
           measured_at - LAG(measured_at) OVER (
               PARTITION BY device_serial ORDER BY measured_at
           ) AS gap
    FROM reading_times
)
SELECT device_serial,
       count(*) FILTER (WHERE gap > interval '1 hour') AS gap_count,
       max(gap) AS largest_gap
FROM gaps
GROUP BY device_serial
ORDER BY device_serial;