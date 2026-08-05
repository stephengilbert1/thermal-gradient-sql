-- 01_schema.sql
-- Set up database for thermal gradient analysis 

-- Drops tables so that file is re-runnable
DROP TABLE IF EXISTS readings, sensors, transformers, staging CASCADE;

-- RAW
-- Input table, data staging
CREATE TABLE staging (
    input_data jsonb
);

-- MODELLED
-- Transformer table, spine of unique transformer ID
CREATE TABLE transformers (
    device_serial text PRIMARY KEY
);

-- Sensor table, position to height lookup
CREATE TABLE sensors (
    position_index int PRIMARY KEY,
    height numeric(4,2),
    submerged boolean,
    sensor_name text -- human-readable label, e.g. TX_00
);

-- Readings table, temperature data
CREATE TABLE readings (
    device_serial text REFERENCES transformers,
    position_index int REFERENCES sensors,
    measured_at timestamptz,
    temperature numeric(4,1),
    PRIMARY KEY (device_serial, position_index, measured_at)
);

