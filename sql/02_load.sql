-- 02_load.sql

TRUNCATE readings, sensors, transformers CASCADE;

INSERT INTO transformers (device_serial)
SELECT DISTINCT input_data ->> 'deviceSerial'
FROM staging;

INSERT INTO sensors (position_index, height, submerged, sensor_name)
SELECT n AS position_index,
       n * 0.25 AS height,
       n <= 8 AS submerged,
       'TX_' || lpad(n::text, 2, '0') AS sensor_name
FROM generate_series(0, 15) AS n;

INSERT INTO readings (device_serial, position_index, temperature, measured_at)
SELECT s.input_data ->> 'deviceSerial',
       t.position - 1,
       t.temperature::numeric,
       to_timestamp((s.input_data ->> 'timestamp')::bigint)
FROM staging AS s,
     jsonb_array_elements(s.input_data -> 'temperatures') WITH ORDINALITY AS t(temperature, position);