-- 01_gradient_validation.sql

WITH endpoints AS (
    SELECT device_serial,
       measured_at,
       MAX(temperature) FILTER (WHERE position_index = 0) AS temp_bottom,
       MAX(temperature) FILTER (WHERE position_index = 8) AS temp_top
FROM readings
GROUP BY device_serial, measured_at
)
SELECT device_serial, AVG((temp_top - temp_bottom) / 2.0) AS mean_gradient 
FROM endpoints GROUP BY device_serial;