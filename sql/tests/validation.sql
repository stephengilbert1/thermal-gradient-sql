-- validation.sql
-- Data quality assertions run after the transform.

-- 1. Row count integrity.
-- Every staging object should explode to exactly 16 readings.

SELECT 'row_count_is_staging_x16' AS check,
       CASE
           WHEN (SELECT count(*) FROM readings) = (SELECT count(*) FROM staging) * 16
           THEN 'PASS' ELSE 'FAIL'
       END AS result

UNION ALL

-- 2. Completeness.
-- Every transformer-timestamp should carry all 16 positions.

SELECT 'every_timestamp_has_16_positions',
       CASE
           WHEN (
               SELECT count(*) FROM (
                   SELECT device_serial, measured_at
                   FROM readings
                   GROUP BY device_serial, measured_at
                   HAVING count(*) <> 16
               ) AS violations
           ) = 0
           THEN 'PASS' ELSE 'FAIL'
       END

UNION ALL

-- 3. Position range.
-- Positions must be exactly 0 to 15

SELECT 'position_index_range_0_to_15',
       CASE
           WHEN (SELECT min(position_index) FROM readings) = 0
            AND (SELECT max(position_index) FROM readings) = 15
            AND (SELECT count(DISTINCT position_index) FROM readings) = 16
           THEN 'PASS' ELSE 'FAIL'
       END

UNION ALL

-- 4. Physical plausibility.
-- Oil temperatures should sit in a sane band. A generous range is used on purpose so only genuinely broken values fail.

SELECT 'temperature_within_physical_bounds',
       CASE
           WHEN (
               SELECT count(*) FROM readings
               WHERE temperature < -60 OR temperature > 200
           ) = 0
           THEN 'PASS' ELSE 'FAIL'
       END

UNION ALL