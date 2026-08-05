-- export.sql
COPY (
    SELECT device_serial, date_bin('15 minutes', measured_at, timestamp '2026-01-01') AS interval_15min, position_index, AVG(temperature) AS avg_Temp FROM readings GROUP BY device_serial, date_bin('15 minutes', measured_at, timestamp '2026-01-01'), position_index ORDER BY device_serial, interval_15min, position_index

) TO '/exports/readings_15mins.csv' WITH (FORMAT csv, HEADER);